codeunit 50020 "IKA Sales Req. Extraction"
{
    var
        JsonHelper: Codeunit "IKA Sales Agent Json Helper";
        LogMgt: Codeunit "IKA Sales Agent Log Mgt.";
        NotAnOrderLbl: Label 'Claude indica que el email no contiene un pedido de venta.';
        ExtractedLbl: Label 'Extracción completada: %1 pedido(s), confianza %2.', Comment = '%1 = no. of orders, %2 = confidence';
        SplitLbl: Label 'Pedido %1 de %2 del mismo email (solicitud origen %3).', Comment = '%1 = index, %2 = total, %3 = parent entry no.';
        AlreadyCreatedErr: Label 'La solicitud %1 ya tiene creado el pedido %2.', Comment = '%1 = entry no., %2 = order no.';

    /// <summary>
    /// Llama a Claude y vuelca el resultado en la solicitud y sus líneas.
    /// Si el email contiene varios pedidos, crea una solicitud adicional por cada uno.
    /// </summary>
    procedure ExtractWithClaude(var RequestHeader: Record "IKA Sales Request Header")
    var
        ClaudeApiClient: Codeunit "IKA Claude API Client";
        ExtractionJson: JsonObject;
    begin
        if RequestHeader."Sales Order No." <> '' then
            Error(AlreadyCreatedErr, RequestHeader."Entry No.", RequestHeader."Sales Order No.");

        ClaudeApiClient.ExtractSalesOrder(RequestHeader, ExtractionJson);
        RequestHeader.Modify();
        ApplyExtraction(RequestHeader, ExtractionJson);
    end;

    procedure ApplyExtraction(var RequestHeader: Record "IKA Sales Request Header"; ExtractionJson: JsonObject)
    var
        ExtraRequestHeader: Record "IKA Sales Request Header";
        OrdersArray: JsonArray;
        WarningsArray: JsonArray;
        OrderToken: JsonToken;
        Confidence: Decimal;
        Warnings: Text;
        OrderIndex: Integer;
        OrderCount: Integer;
    begin
        Confidence := JsonHelper.GetDecimal(ExtractionJson, 'confidence');
        if JsonHelper.GetArray(ExtractionJson, 'warnings', WarningsArray) then
            Warnings := JsonHelper.ArrayToText(WarningsArray, ' | ');
        JsonHelper.GetArray(ExtractionJson, 'orders', OrdersArray);
        OrderCount := OrdersArray.Count();

        ClearExtractedData(RequestHeader);
        RequestHeader.Confidence := Confidence;
        RequestHeader."Claude Warnings" := CopyStr(Warnings, 1, MaxStrLen(RequestHeader."Claude Warnings"));
        RequestHeader."Processed At" := CurrentDateTime();

        if (not JsonHelper.GetBoolean(ExtractionJson, 'is_sales_order')) or (OrderCount = 0) then begin
            RequestHeader.Status := RequestHeader.Status::Ignored;
            RequestHeader.AddToErrorMessage(NotAnOrderLbl);
            RequestHeader.Modify();
            LogMgt.LogWarning(RequestHeader."Entry No.", NotAnOrderLbl);
            exit;
        end;

        foreach OrderToken in OrdersArray do begin
            OrderIndex += 1;
            if OrderIndex = 1 then begin
                RequestHeader."Order Index" := 1;
                ApplyOrder(RequestHeader, OrderToken.AsObject());
            end else begin
                CreateSiblingRequest(RequestHeader, ExtraRequestHeader, OrderIndex);
                ExtraRequestHeader.Confidence := Confidence;
                ExtraRequestHeader."Claude Warnings" := RequestHeader."Claude Warnings";
                ExtraRequestHeader.AddToErrorMessage(StrSubstNo(SplitLbl, OrderIndex, OrderCount, RequestHeader."Entry No."));
                ApplyOrder(ExtraRequestHeader, OrderToken.AsObject());
            end;
        end;

        LogMgt.LogInfo(RequestHeader."Entry No.", StrSubstNo(ExtractedLbl, OrderCount, Confidence));
    end;

    local procedure ApplyOrder(var RequestHeader: Record "IKA Sales Request Header"; OrderJson: JsonObject)
    var
        RequestLine: Record "IKA Sales Request Line";
        LinesArray: JsonArray;
        LineToken: JsonToken;
        LineJson: JsonObject;
        LineNo: Integer;
    begin
        RequestHeader."Ext. Customer Code" := CopyStr(JsonHelper.GetText(OrderJson, 'customer_code'), 1, MaxStrLen(RequestHeader."Ext. Customer Code"));
        RequestHeader."Ext. Customer Name" := CopyStr(JsonHelper.GetText(OrderJson, 'customer_name'), 1, MaxStrLen(RequestHeader."Ext. Customer Name"));
        RequestHeader."Ext. VAT Registration No." := CopyStr(JsonHelper.GetText(OrderJson, 'customer_vat_number'), 1, MaxStrLen(RequestHeader."Ext. VAT Registration No."));
        RequestHeader."Ext. Customer E-Mail" := CopyStr(JsonHelper.GetText(OrderJson, 'customer_email'), 1, MaxStrLen(RequestHeader."Ext. Customer E-Mail"));
        RequestHeader."Ext. Customer Order No." := CopyStr(JsonHelper.GetText(OrderJson, 'customer_order_number'), 1, MaxStrLen(RequestHeader."Ext. Customer Order No."));
        RequestHeader."Ext. Requested Delivery Date" := CopyStr(JsonHelper.GetText(OrderJson, 'requested_delivery_date'), 1, MaxStrLen(RequestHeader."Ext. Requested Delivery Date"));
        RequestHeader."Ext. Ship-to Name" := CopyStr(JsonHelper.GetText(OrderJson, 'ship_to_name'), 1, MaxStrLen(RequestHeader."Ext. Ship-to Name"));
        RequestHeader."Ext. Ship-to Address" := CopyStr(JsonHelper.GetText(OrderJson, 'ship_to_address'), 1, MaxStrLen(RequestHeader."Ext. Ship-to Address"));
        RequestHeader."Ext. Ship-to City" := CopyStr(JsonHelper.GetText(OrderJson, 'ship_to_city'), 1, MaxStrLen(RequestHeader."Ext. Ship-to City"));
        RequestHeader."Ext. Ship-to Post Code" := CopyStr(JsonHelper.GetText(OrderJson, 'ship_to_post_code'), 1, MaxStrLen(RequestHeader."Ext. Ship-to Post Code"));
        RequestHeader.Comments := CopyStr(JsonHelper.GetText(OrderJson, 'comments'), 1, MaxStrLen(RequestHeader.Comments));
        RequestHeader.Status := RequestHeader.Status::Extracted;
        RequestHeader.Modify();

        RequestLine.SetRange("Request Entry No.", RequestHeader."Entry No.");
        RequestLine.DeleteAll(true);

        if not JsonHelper.GetArray(OrderJson, 'lines', LinesArray) then
            exit;
        foreach LineToken in LinesArray do begin
            LineJson := LineToken.AsObject();
            LineNo += 10000;
            RequestLine.Init();
            RequestLine."Request Entry No." := RequestHeader."Entry No.";
            RequestLine."Line No." := LineNo;
            RequestLine."Ext. Customer Item Code" := CopyStr(JsonHelper.GetText(LineJson, 'customer_item_code'), 1, MaxStrLen(RequestLine."Ext. Customer Item Code"));
            RequestLine."Ext. Item No." := CopyStr(JsonHelper.GetText(LineJson, 'supplier_item_code'), 1, MaxStrLen(RequestLine."Ext. Item No."));
            RequestLine."Ext. Description" := CopyStr(JsonHelper.GetText(LineJson, 'description'), 1, MaxStrLen(RequestLine."Ext. Description"));
            RequestLine.Quantity := JsonHelper.GetDecimal(LineJson, 'quantity');
            RequestLine."Ext. Unit of Measure" := CopyStr(JsonHelper.GetText(LineJson, 'unit_of_measure'), 1, MaxStrLen(RequestLine."Ext. Unit of Measure"));
            RequestLine."Ext. Notes" := CopyStr(JsonHelper.GetText(LineJson, 'notes'), 1, MaxStrLen(RequestLine."Ext. Notes"));
            RequestLine.Insert(true);
        end;
    end;

    local procedure CreateSiblingRequest(ParentRequestHeader: Record "IKA Sales Request Header"; var NewRequestHeader: Record "IKA Sales Request Header"; OrderIndex: Integer)
    begin
        // Si ya existía de una extracción anterior, se reutiliza
        NewRequestHeader.SetRange("Parent Entry No.", ParentRequestHeader."Entry No.");
        NewRequestHeader.SetRange("Order Index", OrderIndex);
        if NewRequestHeader.FindFirst() then begin
            if NewRequestHeader."Sales Order No." <> '' then
                Error(AlreadyCreatedErr, NewRequestHeader."Entry No.", NewRequestHeader."Sales Order No.");
            ClearExtractedData(NewRequestHeader);
            exit;
        end;

        NewRequestHeader.Init();
        NewRequestHeader."Entry No." := 0;
        NewRequestHeader.Source := ParentRequestHeader.Source;
        NewRequestHeader."Parent Entry No." := ParentRequestHeader."Entry No.";
        NewRequestHeader."Order Index" := OrderIndex;
        // "Graph Message Id" se deja vacío: el email solo se mueve desde la solicitud origen
        NewRequestHeader."Internet Message Id" := ParentRequestHeader."Internet Message Id";
        NewRequestHeader."Received At" := ParentRequestHeader."Received At";
        NewRequestHeader."Sender Address" := ParentRequestHeader."Sender Address";
        NewRequestHeader."Sender Name" := ParentRequestHeader."Sender Name";
        NewRequestHeader.Subject := ParentRequestHeader.Subject;
        NewRequestHeader."Mail Filter Line No." := ParentRequestHeader."Mail Filter Line No.";
        NewRequestHeader."Claude Model" := ParentRequestHeader."Claude Model";
        NewRequestHeader.SetBodyText(ParentRequestHeader.GetBodyText());
        NewRequestHeader.Insert(true);
    end;

    local procedure ClearExtractedData(var RequestHeader: Record "IKA Sales Request Header")
    begin
        RequestHeader."Ext. Customer Code" := '';
        RequestHeader."Ext. Customer Name" := '';
        RequestHeader."Ext. VAT Registration No." := '';
        RequestHeader."Ext. Customer E-Mail" := '';
        RequestHeader."Ext. Customer Order No." := '';
        RequestHeader."Ext. Requested Delivery Date" := '';
        RequestHeader."Ext. Ship-to Name" := '';
        RequestHeader."Ext. Ship-to Address" := '';
        RequestHeader."Ext. Ship-to City" := '';
        RequestHeader."Ext. Ship-to Post Code" := '';
        RequestHeader.Comments := '';
        RequestHeader."Error Message" := '';
        RequestHeader."Possible Duplicate" := false;
        // Los datos asignados manualmente por el usuario se conservan
        if RequestHeader."Customer Match Status" <> RequestHeader."Customer Match Status"::Manual then begin
            RequestHeader."Customer No." := '';
            RequestHeader."Customer Match Status" := RequestHeader."Customer Match Status"::" ";
            RequestHeader."Customer Match Method" := '';
            RequestHeader."Ship-to Code" := '';
        end;
        RequestHeader."External Document No." := '';
        RequestHeader."Requested Delivery Date" := 0D;
    end;
}
