codeunit 99201 "IKA Mail Graph Client"
{
    // Acceso a Outlook 365 mediante Microsoft Graph v1.0 con autenticación de aplicación
    // (client credentials). Permisos de aplicación necesarios: Mail.ReadWrite y Mail.Send.
    // Recomendado: limitar la aplicación a los buzones dados de alta con RBAC for Applications
    // de Exchange Online (sin ello, el permiso de aplicación da acceso a todos los buzones del tenant).

    var
        Setup: Record "IKA Mail Setup";
        CurrentMailbox: Record "IKA Mail Mailbox";
        JsonHelper: Codeunit "IKA Mail Json Helper";
        UriHelper: Codeunit Uri;
        TokenCache: Dictionary of [Text, Text];
        GraphRootTok: Label 'https://graph.microsoft.com/v1.0', Locked = true;
        TokenUrlTok: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/token', Locked = true;
        MessageSelectTok: Label 'id,internetMessageId,conversationId,subject,from,toRecipients,ccRecipients,receivedDateTime,bodyPreview,isRead,hasAttachments,importance,webLink', Locked = true;
        TokenErr: Label 'No se pudo obtener el token de Microsoft Graph: %1', Comment = '%1 = error';
        GraphErr: Label 'Error de Microsoft Graph (%1): HTTP %2 %3', Comment = '%1 = method, %2 = status, %3 = body';
        FolderNotFoundErr: Label 'No se encuentra la carpeta "%1" en el buzón %2.', Comment = '%1 = folder, %2 = mailbox';
        NoMailboxErr: Label 'No se ha indicado la cuenta de correo.';
        NoCredentialsErr: Label 'La cuenta %1 usa credenciales propias pero no están completas.', Comment = '%1 = mailbox';
        ReferenceAttachmentErr: Label 'El adjunto "%1" es un enlace a OneDrive/SharePoint, no un fichero. Ábralo desde Outlook.', Comment = '%1 = name';
        AttachmentTooBigErr: Label 'El fichero %1 supera 3 MB, el máximo para adjuntar al responder desde BC.', Comment = '%1 = file name';
        NoRecipientsErr: Label 'Indique al menos un destinatario.';
        ConnectionOkLbl: Label 'Conexión correcta con %1: carpeta "%2", %3 emails (%4 sin leer).', Comment = '%1 = address, %2 = folder, %3 = total, %4 = unread';

    procedure SetMailbox(Mailbox: Record "IKA Mail Mailbox")
    begin
        Mailbox.CheckAccess();
        CurrentMailbox := Mailbox;
    end;

    // =====================================================================
    // Sincronización del listado
    // =====================================================================

    /// <summary>
    /// Descarga los últimos emails de la carpeta de la cuenta (o, con LoadOlder, los anteriores al
    /// más antiguo que ya hay) y los guarda/actualiza en la tabla local.
    /// </summary>
    procedure SyncMessages(var Mailbox: Record "IKA Mail Mailbox"; LoadOlder: Boolean): Integer
    var
        MailMessage: Record "IKA Mail Message";
        ResponseJson: JsonObject;
        MessageArray: JsonArray;
        MessageToken: JsonToken;
        Url: Text;
        SyncedCount: Integer;
    begin
        SetMailbox(Mailbox);
        Setup.GetSetup();
        Url := GetMailboxUrl() + '/mailFolders/' + GetFolderId(Mailbox.Folder) + '/messages' +
            '?$top=' + Format(Setup."Messages per Sync") +
            '&$select=' + MessageSelectTok +
            '&$orderby=receivedDateTime%20desc';
        if LoadOlder then begin
            MailMessage.SetCurrentKey("Mailbox Code", "Received At");
            MailMessage.SetRange("Mailbox Code", Mailbox.Code);
            if MailMessage.FindFirst() then
                Url += '&$filter=' + UriHelper.EscapeDataString('receivedDateTime lt ' + Format(MailMessage."Received At", 0, 9));
        end;

        ResponseJson := SendGraphRequest('GET', Url, '');
        if JsonHelper.GetArray(ResponseJson, 'value', MessageArray) then
            foreach MessageToken in MessageArray do begin
                UpsertMessage(Mailbox.Code, MessageToken.AsObject());
                SyncedCount += 1;
            end;

        Mailbox."Last Sync At" := CurrentDateTime();
        Mailbox.Modify();
        exit(SyncedCount);
    end;

    local procedure UpsertMessage(MailboxCode: Code[20]; MessageJson: JsonObject)
    var
        MailMessage: Record "IKA Mail Message";
        GraphId: Text;
        ReceivedAt: DateTime;
        IsNew: Boolean;
    begin
        GraphId := JsonHelper.GetText(MessageJson, 'id');
        MailMessage.SetCurrentKey("Mailbox Code", "Graph Id");
        MailMessage.SetRange("Mailbox Code", MailboxCode);
        MailMessage.SetRange("Graph Id", CopyStr(GraphId, 1, MaxStrLen(MailMessage."Graph Id")));
        IsNew := not MailMessage.FindFirst();
        if IsNew then begin
            MailMessage.Init();
            MailMessage."Mailbox Code" := MailboxCode;
            MailMessage."Graph Id" := CopyStr(GraphId, 1, MaxStrLen(MailMessage."Graph Id"));
        end;

        MailMessage."Internet Message Id" := CopyStr(JsonHelper.GetText(MessageJson, 'internetMessageId'), 1, MaxStrLen(MailMessage."Internet Message Id"));
        MailMessage."Conversation Id" := CopyStr(JsonHelper.GetText(MessageJson, 'conversationId'), 1, MaxStrLen(MailMessage."Conversation Id"));
        if Evaluate(ReceivedAt, JsonHelper.GetText(MessageJson, 'receivedDateTime'), 9) then
            MailMessage."Received At" := ReceivedAt;
        MailMessage."From Address" := CopyStr(JsonHelper.GetTextByPath(MessageJson, '$.from.emailAddress.address'), 1, MaxStrLen(MailMessage."From Address"));
        MailMessage."From Name" := CopyStr(JsonHelper.GetTextByPath(MessageJson, '$.from.emailAddress.name'), 1, MaxStrLen(MailMessage."From Name"));
        MailMessage."To Recipients" := CopyStr(RecipientsToText(MessageJson, 'toRecipients'), 1, MaxStrLen(MailMessage."To Recipients"));
        MailMessage."Cc Recipients" := CopyStr(RecipientsToText(MessageJson, 'ccRecipients'), 1, MaxStrLen(MailMessage."Cc Recipients"));
        MailMessage.Subject := CopyStr(JsonHelper.GetText(MessageJson, 'subject'), 1, MaxStrLen(MailMessage.Subject));
        MailMessage."Body Preview" := CopyStr(JsonHelper.GetText(MessageJson, 'bodyPreview'), 1, MaxStrLen(MailMessage."Body Preview"));
        MailMessage."Is Read" := JsonHelper.GetBoolean(MessageJson, 'isRead');
        MailMessage."Has Attachments" := JsonHelper.GetBoolean(MessageJson, 'hasAttachments');
        MailMessage.Importance := CopyStr(JsonHelper.GetText(MessageJson, 'importance'), 1, MaxStrLen(MailMessage.Importance));
        MailMessage."Web Link" := CopyStr(JsonHelper.GetText(MessageJson, 'webLink'), 1, MaxStrLen(MailMessage."Web Link"));
        if IsNew then
            MailMessage.Insert(true)
        else
            MailMessage.Modify(true);
    end;

    local procedure RecipientsToText(MessageJson: JsonObject; PropertyName: Text): Text
    var
        RecipientArray: JsonArray;
        RecipientToken: JsonToken;
        Name: Text;
        Address: Text;
        Result: Text;
    begin
        if not JsonHelper.GetArray(MessageJson, PropertyName, RecipientArray) then
            exit('');
        foreach RecipientToken in RecipientArray do begin
            Name := JsonHelper.GetTextByPath(RecipientToken.AsObject(), '$.emailAddress.name');
            Address := JsonHelper.GetTextByPath(RecipientToken.AsObject(), '$.emailAddress.address');
            if Result <> '' then
                Result += '; ';
            if (Name <> '') and (Name <> Address) then
                Result += Name + ' <' + Address + '>'
            else
                Result += Address;
        end;
        exit(Result);
    end;

    // =====================================================================
    // Detalle de un email
    // =====================================================================

    /// <summary>
    /// Descarga el cuerpo HTML y la lista de adjuntos. Las imágenes incrustadas pequeñas se descargan
    /// también para poder mostrarlas en el visor.
    /// </summary>
    procedure LoadMessageDetails(var MailMessage: Record "IKA Mail Message"; ForceReload: Boolean)
    var
        MailAttachment: Record "IKA Mail Attachment";
        ResponseJson: JsonObject;
        AttachmentArray: JsonArray;
        AttachmentToken: JsonToken;
        AttachmentJson: JsonObject;
        ODataType: Text;
        LineNo: Integer;
    begin
        if MailMessage."Details Loaded" and not ForceReload then
            exit;
        SetMailboxByCode(MailMessage."Mailbox Code");
        Setup.GetSetup();

        ResponseJson := SendGraphRequest('GET', GetMessageUrl(MailMessage) + '?$select=body,webLink,toRecipients,ccRecipients', '');
        MailMessage.SetBodyHtml(JsonHelper.GetTextByPath(ResponseJson, '$.body.content'));
        if JsonHelper.GetText(ResponseJson, 'webLink') <> '' then
            MailMessage."Web Link" := CopyStr(JsonHelper.GetText(ResponseJson, 'webLink'), 1, MaxStrLen(MailMessage."Web Link"));

        MailAttachment.SetRange("Message Entry No.", MailMessage."Entry No.");
        MailAttachment.DeleteAll();
        // Se consultan siempre: hasAttachments es false cuando solo hay imágenes incrustadas
        ResponseJson := SendGraphRequest('GET', GetMessageUrl(MailMessage) + '/attachments?$select=id,name,contentType,size,isInline', '');
        if JsonHelper.GetArray(ResponseJson, 'value', AttachmentArray) then
            foreach AttachmentToken in AttachmentArray do begin
                AttachmentJson := AttachmentToken.AsObject();
                LineNo += 10000;
                MailAttachment.Init();
                MailAttachment."Message Entry No." := MailMessage."Entry No.";
                MailAttachment."Line No." := LineNo;
                MailAttachment."Graph Attachment Id" := CopyStr(JsonHelper.GetText(AttachmentJson, 'id'), 1, MaxStrLen(MailAttachment."Graph Attachment Id"));
                MailAttachment.Name := CopyStr(JsonHelper.GetText(AttachmentJson, 'name'), 1, MaxStrLen(MailAttachment.Name));
                MailAttachment."Content Type" := CopyStr(JsonHelper.GetText(AttachmentJson, 'contentType'), 1, MaxStrLen(MailAttachment."Content Type"));
                MailAttachment."Size (Bytes)" := JsonHelper.GetInteger(AttachmentJson, 'size');
                MailAttachment."Is Inline" := JsonHelper.GetBoolean(AttachmentJson, 'isInline');
                ODataType := JsonHelper.GetText(AttachmentJson, '@odata.type');
                case ODataType of
                    '#microsoft.graph.itemAttachment':
                        MailAttachment."Attachment Kind" := MailAttachment."Attachment Kind"::Item;
                    '#microsoft.graph.referenceAttachment':
                        MailAttachment."Attachment Kind" := MailAttachment."Attachment Kind"::Reference;
                    else
                        MailAttachment."Attachment Kind" := MailAttachment."Attachment Kind"::File;
                end;
                MailAttachment.Insert();
                if MailAttachment."Is Inline" and Setup."Load Inline Images" and
                   (MailAttachment."Size (Bytes)" <= Setup."Max Inline Image (KB)" * 1024)
                then
                    LoadInlineAttachment(MailMessage, MailAttachment);
            end;

        MailMessage."Details Loaded" := true;
        MailMessage.Modify();
    end;

    local procedure LoadInlineAttachment(MailMessage: Record "IKA Mail Message"; var MailAttachment: Record "IKA Mail Attachment")
    var
        Base64Convert: Codeunit "Base64 Convert";
        ResponseJson: JsonObject;
        OutStr: OutStream;
    begin
        // La ruta individual devuelve contentId y contentBytes (propiedades de fileAttachment)
        ResponseJson := SendGraphRequest('GET', GetMessageUrl(MailMessage) + '/attachments/' + MailAttachment."Graph Attachment Id", '');
        MailAttachment."Content Id" := CopyStr(JsonHelper.GetText(ResponseJson, 'contentId'), 1, MaxStrLen(MailAttachment."Content Id"));
        MailAttachment.Content.CreateOutStream(OutStr);
        Base64Convert.FromBase64(JsonHelper.GetText(ResponseJson, 'contentBytes'), OutStr);
        MailAttachment."Content Loaded" := true;
        MailAttachment.Modify();
    end;

    /// <summary>
    /// Descarga (si hace falta) el contenido binario de un adjunto. Los emails adjuntos se obtienen en MIME (.eml).
    /// </summary>
    procedure LoadAttachmentContent(var MailAttachment: Record "IKA Mail Attachment")
    var
        MailMessage: Record "IKA Mail Message";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
    begin
        if MailAttachment."Content Loaded" then
            exit;
        if MailAttachment."Attachment Kind" = MailAttachment."Attachment Kind"::Reference then
            Error(ReferenceAttachmentErr, MailAttachment.Name);
        MailMessage.Get(MailAttachment."Message Entry No.");
        SetMailboxByCode(MailMessage."Mailbox Code");

        SendGraphRequestBinary(GetMessageUrl(MailMessage) + '/attachments/' + MailAttachment."Graph Attachment Id" + '/$value', TempBlob);
        TempBlob.CreateInStream(InStr);
        MailAttachment.Content.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
        MailAttachment."Content Loaded" := true;
        MailAttachment.Modify();
    end;

    /// <summary>
    /// Email completo en formato MIME (.eml): se abre con Outlook e incluye cuerpo y adjuntos.
    /// </summary>
    procedure GetMimeContent(MailMessage: Record "IKA Mail Message"; var TempBlob: Codeunit "Temp Blob")
    begin
        SetMailboxByCode(MailMessage."Mailbox Code");
        SendGraphRequestBinary(GetMessageUrl(MailMessage) + '/$value', TempBlob);
    end;

    procedure SetReadFlag(var MailMessage: Record "IKA Mail Message"; IsRead: Boolean)
    var
        Body: JsonObject;
        BodyText: Text;
    begin
        SetMailboxByCode(MailMessage."Mailbox Code");
        Body.Add('isRead', IsRead);
        Body.WriteTo(BodyText);
        SendGraphRequest('PATCH', GetMessageUrl(MailMessage), BodyText);
        MailMessage."Is Read" := IsRead;
        MailMessage.Modify();
    end;

    // =====================================================================
    // Responder / reenviar
    // =====================================================================

    /// <summary>
    /// Crea el borrador de respuesta/reenvío en Outlook (que incluye el email original citado),
    /// fija destinatarios, añade los ficheros y lo envía. El email enviado queda en "Elementos enviados".
    /// </summary>
    procedure SendCompose(MailMessage: Record "IKA Mail Message"; Mode: Enum "IKA Mail Compose Mode"; ToText: Text; CcText: Text; CommentText: Text; var TempComposeFile: Record "IKA Mail Compose File" temporary)
    var
        Body: JsonObject;
        DraftJson: JsonObject;
        PatchBody: JsonObject;
        ToArray: JsonArray;
        CcArray: JsonArray;
        BodyText: Text;
        DraftUrl: Text;
        GraphAction: Text;
    begin
        SetMailboxByCode(MailMessage."Mailbox Code");
        ToArray := TextToRecipients(ToText);
        CcArray := TextToRecipients(CcText);
        if ToArray.Count() = 0 then
            Error(NoRecipientsErr);

        case Mode of
            Mode::Reply:
                GraphAction := 'createReply';
            Mode::ReplyAll:
                GraphAction := 'createReplyAll';
            Mode::Forward:
                GraphAction := 'createForward';
        end;
        Body.Add('comment', TextToHtml(CommentText));
        Body.WriteTo(BodyText);
        DraftJson := SendGraphRequest('POST', GetMessageUrl(MailMessage) + '/' + GraphAction, BodyText);
        DraftUrl := GetMailboxUrl() + '/messages/' + JsonHelper.GetText(DraftJson, 'id');

        PatchBody.Add('toRecipients', ToArray);
        PatchBody.Add('ccRecipients', CcArray);
        PatchBody.WriteTo(BodyText);
        SendGraphRequest('PATCH', DraftUrl, BodyText);

        if TempComposeFile.FindSet() then
            repeat
                AddFileToDraft(DraftUrl, TempComposeFile);
            until TempComposeFile.Next() = 0;

        SendGraphRequest('POST', DraftUrl + '/send', '');
    end;

    local procedure AddFileToDraft(DraftUrl: Text; var TempComposeFile: Record "IKA Mail Compose File" temporary)
    var
        Base64Convert: Codeunit "Base64 Convert";
        Body: JsonObject;
        InStr: InStream;
        BodyText: Text;
    begin
        // Para ficheros mayores de 3 MB Graph exige una "upload session" (no implementada)
        if TempComposeFile."Size (Bytes)" > 3 * 1024 * 1024 then
            Error(AttachmentTooBigErr, TempComposeFile."File Name");
        TempComposeFile.CalcFields(Content);
        TempComposeFile.Content.CreateInStream(InStr);
        Body.Add('@odata.type', '#microsoft.graph.fileAttachment');
        Body.Add('name', TempComposeFile."File Name");
        Body.Add('contentType', TempComposeFile."Content Type");
        Body.Add('contentBytes', Base64Convert.ToBase64(InStr));
        Body.WriteTo(BodyText);
        SendGraphRequest('POST', DraftUrl + '/attachments', BodyText);
    end;

    /// <summary>
    /// "Nombre &lt;a@b.com&gt;; c@d.com" -> [{emailAddress:{address,name}}...]
    /// </summary>
    procedure TextToRecipients(RecipientsText: Text): JsonArray
    var
        Result: JsonArray;
        Recipient: JsonObject;
        EmailAddress: JsonObject;
        Part: Text;
        Address: Text;
        Name: Text;
    begin
        foreach Part in RecipientsText.Replace(',', ';').Split(';') do begin
            Part := DelChr(Part, '<>', ' ');
            if Part <> '' then begin
                Name := '';
                Address := Part;
                if (StrPos(Part, '<') > 0) and (StrPos(Part, '>') > StrPos(Part, '<')) then begin
                    Address := CopyStr(Part, StrPos(Part, '<') + 1, StrPos(Part, '>') - StrPos(Part, '<') - 1);
                    Name := DelChr(CopyStr(Part, 1, StrPos(Part, '<') - 1), '<>', ' "');
                end;
                Clear(Recipient);
                Clear(EmailAddress);
                EmailAddress.Add('address', DelChr(Address, '<>', ' '));
                if Name <> '' then
                    EmailAddress.Add('name', Name);
                Recipient.Add('emailAddress', EmailAddress);
                Result.Add(Recipient);
            end;
        end;
        exit(Result);
    end;

    local procedure TextToHtml(PlainText: Text): Text
    var
        Lf: Char;
        Cr: Char;
    begin
        Lf := 10;
        Cr := 13;
        PlainText := PlainText.Replace('&', '&amp;').Replace('<', '&lt;').Replace('>', '&gt;');
        PlainText := PlainText.Replace(Format(Cr), '').Replace(Format(Lf), '<br>');
        exit('<div style="font-family:Segoe UI,Arial,sans-serif;font-size:11pt">' + PlainText + '</div>');
    end;

    // =====================================================================
    // Prueba de conexión
    // =====================================================================

    procedure TestConnection(Mailbox: Record "IKA Mail Mailbox"): Text
    var
        ResponseJson: JsonObject;
    begin
        SetMailbox(Mailbox);
        ResponseJson := SendGraphRequest('GET', GetMailboxUrl() + '/mailFolders/' + GetFolderId(Mailbox.Folder) + '?$select=displayName,totalItemCount,unreadItemCount', '');
        exit(StrSubstNo(ConnectionOkLbl, Mailbox.Address,
            JsonHelper.GetText(ResponseJson, 'displayName'),
            JsonHelper.GetText(ResponseJson, 'totalItemCount'),
            JsonHelper.GetText(ResponseJson, 'unreadItemCount')));
    end;

    // =====================================================================
    // Utilidades
    // =====================================================================

    local procedure SetMailboxByCode(MailboxCode: Code[20])
    var
        Mailbox: Record "IKA Mail Mailbox";
    begin
        if CurrentMailbox.Code = MailboxCode then
            exit;
        Mailbox.Get(MailboxCode);
        SetMailbox(Mailbox);
    end;

    local procedure GetMailboxUrl(): Text
    begin
        if CurrentMailbox.Address = '' then
            Error(NoMailboxErr);
        exit(GraphRootTok + '/users/' + UriHelper.EscapeDataString(CurrentMailbox.Address));
    end;

    local procedure GetMessageUrl(MailMessage: Record "IKA Mail Message"): Text
    begin
        exit(GetMailboxUrl() + '/messages/' + MailMessage."Graph Id");
    end;

    local procedure GetFolderId(FolderName: Text): Text
    var
        ResponseJson: JsonObject;
        FolderArray: JsonArray;
        FolderToken: JsonToken;
        NameFilter: Text;
    begin
        case LowerCase(FolderName) of
            '', 'inbox', 'bandeja de entrada':
                exit('inbox');
            'sentitems', 'enviados', 'elementos enviados':
                exit('sentitems');
            'archive', 'archivo':
                exit('archive');
            'drafts', 'borradores':
                exit('drafts');
            'deleteditems', 'elementos eliminados':
                exit('deleteditems');
            'junkemail', 'correo no deseado':
                exit('junkemail');
        end;
        if (StrLen(FolderName) > 60) and (StrPos(FolderName, ' ') = 0) then
            exit(FolderName);

        NameFilter := UriHelper.EscapeDataString('displayName eq ''' + FolderName.Replace('''', '''''') + '''');
        ResponseJson := SendGraphRequest('GET', GetMailboxUrl() + '/mailFolders/inbox/childFolders?$filter=' + NameFilter + '&$select=id', '');
        if JsonHelper.GetArray(ResponseJson, 'value', FolderArray) then
            foreach FolderToken in FolderArray do
                exit(JsonHelper.GetText(FolderToken.AsObject(), 'id'));
        ResponseJson := SendGraphRequest('GET', GetMailboxUrl() + '/mailFolders?$filter=' + NameFilter + '&$select=id', '');
        if JsonHelper.GetArray(ResponseJson, 'value', FolderArray) then
            foreach FolderToken in FolderArray do
                exit(JsonHelper.GetText(FolderToken.AsObject(), 'id'));
        Error(FolderNotFoundErr, FolderName, CurrentMailbox.Address);
    end;

    local procedure SendGraphRequest(Method: Text; Url: Text; BodyText: Text) ResponseJson: JsonObject
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        ResponseText: Text;
    begin
        Request.Method(Method);
        Request.SetRequestUri(Url);
        Request.GetHeaders(RequestHeaders);
        AddBearerHeader(RequestHeaders);
        RequestHeaders.Add('Prefer', 'outlook.body-content-type="html"');

        // POST sin cuerpo (p.ej. /send) también necesita Content-Type
        if (BodyText <> '') or (Method = 'POST') then begin
            Content.WriteFrom(BodyText);
            Content.GetHeaders(ContentHeaders);
            if ContentHeaders.Contains('Content-Type') then
                ContentHeaders.Remove('Content-Type');
            ContentHeaders.Add('Content-Type', 'application/json');
            Request.Content := Content;
        end;

        Client.Timeout := 120000;
        if not Client.Send(Request, Response) then
            Error(GraphErr, Method, 0, GetLastErrorText());
        Response.Content.ReadAs(ResponseText);
        if not Response.IsSuccessStatusCode() then
            Error(GraphErr, Method, Response.HttpStatusCode(), CopyStr(ResponseText, 1, 1000));
        if ResponseText <> '' then
            if ResponseJson.ReadFrom(ResponseText) then;
    end;

    local procedure SendGraphRequestBinary(Url: Text; var TempBlob: Codeunit "Temp Blob")
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        InStr: InStream;
        OutStr: OutStream;
        ErrorText: Text;
    begin
        Request.Method('GET');
        Request.SetRequestUri(Url);
        Request.GetHeaders(RequestHeaders);
        AddBearerHeader(RequestHeaders);
        Client.Timeout := 300000;
        if not Client.Send(Request, Response) then
            Error(GraphErr, 'GET', 0, GetLastErrorText());
        if not Response.IsSuccessStatusCode() then begin
            Response.Content.ReadAs(ErrorText);
            Error(GraphErr, 'GET', Response.HttpStatusCode(), CopyStr(ErrorText, 1, 1000));
        end;
        Response.Content.ReadAs(InStr);
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
    end;

    [NonDebuggable]
    local procedure AddBearerHeader(var RequestHeaders: HttpHeaders)
    begin
        RequestHeaders.Add('Authorization', 'Bearer ' + GetAccessToken());
    end;

    /// <summary>
    /// Token de aplicación con las credenciales de la cuenta (si tiene propias) o las generales.
    /// Se guarda en memoria durante la sesión de la codeunit.
    /// </summary>
    [NonDebuggable]
    local procedure GetAccessToken(): Text
    var
        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Response: HttpResponseMessage;
        ResponseJson: JsonObject;
        TenantId: Text;
        ClientId: Text;
        ClientSecret: Text;
        CacheKey: Text;
        Token: Text;
        ResponseText: Text;
        BodyText: Text;
    begin
        if CurrentMailbox."Use Own Credentials" then begin
            TenantId := CurrentMailbox."Tenant Id";
            ClientId := CurrentMailbox."Client Id";
            ClientSecret := CurrentMailbox.GetClientSecret();
            if (TenantId = '') or (ClientId = '') or (ClientSecret = '') then
                Error(NoCredentialsErr, CurrentMailbox.Code);
        end else begin
            Setup.TestSetupForGraph();
            TenantId := Setup."Graph Tenant Id";
            ClientId := Setup."Graph Client Id";
            ClientSecret := Setup.GetGraphClientSecret();
        end;

        CacheKey := TenantId + '|' + ClientId;
        if TokenCache.Get(CacheKey, Token) then
            exit(Token);

        BodyText := 'grant_type=client_credentials' +
            '&client_id=' + UriHelper.EscapeDataString(ClientId) +
            '&client_secret=' + UriHelper.EscapeDataString(ClientSecret) +
            '&scope=' + UriHelper.EscapeDataString('https://graph.microsoft.com/.default');
        Content.WriteFrom(BodyText);
        Content.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/x-www-form-urlencoded');

        if not Client.Post(StrSubstNo(TokenUrlTok, TenantId), Content, Response) then
            Error(TokenErr, GetLastErrorText());
        Response.Content.ReadAs(ResponseText);
        if not Response.IsSuccessStatusCode() then
            Error(TokenErr, CopyStr(ResponseText, 1, 1000));
        ResponseJson.ReadFrom(ResponseText);
        Token := JsonHelper.GetText(ResponseJson, 'access_token');
        TokenCache.Set(CacheKey, Token);
        exit(Token);
    end;
}
