codeunit 99211 "IKA Mail Attach Mgt."
{
    // Adjunta el email completo (.eml) o sus ficheros a una entidad de BC usando los adjuntos
    // estándar (tabla "Document Attachment"), de modo que aparecen en el FactBox "Documentos adjuntos"
    // de la ficha. Además registra el vínculo en "IKA Mail Link" y prepara los datos del visor.

    var
        Setup: Record "IKA Mail Setup";
        EntityMgt: Codeunit "IKA Mail Entity Mgt.";
        GraphClient: Codeunit "IKA Mail Graph Client";
        EmailItemIdTok: Label 'EML', Locked = true;
        AttachmentItemPrefixTok: Label 'ATT:', Locked = true;
        EntityNotFoundErr: Label 'No existe %1 %2.', Comment = '%1 = entity type, %2 = no.';
        TooBigErr: Label 'El fichero %1 (%2 MB) supera el máximo configurado de %3 MB.', Comment = '%1 = file, %2 = size, %3 = max';
        AttachedLbl: Label '"%1" adjuntado a %2 %3 - %4.', Comment = '%1 = file, %2 = entity type, %3 = no., %4 = name';
        NoSubjectLbl: Label 'email';

    // =====================================================================
    // Adjuntar
    // =====================================================================

    /// <summary>
    /// ItemId: "EML" = email completo; "ATT:&lt;nº línea&gt;" = adjunto. Devuelve el texto de confirmación.
    /// </summary>
    procedure AttachItem(var MailMessage: Record "IKA Mail Message"; ItemId: Text; EntityType: Enum "IKA Mail Entity Type"; EntityNo: Code[20]): Text
    var
        MailAttachment: Record "IKA Mail Attachment";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
        AttachmentLineNo: Integer;
    begin
        if ItemId = EmailItemIdTok then begin
            GraphClient.GetMimeContent(MailMessage, TempBlob);
            FileName := GetEmailFileName(MailMessage);
        end else begin
            Evaluate(AttachmentLineNo, CopyStr(ItemId, StrLen(AttachmentItemPrefixTok) + 1));
            MailAttachment.Get(MailMessage."Entry No.", AttachmentLineNo);
            GraphClient.LoadAttachmentContent(MailAttachment);
            MailAttachment.CalcFields(Content);
            MailAttachment.Content.CreateInStream(InStr);
            TempBlob.CreateOutStream(OutStr);
            CopyStream(OutStr, InStr);
            FileName := MailAttachment.GetFileName();
        end;
        exit(AttachBlob(MailMessage, AttachmentLineNo, TempBlob, FileName, EntityType, EntityNo));
    end;

    /// <summary>
    /// Fichero soltado desde el escritorio (o desde Outlook de escritorio) sobre una zona de destino.
    /// </summary>
    procedure AttachExternalFile(var MailMessage: Record "IKA Mail Message"; FileName: Text; Base64Content: Text; EntityType: Enum "IKA Mail Entity Type"; EntityNo: Code[20]): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        Base64Convert.FromBase64(Base64Content, OutStr);
        exit(AttachBlob(MailMessage, -1, TempBlob, FileName, EntityType, EntityNo));
    end;

    procedure AttachAllFiles(var MailMessage: Record "IKA Mail Message"; EntityType: Enum "IKA Mail Entity Type"; EntityNo: Code[20]): Integer
    var
        MailAttachment: Record "IKA Mail Attachment";
        AttachedCount: Integer;
    begin
        MailAttachment.SetRange("Message Entry No.", MailMessage."Entry No.");
        MailAttachment.SetRange("Is Inline", false);
        MailAttachment.SetFilter("Attachment Kind", '<>%1', MailAttachment."Attachment Kind"::Reference);
        if MailAttachment.FindSet() then
            repeat
                AttachItem(MailMessage, GetAttachmentItemId(MailAttachment), EntityType, EntityNo);
                AttachedCount += 1;
            until MailAttachment.Next() = 0;
        exit(AttachedCount);
    end;

    local procedure AttachBlob(var MailMessage: Record "IKA Mail Message"; AttachmentLineNo: Integer; var TempBlob: Codeunit "Temp Blob"; FileName: Text; EntityType: Enum "IKA Mail Entity Type"; EntityNo: Code[20]): Text
    var
        MailLink: Record "IKA Mail Link";
        RecRef: RecordRef;
        DocumentAttachmentId: Integer;
    begin
        Setup.GetSetup();
        if not EntityMgt.GetRecRef(EntityType, EntityNo, RecRef) then
            Error(EntityNotFoundErr, EntityType, EntityNo);
        if (Setup."Max Attach Size (MB)" > 0) and (TempBlob.Length() > Setup."Max Attach Size (MB)" * 1048576) then
            Error(TooBigErr, FileName, Round(TempBlob.Length() / 1048576, 0.1), Setup."Max Attach Size (MB)");

        DocumentAttachmentId := SaveToDocumentAttachment(TempBlob, RecRef, EntityNo, FileName);

        MailLink.Init();
        MailLink."Message Entry No." := MailMessage."Entry No.";
        MailLink."Attachment Line No." := AttachmentLineNo;
        MailLink."File Name" := CopyStr(FileName, 1, MaxStrLen(MailLink."File Name"));
        MailLink.Subject := MailMessage.Subject;
        MailLink."From Address" := MailMessage."From Address";
        MailLink."Received At" := MailMessage."Received At";
        MailLink."Entity Type" := EntityType;
        MailLink."Entity No." := EntityNo;
        MailLink."Table ID" := RecRef.Number;
        MailLink."Document Attachment ID" := DocumentAttachmentId;
        MailLink.Insert(true);
        OnAfterAttach(MailMessage, MailLink);

        exit(StrSubstNo(AttachedLbl, FileName, EntityType, EntityNo, EntityMgt.GetName(EntityType, EntityNo)));
    end;

    local procedure SaveToDocumentAttachment(var TempBlob: Codeunit "Temp Blob"; RecRef: RecordRef; EntityNo: Code[20]; FileName: Text): Integer
    var
        DocumentAttachment: Record "Document Attachment";
        InStr: InStream;
    begin
        FileName := GetUniqueFileName(RecRef.Number, EntityNo, FileName);
        TempBlob.CreateInStream(InStr);
        DocumentAttachment.SaveAttachmentFromStream(InStr, RecRef, FileName);
        exit(DocumentAttachment.ID);
    end;

    /// <summary>
    /// Si la entidad ya tiene un adjunto con el mismo nombre, añade " (2)", " (3)"...
    /// </summary>
    local procedure GetUniqueFileName(TableId: Integer; EntityNo: Code[20]; FileName: Text): Text
    var
        DocumentAttachment: Record "Document Attachment";
        BaseName: Text;
        Extension: Text;
        CandidateName: Text;
        DotPos: Integer;
        Counter: Integer;
    begin
        DotPos := StrLen(FileName);
        while (DotPos > 0) and (CopyStr(FileName, DotPos, 1) <> '.') do
            DotPos -= 1;
        if DotPos > 1 then begin
            BaseName := CopyStr(FileName, 1, DotPos - 1);
            Extension := CopyStr(FileName, DotPos + 1);
        end else
            BaseName := FileName;

        DocumentAttachment.SetRange("Table ID", TableId);
        DocumentAttachment.SetRange("No.", EntityNo);
        DocumentAttachment.SetRange("File Extension", CopyStr(Extension, 1, MaxStrLen(DocumentAttachment."File Extension")));
        CandidateName := BaseName;
        Counter := 1;
        repeat
            DocumentAttachment.SetRange("File Name", CopyStr(CandidateName, 1, MaxStrLen(DocumentAttachment."File Name")));
            if DocumentAttachment.IsEmpty() then
                break;
            Counter += 1;
            CandidateName := BaseName + ' (' + Format(Counter) + ')';
        until Counter > 99;

        if Extension = '' then
            exit(CandidateName);
        exit(CandidateName + '.' + Extension);
    end;

    procedure GetEmailFileName(MailMessage: Record "IKA Mail Message"): Text
    var
        Name: Text;
    begin
        Name := DelChr(MailMessage.Subject, '=', '\/:*?"<>|');
        if Name = '' then
            Name := NoSubjectLbl;
        if MailMessage."Received At" <> 0DT then
            Name := Format(DT2Date(MailMessage."Received At"), 0, '<Year4><Month,2><Day,2>') + ' ' + Name;
        exit(CopyStr(Name, 1, 200) + '.eml');
    end;

    procedure GetAttachmentItemId(MailAttachment: Record "IKA Mail Attachment"): Text
    begin
        exit(AttachmentItemPrefixTok + Format(MailAttachment."Line No."));
    end;

    procedure GetEmailItemId(): Text
    begin
        exit(EmailItemIdTok);
    end;

    // =====================================================================
    // Destinos fijados
    // =====================================================================

    procedure PinTarget(EntityType: Enum "IKA Mail Entity Type"; EntityNo: Code[20])
    var
        PinnedTarget: Record "IKA Mail Pinned Target";
    begin
        if EntityNo = '' then
            exit;
        if PinnedTarget.Get(UserId(), EntityType, EntityNo) then
            exit;
        PinnedTarget.Init();
        PinnedTarget."User ID" := CopyStr(UserId(), 1, MaxStrLen(PinnedTarget."User ID"));
        PinnedTarget."Entity Type" := EntityType;
        PinnedTarget."Entity No." := EntityNo;
        PinnedTarget."Pinned At" := CurrentDateTime();
        PinnedTarget.Insert();
    end;

    procedure UnpinTarget(EntityType: Enum "IKA Mail Entity Type"; EntityNo: Code[20])
    var
        PinnedTarget: Record "IKA Mail Pinned Target";
    begin
        if PinnedTarget.Get(UserId(), EntityType, EntityNo) then
            PinnedTarget.Delete();
    end;

    // =====================================================================
    // Datos para el visor (control add-in)
    // =====================================================================

    /// <summary>
    /// Zonas de destino: la entidad seleccionada en la página, las sugeridas por el remitente
    /// y las fijadas por el usuario.
    /// </summary>
    procedure BuildTargets(MailMessage: Record "IKA Mail Message"; SelectedType: Enum "IKA Mail Entity Type"; SelectedNo: Code[20]; var TempDropTarget: Record "IKA Mail Drop Target" temporary)
    var
        PinnedTarget: Record "IKA Mail Pinned Target";
        SortOrder: Integer;
    begin
        TempDropTarget.Reset();
        TempDropTarget.DeleteAll();

        if SelectedNo <> '' then
            InsertTarget(TempDropTarget, SelectedType, SelectedNo, TempDropTarget.Kind::Selected, SortOrder);

        EntityMgt.AddSuggestions(MailMessage."From Address", TempDropTarget, SortOrder);

        PinnedTarget.SetRange("User ID", UserId());
        if PinnedTarget.FindSet() then
            repeat
                // Si ya está como seleccionado o sugerido se deja así (el JSON indica que está fijado)
                if not TempDropTarget.Get(PinnedTarget."Entity Type", PinnedTarget."Entity No.") then
                    InsertTarget(TempDropTarget, PinnedTarget."Entity Type", PinnedTarget."Entity No.", TempDropTarget.Kind::Pinned, SortOrder);
            until PinnedTarget.Next() = 0;
    end;

    local procedure InsertTarget(var TempDropTarget: Record "IKA Mail Drop Target" temporary; EntityType: Enum "IKA Mail Entity Type"; EntityNo: Code[20]; Kind: Enum "IKA Mail Target Kind"; var SortOrder: Integer)
    begin
        if TempDropTarget.Get(EntityType, EntityNo) then
            exit;
        SortOrder += 1;
        TempDropTarget.Init();
        TempDropTarget."Entity Type" := EntityType;
        TempDropTarget."Entity No." := EntityNo;
        TempDropTarget.Name := EntityMgt.GetName(EntityType, EntityNo);
        TempDropTarget.Kind := Kind;
        TempDropTarget."Sort Order" := SortOrder;
        TempDropTarget.Insert();
    end;

    procedure TargetsToJson(var TempDropTarget: Record "IKA Mail Drop Target" temporary): Text
    var
        PinnedTarget: Record "IKA Mail Pinned Target";
        Targets: JsonArray;
        Target: JsonObject;
        Result: Text;
    begin
        TempDropTarget.SetCurrentKey("Sort Order");
        if TempDropTarget.FindSet() then
            repeat
                Clear(Target);
                Target.Add('id', TempDropTarget.GetTargetId());
                Target.Add('type', Format(TempDropTarget."Entity Type"));
                Target.Add('no', TempDropTarget."Entity No.");
                Target.Add('name', TempDropTarget.Name);
                case TempDropTarget.Kind of
                    TempDropTarget.Kind::Selected:
                        Target.Add('kind', 'selected');
                    TempDropTarget.Kind::Suggested:
                        Target.Add('kind', 'suggested');
                    else
                        Target.Add('kind', 'pinned');
                end;
                Target.Add('kindCaption', Format(TempDropTarget.Kind));
                Target.Add('pinned', PinnedTarget.Get(UserId(), TempDropTarget."Entity Type", TempDropTarget."Entity No."));
                Targets.Add(Target);
            until TempDropTarget.Next() = 0;
        Targets.WriteTo(Result);
        exit(Result);
    end;

    /// <summary>
    /// Elementos arrastrables: el email completo y cada adjunto (no incrustado), con sus vínculos.
    /// </summary>
    procedure BuildItemsJson(MailMessage: Record "IKA Mail Message"): Text
    var
        MailAttachment: Record "IKA Mail Attachment";
        Items: JsonArray;
        Result: Text;
    begin
        Items.Add(BuildItem(EmailItemIdTok, GetEmailFileName(MailMessage), '', 'email', MailMessage."Entry No.", 0));
        MailAttachment.SetRange("Message Entry No.", MailMessage."Entry No.");
        MailAttachment.SetRange("Is Inline", false);
        if MailAttachment.FindSet() then
            repeat
                Items.Add(BuildItem(GetAttachmentItemId(MailAttachment), MailAttachment.GetFileName(), MailAttachment.GetSizeText(),
                    LowerCase(Format(MailAttachment."Attachment Kind", 0, 2)), MailMessage."Entry No.", MailAttachment."Line No."));
            until MailAttachment.Next() = 0;
        Items.WriteTo(Result);
        exit(Result);
    end;

    local procedure BuildItem(ItemId: Text; Name: Text; SizeText: Text; Kind: Text; MessageEntryNo: Integer; AttachmentLineNo: Integer): JsonObject
    var
        MailLink: Record "IKA Mail Link";
        Item: JsonObject;
        Links: JsonArray;
    begin
        Item.Add('id', ItemId);
        Item.Add('name', Name);
        Item.Add('size', SizeText);
        // "0" = fichero, "1" = elemento de Outlook, "2" = referencia; "email" = email completo
        case Kind of
            '1':
                Kind := 'item';
            '2':
                Kind := 'reference';
            '0':
                Kind := 'file';
        end;
        Item.Add('kind', Kind);
        MailLink.SetCurrentKey("Message Entry No.", "Attachment Line No.");
        MailLink.SetRange("Message Entry No.", MessageEntryNo);
        MailLink.SetRange("Attachment Line No.", AttachmentLineNo);
        if MailLink.FindSet() then
            repeat
                Links.Add(Format(MailLink."Entity Type") + ' ' + MailLink."Entity No.");
            until MailLink.Next() = 0;
        Item.Add('links', Links);
        exit(Item);
    end;

    /// <summary>
    /// HTML del cuerpo preparado para mostrarse en un iframe aislado (sin scripts):
    /// imágenes incrustadas (cid:) convertidas a data URI, enlaces en pestaña nueva y,
    /// opcionalmente, bloqueo de imágenes externas mediante Content-Security-Policy.
    /// </summary>
    procedure BuildViewerHtml(MailMessage: Record "IKA Mail Message"): Text
    var
        MailAttachment: Record "IKA Mail Attachment";
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
        Html: Text;
        Prefix: Text;
        ContentId: Text;
    begin
        Setup.GetSetup();
        Html := MailMessage.GetBodyHtml();
        if Html = '' then
            Html := '<p style="color:#666;font-family:Segoe UI,Arial,sans-serif">(Sin contenido)</p>';

        MailAttachment.SetRange("Message Entry No.", MailMessage."Entry No.");
        MailAttachment.SetRange("Is Inline", true);
        MailAttachment.SetRange("Content Loaded", true);
        if MailAttachment.FindSet() then
            repeat
                ContentId := DelChr(MailAttachment."Content Id", '<>', '<> ');
                if ContentId <> '' then begin
                    MailAttachment.CalcFields(Content);
                    MailAttachment.Content.CreateInStream(InStr);
                    Html := Html.Replace('cid:' + ContentId, 'data:' + MailAttachment."Content Type" + ';base64,' + Base64Convert.ToBase64(InStr));
                end;
            until MailAttachment.Next() = 0;

        Prefix := '<meta charset="utf-8"><base target="_blank">';
        if Setup."Block Remote Images" then
            Prefix += '<meta http-equiv="Content-Security-Policy" content="default-src ''none''; img-src data:; style-src ''unsafe-inline'' data:; font-src data:">';
        exit(Prefix + Html);
    end;

    // =====================================================================
    // Integración con los adjuntos estándar
    // =====================================================================

    /// <summary>
    /// La tabla "Document Attachment" solo rellena "Nº" para algunas tablas (cliente, proveedor,
    /// producto, empleado, activo, recurso, proyecto...). Para banco y contacto se rellena aquí.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnAfterInitFieldsFromRecRef', '', false, false)]
    local procedure DocumentAttachmentOnAfterInitFieldsFromRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
    begin
        if DocumentAttachment."No." <> '' then
            exit;
        if not (RecRef.Number in [Database::"Bank Account", Database::Contact]) then
            exit;
        FieldRef := RecRef.Field(1);
        DocumentAttachment."No." := FieldRef.Value;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAttach(MailMessage: Record "IKA Mail Message"; MailLink: Record "IKA Mail Link")
    begin
    end;
}
