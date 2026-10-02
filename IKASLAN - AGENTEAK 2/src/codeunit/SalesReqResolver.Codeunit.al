codeunit 50030 "IKA Sales Req. Resolver"
{
    // Convierte los datos "en bruto" extraídos por Claude en registros de Business Central:
    // cliente, dirección de envío, productos, variantes y unidades de medida.
    // Aquí no interviene Claude: toda la lógica es determinista y auditable.

    var
        Setup: Record "IKA Sales Agent Setup";
        LogMgt: Codeunit "IKA Sales Agent Log Mgt.";
        MethodMailFilterLbl: Label 'Filtro de correo';
        MethodCustomerNoLbl: Label 'Nº cliente';
        MethodVatLbl: Label 'NIF';
        MethodEmailLbl: Label 'Email';
        MethodDomainLbl: Label 'Dominio remitente';
        MethodNameLbl: Label 'Nombre';
        MethodCustomerRefLbl: Label 'Referencia cliente';
        MethodItemNoLbl: Label 'Nº producto';
        MethodOtherRefLbl: Label 'Otra referencia (EAN...)';
        MethodDescriptionLbl: Label 'Descripción';
        CustomerNotFoundLbl: Label 'No se ha identificado el cliente.';
        CustomerAmbiguousLbl: Label 'Hay varios clientes posibles (%1).', Comment = '%1 = method';
        CustomerBlockedLbl: Label 'El cliente %1 está bloqueado (%2).', Comment = '%1 = customer no., %2 = blocked';
        ItemAmbiguousLbl: Label 'Varios productos coinciden por %1.', Comment = '%1 = method';
        ItemBlockedLbl: Label 'El producto %1 está bloqueado para venta.', Comment = '%1 = item no.';
        ItemNotFoundLbl: Label 'Producto no encontrado.';
        ZeroQtyLbl: Label 'Cantidad 0 o no indicada.';
        UoMNotFoundLbl: Label 'Unidad "%1" no encontrada para el producto; se usará la de venta por defecto.', Comment = '%1 = unit';
        DuplicateLbl: Label 'Ya existe el pedido %1 para este cliente con el mismo nº de documento externo.', Comment = '%1 = order no.';
        DuplicatePostedLbl: Label 'Ya existe la factura registrada %1 para este cliente con el mismo nº de documento externo.', Comment = '%1 = invoice no.';
        BadDateLbl: Label 'Fecha de entrega no válida: %1.', Comment = '%1 = date text';
        UnresolvedLinesLbl: Label '%1 línea(s) sin resolver.', Comment = '%1 = count';
        LowConfidenceLbl: Label 'Confianza %1 inferior al mínimo %2.', Comment = '%1 = confidence, %2 = minimum';
        NoLinesLbl: Label 'La solicitud no tiene líneas.';
        ShipToNotFoundLbl: Label 'Dirección de envío "%1" no encontrada; revise el código de dirección de envío.', Comment = '%1 = ship-to text';

    procedure ResolveRequest(var RequestHeader: Record "IKA Sales Request Header")
    begin
        if RequestHeader.Status in [RequestHeader.Status::"Order Created", RequestHeader.Status::Ignored] then
            exit;
        Setup.GetSetup();
        RequestHeader."Error Message" := '';
        RequestHeader."Possible Duplicate" := false;

        ResolveCustomer(RequestHeader);
        ResolveHeaderData(RequestHeader);
        ResolveLines(RequestHeader);
        CheckDuplicates(RequestHeader);
        UpdateStatus(RequestHeader);
        RequestHeader.Modify();
    end;

    // ---------------- Cliente ----------------

    local procedure ResolveCustomer(var RequestHeader: Record "IKA Sales Request Header")
    var
        MailFilter: Record "IKA Sales Agent Mail Filter";
        Customer: Record Customer;
    begin
        if (RequestHeader."Customer Match Status" = RequestHeader."Customer Match Status"::Manual) and (RequestHeader."Customer No." <> '') then begin
            CheckCustomerBlocked(RequestHeader);
            exit;
        end;
        RequestHeader."Customer No." := '';
        RequestHeader."Customer Match Status" := RequestHeader."Customer Match Status"::"Not Found";
        RequestHeader."Customer Match Method" := '';

        // 1. Cliente fijado en el filtro de correo que dejó pasar el email
        if MailFilter.Get(RequestHeader."Mail Filter Line No.") then
            if MailFilter."Customer No." <> '' then
                if SetCustomer(RequestHeader, MailFilter."Customer No.", MethodMailFilterLbl) then
                    exit;

        // 2. Nº de cliente indicado en el documento
        if (RequestHeader."Ext. Customer Code" <> '') and (StrLen(RequestHeader."Ext. Customer Code") <= MaxStrLen(Customer."No.")) then
            if Customer.Get(UpperCase(RequestHeader."Ext. Customer Code")) then
                if SetCustomer(RequestHeader, Customer."No.", MethodCustomerNoLbl) then
                    exit;

        // 3. NIF
        if TryMatchCustomerByVat(RequestHeader) then
            exit;

        // 4. Email exacto (el extraído y el del remitente)
        if TryMatchCustomerByEmail(RequestHeader, RequestHeader."Ext. Customer E-Mail") then
            exit;
        if TryMatchCustomerByEmail(RequestHeader, RequestHeader."Sender Address") then
            exit;

        // 5. Dominio del remitente
        if TryMatchCustomerByDomain(RequestHeader) then
            exit;

        // 6. Nombre
        if TryMatchCustomerByName(RequestHeader) then
            exit;

        if RequestHeader."Customer Match Status" = RequestHeader."Customer Match Status"::"Not Found" then
            RequestHeader.AddToErrorMessage(CustomerNotFoundLbl);
    end;

    local procedure TryMatchCustomerByVat(var RequestHeader: Record "IKA Sales Request Header"): Boolean
    var
        Customer: Record Customer;
        Vat: Text;
    begin
        Vat := UpperCase(DelChr(RequestHeader."Ext. VAT Registration No.", '=', ' .-/'));
        if StrLen(Vat) < 5 then
            exit(false);
        // Con y sin prefijo de país (ES)
        if CopyStr(Vat, 1, 2) = 'ES' then
            Vat := DelStr(Vat, 1, 2);
        Customer.SetFilter("VAT Registration No.", '%1|%2', Vat, 'ES' + Vat);
        exit(MatchSingleCustomer(RequestHeader, Customer, MethodVatLbl));
    end;

    local procedure TryMatchCustomerByEmail(var RequestHeader: Record "IKA Sales Request Header"; Email: Text): Boolean
    var
        Customer: Record Customer;
    begin
        Email := LowerCase(DelChr(Email, '<>', ' '));
        if (Email = '') or (StrPos(Email, '@') = 0) or (StrLen(Email) > MaxStrLen(Customer."E-Mail")) then
            exit(false);
        Customer.SetRange("E-Mail", Email);
        exit(MatchSingleCustomer(RequestHeader, Customer, MethodEmailLbl));
    end;

    local procedure TryMatchCustomerByDomain(var RequestHeader: Record "IKA Sales Request Header"): Boolean
    var
        Customer: Record Customer;
        Domain: Text;
        FoundCustomerNo: Code[20];
        MatchCount: Integer;
    begin
        if StrPos(RequestHeader."Sender Address", '@') = 0 then
            exit(false);
        Domain := LowerCase(CopyStr(RequestHeader."Sender Address", StrPos(RequestHeader."Sender Address", '@') + 1));
        // Solo dominios "normales" (letras, números, punto y guion), para poder usarlos en un filtro
        if IsGenericDomain(Domain) or (DelChr(Domain, '=', 'abcdefghijklmnopqrstuvwxyz0123456789.-') <> '') then
            exit(false);
        Customer.SetFilter("E-Mail", '@*' + Domain + '*');
        if Customer.FindSet() then
            repeat
                // Puede haber varios emails separados por ; en el campo
                if StrPos(';' + DelChr(LowerCase(Customer."E-Mail"), '=', ' ') + ';', '@' + Domain + ';') > 0 then
                    if Customer."No." <> FoundCustomerNo then begin
                        MatchCount += 1;
                        FoundCustomerNo := Customer."No.";
                    end;
            until (Customer.Next() = 0) or (MatchCount > 1);

        case MatchCount of
            0:
                exit(false);
            1:
                exit(SetCustomer(RequestHeader, FoundCustomerNo, MethodDomainLbl));
            else begin
                if RequestHeader."Customer Match Status" <> RequestHeader."Customer Match Status"::Ambiguous then
                    RequestHeader.AddToErrorMessage(StrSubstNo(CustomerAmbiguousLbl, MethodDomainLbl));
                RequestHeader."Customer Match Status" := RequestHeader."Customer Match Status"::Ambiguous;
                exit(false);
            end;
        end;
    end;

    local procedure TryMatchCustomerByName(var RequestHeader: Record "IKA Sales Request Header"): Boolean
    var
        Customer: Record Customer;
        SearchName: Text;
    begin
        SearchName := MakeSearchPattern(RequestHeader."Ext. Customer Name");
        if StrLen(DelChr(SearchName, '=', '?')) < 3 then
            exit(false);
        Customer.SetFilter(Name, '@*' + SearchName + '*');
        if MatchSingleCustomer(RequestHeader, Customer, MethodNameLbl) then
            exit(true);
        if RequestHeader."Customer Match Status" = RequestHeader."Customer Match Status"::Ambiguous then
            exit(false);
        Customer.Reset();
        Customer.SetFilter("Search Name", '@*' + SearchName + '*');
        exit(MatchSingleCustomer(RequestHeader, Customer, MethodNameLbl));
    end;

    local procedure MatchSingleCustomer(var RequestHeader: Record "IKA Sales Request Header"; var Customer: Record Customer; Method: Text): Boolean
    begin
        case Customer.Count() of
            0:
                exit(false);
            1:
                begin
                    Customer.FindFirst();
                    exit(SetCustomer(RequestHeader, Customer."No.", Method));
                end;
            else begin
                // Se marca como ambiguo pero se siguen probando otros métodos
                if RequestHeader."Customer Match Status" <> RequestHeader."Customer Match Status"::Ambiguous then
                    RequestHeader.AddToErrorMessage(StrSubstNo(CustomerAmbiguousLbl, Method));
                RequestHeader."Customer Match Status" := RequestHeader."Customer Match Status"::Ambiguous;
                exit(false);
            end;
        end;
    end;

    local procedure SetCustomer(var RequestHeader: Record "IKA Sales Request Header"; CustomerNo: Code[20]; Method: Text): Boolean
    var
        Customer: Record Customer;
    begin
        if not Customer.Get(CustomerNo) then
            exit(false);
        RequestHeader."Customer No." := Customer."No.";
        RequestHeader."Customer Match Status" := RequestHeader."Customer Match Status"::Matched;
        RequestHeader."Customer Match Method" := CopyStr(Method, 1, MaxStrLen(RequestHeader."Customer Match Method"));
        CheckCustomerBlocked(RequestHeader);
        exit(true);
    end;

    local procedure CheckCustomerBlocked(var RequestHeader: Record "IKA Sales Request Header")
    var
        Customer: Record Customer;
    begin
        if not Customer.Get(RequestHeader."Customer No.") then
            exit;
        if Customer.Blocked <> Customer.Blocked::" " then
            RequestHeader.AddToErrorMessage(StrSubstNo(CustomerBlockedLbl, Customer."No.", Customer.Blocked));
    end;

    local procedure IsGenericDomain(Domain: Text): Boolean
    begin
        exit(Domain in ['gmail.com', 'hotmail.com', 'hotmail.es', 'outlook.com', 'outlook.es', 'live.com', 'yahoo.com', 'yahoo.es', 'icloud.com', 'telefonica.net', 'movistar.es', 'euskaltel.net', '']);
    end;

    // ---------------- Cabecera: dirección de envío, fecha, nº documento externo ----------------

    local procedure ResolveHeaderData(var RequestHeader: Record "IKA Sales Request Header")
    var
        DeliveryDate: Date;
    begin
        if RequestHeader."External Document No." = '' then
            RequestHeader."External Document No." := CopyStr(UpperCase(RequestHeader."Ext. Customer Order No."), 1, MaxStrLen(RequestHeader."External Document No."));

        if (RequestHeader."Requested Delivery Date" = 0D) and (RequestHeader."Ext. Requested Delivery Date" <> '') then
            if Evaluate(DeliveryDate, RequestHeader."Ext. Requested Delivery Date", 9) then
                RequestHeader."Requested Delivery Date" := DeliveryDate
            else
                RequestHeader.AddToErrorMessage(StrSubstNo(BadDateLbl, RequestHeader."Ext. Requested Delivery Date"));

        if (RequestHeader."Ship-to Code" = '') and (RequestHeader."Customer No." <> '') then
            ResolveShipTo(RequestHeader);
    end;

    local procedure ResolveShipTo(var RequestHeader: Record "IKA Sales Request Header")
    var
        Customer: Record Customer;
        ShipToAddress: Record "Ship-to Address";
        AddressPattern: Text;
    begin
        if (RequestHeader."Ext. Ship-to Address" = '') and (RequestHeader."Ext. Ship-to Name" = '') then
            exit;
        // Si coincide con la dirección principal del cliente, no hace falta código de envío
        if Customer.Get(RequestHeader."Customer No.") then
            if SameText(Customer.Address, RequestHeader."Ext. Ship-to Address") then
                exit;

        ShipToAddress.SetRange("Customer No.", RequestHeader."Customer No.");
        if RequestHeader."Ext. Ship-to Post Code" <> '' then
            ShipToAddress.SetRange("Post Code", CopyStr(RequestHeader."Ext. Ship-to Post Code", 1, MaxStrLen(ShipToAddress."Post Code")));
        AddressPattern := MakeSearchPattern(CopyStr(RequestHeader."Ext. Ship-to Address", 1, 30));
        if AddressPattern <> '' then
            ShipToAddress.SetFilter(Address, '@*' + AddressPattern + '*');
        if ShipToAddress.Count() <> 1 then begin
            // Segundo intento: por nombre
            ShipToAddress.SetRange(Address);
            AddressPattern := MakeSearchPattern(RequestHeader."Ext. Ship-to Name");
            if AddressPattern = '' then begin
                RequestHeader.AddToErrorMessage(StrSubstNo(ShipToNotFoundLbl, RequestHeader."Ext. Ship-to Address"));
                exit;
            end;
            ShipToAddress.SetFilter(Name, '@*' + AddressPattern + '*');
        end;
        if ShipToAddress.Count() = 1 then begin
            ShipToAddress.FindFirst();
            RequestHeader."Ship-to Code" := ShipToAddress.Code;
        end else
            RequestHeader.AddToErrorMessage(StrSubstNo(ShipToNotFoundLbl, RequestHeader."Ext. Ship-to Name" + ' ' + RequestHeader."Ext. Ship-to Address"));
    end;

    // ---------------- Líneas ----------------

    local procedure ResolveLines(var RequestHeader: Record "IKA Sales Request Header")
    var
        RequestLine: Record "IKA Sales Request Line";
    begin
        RequestLine.SetRange("Request Entry No.", RequestHeader."Entry No.");
        if RequestLine.FindSet(true) then
            repeat
                ResolveLine(RequestHeader, RequestLine);
                RequestLine.Modify();
            until RequestLine.Next() = 0;
    end;

    procedure ResolveLine(RequestHeader: Record "IKA Sales Request Header"; var RequestLine: Record "IKA Sales Request Line")
    var
        Note: Text;
    begin
        if (RequestLine."Match Status" = RequestLine."Match Status"::Manual) and (RequestLine."Item No." <> '') then begin
            RequestLine.Resolved := true;
            exit;
        end;

        RequestLine."Item No." := '';
        RequestLine."Variant Code" := '';
        RequestLine."Unit of Measure Code" := '';
        RequestLine."Match Method" := '';
        RequestLine."Resolution Note" := '';
        RequestLine.Resolved := false;
        RequestLine."Match Status" := RequestLine."Match Status"::"Not Found";

        if not TryMatchByCustomerReference(RequestHeader, RequestLine) then
            if not TryMatchByItemNo(RequestLine, RequestLine."Ext. Item No.") then
                if not TryMatchByItemNo(RequestLine, RequestLine."Ext. Customer Item Code") then
                    if not TryMatchByOtherReference(RequestLine) then
                        if Setup."Allow Description Match" then
                            TryMatchByDescription(RequestLine);

        if RequestLine."Item No." <> '' then begin
            RequestLine.Resolved := true;
            ResolveUnitOfMeasure(RequestLine);
            if IsItemSalesBlocked(RequestLine."Item No.") then
                Note := StrSubstNo(ItemBlockedLbl, RequestLine."Item No.");
        end else
            if RequestLine."Match Status" = RequestLine."Match Status"::"Not Found" then
                Note := ItemNotFoundLbl;

        if RequestLine.Quantity <= 0 then begin
            RequestLine.Resolved := false;
            Note := AppendNote(Note, ZeroQtyLbl);
        end;
        if Note <> '' then
            RequestLine."Resolution Note" := CopyStr(AppendNote(RequestLine."Resolution Note", Note), 1, MaxStrLen(RequestLine."Resolution Note"));
    end;

    local procedure TryMatchByCustomerReference(RequestHeader: Record "IKA Sales Request Header"; var RequestLine: Record "IKA Sales Request Line"): Boolean
    var
        ItemReference: Record "Item Reference";
    begin
        if (RequestHeader."Customer No." = '') or (RequestLine."Ext. Customer Item Code" = '') then
            exit(false);
        ItemReference.SetRange("Reference Type", ItemReference."Reference Type"::Customer);
        ItemReference.SetRange("Reference Type No.", RequestHeader."Customer No.");
        ItemReference.SetRange("Reference No.", CopyStr(UpperCase(RequestLine."Ext. Customer Item Code"), 1, MaxStrLen(ItemReference."Reference No.")));
        exit(MatchSingleReference(RequestLine, ItemReference, MethodCustomerRefLbl));
    end;

    local procedure TryMatchByOtherReference(var RequestLine: Record "IKA Sales Request Line"): Boolean
    var
        ItemReference: Record "Item Reference";
        Code: Text;
    begin
        Code := RequestLine."Ext. Item No.";
        if Code = '' then
            Code := RequestLine."Ext. Customer Item Code";
        if Code = '' then
            exit(false);
        ItemReference.SetFilter("Reference Type", '%1|%2', ItemReference."Reference Type"::" ", ItemReference."Reference Type"::"Bar Code");
        ItemReference.SetRange("Reference No.", CopyStr(UpperCase(Code), 1, MaxStrLen(ItemReference."Reference No.")));
        exit(MatchSingleReference(RequestLine, ItemReference, MethodOtherRefLbl));
    end;

    local procedure MatchSingleReference(var RequestLine: Record "IKA Sales Request Line"; var ItemReference: Record "Item Reference"; Method: Text): Boolean
    begin
        case ItemReference.Count() of
            0:
                exit(false);
            1:
                begin
                    ItemReference.FindFirst();
                    RequestLine."Item No." := ItemReference."Item No.";
                    RequestLine."Variant Code" := ItemReference."Variant Code";
                    RequestLine."Unit of Measure Code" := ItemReference."Unit of Measure";
                    SetMatched(RequestLine, Method);
                    exit(true);
                end;
            else begin
                RequestLine."Match Status" := RequestLine."Match Status"::Ambiguous;
                RequestLine."Resolution Note" := CopyStr(StrSubstNo(ItemAmbiguousLbl, Method), 1, MaxStrLen(RequestLine."Resolution Note"));
                exit(false);
            end;
        end;
    end;

    local procedure TryMatchByItemNo(var RequestLine: Record "IKA Sales Request Line"; ItemCode: Text): Boolean
    var
        Item: Record Item;
    begin
        if (ItemCode = '') or (StrLen(ItemCode) > MaxStrLen(Item."No.")) then
            exit(false);
        if not Item.Get(UpperCase(ItemCode)) then
            exit(false);
        RequestLine."Item No." := Item."No.";
        SetMatched(RequestLine, MethodItemNoLbl);
        exit(true);
    end;

    local procedure TryMatchByDescription(var RequestLine: Record "IKA Sales Request Line"): Boolean
    var
        Item: Record Item;
        SearchText: Text;
    begin
        SearchText := MakeSearchPattern(CopyStr(RequestLine."Ext. Description", 1, 100));
        if StrLen(DelChr(SearchText, '=', '?')) < 4 then
            exit(false);
        Item.SetRange(Blocked, false);
        Item.SetFilter(Description, '@*' + SearchText + '*');
        if Item.Count() = 0 then begin
            Item.SetRange(Description);
            Item.SetFilter("Search Description", '@*' + SearchText + '*');
        end;
        case Item.Count() of
            0:
                exit(false);
            1:
                begin
                    Item.FindFirst();
                    RequestLine."Item No." := Item."No.";
                    SetMatched(RequestLine, MethodDescriptionLbl);
                    exit(true);
                end;
            else begin
                RequestLine."Match Status" := RequestLine."Match Status"::Ambiguous;
                RequestLine."Resolution Note" := CopyStr(StrSubstNo(ItemAmbiguousLbl, MethodDescriptionLbl), 1, MaxStrLen(RequestLine."Resolution Note"));
                exit(false);
            end;
        end;
    end;

    local procedure SetMatched(var RequestLine: Record "IKA Sales Request Line"; Method: Text)
    begin
        RequestLine."Match Status" := RequestLine."Match Status"::Matched;
        RequestLine."Match Method" := CopyStr(Method, 1, MaxStrLen(RequestLine."Match Method"));
        RequestLine."Resolution Note" := '';
    end;

    local procedure ResolveUnitOfMeasure(var RequestLine: Record "IKA Sales Request Line")
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
        UoMText: Text;
    begin
        if (RequestLine."Unit of Measure Code" <> '') or (RequestLine."Ext. Unit of Measure" = '') then
            exit;
        UoMText := UpperCase(DelChr(RequestLine."Ext. Unit of Measure", '<>', ' .'));
        if StrLen(UoMText) <= MaxStrLen(ItemUnitOfMeasure.Code) then
            if ItemUnitOfMeasure.Get(RequestLine."Item No.", UoMText) then begin
                RequestLine."Unit of Measure Code" := ItemUnitOfMeasure.Code;
                exit;
            end;
        // Por descripción de la unidad (p.ej. "cajas" -> CAJA)
        UnitOfMeasure.SetFilter(Description, '@' + MakeSearchPattern(UoMText) + '*');
        if UnitOfMeasure.FindSet() then
            repeat
                if ItemUnitOfMeasure.Get(RequestLine."Item No.", UnitOfMeasure.Code) then begin
                    RequestLine."Unit of Measure Code" := ItemUnitOfMeasure.Code;
                    exit;
                end;
            until UnitOfMeasure.Next() = 0;
        RequestLine."Resolution Note" := CopyStr(StrSubstNo(UoMNotFoundLbl, RequestLine."Ext. Unit of Measure"), 1, MaxStrLen(RequestLine."Resolution Note"));
    end;

    local procedure IsItemSalesBlocked(ItemNo: Code[20]): Boolean
    var
        Item: Record Item;
    begin
        if not Item.Get(ItemNo) then
            exit(true);
        exit(Item.Blocked or Item."Sales Blocked");
    end;

    // ---------------- Duplicados y estado ----------------

    local procedure CheckDuplicates(var RequestHeader: Record "IKA Sales Request Header")
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if (RequestHeader."Customer No." = '') or (RequestHeader."External Document No." = '') then
            exit;
        SalesHeader.SetRange("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader.SetRange("Sell-to Customer No.", RequestHeader."Customer No.");
        SalesHeader.SetRange("External Document No.", RequestHeader."External Document No.");
        if RequestHeader."Sales Order No." <> '' then
            SalesHeader.SetFilter("No.", '<>%1', RequestHeader."Sales Order No.");
        if SalesHeader.FindFirst() then begin
            RequestHeader."Possible Duplicate" := true;
            RequestHeader.AddToErrorMessage(StrSubstNo(DuplicateLbl, SalesHeader."No."));
            exit;
        end;
        SalesInvoiceHeader.SetRange("Sell-to Customer No.", RequestHeader."Customer No.");
        SalesInvoiceHeader.SetRange("External Document No.", RequestHeader."External Document No.");
        if SalesInvoiceHeader.FindFirst() then begin
            RequestHeader."Possible Duplicate" := true;
            RequestHeader.AddToErrorMessage(StrSubstNo(DuplicatePostedLbl, SalesInvoiceHeader."No."));
        end;
    end;

    local procedure UpdateStatus(var RequestHeader: Record "IKA Sales Request Header")
    var
        Customer: Record Customer;
        IsReady: Boolean;
    begin
        RequestHeader.CalcFields("No. of Lines", "No. of Unresolved Lines");
        IsReady := RequestHeader."Customer Match Status" in [RequestHeader."Customer Match Status"::Matched, RequestHeader."Customer Match Status"::Manual];
        if IsReady and Customer.Get(RequestHeader."Customer No.") then
            IsReady := Customer.Blocked = Customer.Blocked::" ";

        if RequestHeader."No. of Lines" = 0 then begin
            IsReady := false;
            RequestHeader.AddToErrorMessage(NoLinesLbl);
        end;
        if RequestHeader."No. of Unresolved Lines" > 0 then begin
            IsReady := false;
            RequestHeader.AddToErrorMessage(StrSubstNo(UnresolvedLinesLbl, RequestHeader."No. of Unresolved Lines"));
        end;
        if RequestHeader."Possible Duplicate" then
            IsReady := false;
        if RequestHeader.Confidence < Setup."Min. Confidence Auto Create" then begin
            IsReady := false;
            RequestHeader.AddToErrorMessage(StrSubstNo(LowConfidenceLbl, RequestHeader.Confidence, Setup."Min. Confidence Auto Create"));
        end;

        if IsReady then
            RequestHeader.Status := RequestHeader.Status::Ready
        else
            RequestHeader.Status := RequestHeader.Status::"Needs Review";
        LogMgt.LogInfo(RequestHeader."Entry No.", Format(RequestHeader.Status) + ': ' + RequestHeader."Error Message");
    end;

    // ---------------- Utilidades ----------------

    /// <summary>
    /// Sustituye por "?" los caracteres que tienen significado en los filtros de BC,
    /// para poder usar el texto dentro de un SetFilter con comodines.
    /// </summary>
    local procedure MakeSearchPattern(Value: Text): Text
    var
        Result: Text;
        i: Integer;
        Ch: Text[1];
    begin
        Value := DelChr(Value, '<>', ' ');
        for i := 1 to StrLen(Value) do begin
            Ch := CopyStr(Value, i, 1);
            if Ch in ['&', '|', '(', ')', '<', '>', '=', '*', '@', '''', '"', '.', '%'] then
                Result += '?'
            else
                Result += Ch;
        end;
        exit(Result);
    end;

    local procedure SameText(Text1: Text; Text2: Text): Boolean
    begin
        exit(UpperCase(DelChr(Text1, '=', ' .,')) = UpperCase(DelChr(Text2, '=', ' .,')));
    end;

    local procedure AppendNote(Note: Text; NewNote: Text): Text
    begin
        if Note = '' then
            exit(NewNote);
        exit(Note + ' ' + NewNote);
    end;
}
