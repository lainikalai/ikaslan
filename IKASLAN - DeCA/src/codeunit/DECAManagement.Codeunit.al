codeunit 50000 "DECA Management"
{
    var
        NoLinesErr: Label 'El DeCA %1 no tiene ningún envío.', Comment = '%1 = nº DeCA';
        WeightErr: Label 'Indique el peso o una magnitud alternativa en el envío %1 del DeCA %2.', Comment = '%1 = nº línea, %2 = nº DeCA';
        HttpsErr: Label 'La URL del DeCA debe empezar por https://. Revise la configuración del repositorio.';
        RenderErr: Label 'No se ha podido generar el PDF del DeCA %1.', Comment = '%1 = nº DeCA';
        SizeErr: Label 'El PDF del DeCA %1 supera el tamaño máximo de 5 MB.', Comment = '%1 = nº DeCA';
        PastDateQst: Label 'La fecha del transporte (%1) es anterior a hoy. El DeCA debe generarse antes del inicio efectivo del servicio. ¿Desea emitirlo igualmente?', Comment = '%1 = fecha';
        ReasonErr: Label 'Indique el motivo de la modificación: este DeCA sustituye al %1.', Comment = '%1 = nº DeCA';
        DifferentAgentErr: Label 'Los albaranes seleccionados tienen transportistas distintos. Solo se pueden agrupar envíos con el mismo cargador contractual y el mismo transportista efectivo.';
        DifferentCustomerErr: Label 'Los albaranes seleccionados son de clientes distintos. Solo se pueden agrupar envíos con el mismo cargador contractual y el mismo transportista efectivo.';
        PendingReplacementErr: Label 'Ya existe el borrador %1 que sustituye a este DeCA.', Comment = '%1 = nº DeCA';
        NoPdfErr: Label 'El DeCA %1 no tiene PDF. Emítalo primero.', Comment = '%1 = nº DeCA';
        MailSubjectLbl: Label 'Documento de control (DeCA) %1 - transporte del %2', Comment = '%1 = nº DeCA, %2 = fecha';
        MailBodyLbl: Label '<p>Se adjunta el documento electrónico de control administrativo (DeCA) <b>%1</b> del transporte previsto para el %2.</p><p>El conductor debe llevarlo a bordo, en el móvil o impreso, siempre con el código QR visible.</p><p>Descarga directa: <a href="%3">%3</a></p>', Comment = '%1 = nº DeCA, %2 = fecha, %3 = URL';
        MailSentMsg: Label 'DeCA %1 enviado a %2.', Comment = '%1 = nº DeCA, %2 = email';
        FileNameTok: Label 'DeCA_%1.pdf', Locked = true;

    // ------------------------------------------------------------------
    // Creación desde documentos de Business Central
    // ------------------------------------------------------------------

    /// <summary>Crea un DeCA con un envío por cada albarán registrado del filtro.</summary>
    procedure CreateFromSalesShipments(var SalesShipmentHeader: Record "Sales Shipment Header"): Code[20]
    var
        DECAHeader: Record "DECA Header";
        DECASetup: Record "DECA Setup";
        FirstShipment: Record "Sales Shipment Header";
        GoodsDescription: Text;
        GrossWeight: Decimal;
    begin
        DECASetup.GetSetup();
        SalesShipmentHeader.FindSet();
        FirstShipment := SalesShipmentHeader;

        CreateHeader(DECAHeader, Enum::"DECA Source Type"::"Sales Shipment", FirstShipment."No.");
        SetPartiesFromSales(DECAHeader, DECASetup, FirstShipment."Sell-to Customer No.", FirstShipment."Shipping Agent Code");
        if FirstShipment."Shipment Date" <> 0D then
            DECAHeader.Validate("Transport Date", FirstShipment."Shipment Date");
        DECAHeader.Modify(true);

        repeat
            if SalesShipmentHeader."Shipping Agent Code" <> FirstShipment."Shipping Agent Code" then
                Error(DifferentAgentErr);
            if (DECASetup."Company Role" = DECASetup."Company Role"::Carrier) and
               (SalesShipmentHeader."Sell-to Customer No." <> FirstShipment."Sell-to Customer No.")
            then
                Error(DifferentCustomerErr);

            GetSalesShipmentGoods(SalesShipmentHeader."No.", DECASetup, GoodsDescription, GrossWeight);
            InsertLine(
                DECAHeader, SalesShipmentHeader."No.", SalesShipmentHeader."Location Code", '', '', '', '',
                SalesShipmentHeader."Ship-to Name", SalesShipmentHeader."Ship-to Address",
                SalesShipmentHeader."Ship-to Post Code", SalesShipmentHeader."Ship-to City",
                GoodsDescription, GrossWeight);
        until SalesShipmentHeader.Next() = 0;

        exit(DECAHeader."No.");
    end;

    procedure CreateFromSalesOrder(SalesHeader: Record "Sales Header"): Code[20]
    var
        DECAHeader: Record "DECA Header";
        DECASetup: Record "DECA Setup";
        GoodsDescription: Text;
        GrossWeight: Decimal;
    begin
        DECASetup.GetSetup();
        SalesHeader.TestField("Document Type", SalesHeader."Document Type"::Order);

        CreateHeader(DECAHeader, Enum::"DECA Source Type"::"Sales Order", SalesHeader."No.");
        SetPartiesFromSales(DECAHeader, DECASetup, SalesHeader."Sell-to Customer No.", SalesHeader."Shipping Agent Code");
        if SalesHeader."Shipment Date" <> 0D then
            DECAHeader.Validate("Transport Date", SalesHeader."Shipment Date");
        DECAHeader.Modify(true);

        GetSalesOrderGoods(SalesHeader, DECASetup, GoodsDescription, GrossWeight);
        InsertLine(
            DECAHeader, SalesHeader."No.", SalesHeader."Location Code", '', '', '', '',
            SalesHeader."Ship-to Name", SalesHeader."Ship-to Address",
            SalesHeader."Ship-to Post Code", SalesHeader."Ship-to City",
            GoodsDescription, GrossWeight);
        exit(DECAHeader."No.");
    end;

    procedure CreateFromTransferOrder(TransferHeader: Record "Transfer Header"): Code[20]
    var
        DECAHeader: Record "DECA Header";
        DECASetup: Record "DECA Setup";
        TransferLine: Record "Transfer Line";
        GoodsDescription: Text;
        GrossWeight: Decimal;
        Qty: Decimal;
    begin
        DECASetup.GetSetup();
        CreateHeader(DECAHeader, Enum::"DECA Source Type"::"Transfer Order", TransferHeader."No.");
        if TransferHeader."Shipping Agent Code" <> '' then
            DECAHeader.Validate("Shipping Agent Code", TransferHeader."Shipping Agent Code");
        if TransferHeader."Shipment Date" <> 0D then
            DECAHeader.Validate("Transport Date", TransferHeader."Shipment Date");
        DECAHeader.Modify(true);

        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.SetFilter("Item No.", '<>%1', '');
        if TransferLine.FindSet() then
            repeat
                Qty := TransferLine."Qty. to Ship";
                if Qty = 0 then
                    Qty := TransferLine."Outstanding Quantity";
                GrossWeight += Qty * TransferLine."Gross Weight";
                AppendDescription(GoodsDescription, TransferLine.Description);
            until TransferLine.Next() = 0;
        ApplyDefaultGoods(DECASetup, GoodsDescription);

        InsertLine(
            DECAHeader, TransferHeader."No.", '',
            TransferHeader."Transfer-from Name", TransferHeader."Transfer-from Address",
            TransferHeader."Transfer-from Post Code", TransferHeader."Transfer-from City",
            TransferHeader."Transfer-to Name", TransferHeader."Transfer-to Address",
            TransferHeader."Transfer-to Post Code", TransferHeader."Transfer-to City",
            GoodsDescription, GrossWeight);
        exit(DECAHeader."No.");
    end;

    procedure CreateFromTransferShipment(TransferShipmentHeader: Record "Transfer Shipment Header"): Code[20]
    var
        DECAHeader: Record "DECA Header";
        DECASetup: Record "DECA Setup";
        TransferShipmentLine: Record "Transfer Shipment Line";
        GoodsDescription: Text;
        GrossWeight: Decimal;
    begin
        DECASetup.GetSetup();
        CreateHeader(DECAHeader, Enum::"DECA Source Type"::"Transfer Shipment", TransferShipmentHeader."No.");
        if TransferShipmentHeader."Shipping Agent Code" <> '' then
            DECAHeader.Validate("Shipping Agent Code", TransferShipmentHeader."Shipping Agent Code");
        if TransferShipmentHeader."Shipment Date" <> 0D then
            DECAHeader.Validate("Transport Date", TransferShipmentHeader."Shipment Date");
        DECAHeader.Modify(true);

        TransferShipmentLine.SetRange("Document No.", TransferShipmentHeader."No.");
        TransferShipmentLine.SetFilter(Quantity, '<>0');
        if TransferShipmentLine.FindSet() then
            repeat
                GrossWeight += TransferShipmentLine.Quantity * TransferShipmentLine."Gross Weight";
                AppendDescription(GoodsDescription, TransferShipmentLine.Description);
            until TransferShipmentLine.Next() = 0;
        ApplyDefaultGoods(DECASetup, GoodsDescription);

        InsertLine(
            DECAHeader, TransferShipmentHeader."No.", '',
            TransferShipmentHeader."Transfer-from Name", TransferShipmentHeader."Transfer-from Address",
            TransferShipmentHeader."Transfer-from Post Code", TransferShipmentHeader."Transfer-from City",
            TransferShipmentHeader."Transfer-to Name", TransferShipmentHeader."Transfer-to Address",
            TransferShipmentHeader."Transfer-to Post Code", TransferShipmentHeader."Transfer-to City",
            GoodsDescription, GrossWeight);
        exit(DECAHeader."No.");
    end;

    // ------------------------------------------------------------------
    // Emisión
    // ------------------------------------------------------------------

    /// <summary>
    /// Emite el DeCA: reserva la URL, genera el PDF nativo con el QR, lo publica en el
    /// repositorio y guarda una copia en Business Central. Registra fecha y hora de creación.
    /// </summary>
    procedure Issue(var DECAHeader: Record "DECA Header")
    var
        DECASetup: Record "DECA Setup";
        ReplacedHeader: Record "DECA Header";
        TempBlob: Codeunit "Temp Blob";
        DECADocumentStorage: Interface "DECA Document Storage";
        PdfInStream: InStream;
        PdfOutStream: OutStream;
    begin
        DECAHeader.TestStatusDraft();
        CheckMandatory(DECAHeader);
        if GuiAllowed() and (DECAHeader."Transport Date" < Today()) then
            if not Confirm(PastDateQst, false, DECAHeader."Transport Date") then
                Error('');

        DECASetup.GetSetup();
        DECADocumentStorage := DECASetup."Storage Provider";

        // 1. La URL va dentro del QR, así que se fija antes de generar el PDF
        DECAHeader."Blob Name" := NewBlobName();
        DECAHeader."Document URL" := CopyStr(DECADocumentStorage.GetDocumentUrl(DECAHeader."Blob Name"), 1, MaxStrLen(DECAHeader."Document URL"));
        if not DECAHeader."Document URL".StartsWith('https://') then
            Error(HttpsErr);
        DECAHeader."Issued At" := CurrentDateTime();
        DECAHeader."Issued By" := CopyStr(UserId(), 1, MaxStrLen(DECAHeader."Issued By"));
        if DECAHeader."Service End Date" = 0D then
            DECAHeader."Service End Date" := DECAHeader."Transport Date" + DECASetup."Default Service Duration";
        DECAHeader.Status := DECAHeader.Status::Issued;
        DECAHeader.Modify();

        // 2. PDF nativo digital (máx. 5 MB)
        TempBlob.CreateOutStream(PdfOutStream);
        RenderPdf(DECAHeader."No.", PdfOutStream);
        if not TempBlob.HasValue() then
            Error(RenderErr, DECAHeader."No.");
        if TempBlob.Length() > 5 * 1024 * 1024 then
            Error(SizeErr, DECAHeader."No.");

        // 3. Copia en Business Central (conservación de un año)
        TempBlob.CreateInStream(PdfInStream);
        Clear(DECAHeader."PDF Content");
        DECAHeader."PDF Content".CreateOutStream(PdfOutStream);
        CopyStream(PdfOutStream, PdfInStream);
        DECAHeader.Modify();

        // 4. Publicación en el repositorio. Si falla, se deshace toda la emisión
        TempBlob.CreateInStream(PdfInStream);
        DECADocumentStorage.Upload(DECAHeader."Blob Name", PdfInStream);

        // 5. Si sustituye a otro, el original queda marcado y se conserva (trazabilidad)
        if DECAHeader."Replaces DeCA No." <> '' then
            if ReplacedHeader.Get(DECAHeader."Replaces DeCA No.") then begin
                ReplacedHeader.Status := ReplacedHeader.Status::Replaced;
                ReplacedHeader."Replaced by DeCA No." := DECAHeader."No.";
                ReplacedHeader.Modify();
            end;
    end;

    /// <summary>
    /// Modificación durante el servicio (apartado quinto, método 2): nuevo DeCA con todos los
    /// datos, nueva URL y nuevo QR. El original se conserva.
    /// </summary>
    procedure CreateReplacement(DECAHeader: Record "DECA Header"): Code[20]
    var
        NewHeader: Record "DECA Header";
        DECALine: Record "DECA Line";
        NewLine: Record "DECA Line";
    begin
        DECAHeader.TestField(Status, DECAHeader.Status::Issued);
        NewHeader.SetRange("Replaces DeCA No.", DECAHeader."No.");
        NewHeader.SetRange(Status, NewHeader.Status::Draft);
        if NewHeader.FindFirst() then
            Error(PendingReplacementErr, NewHeader."No.");
        NewHeader.Reset();

        NewHeader := DECAHeader;
        NewHeader."No." := '';
        NewHeader."No. Series" := '';
        NewHeader.Status := NewHeader.Status::Draft;
        NewHeader."Version No." := DECAHeader."Version No." + 1;
        NewHeader."Replaces DeCA No." := DECAHeader."No.";
        NewHeader."Replaced by DeCA No." := '';
        NewHeader."Modification Reason" := '';
        NewHeader."Document URL" := '';
        NewHeader."Blob Name" := '';
        NewHeader."Issued At" := 0DT;
        NewHeader."Issued By" := '';
        NewHeader."URL Disabled" := false;
        NewHeader."URL Disabled At" := 0DT;
        Clear(NewHeader."PDF Content");
        NewHeader.Insert(true);

        DECALine.SetRange("Document No.", DECAHeader."No.");
        if DECALine.FindSet() then
            repeat
                NewLine := DECALine;
                NewLine."Document No." := NewHeader."No.";
                NewLine.Insert(true);
            until DECALine.Next() = 0;

        exit(NewHeader."No.");
    end;

    procedure CheckMandatory(DECAHeader: Record "DECA Header")
    var
        DECALine: Record "DECA Line";
    begin
        // Art. 6 Orden FOM/2861/2012
        DECAHeader.TestField("Shipper Name");
        DECAHeader.TestField("Shipper VAT Registration No.");
        DECAHeader.TestField("Shipper Address");
        DECAHeader.TestField("Shipper City");
        DECAHeader.TestField("Carrier Name");
        DECAHeader.TestField("Carrier VAT Registration No.");
        DECAHeader.TestField("Transport Date");
        DECAHeader.TestField("Vehicle Plate No.");
        if (DECAHeader."Replaces DeCA No." <> '') and (DECAHeader."Modification Reason" = '') then
            Error(ReasonErr, DECAHeader."Replaces DeCA No.");

        DECALine.SetRange("Document No.", DECAHeader."No.");
        if not DECALine.FindSet() then
            Error(NoLinesErr, DECAHeader."No.");
        repeat
            DECALine.TestField("Origin City");
            DECALine.TestField("Destination City");
            DECALine.TestField("Goods Description");
            if (DECALine."Gross Weight (kg)" = 0) and (DECALine."Alternative Magnitude" = '') then
                Error(WeightErr, DECALine."Line No.", DECAHeader."No.");
        until DECALine.Next() = 0;
    end;

    // ------------------------------------------------------------------
    // Entrega al conductor
    // ------------------------------------------------------------------

    procedure DownloadPdf(DECAHeader: Record "DECA Header")
    var
        PdfInStream: InStream;
        FileName: Text;
    begin
        if not DECAHeader.HasPdf() then
            Error(NoPdfErr, DECAHeader."No.");
        DECAHeader."PDF Content".CreateInStream(PdfInStream);
        FileName := StrSubstNo(FileNameTok, DECAHeader."No.");
        DownloadFromStream(PdfInStream, '', '', '', FileName);
    end;

    procedure SendByEmail(DECAHeader: Record "DECA Header")
    var
        Email: Codeunit Email;
        EmailMessage: Codeunit "Email Message";
        PdfInStream: InStream;
        FileName: Text[250];
    begin
        DECAHeader.TestField("Driver E-Mail");
        if not DECAHeader.HasPdf() then
            Error(NoPdfErr, DECAHeader."No.");
        DECAHeader."PDF Content".CreateInStream(PdfInStream);
        FileName := CopyStr(StrSubstNo(FileNameTok, DECAHeader."No."), 1, MaxStrLen(FileName));

        EmailMessage.Create(
            DECAHeader."Driver E-Mail",
            StrSubstNo(MailSubjectLbl, DECAHeader."No.", DECAHeader."Transport Date"),
            StrSubstNo(MailBodyLbl, DECAHeader."No.", DECAHeader."Transport Date", DECAHeader."Document URL"),
            true);
        EmailMessage.AddAttachment(FileName, 'application/pdf', PdfInStream);
        if Email.Send(EmailMessage, Enum::"Email Scenario"::Default) then
            if GuiAllowed() then
                Message(MailSentMsg, DECAHeader."No.", DECAHeader."Driver E-Mail");
    end;

    // ------------------------------------------------------------------
    // Locales
    // ------------------------------------------------------------------

    local procedure RenderPdf(DECANo: Code[20]; var PdfOutStream: OutStream)
    var
        DECAHeader: Record "DECA Header";
        RecRef: RecordRef;
    begin
        DECAHeader.SetRange("No.", DECANo);
        RecRef.GetTable(DECAHeader);
        if not Report.SaveAs(Report::"DECA Document", '', ReportFormat::Pdf, PdfOutStream, RecRef) then
            Error(RenderErr, DECANo);
    end;

    local procedure NewBlobName(): Text[250]
    begin
        // Nombre no adivinable: actúa como token de la URL
        exit(LowerCase(DelChr(Format(CreateGuid()) + Format(CreateGuid()), '=', '{}-')) + '.pdf');
    end;

    local procedure CreateHeader(var DECAHeader: Record "DECA Header"; SourceType: Enum "DECA Source Type"; SourceNo: Code[20])
    begin
        DECAHeader.Init();
        DECAHeader."No." := '';
        DECAHeader."Source Type" := SourceType;
        DECAHeader."Source No." := SourceNo;
        DECAHeader.Insert(true);
    end;

    /// <summary>
    /// Cargador: la empresa es el cargador contractual y el transportista del documento es el efectivo.
    /// Transportista: la empresa es el transportista efectivo y el cliente es el cargador contractual.
    /// </summary>
    local procedure SetPartiesFromSales(var DECAHeader: Record "DECA Header"; DECASetup: Record "DECA Setup"; CustomerNo: Code[20]; ShippingAgentCode: Code[10])
    begin
        case DECASetup."Company Role" of
            DECASetup."Company Role"::Shipper:
                if ShippingAgentCode <> '' then
                    DECAHeader.Validate("Shipping Agent Code", ShippingAgentCode);
            DECASetup."Company Role"::Carrier:
                DECAHeader.Validate("Shipper Customer No.", CustomerNo);
        end;
    end;

    local procedure GetSalesShipmentGoods(DocumentNo: Code[20]; DECASetup: Record "DECA Setup"; var GoodsDescription: Text; var GrossWeight: Decimal)
    var
        SalesShipmentLine: Record "Sales Shipment Line";
    begin
        GoodsDescription := '';
        GrossWeight := 0;
        SalesShipmentLine.SetRange("Document No.", DocumentNo);
        SalesShipmentLine.SetRange(Type, SalesShipmentLine.Type::Item);
        SalesShipmentLine.SetFilter(Quantity, '<>0');
        if SalesShipmentLine.FindSet() then
            repeat
                GrossWeight += SalesShipmentLine.Quantity * SalesShipmentLine."Gross Weight";
                AppendDescription(GoodsDescription, SalesShipmentLine.Description);
            until SalesShipmentLine.Next() = 0;
        ApplyDefaultGoods(DECASetup, GoodsDescription);
    end;

    local procedure GetSalesOrderGoods(SalesHeader: Record "Sales Header"; DECASetup: Record "DECA Setup"; var GoodsDescription: Text; var GrossWeight: Decimal)
    var
        SalesLine: Record "Sales Line";
        Qty: Decimal;
    begin
        GoodsDescription := '';
        GrossWeight := 0;
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesLine.FindSet() then
            repeat
                Qty := SalesLine."Qty. to Ship";
                if Qty = 0 then
                    Qty := SalesLine."Outstanding Quantity";
                if Qty <> 0 then begin
                    GrossWeight += Qty * SalesLine."Gross Weight";
                    AppendDescription(GoodsDescription, SalesLine.Description);
                end;
            until SalesLine.Next() = 0;
        ApplyDefaultGoods(DECASetup, GoodsDescription);
    end;

    local procedure AppendDescription(var GoodsDescription: Text; LineDescription: Text)
    begin
        if LineDescription = '' then
            exit;
        if GoodsDescription <> '' then
            GoodsDescription += '; ';
        GoodsDescription += LineDescription;
    end;

    local procedure ApplyDefaultGoods(DECASetup: Record "DECA Setup"; var GoodsDescription: Text)
    begin
        if DECASetup."Default Goods Description" <> '' then
            GoodsDescription := DECASetup."Default Goods Description";
    end;

    /// <summary>Si se pasa LocationCode, el origen se toma del almacén (o de la empresa si no tiene dirección).</summary>
    local procedure InsertLine(DECAHeader: Record "DECA Header"; SourceDocumentNo: Code[20]; LocationCode: Code[10]; OriginName: Text; OriginAddress: Text; OriginPostCode: Text; OriginCity: Text; DestinationName: Text; DestinationAddress: Text; DestinationPostCode: Text; DestinationCity: Text; GoodsDescription: Text; GrossWeight: Decimal)
    var
        DECALine: Record "DECA Line";
        LineNo: Integer;
    begin
        if OriginCity = '' then
            GetDefaultOrigin(LocationCode, OriginName, OriginAddress, OriginPostCode, OriginCity);

        DECALine.SetRange("Document No.", DECAHeader."No.");
        if DECALine.FindLast() then
            LineNo := DECALine."Line No.";
        LineNo += 10000;

        DECALine.Init();
        DECALine."Document No." := DECAHeader."No.";
        DECALine."Line No." := LineNo;
        DECALine."Source Document No." := SourceDocumentNo;
        DECALine."Origin Name" := CopyStr(OriginName, 1, MaxStrLen(DECALine."Origin Name"));
        DECALine."Origin Address" := CopyStr(OriginAddress, 1, MaxStrLen(DECALine."Origin Address"));
        DECALine."Origin Post Code" := CopyStr(OriginPostCode, 1, MaxStrLen(DECALine."Origin Post Code"));
        DECALine."Origin City" := CopyStr(OriginCity, 1, MaxStrLen(DECALine."Origin City"));
        DECALine."Destination Name" := CopyStr(DestinationName, 1, MaxStrLen(DECALine."Destination Name"));
        DECALine."Destination Address" := CopyStr(DestinationAddress, 1, MaxStrLen(DECALine."Destination Address"));
        DECALine."Destination Post Code" := CopyStr(DestinationPostCode, 1, MaxStrLen(DECALine."Destination Post Code"));
        DECALine."Destination City" := CopyStr(DestinationCity, 1, MaxStrLen(DECALine."Destination City"));
        DECALine."Goods Description" := CopyStr(GoodsDescription, 1, MaxStrLen(DECALine."Goods Description"));
        DECALine."Gross Weight (kg)" := Round(GrossWeight, 0.01);
        DECALine.Insert(true);
    end;

    local procedure GetDefaultOrigin(LocationCode: Code[10]; var OriginName: Text; var OriginAddress: Text; var OriginPostCode: Text; var OriginCity: Text)
    var
        CompanyInformation: Record "Company Information";
        Location: Record Location;
    begin
        if (LocationCode <> '') and Location.Get(LocationCode) then
            if Location.City <> '' then begin
                OriginName := Location.Name;
                OriginAddress := Location.Address;
                OriginPostCode := Location."Post Code";
                OriginCity := Location.City;
                exit;
            end;
        CompanyInformation.Get();
        OriginName := CompanyInformation.Name;
        OriginAddress := CompanyInformation.Address;
        OriginPostCode := CompanyInformation."Post Code";
        OriginCity := CompanyInformation.City;
    end;
}
