codeunit 99006 "IKA Graph Mail Client"
{
    // Lectura del buzón de Outlook / Exchange Online mediante Microsoft Graph (v1.0),
    // con autenticación de aplicación (client credentials) de un registro de aplicación en Entra ID.
    // Permiso de aplicación necesario: Mail.ReadWrite (con consentimiento de administrador).
    // Recomendado: limitar el acceso de la app SOLO al buzón de pedidos con una
    // Application Access Policy / RBAC for Applications de Exchange Online.

    trigger OnRun()
    begin
        LastImportedCount := ImportNewMessages();
    end;

    var
        Setup: Record "IKA Sales Agent Setup";
        MailAccount: Record "IKA Sales Mail Account";
        JsonHelper: Codeunit "IKA Sales Agent Json Helper";
        LogMgt: Codeunit "IKA Sales Agent Log Mgt.";
        UriHelper: Codeunit Uri;
        AccessToken: Text;
        LastImportedCount: Integer;
        GraphBaseUrlTok: Label 'https://graph.microsoft.com/v1.0/users/', Locked = true;
        TokenUrlTok: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/token', Locked = true;
        TokenErr: Label 'No se pudo obtener el token de Microsoft Graph: %1', Comment = '%1 = error';
        GraphErr: Label 'Error de Microsoft Graph (%1 %2): HTTP %3 %4', Comment = '%1 = method, %2 = url, %3 = status, %4 = body';
        FolderNotFoundErr: Label 'No se encuentra la carpeta "%1" en el buzón %2.', Comment = '%1 = folder, %2 = mailbox';
        ImportedLbl: Label 'Importado email "%1" de %2.', Comment = '%1 = subject, %2 = sender';

    /// <summary>
    /// Lee los emails de la carpeta origen que cumplen algún filtro activo y crea una solicitud
    /// por email (con su cuerpo y adjuntos). Devuelve el nº de solicitudes creadas.
    /// Los emails que no cumplen ningún filtro no se tocan.
    /// </summary>
    procedure ImportNewMessages(): Integer
    var
        MessagesJson: JsonObject;
        MessageArray: JsonArray;
        MessageToken: JsonToken;
        FolderId: Text;
        Url: Text;
        Filter: Text;
        ImportedCount: Integer;
        PageCount: Integer;
    begin
        Setup.TestSetupForGraph();
        LoadMailAccount();
        FolderId := GetFolderId(MailAccount.Folder);

        Filter := 'receivedDateTime ge 2000-01-01T00:00:00Z';
        if Setup."Only Unread" then
            Filter += ' and isRead eq false';

        // Graph exige que la propiedad de $orderby aparezca también la primera en $filter.
        Url := GetMailboxUrl() + '/mailFolders/' + FolderId + '/messages' +
            '?$top=50' +
            '&$orderby=receivedDateTime%20asc' +
            '&$filter=' + UriHelper.EscapeDataString(Filter) +
            '&$select=id,internetMessageId,subject,from,receivedDateTime,body,hasAttachments,isRead';

        // Se pagina porque los emails que no cumplen ningún filtro siguen sin leer y ocupan sitio.
        while (Url <> '') and (ImportedCount < Setup."Max Emails per Run") and (PageCount < 20) do begin
            PageCount += 1;
            MessagesJson := SendGraphRequest('GET', Url, '', 0);
            Url := JsonHelper.GetText(MessagesJson, '@odata.nextLink');
            if JsonHelper.GetArray(MessagesJson, 'value', MessageArray) then
                foreach MessageToken in MessageArray do
                    if ImportedCount < Setup."Max Emails per Run" then
                        if ImportMessage(MessageToken.AsObject()) then begin
                            ImportedCount += 1;
                            Commit();
                        end;
        end;

        exit(ImportedCount);
    end;

    procedure GetLastImportedCount(): Integer
    begin
        exit(LastImportedCount);
    end;

    local procedure ImportMessage(MessageJson: JsonObject): Boolean
    var
        RequestHeader: Record "IKA Sales Request Header";
        MailFilter: Record "IKA Sales Agent Mail Filter";
        GraphMessageId: Text;
        InternetMessageId: Text;
        SenderAddress: Text;
        SenderName: Text;
        Subject: Text;
        BodyText: Text;
        ReceivedAt: DateTime;
    begin
        GraphMessageId := JsonHelper.GetText(MessageJson, 'id');
        InternetMessageId := JsonHelper.GetText(MessageJson, 'internetMessageId');
        SenderAddress := JsonHelper.GetTextByPath(MessageJson, '$.from.emailAddress.address');
        SenderName := JsonHelper.GetTextByPath(MessageJson, '$.from.emailAddress.name');
        Subject := JsonHelper.GetText(MessageJson, 'subject');
        BodyText := JsonHelper.GetTextByPath(MessageJson, '$.body.content');

        // Duplicados: el Internet Message-ID no cambia aunque el email se mueva de carpeta.
        if InternetMessageId <> '' then begin
            RequestHeader.SetRange("Internet Message Id", CopyStr(InternetMessageId, 1, MaxStrLen(RequestHeader."Internet Message Id")));
            if not RequestHeader.IsEmpty() then
                exit(false);
            RequestHeader.Reset();
        end;

        if not MailFilter.FindMatchingFilter("IKA Mail Filter Type"::"Sales Order", SenderAddress, Subject, BodyText) then
            exit(false);

        if Evaluate(ReceivedAt, JsonHelper.GetText(MessageJson, 'receivedDateTime'), 9) then;

        RequestHeader.Init();
        RequestHeader.Source := RequestHeader.Source::Email;
        RequestHeader.Status := RequestHeader.Status::New;
        RequestHeader."Graph Message Id" := CopyStr(GraphMessageId, 1, MaxStrLen(RequestHeader."Graph Message Id"));
        RequestHeader."Internet Message Id" := CopyStr(InternetMessageId, 1, MaxStrLen(RequestHeader."Internet Message Id"));
        RequestHeader."Sender Address" := CopyStr(SenderAddress, 1, MaxStrLen(RequestHeader."Sender Address"));
        RequestHeader."Sender Name" := CopyStr(SenderName, 1, MaxStrLen(RequestHeader."Sender Name"));
        RequestHeader.Subject := CopyStr(Subject, 1, MaxStrLen(RequestHeader.Subject));
        RequestHeader."Received At" := ReceivedAt;
        RequestHeader."Mail Filter Line No." := MailFilter."Line No.";
        RequestHeader.SetBodyText(BodyText);
        RequestHeader.Insert(true);

        if JsonHelper.GetBoolean(MessageJson, 'hasAttachments') then
            ImportAttachments(RequestHeader, GraphMessageId);

        if Setup."Mark as Read" then
            MarkAsRead(GraphMessageId, RequestHeader."Entry No.");

        LogMgt.LogInfo(RequestHeader."Entry No.", StrSubstNo(ImportedLbl, Subject, SenderAddress));
        exit(true);
    end;

    local procedure ImportAttachments(RequestHeader: Record "IKA Sales Request Header"; GraphMessageId: Text)
    var
        RequestAttachment: Record "IKA Sales Request Attachment";
        Base64Convert: Codeunit "Base64 Convert";
        AttachmentsJson: JsonObject;
        AttachmentArray: JsonArray;
        AttachmentToken: JsonToken;
        AttachmentJson: JsonObject;
        OutStr: OutStream;
        LineNo: Integer;
    begin
        AttachmentsJson := SendGraphRequest('GET', GetMailboxUrl() + '/messages/' + GraphMessageId + '/attachments', '', RequestHeader."Entry No.");
        if not JsonHelper.GetArray(AttachmentsJson, 'value', AttachmentArray) then
            exit;

        LineNo := 0;
        foreach AttachmentToken in AttachmentArray do begin
            AttachmentJson := AttachmentToken.AsObject();
            // Solo ficheros (no emails adjuntos ni referencias a OneDrive)
            if JsonHelper.GetText(AttachmentJson, '@odata.type') = '#microsoft.graph.fileAttachment' then begin
                LineNo += 10000;
                RequestAttachment.Init();
                RequestAttachment."Request Entry No." := RequestHeader."Entry No.";
                RequestAttachment."Line No." := LineNo;
                RequestAttachment."Graph Attachment Id" := CopyStr(JsonHelper.GetText(AttachmentJson, 'id'), 1, MaxStrLen(RequestAttachment."Graph Attachment Id"));
                RequestAttachment."File Name" := CopyStr(JsonHelper.GetText(AttachmentJson, 'name'), 1, MaxStrLen(RequestAttachment."File Name"));
                RequestAttachment."Content Type" := CopyStr(JsonHelper.GetText(AttachmentJson, 'contentType'), 1, MaxStrLen(RequestAttachment."Content Type"));
                RequestAttachment."Size (Bytes)" := JsonHelper.GetInteger(AttachmentJson, 'size');
                RequestAttachment."Is Inline" := JsonHelper.GetBoolean(AttachmentJson, 'isInline');
                RequestAttachment.Content.CreateOutStream(OutStr);
                Base64Convert.FromBase64(JsonHelper.GetText(AttachmentJson, 'contentBytes'), OutStr);
                RequestAttachment.Insert(true);
            end;
        end;
    end;

    procedure MarkAsRead(GraphMessageId: Text; RequestEntryNo: Integer)
    var
        Body: JsonObject;
        BodyText: Text;
    begin
        Body.Add('isRead', true);
        Body.WriteTo(BodyText);
        SendGraphRequest('PATCH', GetMailboxUrl() + '/messages/' + GraphMessageId, BodyText, RequestEntryNo);
    end;

    /// <summary>
    /// Mueve el email de la solicitud a la carpeta indicada (procesados / errores).
    /// Graph asigna un id nuevo al mensaje movido; se guarda en la solicitud.
    /// </summary>
    procedure MoveRequestMessage(var RequestHeader: Record "IKA Sales Request Header"; FolderName: Text)
    var
        Body: JsonObject;
        ResponseJson: JsonObject;
        BodyText: Text;
        NewId: Text;
    begin
        if (FolderName = '') or (RequestHeader."Graph Message Id" = '') or RequestHeader."Moved in Mailbox" then
            exit;
        Setup.TestSetupForGraph();

        Body.Add('destinationId', GetFolderId(FolderName));
        Body.WriteTo(BodyText);
        ResponseJson := SendGraphRequest('POST', GetMailboxUrl() + '/messages/' + RequestHeader."Graph Message Id" + '/move', BodyText, RequestHeader."Entry No.");

        NewId := JsonHelper.GetText(ResponseJson, 'id');
        if NewId <> '' then
            RequestHeader."Graph Message Id" := CopyStr(NewId, 1, MaxStrLen(RequestHeader."Graph Message Id"));
        RequestHeader."Moved in Mailbox" := true;
        RequestHeader.Modify();
    end;

    procedure TestConnection(): Text
    begin
        Setup.TestSetupForGraph();
        LoadMailAccount();
        exit(TestAccount(MailAccount));
    end;

    /// <summary>
    /// Prueba una cuenta concreta (desde la página "Cuentas de Outlook 365").
    /// </summary>
    procedure TestAccount(Account: Record "IKA Sales Mail Account"): Text
    var
        ResponseJson: JsonObject;
    begin
        Setup.GetSetup();
        MailAccount := Account;
        MailAccount.TestField(Address);
        AccessToken := '';
        ResponseJson := SendGraphRequest('GET', GetMailboxUrl() + '/mailFolders/' + GetFolderId(MailAccount.Folder) + '?$select=displayName,totalItemCount,unreadItemCount', '', 0);
        exit(StrSubstNo('%1 - %2: %3 emails (%4 sin leer)',
            MailAccount.Address,
            JsonHelper.GetText(ResponseJson, 'displayName'),
            JsonHelper.GetText(ResponseJson, 'totalItemCount'),
            JsonHelper.GetText(ResponseJson, 'unreadItemCount')));
    end;

    local procedure LoadMailAccount()
    begin
        if MailAccount.Code <> '' then
            exit;
        Setup.TestSetupForGraph();
        MailAccount.Get(Setup."Mail Account Code");
        MailAccount.TestField(Address);
        MailAccount.TestField(Enabled);
    end;

    /// <summary>
    /// Acepta nombres conocidos (inbox, archive, deleteditems...), un id de carpeta o el nombre
    /// visible de una carpeta de primer nivel o de una subcarpeta de la bandeja de entrada.
    /// </summary>
    local procedure GetFolderId(FolderName: Text): Text
    var
        ResponseJson: JsonObject;
        FolderArray: JsonArray;
        FolderToken: JsonToken;
        NameFilter: Text;
    begin
        case LowerCase(FolderName) of
            'inbox', 'bandeja de entrada':
                exit('inbox');
            'archive', 'archivo':
                exit('archive');
            'deleteditems', 'elementos eliminados':
                exit('deleteditems');
            'junkemail', 'correo no deseado':
                exit('junkemail');
        end;
        // Un id de Graph es largo y sin espacios
        if (StrLen(FolderName) > 60) and (StrPos(FolderName, ' ') = 0) then
            exit(FolderName);

        NameFilter := UriHelper.EscapeDataString('displayName eq ''' + FolderName.Replace('''', '''''') + '''');
        ResponseJson := SendGraphRequest('GET', GetMailboxUrl() + '/mailFolders/inbox/childFolders?$filter=' + NameFilter + '&$select=id,displayName', '', 0);
        if JsonHelper.GetArray(ResponseJson, 'value', FolderArray) then
            foreach FolderToken in FolderArray do
                exit(JsonHelper.GetText(FolderToken.AsObject(), 'id'));

        ResponseJson := SendGraphRequest('GET', GetMailboxUrl() + '/mailFolders?$filter=' + NameFilter + '&$select=id,displayName', '', 0);
        if JsonHelper.GetArray(ResponseJson, 'value', FolderArray) then
            foreach FolderToken in FolderArray do
                exit(JsonHelper.GetText(FolderToken.AsObject(), 'id'));

        Error(FolderNotFoundErr, FolderName, MailAccount.Address);
    end;

    local procedure GetMailboxUrl(): Text
    begin
        LoadMailAccount();
        exit(GraphBaseUrlTok + UriHelper.EscapeDataString(MailAccount.Address));
    end;

    local procedure SendGraphRequest(Method: Text; Url: Text; BodyText: Text; RequestEntryNo: Integer) ResponseJson: JsonObject
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
        // Cuerpo del email en texto plano en lugar de HTML
        RequestHeaders.Add('Prefer', 'outlook.body-content-type="text"');

        if BodyText <> '' then begin
            Content.WriteFrom(BodyText);
            Content.GetHeaders(ContentHeaders);
            if ContentHeaders.Contains('Content-Type') then
                ContentHeaders.Remove('Content-Type');
            ContentHeaders.Add('Content-Type', 'application/json');
            Request.Content := Content;
        end;

        Client.Timeout := 120000;
        if not Client.Send(Request, Response) then
            Error(GraphErr, Method, Url, 0, GetLastErrorText());

        Response.Content.ReadAs(ResponseText);
        if not Response.IsSuccessStatusCode() then begin
            LogMgt.LogGraphCall(RequestEntryNo, Method + ' ' + Url, Response.HttpStatusCode(), ResponseText);
            Commit();
            Error(GraphErr, Method, Url, Response.HttpStatusCode(), CopyStr(ResponseText, 1, 1000));
        end;
        if ResponseText <> '' then
            if ResponseJson.ReadFrom(ResponseText) then;
    end;

    [NonDebuggable]
    local procedure AddBearerHeader(var RequestHeaders: HttpHeaders)
    begin
        if AccessToken = '' then
            AccessToken := GetAccessToken();
        RequestHeaders.Add('Authorization', 'Bearer ' + AccessToken);
    end;

    [NonDebuggable]
    local procedure GetAccessToken(): Text
    var
        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Response: HttpResponseMessage;
        ResponseJson: JsonObject;
        ResponseText: Text;
        BodyText: Text;
        TenantId: Text;
        ClientId: Text;
        ClientSecret: Text;
    begin
        // Credenciales propias de la cuenta (otro tenant) o las generales de la configuración
        LoadMailAccount();
        if MailAccount."Use Own Credentials" then begin
            MailAccount.TestField("Tenant Id");
            MailAccount.TestField("Client Id");
            TenantId := MailAccount."Tenant Id";
            ClientId := MailAccount."Client Id";
            ClientSecret := MailAccount.GetClientSecret();
        end else begin
            Setup.TestGeneralCredentials();
            TenantId := Setup."Graph Tenant Id";
            ClientId := Setup."Graph Client Id";
            ClientSecret := Setup.GetGraphClientSecret();
        end;

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
        exit(JsonHelper.GetText(ResponseJson, 'access_token'));
    end;
}
