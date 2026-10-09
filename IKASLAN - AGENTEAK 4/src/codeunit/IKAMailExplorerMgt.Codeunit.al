codeunit 99221 "IKA Mail Explorer Mgt."
{
    // Vista tipo Outlook ("IKA Mail Explorer"): datos en JSON para los tres paneles del control add-in
    // (carpetas, emails de la carpeta y email seleccionado) y las acciones sobre un email.
    // El estado (cuenta, carpeta, email seleccionado) lo guarda la página.

    var
        GraphClient: Codeunit "IKA Mail Graph Client";
        AttachMgt: Codeunit "IKA Mail Attach Mgt.";
        NoWebLinkErr: Label 'Este email no tiene enlace a Outlook Web. Sincronice la carpeta e inténtelo de nuevo.';
        DeleteForeverQst: Label 'El email "%1" está en Elementos eliminados. ¿Eliminarlo definitivamente de Outlook?', Comment = '%1 = subject';
        DeleteLinkedForeverQst: Label 'El email "%1" está en Elementos eliminados y tiene %2 fichero(s) adjuntado(s) a entidades de BC. Esos ficheros se conservan en BC. ¿Eliminar el email definitivamente de Outlook?', Comment = '%1 = subject, %2 = links';
        ReferenceAttachmentErr: Label 'El adjunto "%1" es un enlace a OneDrive/SharePoint, no un fichero. Ábralo desde Outlook.', Comment = '%1 = name';

    // =====================================================================
    // Cuenta y carpetas
    // =====================================================================

    /// <summary>
    /// Cuenta con la que se abre la vista: la última que usó el usuario, la de la configuración o la primera permitida.
    /// </summary>
    procedure GetInitialMailbox(var UserSetting: Record "IKA Mail User Setting"): Code[20]
    var
        Setup: Record "IKA Mail Setup";
        Mailbox: Record "IKA Mail Mailbox";
        AllowedFilter: Text;
    begin
        AllowedFilter := Mailbox.GetAllowedFilter();
        if AllowedFilter = '' then
            exit('');
        if UserSetting."Last Mailbox Code" <> '' then
            if IsAllowed(UserSetting."Last Mailbox Code") then
                exit(UserSetting."Last Mailbox Code");
        Setup.GetSetup();
        if Setup."Default Mailbox Code" <> '' then
            if IsAllowed(Setup."Default Mailbox Code") then
                exit(Setup."Default Mailbox Code");
        Mailbox.SetFilter(Code, AllowedFilter);
        if Mailbox.FindFirst() then
            exit(Mailbox.Code);
        exit('');
    end;

    local procedure IsAllowed(MailboxCode: Code[20]): Boolean
    var
        Mailbox: Record "IKA Mail Mailbox";
    begin
        if not Mailbox.Get(MailboxCode) then
            exit(false);
        exit(Mailbox.Enabled and Mailbox.HasAccess());
    end;

    /// <summary>
    /// Prepara la cuenta: descarga el árbol de carpetas si aún no está y devuelve la carpeta a mostrar
    /// (la pedida si existe; si no, la carpeta por defecto de la cuenta).
    /// </summary>
    procedure PrepareMailbox(MailboxCode: Code[20]; WantedFolderId: Text; var DefaultFolderId: Text): Text
    var
        Mailbox: Record "IKA Mail Mailbox";
        MailFolder: Record "IKA Mail Folder";
    begin
        Mailbox.Get(MailboxCode);
        Mailbox.CheckAccess();
        MailFolder.SetRange("Mailbox Code", MailboxCode);
        if MailFolder.IsEmpty() then
            GraphClient.SyncFolders(Mailbox);
        DefaultFolderId := GraphClient.GetDefaultFolderId(Mailbox);
        if WantedFolderId <> '' then
            if MailFolder.Get(MailboxCode, CopyStr(WantedFolderId, 1, MaxStrLen(MailFolder."Folder Id"))) then
                exit(WantedFolderId);
        exit(DefaultFolderId);
    end;

    procedure RefreshFolders(MailboxCode: Code[20])
    var
        Mailbox: Record "IKA Mail Mailbox";
    begin
        Mailbox.Get(MailboxCode);
        GraphClient.SyncFolders(Mailbox);
    end;

    /// <summary>
    /// Descarga los emails de la carpeta: los últimos o, con LoadOlder, los anteriores a los que ya hay.
    /// </summary>
    procedure SyncFolder(MailboxCode: Code[20]; FolderId: Text; LoadOlder: Boolean): Integer
    var
        Mailbox: Record "IKA Mail Mailbox";
    begin
        Mailbox.Get(MailboxCode);
        exit(GraphClient.SyncFolderMessages(Mailbox, FolderId, LoadOlder));
    end;

    procedure HasLocalMessages(MailboxCode: Code[20]; FolderId: Text; DefaultFolderId: Text): Boolean
    var
        MailMessage: Record "IKA Mail Message";
    begin
        SetFolderFilter(MailMessage, MailboxCode, FolderId, DefaultFolderId);
        exit(not MailMessage.IsEmpty());
    end;

    /// <summary>
    /// Email que se selecciona después de eliminar EntryNo: el siguiente de la lista (más antiguo) o, si era el
    /// último, el anterior. 0 si no queda ninguno.
    /// </summary>
    procedure GetNextEntryNo(MailboxCode: Code[20]; FolderId: Text; DefaultFolderId: Text; EntryNo: Integer): Integer
    var
        CurrentMessage: Record "IKA Mail Message";
        MailMessage: Record "IKA Mail Message";
    begin
        if not CurrentMessage.Get(EntryNo) then
            exit(0);
        MailMessage.SetCurrentKey("Mailbox Code", "Received At");
        SetFolderFilter(MailMessage, MailboxCode, FolderId, DefaultFolderId);
        MailMessage.SetFilter("Entry No.", '<>%1', EntryNo);
        // Siguiente en la lista: el más reciente de los anteriores
        MailMessage.SetFilter("Received At", '<=%1', CurrentMessage."Received At");
        if MailMessage.FindLast() then
            exit(MailMessage."Entry No.");
        // Era el último: el más antiguo de los posteriores
        MailMessage.SetFilter("Received At", '>%1', CurrentMessage."Received At");
        if MailMessage.FindFirst() then
            exit(MailMessage."Entry No.");
        exit(0);
    end;

    local procedure SetFolderFilter(var MailMessage: Record "IKA Mail Message"; MailboxCode: Code[20]; FolderId: Text; DefaultFolderId: Text)
    begin
        MailMessage.SetRange("Mailbox Code", MailboxCode);
        // Los emails guardados antes de existir el selector de carpetas no tienen carpeta: son de la carpeta por defecto
        if FolderId = DefaultFolderId then
            MailMessage.SetFilter("Folder Id", '%1|%2', FolderId, '')
        else
            MailMessage.SetRange("Folder Id", FolderId);
    end;

    // =====================================================================
    // JSON para el control add-in
    // =====================================================================

    /// <summary>
    /// { current, items: [{ code, label }] } con las cuentas a las que tiene acceso el usuario.
    /// </summary>
    procedure BuildMailboxesJson(CurrentMailboxCode: Code[20]): Text
    var
        Mailbox: Record "IKA Mail Mailbox";
        Data: JsonObject;
        Items: JsonArray;
        Item: JsonObject;
        AllowedFilter: Text;
        Result: Text;
    begin
        AllowedFilter := Mailbox.GetAllowedFilter();
        if AllowedFilter <> '' then begin
            Mailbox.SetFilter(Code, AllowedFilter);
            if Mailbox.FindSet() then
                repeat
                    Clear(Item);
                    Item.Add('code', Mailbox.Code);
                    if Mailbox.Description <> '' then
                        Item.Add('label', Mailbox.Description + ' (' + Mailbox.Address + ')')
                    else
                        Item.Add('label', Mailbox.Address);
                    Items.Add(Item);
                until Mailbox.Next() = 0;
        end;
        Data.Add('current', CurrentMailboxCode);
        Data.Add('items', Items);
        Data.WriteTo(Result);
        exit(Result);
    end;

    /// <summary>
    /// { selected, items: [{ id, name, path, level, unread, total, children, wellKnown }] } en el orden de Outlook.
    /// </summary>
    procedure BuildFoldersJson(MailboxCode: Code[20]; SelectedFolderId: Text): Text
    var
        MailFolder: Record "IKA Mail Folder";
        Data: JsonObject;
        Items: JsonArray;
        Item: JsonObject;
        Result: Text;
    begin
        MailFolder.SetCurrentKey("Mailbox Code", "Sorting Order");
        MailFolder.SetRange("Mailbox Code", MailboxCode);
        if MailFolder.FindSet() then
            repeat
                Clear(Item);
                Item.Add('id', MailFolder."Folder Id");
                Item.Add('name', MailFolder."Display Name");
                Item.Add('path', MailFolder.Path);
                Item.Add('level', MailFolder.Level);
                Item.Add('unread', MailFolder."Unread Items");
                Item.Add('total', MailFolder."Total Items");
                Item.Add('children', MailFolder."Child Folder Count" > 0);
                Item.Add('wellKnown', MailFolder."Well-known Name");
                Items.Add(Item);
            until MailFolder.Next() = 0;
        Data.Add('selected', SelectedFolderId);
        Data.Add('items', Items);
        Data.WriteTo(Result);
        exit(Result);
    end;

    /// <summary>
    /// { folderId, title, selected, truncated, items: [...] } con los emails de la carpeta, del más reciente al más antiguo.
    /// </summary>
    procedure BuildMessagesJson(MailboxCode: Code[20]; FolderId: Text; DefaultFolderId: Text; SelectedEntryNo: Integer): Text
    var
        MailMessage: Record "IKA Mail Message";
        MailFolder: Record "IKA Mail Folder";
        Data: JsonObject;
        Items: JsonArray;
        Title: Text;
        Result: Text;
        MaxMessages: Integer;
        MessageCount: Integer;
    begin
        MaxMessages := 500;
        if MailFolder.Get(MailboxCode, CopyStr(FolderId, 1, MaxStrLen(MailFolder."Folder Id"))) then
            Title := MailFolder."Display Name";

        MailMessage.SetCurrentKey("Mailbox Code", "Received At");
        MailMessage.Ascending(false);
        SetFolderFilter(MailMessage, MailboxCode, FolderId, DefaultFolderId);
        MailMessage.SetAutoCalcFields("No. of Links");
        if MailMessage.FindSet() then
            repeat
                MessageCount += 1;
                if MessageCount <= MaxMessages then
                    Items.Add(BuildMessageItem(MailMessage));
            until (MailMessage.Next() = 0) or (MessageCount > MaxMessages);

        Data.Add('folderId', FolderId);
        Data.Add('title', Title);
        Data.Add('selected', SelectedEntryNo);
        Data.Add('truncated', MessageCount > MaxMessages);
        Data.Add('items', Items);
        Data.WriteTo(Result);
        exit(Result);
    end;

    /// <summary>
    /// Fila de la lista de emails (también se envía sola para actualizar el leído de un email).
    /// </summary>
    procedure BuildMessageItemJson(MailMessage: Record "IKA Mail Message"): Text
    var
        Result: Text;
    begin
        MailMessage.CalcFields("No. of Links");
        BuildMessageItem(MailMessage).WriteTo(Result);
        exit(Result);
    end;

    local procedure BuildMessageItem(MailMessage: Record "IKA Mail Message") Item: JsonObject
    begin
        Item.Add('id', MailMessage."Entry No.");
        Item.Add('from', GetSenderText(MailMessage));
        Item.Add('fromAddress', MailMessage."From Address");
        Item.Add('subject', MailMessage.Subject);
        Item.Add('preview', MailMessage."Body Preview");
        Item.Add('date', FormatShortDate(MailMessage."Received At"));
        Item.Add('dateFull', Format(MailMessage."Received At"));
        Item.Add('read', MailMessage."Is Read");
        Item.Add('attachments', MailMessage."Has Attachments");
        Item.Add('important', LowerCase(MailMessage.Importance) = 'high');
        Item.Add('linked', MailMessage."No. of Links" > 0);
    end;

    /// <summary>
    /// Cabecera y adjuntos del email para el panel de lectura (el cuerpo se envía aparte con BuildViewerHtml).
    /// </summary>
    procedure BuildMessageDetailJson(MailMessage: Record "IKA Mail Message"): Text
    var
        MailAttachment: Record "IKA Mail Attachment";
        Data: JsonObject;
        Attachments: JsonArray;
        Attachment: JsonObject;
        Result: Text;
    begin
        MailMessage.CalcFields("No. of Links", "Folder Name");
        Data.Add('id', MailMessage."Entry No.");
        Data.Add('from', GetSenderText(MailMessage));
        Data.Add('fromAddress', MailMessage."From Address");
        Data.Add('to', MailMessage."To Recipients");
        Data.Add('cc', MailMessage."Cc Recipients");
        Data.Add('subject', MailMessage.Subject);
        Data.Add('date', Format(MailMessage."Received At"));
        Data.Add('folder', MailMessage."Folder Name");
        Data.Add('read', MailMessage."Is Read");
        Data.Add('links', MailMessage."No. of Links");
        Data.Add('hasWebLink', MailMessage."Web Link" <> '');

        MailAttachment.SetRange("Message Entry No.", MailMessage."Entry No.");
        MailAttachment.SetRange("Is Inline", false);
        if MailAttachment.FindSet() then
            repeat
                Clear(Attachment);
                Attachment.Add('line', MailAttachment."Line No.");
                Attachment.Add('name', MailAttachment.GetFileName());
                Attachment.Add('size', MailAttachment.GetSizeText());
                Attachment.Add('reference', MailAttachment."Attachment Kind" = MailAttachment."Attachment Kind"::Reference);
                Attachments.Add(Attachment);
            until MailAttachment.Next() = 0;
        Data.Add('attachments', Attachments);
        Data.WriteTo(Result);
        exit(Result);
    end;

    local procedure GetSenderText(MailMessage: Record "IKA Mail Message"): Text
    begin
        if MailMessage."From Name" <> '' then
            exit(MailMessage."From Name");
        exit(MailMessage."From Address");
    end;

    /// <summary>
    /// Como Outlook: hora si es de hoy, día y mes si es de este año y la fecha completa si es anterior.
    /// </summary>
    local procedure FormatShortDate(ReceivedAt: DateTime): Text
    var
        ReceivedDate: Date;
    begin
        if ReceivedAt = 0DT then
            exit('');
        ReceivedDate := DT2Date(ReceivedAt);
        if ReceivedDate = Today() then
            exit(Format(DT2Time(ReceivedAt), 0, '<Hours24,2>:<Minutes,2>'));
        if Date2DMY(ReceivedDate, 3) = Date2DMY(Today(), 3) then
            exit(Format(ReceivedDate, 0, '<Day,2>/<Month,2>'));
        exit(Format(ReceivedDate, 0, '<Day,2>/<Month,2>/<Year4>'));
    end;

    // =====================================================================
    // Acciones sobre un email
    // =====================================================================

    /// <summary>
    /// Descarga (si hace falta) el cuerpo y los adjuntos y, si está configurado, lo marca como leído.
    /// </summary>
    procedure OpenMessage(EntryNo: Integer; var MailMessage: Record "IKA Mail Message")
    var
        Setup: Record "IKA Mail Setup";
        Mailbox: Record "IKA Mail Mailbox";
    begin
        MailMessage.Get(EntryNo);
        Mailbox.Get(MailMessage."Mailbox Code");
        Mailbox.CheckAccess();
        GraphClient.LoadMessageDetails(MailMessage, false);
        Setup.GetSetup();
        if Setup."Mark as Read on Open" and not MailMessage."Is Read" then
            GraphClient.SetReadFlag(MailMessage, true);
        MailMessage.Get(EntryNo);
    end;

    procedure GetViewerHtml(MailMessage: Record "IKA Mail Message"): Text
    begin
        exit(AttachMgt.BuildViewerHtml(MailMessage));
    end;

    procedure ToggleRead(EntryNo: Integer; var MailMessage: Record "IKA Mail Message")
    begin
        MailMessage.Get(EntryNo);
        CheckAccess(MailMessage);
        GraphClient.SetReadFlag(MailMessage, not MailMessage."Is Read");
    end;

    /// <summary>
    /// Pide la carpeta de destino y mueve el email en Outlook. Devuelve false si el usuario cancela.
    /// </summary>
    procedure MoveMessage(EntryNo: Integer): Boolean
    var
        MailMessage: Record "IKA Mail Message";
        MailFolder: Record "IKA Mail Folder";
        DestinationFolder: Record "IKA Mail Folder";
        SourceFolderId: Text;
    begin
        MailMessage.Get(EntryNo);
        CheckAccess(MailMessage);
        if not MailFolder.SelectFolder(MailMessage."Mailbox Code", '', DestinationFolder) then
            exit(false);
        MailMessage.Get(EntryNo);
        if MailMessage."Folder Id" = DestinationFolder."Folder Id" then
            exit(false);
        SourceFolderId := MailMessage."Folder Id";
        GraphClient.MoveMessage(MailMessage, DestinationFolder."Folder Id");
        GraphClient.UpdateFolderCounts(MailMessage."Mailbox Code", SourceFolderId);
        GraphClient.UpdateFolderCounts(MailMessage."Mailbox Code", DestinationFolder."Folder Id");
        exit(true);
    end;

    /// <summary>
    /// Elimina el email como Outlook: lo mueve a "Elementos eliminados" o, si ya está allí, lo borra
    /// definitivamente tras pedir confirmación. Devuelve false si el usuario cancela; Permanent indica
    /// si se ha borrado definitivamente.
    /// </summary>
    procedure DeleteMessage(EntryNo: Integer; var Permanent: Boolean): Boolean
    var
        MailMessage: Record "IKA Mail Message";
        SourceFolderId: Text;
        DeletedItemsFolderId: Text;
    begin
        MailMessage.Get(EntryNo);
        CheckAccess(MailMessage);
        SourceFolderId := MailMessage."Folder Id";
        DeletedItemsFolderId := GraphClient.GetDeletedItemsFolderId(MailMessage."Mailbox Code");
        Permanent := (DeletedItemsFolderId <> '') and (SourceFolderId = DeletedItemsFolderId);
        if Permanent then begin
            MailMessage.CalcFields("No. of Links");
            if MailMessage."No. of Links" > 0 then begin
                if not Confirm(DeleteLinkedForeverQst, false, MailMessage.Subject, MailMessage."No. of Links") then
                    exit(false);
            end else
                if not Confirm(DeleteForeverQst, false, MailMessage.Subject) then
                    exit(false);
        end;
        Permanent := GraphClient.DeleteMessage(MailMessage);
        // Contadores de no leídos de la carpeta de origen y de "Elementos eliminados"
        GraphClient.UpdateFolderCounts(MailMessage."Mailbox Code", SourceFolderId);
        if not Permanent then
            GraphClient.UpdateFolderCounts(MailMessage."Mailbox Code", MailMessage."Folder Id");
        exit(true);
    end;

    /// <summary>
    /// Responder ("reply"), responder a todos ("replyAll") o reenviar ("forward").
    /// </summary>
    procedure Compose(EntryNo: Integer; ModeText: Text)
    var
        MailMessage: Record "IKA Mail Message";
        MailCompose: Page "IKA Mail Compose";
        Mode: Enum "IKA Mail Compose Mode";
    begin
        MailMessage.Get(EntryNo);
        CheckAccess(MailMessage);
        case ModeText of
            'replyAll':
                Mode := Mode::ReplyAll;
            'forward':
                Mode := Mode::Forward;
            else
                Mode := Mode::Reply;
        end;
        MailCompose.SetMessage(MailMessage, Mode);
        MailCompose.RunModal();
    end;

    /// <summary>
    /// Abre la ficha del email, con el visor y el arrastre de adjuntos a entidades de BC.
    /// </summary>
    procedure OpenCard(EntryNo: Integer)
    var
        MailMessage: Record "IKA Mail Message";
    begin
        MailMessage.Get(EntryNo);
        CheckAccess(MailMessage);
        MailMessage.SetRange("Entry No.", EntryNo);
        Page.Run(Page::"IKA Mail Message", MailMessage);
    end;

    procedure OpenInOutlook(EntryNo: Integer)
    var
        MailMessage: Record "IKA Mail Message";
    begin
        MailMessage.Get(EntryNo);
        CheckAccess(MailMessage);
        if MailMessage."Web Link" = '' then
            Error(NoWebLinkErr);
        Hyperlink(MailMessage."Web Link");
    end;

    procedure DownloadAttachment(EntryNo: Integer; LineNo: Integer)
    var
        MailMessage: Record "IKA Mail Message";
        MailAttachment: Record "IKA Mail Attachment";
        InStr: InStream;
        FileName: Text;
    begin
        MailMessage.Get(EntryNo);
        CheckAccess(MailMessage);
        MailAttachment.Get(EntryNo, LineNo);
        if MailAttachment."Attachment Kind" = MailAttachment."Attachment Kind"::Reference then
            Error(ReferenceAttachmentErr, MailAttachment.Name);
        GraphClient.LoadAttachmentContent(MailAttachment);
        MailAttachment.CalcFields(Content);
        MailAttachment.Content.CreateInStream(InStr);
        FileName := MailAttachment.GetFileName();
        DownloadFromStream(InStr, '', '', '', FileName);
    end;

    procedure DownloadEml(EntryNo: Integer)
    var
        MailMessage: Record "IKA Mail Message";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        FileName: Text;
    begin
        MailMessage.Get(EntryNo);
        CheckAccess(MailMessage);
        GraphClient.GetMimeContent(MailMessage, TempBlob);
        TempBlob.CreateInStream(InStr);
        FileName := AttachMgt.GetEmailFileName(MailMessage);
        DownloadFromStream(InStr, '', '', '', FileName);
    end;

    local procedure CheckAccess(MailMessage: Record "IKA Mail Message")
    var
        Mailbox: Record "IKA Mail Mailbox";
    begin
        Mailbox.Get(MailMessage."Mailbox Code");
        Mailbox.CheckAccess();
    end;

    // =====================================================================
    // Preferencias del usuario
    // =====================================================================

    procedure SaveLocation(MailboxCode: Code[20]; FolderId: Text)
    var
        UserSetting: Record "IKA Mail User Setting";
    begin
        UserSetting.GetForCurrentUser();
        if (UserSetting."Last Mailbox Code" = MailboxCode) and (UserSetting."Last Folder Id" = FolderId) then
            exit;
        UserSetting."Last Mailbox Code" := MailboxCode;
        UserSetting."Last Folder Id" := CopyStr(FolderId, 1, MaxStrLen(UserSetting."Last Folder Id"));
        UserSetting.Modify();
    end;

    procedure SaveReadingPane(Visible: Boolean)
    var
        UserSetting: Record "IKA Mail User Setting";
    begin
        UserSetting.GetForCurrentUser();
        if UserSetting."Hide Reading Pane" = not Visible then
            exit;
        UserSetting."Hide Reading Pane" := not Visible;
        UserSetting.Modify();
    end;
}
