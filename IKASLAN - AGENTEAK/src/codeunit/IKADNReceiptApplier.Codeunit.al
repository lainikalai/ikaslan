codeunit 99126 "IKA DN Receipt Applier"
{
    // Aplica un albarán conciliado a los pedidos de compra:
    //  - "Nº albarán proveedor" (Vendor Shipment No.) en la cabecera de cada pedido afectado.
    //  - "Cant. a recibir" en cada línea de pedido conciliada (opcionalmente, 0 en el resto).
    // Todo con Validate, para que BC aplique su lógica estándar.
    // Opcionalmente registra la recepción (sin factura).

    var
        Setup: Record "IKA Sales Agent Setup";
        LogMgt: Codeunit "IKA DN Log Mgt.";
        WrongStatusErr: Label 'No se puede aplicar un albarán en estado %1.', Comment = '%1 = status';
        NoMatchedLinesErr: Label 'El albarán %1 no tiene ninguna línea conciliada con un pedido.', Comment = '%1 = entry no.';
        NotReadyErr: Label 'El albarán %1 no está conciliado sin discrepancias; revíselo antes de aplicarlo.', Comment = '%1 = entry no.';
        PendingIssuesQst: Label 'El albarán tiene %1 línea(s) sin conciliar y %2 con discrepancias de cantidad sin aceptar:%3\Esas líneas NO se aplicarán (para aplicarlas, marque "Aceptar discrepancia" en la línea). ¿Aplicar el resto?', Comment = '%1 = unmatched, %2 = discrepancies, %3 = list of lines with their discrepancy';
        DiscrepancyLineLbl: Label '\- %1: %2', Comment = '%1 = item, %2 = discrepancy text';
        PriceDifferencesQst: Label 'Hay %1 línea(s) con un precio distinto al del pedido:%2\Se llevará la cantidad a recibir; el precio del pedido no se modifica. ¿Continuar?', Comment = '%1 = count, %2 = list of lines with their price difference';
        DuplicateQst: Label 'El albarán está marcado como posible duplicado. ¿Desea aplicarlo igualmente?';
        AppliedLbl: Label 'Aplicado a %1 pedido(s): %2.', Comment = '%1 = count, %2 = order list';
        PostedLbl: Label 'Recepción registrada: %1.', Comment = '%1 = receipt nos.';
        NotAppliedErr: Label 'Primero hay que aplicar el albarán a los pedidos.';

    procedure ApplyToOrders(var DNDocument: Record "IKA DN Document")
    var
        DocumentLine: Record "IKA DN Document Line";
        QtyByPurchLine: Dictionary of [Text, Decimal];
        Orders: List of [Code[20]];
        OrderNo: Code[20];
        LineKey: Text;
        Qty: Decimal;
        OrderList: Text;
    begin
        CheckBeforeApply(DNDocument);

        DocumentLine.SetRange("Document Entry No.", DNDocument."Entry No.");
        DocumentLine.SetRange("Order Matched", true);
        DocumentLine.FindSet();
        repeat
            // Las líneas sin cantidad solo sirven para situar las demás: no se aplican al pedido.
            // Una diferencia de precio no impide aplicar: al pedido solo se lleva la cantidad.
            if ((not DocumentLine."Qty. Discrepancy") or DocumentLine."Accept Discrepancy") and (DocumentLine."Qty. to Receive (Order UoM)" <> 0) then begin
                LineKey := DocumentLine."Purchase Order No." + '|' + Format(DocumentLine."Purchase Order Line No.");
                if QtyByPurchLine.Get(LineKey, Qty) then
                    QtyByPurchLine.Set(LineKey, Qty + DocumentLine."Qty. to Receive (Order UoM)")
                else
                    QtyByPurchLine.Add(LineKey, DocumentLine."Qty. to Receive (Order UoM)");
                if not Orders.Contains(DocumentLine."Purchase Order No.") then
                    Orders.Add(DocumentLine."Purchase Order No.");
            end;
        until DocumentLine.Next() = 0;
        if Orders.Count() = 0 then
            Error(NoMatchedLinesErr, DNDocument."Entry No.");

        foreach OrderNo in Orders do begin
            PrepareOrderHeader(DNDocument, OrderNo);
            if OrderList <> '' then
                OrderList += ', ';
            OrderList += OrderNo;
        end;
        foreach LineKey in QtyByPurchLine.Keys() do
            SetQtyToReceive(LineKey, QtyByPurchLine.Get(LineKey));

        DNDocument.Status := DNDocument.Status::Applied;
        DNDocument."Applied At" := CurrentDateTime();
        DNDocument."Applied By" := CopyStr(UserId(), 1, MaxStrLen(DNDocument."Applied By"));
        DNDocument.Modify();
        LogMgt.LogInfo(DNDocument."Entry No.", StrSubstNo(AppliedLbl, Orders.Count(), OrderList));
    end;

    local procedure CheckBeforeApply(var DNDocument: Record "IKA DN Document")
    var
        DocumentLine: Record "IKA DN Document Line";
        Discrepancies: Integer;
        DiscrepancyList: Text;
        PriceDifferences: Integer;
        PriceList: Text;
    begin
        Setup.GetSetup();
        if not (DNDocument.Status in [DNDocument.Status::Matched, DNDocument.Status::"Needs Review"]) then
            Error(WrongStatusErr, DNDocument.Status);
        DNDocument.TestField("Vendor No.");
        DNDocument.TestField("Vendor Shipment No.");

        DNDocument.CalcFields("No. of Unmatched Lines");
        DocumentLine.SetRange("Document Entry No.", DNDocument."Entry No.");
        DocumentLine.SetRange("Qty. Discrepancy", true);
        DocumentLine.SetRange("Accept Discrepancy", false);
        Discrepancies := DocumentLine.Count();
        DiscrepancyList := GetDiscrepancyList(DocumentLine);
        DocumentLine.SetRange("Qty. Discrepancy", false);
        DocumentLine.SetRange("Price Discrepancy", true);
        PriceDifferences := DocumentLine.Count();
        PriceList := GetDiscrepancyList(DocumentLine);

        if not GuiAllowed() then begin
            // En automático solo se aplica lo que está totalmente conciliado
            if DNDocument.Status <> DNDocument.Status::Matched then
                Error(NotReadyErr, DNDocument."Entry No.");
            exit;
        end;
        if (DNDocument."No. of Unmatched Lines" > 0) or (Discrepancies > 0) then
            if not Confirm(PendingIssuesQst, false, DNDocument."No. of Unmatched Lines", Discrepancies, DiscrepancyList) then
                Error('');
        if PriceDifferences > 0 then
            if not Confirm(PriceDifferencesQst, false, PriceDifferences, PriceList) then
                Error('');
        if DNDocument."Possible Duplicate" then
            if not Confirm(DuplicateQst, false) then
                Error('');
    end;

    local procedure GetDiscrepancyList(var DocumentLine: Record "IKA DN Document Line") Result: Text
    begin
        if DocumentLine.FindSet() then
            repeat
                if StrLen(Result) < 500 then
                    Result += StrSubstNo(DiscrepancyLineLbl, DocumentLine.GetDisplayText(), DocumentLine."Discrepancy Text");
            until DocumentLine.Next() = 0;
    end;

    local procedure PrepareOrderHeader(DNDocument: Record "IKA DN Document"; OrderNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderNo);
        PurchaseHeader.Validate("Vendor Shipment No.", DNDocument."Vendor Shipment No.");
        PurchaseHeader."IKA DN Document Entry No." := DNDocument."Entry No.";
        OnBeforeModifyPurchaseHeader(DNDocument, PurchaseHeader);
        PurchaseHeader.Modify(true);

        if Setup."Reset Qty. to Receive" then begin
            PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
            PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
            PurchaseLine.SetFilter("Qty. to Receive", '<>0');
            if PurchaseLine.FindSet(true) then
                repeat
                    PurchaseLine.Validate("Qty. to Receive", 0);
                    PurchaseLine.Modify(true);
                until PurchaseLine.Next() = 0;
        end;
    end;

    local procedure SetQtyToReceive(LineKey: Text; Qty: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
        Parts: List of [Text];
        LineNo: Integer;
    begin
        Parts := LineKey.Split('|');
        Evaluate(LineNo, Parts.Get(2));
        PurchaseLine.Get(PurchaseLine."Document Type"::Order, Parts.Get(1), LineNo);
        if Setup."Reset Qty. to Receive" then
            PurchaseLine.Validate("Qty. to Receive", Qty)
        else
            PurchaseLine.Validate("Qty. to Receive", PurchaseLine."Qty. to Receive" + Qty);
        OnBeforeModifyPurchaseLine(PurchaseLine);
        PurchaseLine.Modify(true);
    end;

    /// <summary>
    /// Registra la recepción (sin factura) de todos los pedidos a los que se aplicó el albarán.
    /// </summary>
    procedure PostReceipts(var DNDocument: Record "IKA DN Document")
    var
        DocumentLine: Record "IKA DN Document Line";
        PurchaseHeader: Record "Purchase Header";
        PurchPost: Codeunit "Purch.-Post";
        Orders: List of [Code[20]];
        OrderNo: Code[20];
        ReceiptNos: Text;
    begin
        if DNDocument.Status <> DNDocument.Status::Applied then
            Error(NotAppliedErr);

        DocumentLine.SetRange("Document Entry No.", DNDocument."Entry No.");
        DocumentLine.SetRange("Order Matched", true);
        DocumentLine.SetFilter("Qty. to Receive (Order UoM)", '<>0');
        if DocumentLine.FindSet() then
            repeat
                if not Orders.Contains(DocumentLine."Purchase Order No.") then
                    Orders.Add(DocumentLine."Purchase Order No.");
            until DocumentLine.Next() = 0;

        foreach OrderNo in Orders do begin
            PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderNo);
            PurchaseHeader.Receive := true;
            PurchaseHeader.Invoice := false;
            Clear(PurchPost);
            PurchPost.Run(PurchaseHeader);
            PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderNo);
            if ReceiptNos <> '' then
                ReceiptNos += ', ';
            ReceiptNos += PurchaseHeader."Last Receiving No.";
        end;

        DNDocument."Posted Receipt Nos." := CopyStr(ReceiptNos, 1, MaxStrLen(DNDocument."Posted Receipt Nos."));
        DNDocument.Status := DNDocument.Status::Received;
        DNDocument.Modify();
        LogMgt.LogInfo(DNDocument."Entry No.", StrSubstNo(PostedLbl, ReceiptNos));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPurchaseHeader(DNDocument: Record "IKA DN Document"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyPurchaseLine(var PurchaseLine: Record "Purchase Line")
    begin
    end;
}
