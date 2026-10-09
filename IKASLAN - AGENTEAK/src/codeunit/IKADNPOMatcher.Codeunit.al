codeunit 99121 "IKA DN PO Matcher"
{
    // Concilia un albarán (ya extraído) con los pedidos de compra abiertos:
    //  1. Proveedor y productos (codeunit "IKA DN Vendor Item Resolver").
    //  2. Pedidos citados en el albarán -> pedidos de compra de BC.
    //  3. Cada línea del albarán -> UNA línea de pedido con cantidad pendiente (la que mejor encaja).
    //     Si la cantidad supera el pendiente, se marca discrepancia para revisión.
    //  4. Discrepancias de cantidad y precio, duplicados y estado final.

    var
        Setup: Record "IKA Sales Agent Setup";
        Resolver: Codeunit "IKA DN Vendor Item Resolver";
        LogMgt: Codeunit "IKA DN Log Mgt.";
        AllocatedBaseQty: Dictionary of [Text, Decimal];
        UsedPurchLines: List of [Text];
        CandidateOrders: List of [Code[20]];
        NoQtyLbl: Label 'Sin cantidad en el albarán: no se recibe.';
        MethodLineRefLbl: Label 'Pedido indicado en la línea';
        MethodHeaderRefLbl: Label 'Pedido indicado en el albarán';
        MethodOtherOrderLbl: Label 'Otro pedido abierto del proveedor';
        OrderRefNotFoundLbl: Label 'Pedido "%1" no encontrado (o sin pendiente) para el proveedor.', Comment = '%1 = reference';
        NoOrderLineLbl: Label 'No hay línea de pedido abierta para este producto.';
        QtyDiscrepancyLbl: Label 'Recibe %1 y el pendiente es %2.', Comment = '%1 = qty, %2 = outstanding';
        PriceDiscrepancyLbl: Label 'Precio neto albarán %1 / pedido %2.', Comment = '%1 = dn net price, %2 = order net price';
        NoShipmentNoLbl: Label 'Falta el nº de albarán.';
        BadDateLbl: Label 'Fecha de albarán no válida: %1.', Comment = '%1 = date text';
        UnmatchedLinesLbl: Label '%1 línea(s) sin conciliar.', Comment = '%1 = count';
        DiscrepancyLinesLbl: Label '%1 línea(s) con discrepancias de cantidad.', Comment = '%1 = count';
        PriceDifferencesLbl: Label '%1 línea(s) con precio distinto al del pedido (aviso: se aplica la cantidad y se mantiene el precio del pedido).', Comment = '%1 = count';
        LowConfidenceLbl: Label 'Confianza %1 inferior al mínimo %2.', Comment = '%1 = confidence, %2 = minimum';
        NoLinesLbl: Label 'El albarán no tiene líneas.';
        DuplicateDocLbl: Label 'El albarán %1 de este proveedor ya se procesó (mov. %2).', Comment = '%1 = shipment no., %2 = entry no.';
        DuplicateReceiptLbl: Label 'Ya existe la recepción registrada %1 con el albarán %2.', Comment = '%1 = receipt no., %2 = shipment no.';

    procedure MatchDocument(var DNDocument: Record "IKA DN Document")
    var
        DocumentLine: Record "IKA DN Document Line";
    begin
        if DNDocument.Status in [DNDocument.Status::Applied, DNDocument.Status::Received, DNDocument.Status::Ignored] then
            exit;
        Setup.GetSetup();
        Clear(AllocatedBaseQty);
        Clear(UsedPurchLines);
        Clear(CandidateOrders);
        DNDocument."Review Notes" := '';
        DNDocument."Possible Duplicate" := false;

        Resolver.ResolveVendor(DNDocument);
        ResolveHeaderData(DNDocument);
        if DNDocument."Vendor No." <> '' then
            ResolveHeaderOrders(DNDocument);

        // Las líneas de pedido asignadas a mano quedan reservadas antes de asignar las demás
        DocumentLine.SetRange("Document Entry No.", DNDocument."Entry No.");
        DocumentLine.SetRange("Order Match Status", DocumentLine."Order Match Status"::Manual);
        if DocumentLine.FindSet() then
            repeat
                if (DocumentLine."Purchase Order No." <> '') and (DocumentLine."Purchase Order Line No." <> 0) then
                    UsedPurchLines.Add(DocumentLine."Purchase Order No." + '|' + Format(DocumentLine."Purchase Order Line No."));
            until DocumentLine.Next() = 0;
        DocumentLine.SetRange("Order Match Status");
        if DocumentLine.FindSet(true) then
            repeat
                MatchLine(DNDocument, DocumentLine);
                DocumentLine.Modify();
            until DocumentLine.Next() = 0;

        UpdateOrderSummary(DNDocument);
        CheckDuplicates(DNDocument);
        UpdateStatus(DNDocument);
        DNDocument.Modify();
    end;

    // ---------------- Cabecera ----------------

    local procedure ResolveHeaderData(var DNDocument: Record "IKA DN Document")
    var
        NoteDate: Date;
    begin
        if DNDocument."Vendor Shipment No." = '' then
            DNDocument."Vendor Shipment No." := CopyStr(UpperCase(DelChr(DNDocument."Ext. Delivery Note No.", '<>', ' ')), 1, MaxStrLen(DNDocument."Vendor Shipment No."));
        if DNDocument."Vendor Shipment No." = '' then
            DNDocument.AddReviewNote(NoShipmentNoLbl);

        if (DNDocument."Delivery Note Date" = 0D) and (DNDocument."Ext. Delivery Note Date" <> '') then
            if Evaluate(NoteDate, DNDocument."Ext. Delivery Note Date", 9) then
                DNDocument."Delivery Note Date" := NoteDate
            else
                DNDocument.AddReviewNote(StrSubstNo(BadDateLbl, DNDocument."Ext. Delivery Note Date"));
    end;

    local procedure ResolveHeaderOrders(var DNDocument: Record "IKA DN Document")
    var
        OrderRef: Text;
        OrderNo: Code[20];
    begin
        // Pedido asignado manualmente en cabecera: es el primer candidato
        if DNDocument."Purchase Order No." <> '' then
            AddCandidate(DNDocument."Purchase Order No.");

        foreach OrderRef in DNDocument."Ext. Order References".Split('|') do
            if DelChr(OrderRef, '=', ' ') <> '' then
                if FindPurchaseOrder(DNDocument."Vendor No.", OrderRef, OrderNo) then
                    AddCandidate(OrderNo)
                else
                    DNDocument.AddReviewNote(StrSubstNo(OrderRefNotFoundLbl, OrderRef));
    end;

    /// <summary>
    /// Busca nuestro pedido de compra a partir de la referencia que da el proveedor:
    /// nº exacto, "Nº pedido proveedor", "Su referencia" o nº que termina en la referencia (p.ej. "123" -> "PC-000123").
    /// </summary>
    procedure FindPurchaseOrder(VendorNo: Code[20]; OrderRef: Text; var OrderNo: Code[20]): Boolean
    var
        PurchaseHeader: Record "Purchase Header";
        CleanRef: Text;
    begin
        CleanRef := UpperCase(DelChr(OrderRef, '<>', ' '));
        if CleanRef = '' then
            exit(false);
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);

        if StrLen(CleanRef) <= MaxStrLen(PurchaseHeader."No.") then begin
            PurchaseHeader.SetRange("No.", CleanRef);
            if PurchaseHeader.FindFirst() then begin
                OrderNo := PurchaseHeader."No.";
                exit(true);
            end;
            PurchaseHeader.SetRange("No.");
        end;

        if StrLen(CleanRef) <= MaxStrLen(PurchaseHeader."Vendor Order No.") then begin
            PurchaseHeader.SetRange("Vendor Order No.", CleanRef);
            if PurchaseHeader.Count() = 1 then begin
                PurchaseHeader.FindFirst();
                OrderNo := PurchaseHeader."No.";
                exit(true);
            end;
            PurchaseHeader.SetRange("Vendor Order No.");
        end;

        if StrLen(CleanRef) <= MaxStrLen(PurchaseHeader."Your Reference") then begin
            PurchaseHeader.SetRange("Your Reference", CleanRef);
            if PurchaseHeader.Count() = 1 then begin
                PurchaseHeader.FindFirst();
                OrderNo := PurchaseHeader."No.";
                exit(true);
            end;
            PurchaseHeader.SetRange("Your Reference");
        end;

        // Coincidencia por final del número (el proveedor omite prefijos/ceros)
        CleanRef := Resolver.MakeSearchPattern(CleanRef);
        if StrLen(DelChr(CleanRef, '=', '?')) >= 3 then begin
            PurchaseHeader.SetFilter("No.", '*' + CleanRef);
            if PurchaseHeader.Count() = 1 then begin
                PurchaseHeader.FindFirst();
                OrderNo := PurchaseHeader."No.";
                exit(true);
            end;
        end;
        exit(false);
    end;

    local procedure AddCandidate(OrderNo: Code[20])
    begin
        if (OrderNo <> '') and not CandidateOrders.Contains(OrderNo) then
            CandidateOrders.Add(OrderNo);
    end;

    // ---------------- Líneas ----------------

    local procedure MatchLine(DNDocument: Record "IKA DN Document"; var DocumentLine: Record "IKA DN Document Line")
    var
        PurchaseLine: Record "Purchase Line";
        LineOrderNo: Code[20];
        ManualOrderLine: Boolean;
        Found: Boolean;
    begin
        ManualOrderLine := (DocumentLine."Order Match Status" = DocumentLine."Order Match Status"::Manual) and
            (DocumentLine."Purchase Order No." <> '') and (DocumentLine."Purchase Order Line No." <> 0);
        DocumentLine.ClearOrderMatch();

        Resolver.ResolveItem(DNDocument, DocumentLine, Setup."DN Allow Description Match");
        if DNDocument."Vendor No." = '' then
            exit;

        // 1. Línea de pedido asignada a mano
        if ManualOrderLine then
            if PurchaseLine.Get(PurchaseLine."Document Type"::Order, DocumentLine."Purchase Order No.", DocumentLine."Purchase Order Line No.") then begin
                SetOrderLine(DocumentLine, PurchaseLine, '');
                AddAllocated(PurchaseLine, GetDNQtyBase(DocumentLine, PurchaseLine));
                DocumentLine."Order Match Status" := DocumentLine."Order Match Status"::Manual;
                if DocumentLine."Item No." = '' then
                    DocumentLine."Item No." := PurchaseLine."No.";
                CheckDiscrepancies(DNDocument, DocumentLine, PurchaseLine);
                exit;
            end;

        DocumentLine."Purchase Order No." := '';
        DocumentLine."Purchase Order Line No." := 0;
        if DocumentLine."Item No." = '' then begin
            DocumentLine."Order Match Status" := DocumentLine."Order Match Status"::"Not Found";
            exit;
        end;

        // 2. Pedido indicado en la propia línea
        if DocumentLine."Ext. Order Reference" <> '' then
            if FindPurchaseOrder(DNDocument."Vendor No.", DocumentLine."Ext. Order Reference", LineOrderNo) then
                Found := FindBestPurchaseLine(DNDocument, DocumentLine, LineOrderNo, PurchaseLine, MethodLineRefLbl);

        // 3. Pedidos indicados en cabecera
        if not Found and (CandidateOrders.Count() > 0) then
            Found := FindBestPurchaseLine(DNDocument, DocumentLine, GetCandidateFilter(), PurchaseLine, MethodHeaderRefLbl);

        // 4. Cualquier pedido abierto del proveedor
        if not Found and Setup."Search Other Open Orders" then
            Found := FindBestPurchaseLine(DNDocument, DocumentLine, '', PurchaseLine, MethodOtherOrderLbl);

        if not Found then begin
            DocumentLine."Order Match Status" := DocumentLine."Order Match Status"::"Not Found";
            DocumentLine."Discrepancy Text" := NoOrderLineLbl;
            exit;
        end;
        CheckDiscrepancies(DNDocument, DocumentLine, PurchaseLine);
    end;

    /// <summary>
    /// Elige la línea de pedido abierta del producto para esta línea del albarán. Cada línea de pedido se
    /// asigna a UNA sola línea del albarán (los albaranes suelen repetir el pedido línea a línea, también
    /// las que no traen cantidad). Entre las libres gana la de la misma descripción, después la de la misma
    /// fecha de entrega y, a igualdad, la primera del pedido (misma posición). Si ya están todas asignadas,
    /// la que tenga más pendiente sin asignar (la cantidad se revisará como discrepancia).
    /// </summary>
    local procedure FindBestPurchaseLine(DNDocument: Record "IKA DN Document"; var DocumentLine: Record "IKA DN Document Line"; OrderFilter: Text; var BestPurchaseLine: Record "Purchase Line"; Method: Text): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        RemainingBase: Decimal;
        BestRemainingBase: Decimal;
        Score: Integer;
        BestScore: Integer;
        IsFree: Boolean;
        BestIsFree: Boolean;
        Better: Boolean;
        Found: Boolean;
    begin
        Resolver.FilterOpenOrderLines(PurchaseLine, DNDocument."Vendor No.");
        PurchaseLine.SetRange("No.", DocumentLine."Item No.");
        if DocumentLine."Variant Code" <> '' then
            PurchaseLine.SetRange("Variant Code", DocumentLine."Variant Code");
        if OrderFilter <> '' then
            PurchaseLine.SetFilter("Document No.", OrderFilter);
        if not PurchaseLine.FindSet() then
            exit(false);

        // FindSet recorre por nº de pedido y nº de línea: a igualdad se queda la primera (posición)
        repeat
            IsFree := not UsedPurchLines.Contains(PurchLineKey(PurchaseLine));
            RemainingBase := PurchaseLine."Outstanding Qty. (Base)" - GetAllocated(PurchaseLine);
            Score := GetMatchScore(DocumentLine, PurchaseLine);
            if not Found then
                Better := true
            else
                if IsFree <> BestIsFree then
                    Better := IsFree
                else
                    if IsFree then
                        Better := Score > BestScore
                    else
                        Better := RemainingBase > BestRemainingBase;
            if Better then begin
                BestPurchaseLine := PurchaseLine;
                BestRemainingBase := RemainingBase;
                BestScore := Score;
                BestIsFree := IsFree;
                Found := true;
            end;
        until PurchaseLine.Next() = 0;

        SetOrderLine(DocumentLine, BestPurchaseLine, Method);
        AddAllocated(BestPurchaseLine, GetDNQtyBase(DocumentLine, BestPurchaseLine));
        MarkUsed(BestPurchaseLine);
        DocumentLine."Order Outstanding Qty." := Round(BestRemainingBase / GetQtyPerUoM(BestPurchaseLine), 0.00001);
        exit(true);
    end;

    /// <summary>
    /// Cuánto se parece la línea de pedido a la del albarán: misma posición (4), misma descripción (2)
    /// y misma fecha de entrega (1).
    /// </summary>
    local procedure GetMatchScore(DocumentLine: Record "IKA DN Document Line"; PurchaseLine: Record "Purchase Line"): Integer
    var
        Score: Integer;
        Position: Integer;
    begin
        // Posición 2 = línea 2, 20, 200, 2000 o 20000 del pedido (según cómo numere BC y cómo la imprima el proveedor)
        if Evaluate(Position, DelChr(DocumentLine."Ext. Position", '=', ' .')) then
            if Position > 0 then
                if PurchaseLine."Line No." in [Position, Position * 10, Position * 100, Position * 1000, Position * 10000] then
                    Score += 4;
        if DocumentLine."Ext. Description" <> '' then
            if SameText(DocumentLine."Ext. Description", PurchaseLine.Description) or
               SameText(DocumentLine."Ext. Description", PurchaseLine.Description + PurchaseLine."Description 2")
            then
                Score += 2;
        if DocumentLine."Delivery Date" <> 0D then
            if DocumentLine."Delivery Date" in [PurchaseLine."Expected Receipt Date", PurchaseLine."Requested Receipt Date", PurchaseLine."Promised Receipt Date"] then
                Score += 1;
        exit(Score);
    end;

    local procedure SameText(Text1: Text; Text2: Text): Boolean
    begin
        exit(UpperCase(DelChr(Text1, '=', ' .,-/')) = UpperCase(DelChr(Text2, '=', ' .,-/')));
    end;

    local procedure MarkUsed(PurchaseLine: Record "Purchase Line")
    begin
        if not UsedPurchLines.Contains(PurchLineKey(PurchaseLine)) then
            UsedPurchLines.Add(PurchLineKey(PurchaseLine));
    end;

    local procedure SetOrderLine(var DocumentLine: Record "IKA DN Document Line"; PurchaseLine: Record "Purchase Line"; Method: Text)
    begin
        DocumentLine."Purchase Order No." := PurchaseLine."Document No.";
        DocumentLine."Purchase Order Line No." := PurchaseLine."Line No.";
        DocumentLine."Order Matched" := true;
        DocumentLine."Order Match Status" := DocumentLine."Order Match Status"::Matched;
        DocumentLine."Order Match Method" := CopyStr(Method, 1, MaxStrLen(DocumentLine."Order Match Method"));
        DocumentLine."Order Outstanding Qty." := PurchaseLine."Outstanding Quantity";
        DocumentLine."Order Unit Cost" := PurchaseLine."Direct Unit Cost";
        DocumentLine."Order Discount %" := PurchaseLine."Line Discount %";
        DocumentLine."Order Unit of Measure" := PurchaseLine."Unit of Measure Code";
        DocumentLine."Qty. to Receive (Order UoM)" := Round(GetDNQtyBase(DocumentLine, PurchaseLine) / GetQtyPerUoM(PurchaseLine), 0.00001);
        if DocumentLine."Variant Code" = '' then
            DocumentLine."Variant Code" := PurchaseLine."Variant Code";
    end;

    // ---------------- Discrepancias ----------------

    local procedure CheckDiscrepancies(DNDocument: Record "IKA DN Document"; var DocumentLine: Record "IKA DN Document Line"; PurchaseLine: Record "Purchase Line")
    var
        DNNetPrice: Decimal;
        OrderNetPrice: Decimal;
        DiffPct: Decimal;
        RoundingTolerance: Decimal;
        Note: Text;
    begin
        // Cantidad (en la unidad del pedido)
        if (DocumentLine."Qty. to Receive (Order UoM)" > DocumentLine."Order Outstanding Qty.") and not Setup."Allow Over-Receipt" then begin
            DocumentLine."Qty. Discrepancy" := true;
            Note := StrSubstNo(QtyDiscrepancyLbl, DocumentLine."Qty. to Receive (Order UoM)", DocumentLine."Order Outstanding Qty.");
        end;
        if DocumentLine.Quantity < 0 then
            DocumentLine."Qty. Discrepancy" := true;
        // Línea sin cantidad: solo sitúa el artículo en el pedido; no es discrepancia
        if DocumentLine.Quantity = 0 then
            Note := NoQtyLbl;

        // Precio neto (convertido a la unidad del pedido)
        if DNDocument."Prices Included" and (DocumentLine.Quantity <> 0) and (DocumentLine."Unit Price" <> 0) and (PurchaseLine."Direct Unit Cost" <> 0) then begin
            DNNetPrice := DocumentLine."Unit Price" * (1 - DocumentLine."Discount %" / 100) *
                GetQtyPerUoM(PurchaseLine) / GetDNQtyPerUoM(DocumentLine, PurchaseLine);
            OrderNetPrice := PurchaseLine."Direct Unit Cost" * (1 - PurchaseLine."Line Discount %" / 100);
            DiffPct := Abs(DNNetPrice - OrderNetPrice) / OrderNetPrice * 100;
            // Además del %, se admite el redondeo del precio impreso (0,0018 puede ser 0,00178 en el pedido)
            RoundingTolerance := GetPrintedPrecision(DocumentLine."Unit Price") / 2 *
                GetQtyPerUoM(PurchaseLine) / GetDNQtyPerUoM(DocumentLine, PurchaseLine);
            if (DiffPct > Setup."Price Tolerance %") and (Abs(DNNetPrice - OrderNetPrice) > RoundingTolerance) then begin
                DocumentLine."Price Discrepancy" := true;
                if Note <> '' then
                    Note += ' ';
                Note += StrSubstNo(PriceDiscrepancyLbl, Round(DNNetPrice, 0.00001), Round(OrderNetPrice, 0.00001));
            end;
        end;

        DocumentLine."Has Discrepancy" := DocumentLine."Qty. Discrepancy" or DocumentLine."Price Discrepancy";
        DocumentLine."Discrepancy Text" := CopyStr(Note, 1, MaxStrLen(DocumentLine."Discrepancy Text"));
    end;

    /// <summary>
    /// Valor de la última cifra decimal con que viene el precio: 0,0018 -> 0,0001; 1,27 -> 0,01; 5 -> 1.
    /// </summary>
    local procedure GetPrintedPrecision(Price: Decimal): Decimal
    var
        PriceText: Text;
        Decimals: Integer;
    begin
        PriceText := Format(Price, 0, 9);
        if StrPos(PriceText, '.') = 0 then
            exit(1);
        Decimals := StrLen(PriceText) - StrPos(PriceText, '.');
        exit(Power(10, -Decimals));
    end;

    // ---------------- Unidades de medida ----------------

    local procedure GetDNQtyBase(DocumentLine: Record "IKA DN Document Line"; PurchaseLine: Record "Purchase Line"): Decimal
    begin
        exit(DocumentLine.Quantity * GetDNQtyPerUoM(DocumentLine, PurchaseLine));
    end;

    /// <summary>
    /// Cantidad por unidad de la unidad del albarán. Si no se reconoció, se asume la del pedido.
    /// </summary>
    local procedure GetDNQtyPerUoM(DocumentLine: Record "IKA DN Document Line"; PurchaseLine: Record "Purchase Line"): Decimal
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        if DocumentLine."Unit of Measure Code" <> '' then
            if ItemUnitOfMeasure.Get(PurchaseLine."No.", DocumentLine."Unit of Measure Code") then
                if ItemUnitOfMeasure."Qty. per Unit of Measure" <> 0 then
                    exit(ItemUnitOfMeasure."Qty. per Unit of Measure");
        exit(GetQtyPerUoM(PurchaseLine));
    end;

    local procedure GetQtyPerUoM(PurchaseLine: Record "Purchase Line"): Decimal
    begin
        if PurchaseLine."Qty. per Unit of Measure" = 0 then
            exit(1);
        exit(PurchaseLine."Qty. per Unit of Measure");
    end;

    local procedure GetAllocated(PurchaseLine: Record "Purchase Line"): Decimal
    var
        Allocated: Decimal;
    begin
        if AllocatedBaseQty.Get(PurchLineKey(PurchaseLine), Allocated) then
            exit(Allocated);
        exit(0);
    end;

    local procedure AddAllocated(PurchaseLine: Record "Purchase Line"; QtyBase: Decimal)
    begin
        AllocatedBaseQty.Set(PurchLineKey(PurchaseLine), GetAllocated(PurchaseLine) + QtyBase);
    end;

    local procedure PurchLineKey(PurchaseLine: Record "Purchase Line"): Text
    begin
        exit(PurchaseLine."Document No." + '|' + Format(PurchaseLine."Line No."));
    end;

    local procedure GetCandidateFilter(): Text
    var
        OrderNo: Code[20];
        Result: Text;
    begin
        foreach OrderNo in CandidateOrders do begin
            if Result <> '' then
                Result += '|';
            Result += OrderNo;
        end;
        exit(Result);
    end;

    // ---------------- Resumen, duplicados y estado ----------------

    local procedure UpdateOrderSummary(var DNDocument: Record "IKA DN Document")
    var
        DocumentLine: Record "IKA DN Document Line";
        Orders: List of [Code[20]];
    begin
        DocumentLine.SetRange("Document Entry No.", DNDocument."Entry No.");
        DocumentLine.SetRange("Order Matched", true);
        if DocumentLine.FindSet() then
            repeat
                if not Orders.Contains(DocumentLine."Purchase Order No.") then
                    Orders.Add(DocumentLine."Purchase Order No.");
            until DocumentLine.Next() = 0;
        DNDocument."No. of Orders" := Orders.Count();
        if DNDocument."Purchase Order No." = '' then
            if Orders.Count() > 0 then
                DNDocument."Purchase Order No." := Orders.Get(1)
            else
                if CandidateOrders.Count() > 0 then
                    DNDocument."Purchase Order No." := CandidateOrders.Get(1);
    end;

    local procedure CheckDuplicates(var DNDocument: Record "IKA DN Document")
    var
        OtherDocument: Record "IKA DN Document";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
    begin
        if (DNDocument."Vendor No." = '') or (DNDocument."Vendor Shipment No." = '') then
            exit;
        OtherDocument.SetRange("Vendor No.", DNDocument."Vendor No.");
        OtherDocument.SetRange("Vendor Shipment No.", DNDocument."Vendor Shipment No.");
        OtherDocument.SetFilter("Entry No.", '<>%1', DNDocument."Entry No.");
        OtherDocument.SetFilter(Status, '<>%1&<>%2', OtherDocument.Status::Ignored, OtherDocument.Status::Error);
        if OtherDocument.FindFirst() then begin
            DNDocument."Possible Duplicate" := true;
            DNDocument.AddReviewNote(StrSubstNo(DuplicateDocLbl, DNDocument."Vendor Shipment No.", OtherDocument."Entry No."));
            exit;
        end;
        PurchRcptHeader.SetRange("Buy-from Vendor No.", DNDocument."Vendor No.");
        PurchRcptHeader.SetRange("Vendor Shipment No.", DNDocument."Vendor Shipment No.");
        if PurchRcptHeader.FindFirst() then begin
            DNDocument."Possible Duplicate" := true;
            DNDocument.AddReviewNote(StrSubstNo(DuplicateReceiptLbl, PurchRcptHeader."No.", DNDocument."Vendor Shipment No."));
        end;
    end;

    local procedure UpdateStatus(var DNDocument: Record "IKA DN Document")
    var
        DocumentLine: Record "IKA DN Document Line";
        IsMatched: Boolean;
        UnacceptedDiscrepancies: Integer;
        PriceDifferences: Integer;
    begin
        DNDocument.CalcFields("No. of Lines", "No. of Unmatched Lines");
        DocumentLine.SetRange("Document Entry No.", DNDocument."Entry No.");
        // Solo bloquean las discrepancias de cantidad; el precio es informativo (se mantiene el del pedido)
        DocumentLine.SetRange("Qty. Discrepancy", true);
        DocumentLine.SetRange("Accept Discrepancy", false);
        UnacceptedDiscrepancies := DocumentLine.Count();
        DocumentLine.SetRange("Qty. Discrepancy", false);
        DocumentLine.SetRange("Price Discrepancy", true);
        PriceDifferences := DocumentLine.Count();

        IsMatched := DNDocument."Vendor Match Status" in [DNDocument."Vendor Match Status"::Matched, DNDocument."Vendor Match Status"::Manual];
        if DNDocument."Vendor Shipment No." = '' then
            IsMatched := false;
        if DNDocument."No. of Lines" = 0 then begin
            IsMatched := false;
            DNDocument.AddReviewNote(NoLinesLbl);
        end;
        if DNDocument."No. of Unmatched Lines" > 0 then begin
            IsMatched := false;
            DNDocument.AddReviewNote(StrSubstNo(UnmatchedLinesLbl, DNDocument."No. of Unmatched Lines"));
        end;
        if UnacceptedDiscrepancies > 0 then begin
            IsMatched := false;
            DNDocument.AddReviewNote(StrSubstNo(DiscrepancyLinesLbl, UnacceptedDiscrepancies));
        end;
        if PriceDifferences > 0 then
            DNDocument.AddReviewNote(StrSubstNo(PriceDifferencesLbl, PriceDifferences));
        if DNDocument."Possible Duplicate" then
            IsMatched := false;
        if DNDocument.Confidence < Setup."DN Min. Confidence" then begin
            IsMatched := false;
            DNDocument.AddReviewNote(StrSubstNo(LowConfidenceLbl, DNDocument.Confidence, Setup."DN Min. Confidence"));
        end;

        if IsMatched then
            DNDocument.Status := DNDocument.Status::Matched
        else
            DNDocument.Status := DNDocument.Status::"Needs Review";
        LogMgt.LogInfo(DNDocument."Entry No.", Format(DNDocument.Status) + ': ' + DNDocument."Review Notes");
    end;
}
