codeunit 50040 "IKA Sales Order Creator"
{
    // Crea el pedido de venta estándar a partir de una solicitud resuelta.
    // Todo se hace con Validate para que BC aplique su lógica: precios, descuentos,
    // condiciones de pago, almacén, dimensiones, etc. salen de la configuración de BC.

    var
        Setup: Record "IKA Sales Agent Setup";
        LogMgt: Codeunit "IKA Sales Agent Log Mgt.";
        AlreadyCreatedErr: Label 'La solicitud %1 ya tiene creado el pedido %2.', Comment = '%1 = entry no., %2 = order no.';
        WrongStatusErr: Label 'No se puede crear el pedido desde una solicitud en estado %1.', Comment = '%1 = status';
        NoResolvedLinesErr: Label 'La solicitud %1 no tiene ninguna línea con producto identificado.', Comment = '%1 = entry no.';
        UnresolvedLinesQst: Label 'Hay %1 línea(s) sin resolver. ¿Desea crear el pedido igualmente?%2', Comment = '%1 = count, %2 = what will happen';
        AsCommentsTxt: Label ' Se añadirán como líneas de comentario.';
        SkippedTxt: Label ' No se incluirán en el pedido.';
        DuplicateQst: Label 'La solicitud está marcada como posible duplicado. ¿Desea crear el pedido igualmente?';
        UnmatchedCommentLbl: Label '[NO IDENTIFICADO] %1 - Cant.: %2 %3', Comment = '%1 = item text, %2 = qty, %3 = unit';
        CreatedLbl: Label 'Creado el pedido de venta %1.', Comment = '%1 = order no.';
        SourceCommentLbl: Label 'Pedido creado por el agente de ventas desde: %1', Comment = '%1 = email subject or source';

    procedure CreateSalesOrder(var RequestHeader: Record "IKA Sales Request Header"): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        CheckRequest(RequestHeader);

        CreateHeader(RequestHeader, SalesHeader);
        CreateLines(RequestHeader, SalesHeader);

        RequestHeader."Sales Order No." := SalesHeader."No.";
        RequestHeader.Status := RequestHeader.Status::"Order Created";
        RequestHeader.Modify();
        LogMgt.LogInfo(RequestHeader."Entry No.", StrSubstNo(CreatedLbl, SalesHeader."No."));
        exit(SalesHeader."No.");
    end;

    local procedure CheckRequest(var RequestHeader: Record "IKA Sales Request Header")
    var
        RequestLine: Record "IKA Sales Request Line";
        WhatHappens: Text;
    begin
        Setup.GetSetup();
        if RequestHeader."Sales Order No." <> '' then
            Error(AlreadyCreatedErr, RequestHeader."Entry No.", RequestHeader."Sales Order No.");
        if not (RequestHeader.Status in [RequestHeader.Status::Ready, RequestHeader.Status::"Needs Review"]) then
            Error(WrongStatusErr, RequestHeader.Status);
        RequestHeader.TestField("Customer No.");

        RequestLine.SetRange("Request Entry No.", RequestHeader."Entry No.");
        RequestLine.SetRange(Resolved, true);
        if RequestLine.IsEmpty() then
            Error(NoResolvedLinesErr, RequestHeader."Entry No.");

        if not GuiAllowed() then
            exit;
        RequestHeader.CalcFields("No. of Unresolved Lines");
        if RequestHeader."No. of Unresolved Lines" > 0 then begin
            if Setup."Unmatched Lines as Comments" then
                WhatHappens := AsCommentsTxt
            else
                WhatHappens := SkippedTxt;
            if not Confirm(UnresolvedLinesQst, false, RequestHeader."No. of Unresolved Lines", WhatHappens) then
                Error('');
        end;
        if RequestHeader."Possible Duplicate" then
            if not Confirm(DuplicateQst, false) then
                Error('');
    end;

    local procedure CreateHeader(RequestHeader: Record "IKA Sales Request Header"; var SalesHeader: Record "Sales Header")
    begin
        SalesHeader.Init();
        SalesHeader.Validate("Document Type", SalesHeader."Document Type"::Order);
        SalesHeader."No." := '';
        SalesHeader.Insert(true);

        SalesHeader.Validate("Sell-to Customer No.", RequestHeader."Customer No.");
        if RequestHeader."Ship-to Code" <> '' then
            SalesHeader.Validate("Ship-to Code", RequestHeader."Ship-to Code");
        if RequestHeader."External Document No." <> '' then
            SalesHeader.Validate("External Document No.", RequestHeader."External Document No.");
        if RequestHeader."Requested Delivery Date" <> 0D then
            SalesHeader.Validate("Requested Delivery Date", RequestHeader."Requested Delivery Date");
        SalesHeader."IKA Sales Request Entry No." := RequestHeader."Entry No.";
        OnBeforeModifySalesHeader(RequestHeader, SalesHeader);
        SalesHeader.Modify(true);
    end;

    local procedure CreateLines(RequestHeader: Record "IKA Sales Request Header"; SalesHeader: Record "Sales Header")
    var
        RequestLine: Record "IKA Sales Request Line";
        SalesLine: Record "Sales Line";
        LineNo: Integer;
    begin
        RequestLine.SetRange("Request Entry No.", RequestHeader."Entry No.");
        if RequestLine.FindSet() then
            repeat
                if RequestLine.Resolved then begin
                    LineNo += 10000;
                    InitSalesLine(SalesHeader, SalesLine, LineNo);
                    SalesLine.Validate(Type, SalesLine.Type::Item);
                    SalesLine.Validate("No.", RequestLine."Item No.");
                    if RequestLine."Variant Code" <> '' then
                        SalesLine.Validate("Variant Code", RequestLine."Variant Code");
                    if RequestLine."Unit of Measure Code" <> '' then
                        SalesLine.Validate("Unit of Measure Code", RequestLine."Unit of Measure Code");
                    SalesLine.Validate(Quantity, RequestLine.Quantity);
                    OnBeforeInsertSalesLine(RequestLine, SalesLine);
                    SalesLine.Insert(true);
                    if RequestLine."Ext. Notes" <> '' then
                        InsertCommentLine(SalesHeader, LineNo, RequestLine."Ext. Notes");
                end else
                    if Setup."Unmatched Lines as Comments" then
                        InsertCommentLine(SalesHeader, LineNo,
                            StrSubstNo(UnmatchedCommentLbl, RequestLine.GetDisplayText(), RequestLine.Quantity, RequestLine."Ext. Unit of Measure"));
            until RequestLine.Next() = 0;

        if RequestHeader.Comments <> '' then
            InsertCommentLine(SalesHeader, LineNo, RequestHeader.Comments);
        if RequestHeader.Subject <> '' then
            InsertCommentLine(SalesHeader, LineNo, StrSubstNo(SourceCommentLbl, RequestHeader.Subject));
    end;

    local procedure InitSalesLine(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; LineNo: Integer)
    begin
        SalesLine.Init();
        SalesLine."Document Type" := SalesHeader."Document Type";
        SalesLine."Document No." := SalesHeader."No.";
        SalesLine."Line No." := LineNo;
        SalesLine.SetSalesHeader(SalesHeader);
    end;

    /// <summary>
    /// Inserta el texto como una o varias líneas de comentario (tipo en blanco) de 100 caracteres.
    /// </summary>
    local procedure InsertCommentLine(SalesHeader: Record "Sales Header"; var LineNo: Integer; CommentText: Text)
    var
        SalesLine: Record "Sales Line";
        Cr: Char;
        Lf: Char;
    begin
        Cr := 13;
        Lf := 10;
        CommentText := DelChr(ConvertStr(CommentText, Format(Cr) + Format(Lf), '  '), '<>', ' ');
        while CommentText <> '' do begin
            LineNo += 10000;
            InitSalesLine(SalesHeader, SalesLine, LineNo);
            SalesLine.Validate(Type, SalesLine.Type::" ");
            SalesLine.Description := CopyStr(CommentText, 1, MaxStrLen(SalesLine.Description));
            SalesLine.Insert(true);
            CommentText := DelChr(CopyStr(CommentText, MaxStrLen(SalesLine.Description) + 1), '<', ' ');
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifySalesHeader(RequestHeader: Record "IKA Sales Request Header"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSalesLine(RequestLine: Record "IKA Sales Request Line"; var SalesLine: Record "Sales Line")
    begin
    end;
}
