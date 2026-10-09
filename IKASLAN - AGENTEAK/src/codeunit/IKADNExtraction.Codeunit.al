codeunit 99111 "IKA DN Extraction"
{
    var
        JsonHelper: Codeunit "IKA Sales Agent Json Helper";
        LogMgt: Codeunit "IKA DN Log Mgt.";
        NotADeliveryNoteLbl: Label 'Claude indica que el documento no es un albarán (tipo: %1).', Comment = '%1 = document type';
        ExtractedLbl: Label 'Extracción completada: %1 albarán(es), confianza %2.', Comment = '%1 = count, %2 = confidence';
        SplitLbl: Label 'Albarán %1 de %2 del mismo documento (documento origen %3).', Comment = '%1 = index, %2 = total, %3 = parent';
        AlreadyAppliedErr: Label 'El albarán %1 ya se ha aplicado a los pedidos; no se puede volver a extraer.', Comment = '%1 = entry no.';

    procedure ExtractWithClaude(var DNDocument: Record "IKA DN Document")
    var
        ClaudeClient: Codeunit "IKA DN Claude Client";
        ExtractionJson: JsonObject;
    begin
        if DNDocument.Status in [DNDocument.Status::Applied, DNDocument.Status::Received] then
            Error(AlreadyAppliedErr, DNDocument."Entry No.");
        ClaudeClient.ExtractDeliveryNote(DNDocument, ExtractionJson);
        DNDocument.Modify();
        ApplyExtraction(DNDocument, ExtractionJson);
    end;

    procedure ApplyExtraction(var DNDocument: Record "IKA DN Document"; ExtractionJson: JsonObject)
    var
        SiblingDocument: Record "IKA DN Document";
        NotesArray: JsonArray;
        WarningsArray: JsonArray;
        NoteToken: JsonToken;
        Confidence: Decimal;
        Warnings: Text;
        NoteIndex: Integer;
        NoteCount: Integer;
    begin
        Confidence := JsonHelper.GetDecimal(ExtractionJson, 'confidence');
        if JsonHelper.GetArray(ExtractionJson, 'warnings', WarningsArray) then
            Warnings := JsonHelper.ArrayToText(WarningsArray, ' | ');
        JsonHelper.GetArray(ExtractionJson, 'delivery_notes', NotesArray);
        NoteCount := NotesArray.Count();

        ClearExtractedData(DNDocument);
        DNDocument.Confidence := Confidence;
        DNDocument."Claude Warnings" := CopyStr(Warnings, 1, MaxStrLen(DNDocument."Claude Warnings"));
        DNDocument."Processed At" := CurrentDateTime();

        if (not JsonHelper.GetBoolean(ExtractionJson, 'is_delivery_note')) or (NoteCount = 0) then begin
            DNDocument.Status := DNDocument.Status::Ignored;
            DNDocument.AddReviewNote(StrSubstNo(NotADeliveryNoteLbl, JsonHelper.GetText(ExtractionJson, 'document_type')));
            DNDocument.Modify();
            LogMgt.LogWarning(DNDocument."Entry No.", DNDocument."Review Notes");
            exit;
        end;

        foreach NoteToken in NotesArray do begin
            NoteIndex += 1;
            if NoteIndex = 1 then begin
                DNDocument."Note Index" := 1;
                ApplyDeliveryNote(DNDocument, NoteToken.AsObject());
            end else begin
                CreateSibling(DNDocument, SiblingDocument, NoteIndex);
                SiblingDocument.Confidence := Confidence;
                SiblingDocument."Claude Warnings" := DNDocument."Claude Warnings";
                SiblingDocument.AddReviewNote(StrSubstNo(SplitLbl, NoteIndex, NoteCount, DNDocument."Entry No."));
                ApplyDeliveryNote(SiblingDocument, NoteToken.AsObject());
            end;
        end;
        LogMgt.LogInfo(DNDocument."Entry No.", StrSubstNo(ExtractedLbl, NoteCount, Confidence));
    end;

    local procedure ApplyDeliveryNote(var DNDocument: Record "IKA DN Document"; NoteJson: JsonObject)
    var
        DocumentLine: Record "IKA DN Document Line";
        OrderRefsArray: JsonArray;
        LinesArray: JsonArray;
        LineToken: JsonToken;
        LineJson: JsonObject;
        ExpirationDate: Date;
        LineDeliveryDate: Date;
        LineNo: Integer;
    begin
        DNDocument."Ext. Vendor Name" := CopyStr(JsonHelper.GetText(NoteJson, 'vendor_name'), 1, MaxStrLen(DNDocument."Ext. Vendor Name"));
        DNDocument."Ext. Vendor VAT No." := CopyStr(JsonHelper.GetText(NoteJson, 'vendor_vat_number'), 1, MaxStrLen(DNDocument."Ext. Vendor VAT No."));
        DNDocument."Ext. Vendor E-Mail" := CopyStr(JsonHelper.GetText(NoteJson, 'vendor_email'), 1, MaxStrLen(DNDocument."Ext. Vendor E-Mail"));
        DNDocument."Ext. Our Customer Code" := CopyStr(JsonHelper.GetText(NoteJson, 'our_customer_code'), 1, MaxStrLen(DNDocument."Ext. Our Customer Code"));
        DNDocument."Ext. Delivery Note No." := CopyStr(JsonHelper.GetText(NoteJson, 'delivery_note_number'), 1, MaxStrLen(DNDocument."Ext. Delivery Note No."));
        DNDocument."Ext. Delivery Note Date" := CopyStr(JsonHelper.GetText(NoteJson, 'delivery_note_date'), 1, MaxStrLen(DNDocument."Ext. Delivery Note Date"));
        if JsonHelper.GetArray(NoteJson, 'order_references', OrderRefsArray) then
            DNDocument."Ext. Order References" := CopyStr(JsonHelper.ArrayToText(OrderRefsArray, '|'), 1, MaxStrLen(DNDocument."Ext. Order References"));
        DNDocument."Prices Included" := JsonHelper.GetBoolean(NoteJson, 'prices_included');
        DNDocument."Ext. Total Amount" := JsonHelper.GetDecimal(NoteJson, 'total_amount');
        DNDocument."Ext. Currency" := CopyStr(JsonHelper.GetText(NoteJson, 'currency'), 1, MaxStrLen(DNDocument."Ext. Currency"));
        DNDocument.AddReviewNote(JsonHelper.GetText(NoteJson, 'comments'));
        DNDocument.Status := DNDocument.Status::Extracted;
        DNDocument.Modify();

        DocumentLine.SetRange("Document Entry No.", DNDocument."Entry No.");
        DocumentLine.DeleteAll(true);
        if not JsonHelper.GetArray(NoteJson, 'lines', LinesArray) then
            exit;

        foreach LineToken in LinesArray do begin
            LineJson := LineToken.AsObject();
            LineNo += 10000;
            DocumentLine.Init();
            DocumentLine."Document Entry No." := DNDocument."Entry No.";
            DocumentLine."Line No." := LineNo;
            DocumentLine."Ext. Vendor Item Code" := CopyStr(JsonHelper.GetText(LineJson, 'vendor_item_code'), 1, MaxStrLen(DocumentLine."Ext. Vendor Item Code"));
            DocumentLine."Ext. Our Item Code" := CopyStr(JsonHelper.GetText(LineJson, 'our_item_code'), 1, MaxStrLen(DocumentLine."Ext. Our Item Code"));
            DocumentLine."Ext. EAN" := CopyStr(JsonHelper.GetText(LineJson, 'ean'), 1, MaxStrLen(DocumentLine."Ext. EAN"));
            DocumentLine."Ext. Description" := CopyStr(JsonHelper.GetText(LineJson, 'description'), 1, MaxStrLen(DocumentLine."Ext. Description"));
            DocumentLine.Quantity := JsonHelper.GetDecimal(LineJson, 'quantity');
            DocumentLine."Ext. Unit of Measure" := CopyStr(JsonHelper.GetText(LineJson, 'unit_of_measure'), 1, MaxStrLen(DocumentLine."Ext. Unit of Measure"));
            DocumentLine."Unit Price" := JsonHelper.GetDecimal(LineJson, 'unit_price');
            DocumentLine."Discount %" := JsonHelper.GetDecimal(LineJson, 'discount_percent');
            DocumentLine."Line Amount" := JsonHelper.GetDecimal(LineJson, 'line_amount');
            DocumentLine."Ext. Order Reference" := CopyStr(JsonHelper.GetText(LineJson, 'order_reference'), 1, MaxStrLen(DocumentLine."Ext. Order Reference"));
            DocumentLine."Lot No." := CopyStr(UpperCase(JsonHelper.GetText(LineJson, 'lot_number')), 1, MaxStrLen(DocumentLine."Lot No."));
            DocumentLine."Ext. Expiration Date" := CopyStr(JsonHelper.GetText(LineJson, 'expiration_date'), 1, MaxStrLen(DocumentLine."Ext. Expiration Date"));
            if Evaluate(ExpirationDate, DocumentLine."Ext. Expiration Date", 9) then
                DocumentLine."Expiration Date" := ExpirationDate;
            DocumentLine."Ext. Notes" := CopyStr(JsonHelper.GetText(LineJson, 'notes'), 1, MaxStrLen(DocumentLine."Ext. Notes"));
            DocumentLine."Ext. Position" := CopyStr(JsonHelper.GetText(LineJson, 'position'), 1, MaxStrLen(DocumentLine."Ext. Position"));
            DocumentLine."Ext. Delivery Date" := CopyStr(JsonHelper.GetText(LineJson, 'delivery_date'), 1, MaxStrLen(DocumentLine."Ext. Delivery Date"));
            if Evaluate(LineDeliveryDate, DocumentLine."Ext. Delivery Date", 9) then
                DocumentLine."Delivery Date" := LineDeliveryDate;
            DocumentLine.Insert(true);
        end;
    end;

    local procedure CreateSibling(ParentDocument: Record "IKA DN Document"; var NewDocument: Record "IKA DN Document"; NoteIndex: Integer)
    begin
        NewDocument.SetRange("Parent Entry No.", ParentDocument."Entry No.");
        NewDocument.SetRange("Note Index", NoteIndex);
        if NewDocument.FindFirst() then begin
            if NewDocument.Status in [NewDocument.Status::Applied, NewDocument.Status::Received] then
                Error(AlreadyAppliedErr, NewDocument."Entry No.");
            ClearExtractedData(NewDocument);
            exit;
        end;

        NewDocument.Init();
        NewDocument."Entry No." := 0;
        NewDocument.Source := ParentDocument.Source;
        NewDocument."Parent Entry No." := ParentDocument."Entry No.";
        NewDocument."Note Index" := NoteIndex;
        NewDocument."Internet Message Id" := ParentDocument."Internet Message Id";
        NewDocument."Received At" := ParentDocument."Received At";
        NewDocument."Sender Address" := ParentDocument."Sender Address";
        NewDocument."Sender Name" := ParentDocument."Sender Name";
        NewDocument.Subject := ParentDocument.Subject;
        NewDocument."Source File Name" := ParentDocument."Source File Name";
        NewDocument."Mail Filter Line No." := ParentDocument."Mail Filter Line No.";
        NewDocument."Claude Model" := ParentDocument."Claude Model";
        NewDocument.Insert(true);
    end;

    local procedure ClearExtractedData(var DNDocument: Record "IKA DN Document")
    begin
        DNDocument."Ext. Vendor Name" := '';
        DNDocument."Ext. Vendor VAT No." := '';
        DNDocument."Ext. Vendor E-Mail" := '';
        DNDocument."Ext. Our Customer Code" := '';
        DNDocument."Ext. Delivery Note No." := '';
        DNDocument."Ext. Delivery Note Date" := '';
        DNDocument."Ext. Order References" := '';
        DNDocument."Ext. Total Amount" := 0;
        DNDocument."Ext. Currency" := '';
        DNDocument."Prices Included" := false;
        DNDocument."Review Notes" := '';
        DNDocument."Possible Duplicate" := false;
        if DNDocument."Vendor Match Status" <> DNDocument."Vendor Match Status"::Manual then begin
            DNDocument."Vendor No." := '';
            DNDocument."Vendor Match Status" := DNDocument."Vendor Match Status"::" ";
            DNDocument."Vendor Match Method" := '';
        end;
        DNDocument."Vendor Shipment No." := '';
        DNDocument."Delivery Note Date" := 0D;
        DNDocument."Purchase Order No." := '';
        DNDocument."No. of Orders" := 0;
    end;
}
