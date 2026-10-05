codeunit 50210 "IKA DN Graph Client"
{
    // Origen de los albaranes mediante Microsoft Graph (v1.0), con autenticación de aplicación
    // (client credentials) de un registro de aplicación en Entra ID:
    //  - Buzón de Outlook: permiso de aplicación Mail.ReadWrite.
    //  - Carpeta de SharePoint / OneDrive: permiso Sites.Selected (recomendado, concediendo
    //    acceso solo al sitio de compras) o Files.ReadWrite.All.
    // BC en la nube no puede leer carpetas de red locales: la carpeta "de ficheros" se sincroniza
    // con una biblioteca de SharePoint/OneDrive y se lee desde ahí.

    trigger OnRun()
    begin
        LastImportedCount := 0;
        Setup.GetSetup();
        if Setup."Mail Enabled" then
            LastImportedCount += ImportNewMessages();
        if Setup."Folder Enabled" then
            LastImportedCount += ImportNewFiles();
    end;

    var
        Setup: Record "IKA DN Setup";
        MailAccount: Record "IKA DN Mail Account";
        JsonHelper: Codeunit "IKA DN Json Helper";
        LogMgt: Codeunit "IKA DN Log Mgt.";
        UriHelper: Codeunit Uri;
        MailAccessToken: Text;
        GeneralAccessToken: Text;
        DriveId: Text;
        LastImportedCount: Integer;
        GraphRootTok: Label 'https://graph.microsoft.com/v1.0', Locked = true;
        TokenUrlTok: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/token', Locked = true;
        TokenErr: Label 'No se pudo obtener el token de Microsoft Graph: %1', Comment = '%1 = error';
        GraphErr: Label 'Error de Microsoft Graph (%1 %2): HTTP %3 %4', Comment = '%1 = method, %2 = url, %3 = status, %4 = body';
        DownloadErr: Label 'No se pudo descargar el fichero %1: HTTP %2', Comment = '%1 = file name, %2 = status';
        MailFolderNotFoundErr: Label 'No se encuentra la carpeta "%1" en el buzón %2.', Comment = '%1 = folder, %2 = mailbox';
        DriveNotConfiguredErr: Label 'Indique el Drive Id o el Sitio SharePoint en la configuración.';
        ImportedMailLbl: Label 'Importado email "%1" de %2.', Comment = '%1 = subject, %2 = sender';
        ImportedFileLbl: Label 'Importado fichero "%1" de la carpeta %2.', Comment = '%1 = file, %2 = folder';
        TooBigLbl: Label 'Fichero %1 ignorado: supera el tamaño máximo (%2 KB).', Comment = '%1 = file, %2 = KB';

    procedure GetLastImportedCount(): Integer
    begin
        exit(LastImportedCount);
    end;

    // =====================================================================
    // Correo
    // =====================================================================

    /// <summary>
    /// Importa los emails que corresponden a una plantilla de proveedor (por remitente/asunto)
    /// o, si se permite, los de remitentes desconocidos cuyo asunto cumple el filtro genérico.
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
        FolderId := GetMailFolderId(MailAccount.Folder);

        Filter := 'receivedDateTime ge 2000-01-01T00:00:00Z';
        if Setup."Only Unread" then
            Filter += ' and isRead eq false';

        Url := GetMailboxUrl() + '/mailFolders/' + FolderId + '/messages' +
            '?$top=50' +
            '&$orderby=receivedDateTime%20asc' +
            '&$filter=' + UriHelper.EscapeDataString(Filter) +
            '&$select=id,internetMessageId,subject,from,receivedDateTime,body,hasAttachments,isRead';

        while (Url <> '') and (ImportedCount < Setup."Max Documents per Run") and (PageCount < 20) do begin
            PageCount += 1;
            MessagesJson := SendGraphRequest('GET', Url, '', 0);
            Url := JsonHelper.GetText(MessagesJson, '@odata.nextLink');
            if JsonHelper.GetArray(MessagesJson, 'value', MessageArray) then
                foreach MessageToken in MessageArray do
                    if ImportedCount < Setup."Max Documents per Run" then
                        if ImportMessage(MessageToken.AsObject()) then begin
                            ImportedCount += 1;
                            Commit();
                        end;
        end;
        exit(ImportedCount);
    end;

    local procedure ImportMessage(MessageJson: JsonObject): Boolean
    var
        DNDocument: Record "IKA DN Document";
        VendorTemplate: Record "IKA DN Vendor Template";
        GraphMessageId: Text;
        InternetMessageId: Text;
        SenderAddress: Text;
        Subject: Text;
        ReceivedAt: DateTime;
        TemplateFound: Boolean;
    begin
        GraphMessageId := JsonHelper.GetText(MessageJson, 'id');
        InternetMessageId := JsonHelper.GetText(MessageJson, 'internetMessageId');
        SenderAddress := JsonHelper.GetTextByPath(MessageJson, '$.from.emailAddress.address');
        Subject := JsonHelper.GetText(MessageJson, 'subject');

        if InternetMessageId <> '' then begin
            DNDocument.SetRange("Internet Message Id", CopyStr(InternetMessageId, 1, MaxStrLen(DNDocument."Internet Message Id")));
            if not DNDocument.IsEmpty() then
                exit(false);
            DNDocument.Reset();
        end;

        TemplateFound := VendorTemplate.FindByEmail(SenderAddress, Subject);
        if not TemplateFound then
            if not (Setup."Accept Unknown Senders" and VendorTemplate.MatchesPattern(Subject, Setup."Generic Subject Filter")) then
                exit(false);

        if Evaluate(ReceivedAt, JsonHelper.GetText(MessageJson, 'receivedDateTime'), 9) then;

        DNDocument.Init();
        DNDocument.Source := DNDocument.Source::Email;
        DNDocument.Status := DNDocument.Status::New;
        DNDocument."Graph Message Id" := CopyStr(GraphMessageId, 1, MaxStrLen(DNDocument."Graph Message Id"));
        DNDocument."Internet Message Id" := CopyStr(InternetMessageId, 1, MaxStrLen(DNDocument."Internet Message Id"));
        DNDocument."Sender Address" := CopyStr(SenderAddress, 1, MaxStrLen(DNDocument."Sender Address"));
        DNDocument."Sender Name" := CopyStr(JsonHelper.GetTextByPath(MessageJson, '$.from.emailAddress.name'), 1, MaxStrLen(DNDocument."Sender Name"));
        DNDocument.Subject := CopyStr(Subject, 1, MaxStrLen(DNDocument.Subject));
        DNDocument."Received At" := ReceivedAt;
        if TemplateFound then
            DNDocument."Template Vendor No." := VendorTemplate."Vendor No.";
        DNDocument.SetBodyText(JsonHelper.GetTextByPath(MessageJson, '$.body.content'));
        DNDocument.Insert(true);

        if JsonHelper.GetBoolean(MessageJson, 'hasAttachments') then
            ImportAttachments(DNDocument, GraphMessageId);

        if Setup."Mark as Read" then
            MarkAsRead(GraphMessageId, DNDocument."Entry No.");

        LogMgt.LogInfo(DNDocument."Entry No.", StrSubstNo(ImportedMailLbl, Subject, SenderAddress));
        exit(true);
    end;

    local procedure ImportAttachments(DNDocument: Record "IKA DN Document"; GraphMessageId: Text)
    var
        DNFile: Record "IKA DN File";
        Base64Convert: Codeunit "Base64 Convert";
        AttachmentsJson: JsonObject;
        AttachmentArray: JsonArray;
        AttachmentToken: JsonToken;
        AttachmentJson: JsonObject;
        OutStr: OutStream;
        LineNo: Integer;
    begin
        AttachmentsJson := SendGraphRequest('GET', GetMailboxUrl() + '/messages/' + GraphMessageId + '/attachments', '', DNDocument."Entry No.");
        if not JsonHelper.GetArray(AttachmentsJson, 'value', AttachmentArray) then
            exit;

        foreach AttachmentToken in AttachmentArray do begin
            AttachmentJson := AttachmentToken.AsObject();
            if JsonHelper.GetText(AttachmentJson, '@odata.type') = '#microsoft.graph.fileAttachment' then begin
                LineNo += 10000;
                DNFile.Init();
                DNFile."Document Entry No." := DNDocument."Entry No.";
                DNFile."Line No." := LineNo;
                DNFile."Graph Attachment Id" := CopyStr(JsonHelper.GetText(AttachmentJson, 'id'), 1, MaxStrLen(DNFile."Graph Attachment Id"));
                DNFile."File Name" := CopyStr(JsonHelper.GetText(AttachmentJson, 'name'), 1, MaxStrLen(DNFile."File Name"));
                DNFile."Content Type" := CopyStr(JsonHelper.GetText(AttachmentJson, 'contentType'), 1, MaxStrLen(DNFile."Content Type"));
                DNFile."Size (Bytes)" := JsonHelper.GetInteger(AttachmentJson, 'size');
                DNFile."Is Inline" := JsonHelper.GetBoolean(AttachmentJson, 'isInline');
                DNFile.Content.CreateOutStream(OutStr);
                Base64Convert.FromBase64(JsonHelper.GetText(AttachmentJson, 'contentBytes'), OutStr);
                DNFile.Insert(true);
            end;
        end;
    end;

    procedure MarkAsRead(GraphMessageId: Text; DocumentEntryNo: Integer)
    var
        Body: JsonObject;
        BodyText: Text;
    begin
        Body.Add('isRead', true);
        Body.WriteTo(BodyText);
        SendGraphRequest('PATCH', GetMailboxUrl() + '/messages/' + GraphMessageId, BodyText, DocumentEntryNo);
    end;

    procedure MoveMessage(var DNDocument: Record "IKA DN Document"; FolderName: Text)
    var
        Body: JsonObject;
        ResponseJson: JsonObject;
        BodyText: Text;
        NewId: Text;
    begin
        if (FolderName = '') or (DNDocument."Graph Message Id" = '') or DNDocument."Moved at Source" then
            exit;
        Setup.TestSetupForGraph();
        Body.Add('destinationId', GetMailFolderId(FolderName));
        Body.WriteTo(BodyText);
        ResponseJson := SendGraphRequest('POST', GetMailboxUrl() + '/messages/' + DNDocument."Graph Message Id" + '/move', BodyText, DNDocument."Entry No.");
        NewId := JsonHelper.GetText(ResponseJson, 'id');
        if NewId <> '' then
            DNDocument."Graph Message Id" := CopyStr(NewId, 1, MaxStrLen(DNDocument."Graph Message Id"));
        DNDocument."Moved at Source" := true;
        DNDocument.Modify();
    end;

    local procedure GetMailFolderId(FolderName: Text): Text
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
        end;
        if (StrLen(FolderName) > 60) and (StrPos(FolderName, ' ') = 0) then
            exit(FolderName);

        NameFilter := UriHelper.EscapeDataString('displayName eq ''' + FolderName.Replace('''', '''''') + '''');
        ResponseJson := SendGraphRequest('GET', GetMailboxUrl() + '/mailFolders/inbox/childFolders?$filter=' + NameFilter + '&$select=id', '', 0);
        if JsonHelper.GetArray(ResponseJson, 'value', FolderArray) then
            foreach FolderToken in FolderArray do
                exit(JsonHelper.GetText(FolderToken.AsObject(), 'id'));
        ResponseJson := SendGraphRequest('GET', GetMailboxUrl() + '/mailFolders?$filter=' + NameFilter + '&$select=id', '', 0);
        if JsonHelper.GetArray(ResponseJson, 'value', FolderArray) then
            foreach FolderToken in FolderArray do
                exit(JsonHelper.GetText(FolderToken.AsObject(), 'id'));
        Error(MailFolderNotFoundErr, FolderName, MailAccount.Address);
    end;

    local procedure GetMailboxUrl(): Text
    begin
        LoadMailAccount();
        exit(GraphRootTok + '/users/' + UriHelper.EscapeDataString(MailAccount.Address));
    end;

    local procedure LoadMailAccount()
    begin
        if MailAccount.Code <> '' then
            exit;
        Setup.GetSetup();
        Setup.TestField("Mail Account Code");
        MailAccount.Get(Setup."Mail Account Code");
        MailAccount.TestField(Address);
        MailAccount.TestField(Enabled);
    end;

    /// <summary>
    /// Prueba una cuenta concreta (desde la página "Cuentas de Outlook 365").
    /// </summary>
    procedure TestAccount(Account: Record "IKA DN Mail Account"): Text
    var
        ResponseJson: JsonObject;
    begin
        Setup.GetSetup();
        MailAccount := Account;
        MailAccount.TestField(Address);
        MailAccessToken := '';
        ResponseJson := SendGraphRequest('GET', GetMailboxUrl() + '/mailFolders/' + GetMailFolderId(MailAccount.Folder) + '?$select=displayName,unreadItemCount', '', 0);
        exit(StrSubstNo('%1 - %2 (%3 sin leer)', MailAccount.Address, JsonHelper.GetText(ResponseJson, 'displayName'), JsonHelper.GetText(ResponseJson, 'unreadItemCount')));
    end;

    // =====================================================================
    // Carpeta SharePoint / OneDrive
    // =====================================================================

    /// <summary>
    /// Importa cada fichero de la carpeta de entrada como un documento nuevo.
    /// Un fichero ya importado (mismo id de Graph) no se vuelve a importar.
    /// </summary>
    procedure ImportNewFiles(): Integer
    var
        ChildrenJson: JsonObject;
        ItemArray: JsonArray;
        ItemToken: JsonToken;
        Url: Text;
        ImportedCount: Integer;
        PageCount: Integer;
    begin
        Setup.TestSetupForGraph();
        Setup.TestField("Folder Inbox Path");

        Url := GetDriveUrl() + '/root:/' + EncodePath(Setup."Folder Inbox Path") + ':/children' +
            '?$top=50&$select=id,name,size,file,lastModifiedDateTime,@microsoft.graph.downloadUrl';

        while (Url <> '') and (ImportedCount < Setup."Max Documents per Run") and (PageCount < 20) do begin
            PageCount += 1;
            ChildrenJson := SendGraphRequest('GET', Url, '', 0);
            Url := JsonHelper.GetText(ChildrenJson, '@odata.nextLink');
            if JsonHelper.GetArray(ChildrenJson, 'value', ItemArray) then
                foreach ItemToken in ItemArray do
                    if ImportedCount < Setup."Max Documents per Run" then
                        if ImportFile(ItemToken.AsObject()) then begin
                            ImportedCount += 1;
                            Commit();
                        end;
        end;
        exit(ImportedCount);
    end;

    local procedure ImportFile(ItemJson: JsonObject): Boolean
    var
        DNDocument: Record "IKA DN Document";
        DNFile: Record "IKA DN File";
        VendorTemplate: Record "IKA DN Vendor Template";
        FileJson: JsonObject;
        ItemId: Text;
        FileName: Text;
        FileSize: Integer;
        ModifiedAt: DateTime;
    begin
        // Las subcarpetas (procesados, errores...) no tienen la propiedad "file"
        if not JsonHelper.GetObject(ItemJson, 'file', FileJson) then
            exit(false);
        ItemId := JsonHelper.GetText(ItemJson, 'id');
        FileName := JsonHelper.GetText(ItemJson, 'name');
        FileSize := JsonHelper.GetInteger(ItemJson, 'size');

        DNDocument.SetRange("Drive Item Id", CopyStr(ItemId, 1, MaxStrLen(DNDocument."Drive Item Id")));
        if not DNDocument.IsEmpty() then
            exit(false);
        DNDocument.Reset();

        if (Setup."Max Attachment Size (KB)" > 0) and (FileSize > Setup."Max Attachment Size (KB)" * 1024) then begin
            LogMgt.LogWarning(0, StrSubstNo(TooBigLbl, FileName, Setup."Max Attachment Size (KB)"));
            exit(false);
        end;

        if Evaluate(ModifiedAt, JsonHelper.GetText(ItemJson, 'lastModifiedDateTime'), 9) then;

        DNDocument.Init();
        DNDocument.Source := DNDocument.Source::Folder;
        DNDocument.Status := DNDocument.Status::New;
        DNDocument."Drive Item Id" := CopyStr(ItemId, 1, MaxStrLen(DNDocument."Drive Item Id"));
        DNDocument."Source File Name" := CopyStr(FileName, 1, MaxStrLen(DNDocument."Source File Name"));
        DNDocument.Subject := CopyStr(FileName, 1, MaxStrLen(DNDocument.Subject));
        DNDocument."Received At" := ModifiedAt;
        if VendorTemplate.FindByFileName(FileName) then
            DNDocument."Template Vendor No." := VendorTemplate."Vendor No.";
        DNDocument.Insert(true);

        DNFile.Init();
        DNFile."Document Entry No." := DNDocument."Entry No.";
        DNFile."Line No." := 10000;
        DNFile."Graph Attachment Id" := CopyStr(ItemId, 1, MaxStrLen(DNFile."Graph Attachment Id"));
        DNFile."File Name" := CopyStr(FileName, 1, MaxStrLen(DNFile."File Name"));
        DNFile."Content Type" := CopyStr(JsonHelper.GetText(FileJson, 'mimeType'), 1, MaxStrLen(DNFile."Content Type"));
        DNFile."Size (Bytes)" := FileSize;
        DownloadFile(JsonHelper.GetText(ItemJson, '@microsoft.graph.downloadUrl'), ItemId, DNFile);
        DNFile.Insert(true);

        LogMgt.LogInfo(DNDocument."Entry No.", StrSubstNo(ImportedFileLbl, FileName, Setup."Folder Inbox Path"));
        exit(true);
    end;

    local procedure DownloadFile(DownloadUrl: Text; ItemId: Text; var DNFile: Record "IKA DN File")
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        InStr: InStream;
        OutStr: OutStream;
    begin
        // La downloadUrl es una URL pre-autenticada de corta duración: no lleva token.
        // Si no viene, se usa /content con el token (Graph redirige a la descarga).
        if DownloadUrl <> '' then
            Request.SetRequestUri(DownloadUrl)
        else begin
            Request.SetRequestUri(GetDriveUrl() + '/items/' + ItemId + '/content');
            Request.GetHeaders(RequestHeaders);
            AddBearerHeader(RequestHeaders, false);
        end;
        Request.Method('GET');
        Client.Timeout := 300000;
        if not Client.Send(Request, Response) then
            Error(DownloadErr, DNFile."File Name", 0);
        if not Response.IsSuccessStatusCode() then
            Error(DownloadErr, DNFile."File Name", Response.HttpStatusCode());
        Response.Content.ReadAs(InStr);
        DNFile.Content.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
    end;

    /// <summary>
    /// Mueve el fichero a otra carpeta de la misma biblioteca (renombrando si ya existe uno igual).
    /// </summary>
    procedure MoveFile(var DNDocument: Record "IKA DN Document"; FolderPath: Text)
    var
        Body: JsonObject;
        ParentReference: JsonObject;
        FolderJson: JsonObject;
        BodyText: Text;
    begin
        if (FolderPath = '') or (DNDocument."Drive Item Id" = '') or DNDocument."Moved at Source" then
            exit;
        Setup.TestSetupForGraph();
        FolderJson := SendGraphRequest('GET', GetDriveUrl() + '/root:/' + EncodePath(FolderPath) + '?$select=id', '', DNDocument."Entry No.");
        ParentReference.Add('id', JsonHelper.GetText(FolderJson, 'id'));
        Body.Add('parentReference', ParentReference);
        Body.Add('@microsoft.graph.conflictBehavior', 'rename');
        Body.WriteTo(BodyText);
        SendGraphRequest('PATCH', GetDriveUrl() + '/items/' + DNDocument."Drive Item Id", BodyText, DNDocument."Entry No.");
        DNDocument."Moved at Source" := true;
        DNDocument.Modify();
    end;

    local procedure GetDriveUrl(): Text
    var
        SiteJson: JsonObject;
        DriveJson: JsonObject;
    begin
        if DriveId = '' then
            DriveId := Setup."Drive Id";
        if DriveId = '' then begin
            if Setup."Drive Site" = '' then
                Error(DriveNotConfiguredErr);
            // "empresa.sharepoint.com:/sites/Compras" -> id del sitio -> biblioteca por defecto
            SiteJson := SendGraphRequest('GET', GraphRootTok + '/sites/' + Setup."Drive Site" + '?$select=id', '', 0);
            DriveJson := SendGraphRequest('GET', GraphRootTok + '/sites/' + JsonHelper.GetText(SiteJson, 'id') + '/drive?$select=id', '', 0);
            DriveId := JsonHelper.GetText(DriveJson, 'id');
        end;
        exit(GraphRootTok + '/drives/' + DriveId);
    end;

    procedure ResolveDriveId(): Text
    begin
        Setup.TestSetupForGraph();
        Clear(DriveId);
        Setup."Drive Id" := '';
        GetDriveUrl();
        exit(DriveId);
    end;

    local procedure EncodePath(FolderPath: Text): Text
    var
        Segments: List of [Text];
        Segment: Text;
        Result: Text;
    begin
        Segments := FolderPath.Replace('\', '/').Split('/');
        foreach Segment in Segments do
            if Segment <> '' then begin
                if Result <> '' then
                    Result += '/';
                Result += UriHelper.EscapeDataString(Segment);
            end;
        exit(Result);
    end;

    // =====================================================================
    // Pruebas de conexión
    // =====================================================================

    procedure TestConnection(): Text
    var
        ResponseJson: JsonObject;
        Result: Text;
    begin
        Setup.TestSetupForGraph();
        if Setup."Mail Enabled" then begin
            ResponseJson := SendGraphRequest('GET', GetMailboxUrl() + '/mailFolders/' + GetMailFolderId(MailAccount.Folder) + '?$select=displayName,unreadItemCount', '', 0);
            Result := StrSubstNo('Correo: %1 (%2 sin leer). ', JsonHelper.GetText(ResponseJson, 'displayName'), JsonHelper.GetText(ResponseJson, 'unreadItemCount'));
        end;
        if Setup."Folder Enabled" then begin
            ResponseJson := SendGraphRequest('GET', GetDriveUrl() + '/root:/' + EncodePath(Setup."Folder Inbox Path") + '?$select=name,folder', '', 0);
            Result += StrSubstNo('Carpeta: %1 (%2 elementos).', JsonHelper.GetText(ResponseJson, 'name'), JsonHelper.GetTextByPath(ResponseJson, '$.folder.childCount'));
        end;
        exit(Result);
    end;

    // =====================================================================
    // HTTP
    // =====================================================================

    local procedure SendGraphRequest(Method: Text; Url: Text; BodyText: Text; DocumentEntryNo: Integer) ResponseJson: JsonObject
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
        // Las llamadas al buzón (/users/...) usan las credenciales de la cuenta de correo
        AddBearerHeader(RequestHeaders, StrPos(Url, GraphRootTok + '/users/') = 1);
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
            LogMgt.LogGraphCall(DocumentEntryNo, Method + ' ' + Url, Response.HttpStatusCode(), ResponseText);
            Commit();
            Error(GraphErr, Method, Url, Response.HttpStatusCode(), CopyStr(ResponseText, 1, 1000));
        end;
        if ResponseText <> '' then
            if ResponseJson.ReadFrom(ResponseText) then;
    end;

    [NonDebuggable]
    local procedure AddBearerHeader(var RequestHeaders: HttpHeaders; ForMailAccount: Boolean)
    begin
        if ForMailAccount then begin
            if MailAccessToken = '' then
                MailAccessToken := GetAccessToken(true);
            RequestHeaders.Add('Authorization', 'Bearer ' + MailAccessToken);
        end else begin
            if GeneralAccessToken = '' then
                GeneralAccessToken := GetAccessToken(false);
            RequestHeaders.Add('Authorization', 'Bearer ' + GeneralAccessToken);
        end;
    end;

    [NonDebuggable]
    local procedure GetAccessToken(ForMailAccount: Boolean): Text
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
        // Cuenta con credenciales propias (otro tenant) o credenciales generales de la configuración
        if ForMailAccount then
            LoadMailAccount();
        if ForMailAccount and MailAccount."Use Own Credentials" then begin
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
