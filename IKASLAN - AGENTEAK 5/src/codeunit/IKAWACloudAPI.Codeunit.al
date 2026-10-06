codeunit 50600 "IKA WA Cloud API"
{
    // Cliente de la WhatsApp Business Platform - Cloud API de Meta (graph.facebook.com).
    // Envío: POST /{phone-number-id}/messages. Ficheros: POST /{phone-number-id}/media (multipart).
    // Plantillas: GET /{waba-id}/message_templates.
    // Reglas de WhatsApp que se aplican aquí:
    //  - Texto libre y ficheros solo dentro de las 24 h siguientes al último mensaje del cliente.
    //  - Fuera de esa ventana, o para escribir primero, solo plantillas aprobadas por Meta.

    var
        Setup: Record "IKA WA Setup";
        JsonHelper: Codeunit "IKA WA Json Helper";
        MetaErr: Label 'WhatsApp (Meta) devolvió el error HTTP %1: %2', Comment = '%1 = status, %2 = message';
        ConnectErr: Label 'No se pudo conectar con la API de WhatsApp: %1', Comment = '%1 = error';
        WindowClosedErr: Label 'Han pasado más de 24 horas desde el último mensaje de %1. WhatsApp solo permite escribirle con una plantilla aprobada.', Comment = '%1 = phone';
        EmptyTextErr: Label 'Escriba el texto del mensaje.';
        TooBigErr: Label 'El fichero %1 supera el tamaño máximo de %2 MB.', Comment = '%1 = file, %2 = MB';
        MissingParamErr: Label 'Falta el valor de la variable {{%1}} de la plantilla %2.', Comment = '%1 = param no., %2 = template';
        TestOkLbl: Label 'Conexión correcta: %1 (%2). Calidad: %3.', Comment = '%1 = phone, %2 = verified name, %3 = quality';

    // =====================================================================
    // Envío
    // =====================================================================

    /// <summary>
    /// Mensaje de texto libre (solo dentro de la ventana de 24 h).
    /// </summary>
    procedure SendText(var Conversation: Record "IKA WA Conversation"; MessageText: Text): Integer
    var
        Account: Record "IKA WA Account";
        Body: JsonObject;
        TextJson: JsonObject;
        WAMessage: Record "IKA WA Message";
    begin
        if DelChr(MessageText, '=', ' ') = '' then
            Error(EmptyTextErr);
        CheckWindow(Conversation);
        GetAccount(Conversation."Account Code", Account);

        TextJson.Add('preview_url', false);
        TextJson.Add('body', MessageText);
        Body := NewMessageBody(Conversation."Phone No.", 'text');
        Body.Add('text', TextJson);

        InitOutbound(WAMessage, Conversation, WAMessage."Message Type"::"Plain Text");
        WAMessage.SetFullText(MessageText);
        exit(PostMessage(Account, Body, WAMessage, Conversation));
    end;

    /// <summary>
    /// Documento o imagen como mensaje libre (solo dentro de la ventana de 24 h).
    /// </summary>
    procedure SendFile(var Conversation: Record "IKA WA Conversation"; var TempBlob: Codeunit "Temp Blob"; FileName: Text; Caption: Text; SourceTableId: Integer; SourceDocNo: Code[20]): Integer
    var
        Account: Record "IKA WA Account";
        WAMessage: Record "IKA WA Message";
        Body: JsonObject;
        MediaJson: JsonObject;
        MimeType: Text;
        MediaType: Text;
        MediaId: Text;
    begin
        CheckWindow(Conversation);
        GetAccount(Conversation."Account Code", Account);
        MimeType := GetMimeType(FileName);
        MediaId := UploadMedia(Account, TempBlob, FileName, MimeType);

        if MimeType in ['image/jpeg', 'image/png'] then begin
            MediaType := 'image';
            InitOutbound(WAMessage, Conversation, WAMessage."Message Type"::Image);
        end else begin
            MediaType := 'document';
            InitOutbound(WAMessage, Conversation, WAMessage."Message Type"::Document);
            MediaJson.Add('filename', FileName);
        end;
        MediaJson.Add('id', MediaId);
        if Caption <> '' then
            MediaJson.Add('caption', Caption);
        Body := NewMessageBody(Conversation."Phone No.", MediaType);
        Body.Add(MediaType, MediaJson);

        WAMessage."Media ID" := CopyStr(MediaId, 1, MaxStrLen(WAMessage."Media ID"));
        WAMessage."File Name" := CopyStr(FileName, 1, MaxStrLen(WAMessage."File Name"));
        WAMessage."MIME Type" := CopyStr(MimeType, 1, MaxStrLen(WAMessage."MIME Type"));
        WAMessage.SetFullText(Caption);
        WAMessage."Source Table ID" := SourceTableId;
        WAMessage."Source Document No." := SourceDocNo;
        StoreMedia(WAMessage, TempBlob);
        exit(PostMessage(Account, Body, WAMessage, Conversation));
    end;

    /// <summary>
    /// Mensaje con plantilla aprobada (se puede enviar en cualquier momento). Si la plantilla tiene
    /// cabecera de tipo Documento/Imagen, se adjunta el fichero indicado.
    /// </summary>
    procedure SendTemplate(var Conversation: Record "IKA WA Conversation"; WATemplate: Record "IKA WA Template"; Parameters: List of [Text]; var TempBlob: Codeunit "Temp Blob"; FileName: Text; SourceTableId: Integer; SourceDocNo: Code[20]): Integer
    var
        Account: Record "IKA WA Account";
        WAMessage: Record "IKA WA Message";
        Body: JsonObject;
        TemplateJson: JsonObject;
        LanguageJson: JsonObject;
        Components: JsonArray;
        HeaderComponent: JsonObject;
        HeaderParams: JsonArray;
        HeaderParam: JsonObject;
        MediaJson: JsonObject;
        BodyComponent: JsonObject;
        BodyParams: JsonArray;
        BodyParam: JsonObject;
        RenderedText: Text;
        MediaId: Text;
        MimeType: Text;
        i: Integer;
    begin
        GetAccount(Conversation."Account Code", Account);
        InitOutbound(WAMessage, Conversation, WAMessage."Message Type"::Template);

        if WATemplate."Header Type" in [WATemplate."Header Type"::Document, WATemplate."Header Type"::Image, WATemplate."Header Type"::Video] then begin
            MimeType := GetMimeType(FileName);
            MediaId := UploadMedia(Account, TempBlob, FileName, MimeType);
            MediaJson.Add('id', MediaId);
            case WATemplate."Header Type" of
                WATemplate."Header Type"::Document:
                    begin
                        MediaJson.Add('filename', FileName);
                        HeaderParam.Add('type', 'document');
                        HeaderParam.Add('document', MediaJson);
                    end;
                WATemplate."Header Type"::Image:
                    begin
                        HeaderParam.Add('type', 'image');
                        HeaderParam.Add('image', MediaJson);
                    end;
                WATemplate."Header Type"::Video:
                    begin
                        HeaderParam.Add('type', 'video');
                        HeaderParam.Add('video', MediaJson);
                    end;
            end;
            HeaderParams.Add(HeaderParam);
            HeaderComponent.Add('type', 'header');
            HeaderComponent.Add('parameters', HeaderParams);
            Components.Add(HeaderComponent);
            WAMessage."Media ID" := CopyStr(MediaId, 1, MaxStrLen(WAMessage."Media ID"));
            WAMessage."File Name" := CopyStr(FileName, 1, MaxStrLen(WAMessage."File Name"));
            WAMessage."MIME Type" := CopyStr(MimeType, 1, MaxStrLen(WAMessage."MIME Type"));
            StoreMedia(WAMessage, TempBlob);
        end;

        RenderedText := WATemplate."Body Text";
        if WATemplate."No. of Body Parameters" > 0 then begin
            for i := 1 to WATemplate."No. of Body Parameters" do begin
                if (i > Parameters.Count()) or (DelChr(Parameters.Get(i), '=', ' ') = '') then
                    Error(MissingParamErr, i, WATemplate.Name);
                Clear(BodyParam);
                BodyParam.Add('type', 'text');
                BodyParam.Add('text', Parameters.Get(i));
                BodyParams.Add(BodyParam);
                RenderedText := RenderedText.Replace('{{' + Format(i) + '}}', Parameters.Get(i));
            end;
            BodyComponent.Add('type', 'body');
            BodyComponent.Add('parameters', BodyParams);
            Components.Add(BodyComponent);
        end;

        LanguageJson.Add('code', WATemplate."Language Code");
        TemplateJson.Add('name', WATemplate.Name);
        TemplateJson.Add('language', LanguageJson);
        if Components.Count() > 0 then
            TemplateJson.Add('components', Components);
        Body := NewMessageBody(Conversation."Phone No.", 'template');
        Body.Add('template', TemplateJson);

        WAMessage."Template Name" := WATemplate.Name;
        WAMessage.SetFullText(RenderedText);
        WAMessage."Source Table ID" := SourceTableId;
        WAMessage."Source Document No." := SourceDocNo;
        exit(PostMessage(Account, Body, WAMessage, Conversation));
    end;

    /// <summary>
    /// Doble check azul en el móvil del cliente.
    /// </summary>
    procedure MarkAsRead(AccountCode: Code[20]; WAMessageId: Text)
    var
        Account: Record "IKA WA Account";
        Body: JsonObject;
    begin
        if WAMessageId = '' then
            exit;
        GetAccount(AccountCode, Account);
        Body.Add('messaging_product', 'whatsapp');
        Body.Add('status', 'read');
        Body.Add('message_id', WAMessageId);
        SendJsonRequest(Account, 'POST', GetPhoneNumberUrl(Account) + '/messages', Body);
    end;

    local procedure NewMessageBody(ToPhone: Text; MessageType: Text): JsonObject
    var
        Body: JsonObject;
    begin
        Body.Add('messaging_product', 'whatsapp');
        Body.Add('recipient_type', 'individual');
        Body.Add('to', ToPhone);
        Body.Add('type', MessageType);
        exit(Body);
    end;

    local procedure InitOutbound(var WAMessage: Record "IKA WA Message"; Conversation: Record "IKA WA Conversation"; MessageType: Enum "IKA WA Message Type")
    begin
        WAMessage.Init();
        WAMessage."Entry No." := 0;
        WAMessage."Conversation Entry No." := Conversation."Entry No.";
        WAMessage."Account Code" := Conversation."Account Code";
        WAMessage.Direction := WAMessage.Direction::Outbound;
        WAMessage."Message Type" := MessageType;
        WAMessage."Sent At" := CurrentDateTime();
        WAMessage."Sent By" := CopyStr(UserId(), 1, MaxStrLen(WAMessage."Sent By"));
    end;

    /// <summary>
    /// Envía el mensaje y lo registra (con el wamid devuelto por Meta). Los cambios de estado
    /// (entregado, leído, error) llegan después por el webhook.
    /// </summary>
    local procedure PostMessage(Account: Record "IKA WA Account"; Body: JsonObject; var WAMessage: Record "IKA WA Message"; var Conversation: Record "IKA WA Conversation"): Integer
    var
        ResponseJson: JsonObject;
    begin
        ResponseJson := SendJsonRequest(Account, 'POST', GetPhoneNumberUrl(Account) + '/messages', Body);
        WAMessage."WA Message ID" := CopyStr(JsonHelper.GetTextByPath(ResponseJson, '$.messages[0].id'), 1, MaxStrLen(WAMessage."WA Message ID"));
        WAMessage.Status := WAMessage.Status::Sent;
        WAMessage.Insert(true);

        Conversation."Last Message At" := WAMessage."Sent At";
        Conversation."Last Message Preview" := CopyStr(WAMessage.GetDisplayText(), 1, MaxStrLen(Conversation."Last Message Preview"));
        Conversation.Modify();
        exit(WAMessage."Entry No.");
    end;

    local procedure CheckWindow(Conversation: Record "IKA WA Conversation")
    begin
        if not Conversation.IsWindowOpen() then
            Error(WindowClosedErr, Conversation."Phone No.");
    end;

    local procedure StoreMedia(var WAMessage: Record "IKA WA Message"; var TempBlob: Codeunit "Temp Blob")
    var
        InStr: InStream;
        OutStr: OutStream;
    begin
        TempBlob.CreateInStream(InStr);
        WAMessage."Media Content".CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
        WAMessage."Media Downloaded" := true;
    end;

    // =====================================================================
    // Ficheros (media)
    // =====================================================================

    /// <summary>
    /// Sube un fichero a Meta (multipart/form-data) y devuelve su id para usarlo en un mensaje.
    /// </summary>
    procedure UploadMedia(Account: Record "IKA WA Account"; var TempBlob: Codeunit "Temp Blob"; FileName: Text; MimeType: Text): Text
    var
        BodyBlob: Codeunit "Temp Blob";
        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Response: HttpResponseMessage;
        ResponseJson: JsonObject;
        FileInStr: InStream;
        BodyInStr: InStream;
        OutStr: OutStream;
        Boundary: Text;
        Crlf: Text[2];
        ResponseText: Text;
    begin
        Setup.GetSetup();
        if (Setup."Max Media Size (MB)" > 0) and (TempBlob.Length() > Setup."Max Media Size (MB)" * 1048576) then
            Error(TooBigErr, FileName, Setup."Max Media Size (MB)");

        Crlf[1] := 13;
        Crlf[2] := 10;
        Boundary := 'IkaWaBoundary' + DelChr(Format(CreateGuid()), '=', '{}-');

        BodyBlob.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText('--' + Boundary + Crlf + 'Content-Disposition: form-data; name="messaging_product"' + Crlf + Crlf + 'whatsapp' + Crlf);
        OutStr.WriteText('--' + Boundary + Crlf + 'Content-Disposition: form-data; name="type"' + Crlf + Crlf + MimeType + Crlf);
        OutStr.WriteText('--' + Boundary + Crlf + 'Content-Disposition: form-data; name="file"; filename="' + FileName.Replace('"', '') + '"' + Crlf +
            'Content-Type: ' + MimeType + Crlf + Crlf);
        TempBlob.CreateInStream(FileInStr);
        CopyStream(OutStr, FileInStr);
        OutStr.WriteText(Crlf + '--' + Boundary + '--' + Crlf);

        BodyBlob.CreateInStream(BodyInStr);
        Content.WriteFrom(BodyInStr);
        Content.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'multipart/form-data; boundary=' + Boundary);

        AddAuthorization(Client, Account);
        Client.Timeout := 300000;
        if not Client.Post(GetPhoneNumberUrl(Account) + '/media', Content, Response) then
            Error(ConnectErr, GetLastErrorText());
        Response.Content.ReadAs(ResponseText);
        if not Response.IsSuccessStatusCode() then
            Error(MetaErr, Response.HttpStatusCode(), GetMetaErrorMessage(ResponseText));
        ResponseJson.ReadFrom(ResponseText);
        exit(JsonHelper.GetText(ResponseJson, 'id'));
    end;

    /// <summary>
    /// Descarga un fichero recibido: primero se pide su URL temporal y después el contenido (con el token).
    /// </summary>
    procedure DownloadMedia(var WAMessage: Record "IKA WA Message")
    var
        Account: Record "IKA WA Account";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        RequestHeaders: HttpHeaders;
        MediaJson: JsonObject;
        EmptyBody: JsonObject;
        InStr: InStream;
        OutStr: OutStream;
        ErrorText: Text;
    begin
        if (WAMessage."Media ID" = '') or WAMessage."Media Downloaded" then
            exit;
        // Sin comprobar el usuario: se ejecuta también desde la cola de proyectos
        Account.Get(WAMessage."Account Code");
        MediaJson := SendJsonRequest(Account, 'GET', Setup.GetApiUrl() + '/' + WAMessage."Media ID", EmptyBody);
        if WAMessage."MIME Type" = '' then
            WAMessage."MIME Type" := CopyStr(JsonHelper.GetText(MediaJson, 'mime_type'), 1, MaxStrLen(WAMessage."MIME Type"));

        Request.Method('GET');
        Request.SetRequestUri(JsonHelper.GetText(MediaJson, 'url'));
        Request.GetHeaders(RequestHeaders);
        AddAuthorizationHeader(RequestHeaders, Account);
        Client.Timeout := 300000;
        if not Client.Send(Request, Response) then
            Error(ConnectErr, GetLastErrorText());
        if not Response.IsSuccessStatusCode() then begin
            Response.Content.ReadAs(ErrorText);
            Error(MetaErr, Response.HttpStatusCode(), CopyStr(ErrorText, 1, 500));
        end;
        Response.Content.ReadAs(InStr);
        WAMessage."Media Content".CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
        WAMessage."Media Downloaded" := true;
        if WAMessage."File Name" = '' then
            WAMessage."File Name" := CopyStr(GetDefaultFileName(WAMessage), 1, MaxStrLen(WAMessage."File Name"));
        WAMessage.Modify();
    end;

    procedure GetDefaultFileName(WAMessage: Record "IKA WA Message"): Text
    var
        Extension: Text;
    begin
        case LowerCase(WAMessage."MIME Type") of
            'image/jpeg':
                Extension := 'jpg';
            'image/png':
                Extension := 'png';
            'image/webp':
                Extension := 'webp';
            'application/pdf':
                Extension := 'pdf';
            'audio/ogg', 'audio/ogg; codecs=opus':
                Extension := 'ogg';
            'audio/mpeg':
                Extension := 'mp3';
            'video/mp4':
                Extension := 'mp4';
            else
                Extension := 'bin';
        end;
        exit('whatsapp_' + Format(WAMessage."Sent At", 0, '<Year4><Month,2><Day,2>_<Hours24,2><Minutes,2><Seconds,2>') + '.' + Extension);
    end;

    procedure GetMimeType(FileName: Text): Text
    var
        Extension: Text;
        DotPos: Integer;
    begin
        DotPos := StrLen(FileName);
        while (DotPos > 0) and (CopyStr(FileName, DotPos, 1) <> '.') do
            DotPos -= 1;
        if DotPos > 0 then
            Extension := LowerCase(CopyStr(FileName, DotPos + 1));
        case Extension of
            'pdf':
                exit('application/pdf');
            'jpg', 'jpeg':
                exit('image/jpeg');
            'png':
                exit('image/png');
            'xlsx':
                exit('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
            'docx':
                exit('application/vnd.openxmlformats-officedocument.wordprocessingml.document');
            'txt':
                exit('text/plain');
            'mp4':
                exit('video/mp4');
            else
                exit('application/pdf');
        end;
    end;

    // =====================================================================
    // Plantillas y prueba de conexión
    // =====================================================================

    /// <summary>
    /// Trae de Meta las plantillas de la cuenta (nombre, idioma, estado, categoría, cabecera y texto).
    /// Conserva la descripción y la configuración de variables ya definidas en BC.
    /// </summary>
    procedure SyncTemplates(var Account: Record "IKA WA Account"): Integer
    var
        WATemplate: Record "IKA WA Template";
        ResponseJson: JsonObject;
        TemplateArray: JsonArray;
        TemplateToken: JsonToken;
        TemplateJson: JsonObject;
        ComponentArray: JsonArray;
        ComponentToken: JsonToken;
        ComponentJson: JsonObject;
        EmptyBody: JsonObject;
        Url: Text;
        TemplateName: Text;
        LanguageCode: Text;
        SyncedCount: Integer;
        PageCount: Integer;
    begin
        Account.TestField("Business Account ID");
        Url := Setup.GetApiUrl() + '/' + Account."Business Account ID" + '/message_templates?fields=name,language,status,category,components&limit=100';
        while (Url <> '') and (PageCount < 20) do begin
            PageCount += 1;
            ResponseJson := SendJsonRequest(Account, 'GET', Url, EmptyBody);
            Url := JsonHelper.GetTextByPath(ResponseJson, '$.paging.next');
            if JsonHelper.GetArray(ResponseJson, 'data', TemplateArray) then
                foreach TemplateToken in TemplateArray do begin
                    TemplateJson := TemplateToken.AsObject();
                    TemplateName := JsonHelper.GetText(TemplateJson, 'name');
                    LanguageCode := JsonHelper.GetText(TemplateJson, 'language');
                    if not WATemplate.Get(Account.Code, CopyStr(TemplateName, 1, MaxStrLen(WATemplate.Name)), CopyStr(LanguageCode, 1, MaxStrLen(WATemplate."Language Code"))) then begin
                        WATemplate.Init();
                        WATemplate."Account Code" := Account.Code;
                        WATemplate.Name := CopyStr(TemplateName, 1, MaxStrLen(WATemplate.Name));
                        WATemplate."Language Code" := CopyStr(LanguageCode, 1, MaxStrLen(WATemplate."Language Code"));
                        WATemplate.Insert();
                    end;
                    WATemplate.Category := CopyStr(JsonHelper.GetText(TemplateJson, 'category'), 1, MaxStrLen(WATemplate.Category));
                    WATemplate.Status := ParseTemplateStatus(JsonHelper.GetText(TemplateJson, 'status'));
                    WATemplate."Header Type" := WATemplate."Header Type"::" ";
                    WATemplate."Body Text" := '';
                    if JsonHelper.GetArray(TemplateJson, 'components', ComponentArray) then
                        foreach ComponentToken in ComponentArray do begin
                            ComponentJson := ComponentToken.AsObject();
                            case UpperCase(JsonHelper.GetText(ComponentJson, 'type')) of
                                'HEADER':
                                    case UpperCase(JsonHelper.GetText(ComponentJson, 'format')) of
                                        'DOCUMENT':
                                            WATemplate."Header Type" := WATemplate."Header Type"::Document;
                                        'IMAGE':
                                            WATemplate."Header Type" := WATemplate."Header Type"::Image;
                                        'VIDEO':
                                            WATemplate."Header Type" := WATemplate."Header Type"::Video;
                                        'TEXT':
                                            WATemplate."Header Type" := WATemplate."Header Type"::"Text Header";
                                    end;
                                'BODY':
                                    WATemplate."Body Text" := CopyStr(JsonHelper.GetText(ComponentJson, 'text'), 1, MaxStrLen(WATemplate."Body Text"));
                            end;
                        end;
                    WATemplate."No. of Body Parameters" := WATemplate.CountBodyParameters();
                    WATemplate.Modify();
                    SyncedCount += 1;
                end;
        end;
        Account."Last Template Sync" := CurrentDateTime();
        Account.Modify();
        exit(SyncedCount);
    end;

    local procedure ParseTemplateStatus(StatusText: Text): Enum "IKA WA Template Status"
    var
        WATemplate: Record "IKA WA Template";
    begin
        case UpperCase(StatusText) of
            'APPROVED':
                exit(WATemplate.Status::Approved);
            'PENDING', 'IN_APPEAL':
                exit(WATemplate.Status::Pending);
            'REJECTED':
                exit(WATemplate.Status::Rejected);
            'PAUSED':
                exit(WATemplate.Status::Paused);
            'DISABLED':
                exit(WATemplate.Status::Disabled);
        end;
        exit(WATemplate.Status::Unknown);
    end;

    procedure TestAccount(Account: Record "IKA WA Account"): Text
    var
        ResponseJson: JsonObject;
        EmptyBody: JsonObject;
    begin
        Account.TestField("Phone Number ID");
        ResponseJson := SendJsonRequest(Account, 'GET', GetPhoneNumberUrl(Account) + '?fields=display_phone_number,verified_name,quality_rating', EmptyBody);
        exit(StrSubstNo(TestOkLbl,
            JsonHelper.GetText(ResponseJson, 'display_phone_number'),
            JsonHelper.GetText(ResponseJson, 'verified_name'),
            JsonHelper.GetText(ResponseJson, 'quality_rating')));
    end;

    // =====================================================================
    // HTTP
    // =====================================================================

    local procedure GetAccount(AccountCode: Code[20]; var Account: Record "IKA WA Account")
    begin
        Account.Get(AccountCode);
        Account.TestField(Enabled);
        Account.TestField("Phone Number ID");
        Account.CheckAccess();
    end;

    local procedure GetPhoneNumberUrl(Account: Record "IKA WA Account"): Text
    begin
        exit(Setup.GetApiUrl() + '/' + Account."Phone Number ID");
    end;

    local procedure SendJsonRequest(Account: Record "IKA WA Account"; Method: Text; Url: Text; Body: JsonObject) ResponseJson: JsonObject
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        RequestHeaders: HttpHeaders;
        BodyText: Text;
        ResponseText: Text;
    begin
        Request.Method(Method);
        Request.SetRequestUri(Url);
        Request.GetHeaders(RequestHeaders);
        AddAuthorizationHeader(RequestHeaders, Account);
        if Method <> 'GET' then begin
            Body.WriteTo(BodyText);
            Content.WriteFrom(BodyText);
            Content.GetHeaders(ContentHeaders);
            if ContentHeaders.Contains('Content-Type') then
                ContentHeaders.Remove('Content-Type');
            ContentHeaders.Add('Content-Type', 'application/json');
            Request.Content := Content;
        end;
        Client.Timeout := 120000;
        if not Client.Send(Request, Response) then
            Error(ConnectErr, GetLastErrorText());
        Response.Content.ReadAs(ResponseText);
        if not Response.IsSuccessStatusCode() then
            Error(MetaErr, Response.HttpStatusCode(), GetMetaErrorMessage(ResponseText));
        if ResponseText <> '' then
            if ResponseJson.ReadFrom(ResponseText) then;
    end;

    /// <summary>
    /// Meta devuelve {"error":{"message":"...","error_data":{"details":"..."}}}.
    /// </summary>
    local procedure GetMetaErrorMessage(ResponseText: Text): Text
    var
        ResponseJson: JsonObject;
        Result: Text;
        Details: Text;
    begin
        if not ResponseJson.ReadFrom(ResponseText) then
            exit(CopyStr(ResponseText, 1, 500));
        Result := JsonHelper.GetTextByPath(ResponseJson, '$.error.message');
        Details := JsonHelper.GetTextByPath(ResponseJson, '$.error.error_data.details');
        if Details <> '' then
            Result += ' (' + Details + ')';
        if Result = '' then
            exit(CopyStr(ResponseText, 1, 500));
        exit(Result);
    end;

    [NonDebuggable]
    local procedure AddAuthorization(var Client: HttpClient; Account: Record "IKA WA Account")
    begin
        Client.DefaultRequestHeaders.Add('Authorization', 'Bearer ' + Account.GetAccessToken());
    end;

    [NonDebuggable]
    local procedure AddAuthorizationHeader(var RequestHeaders: HttpHeaders; Account: Record "IKA WA Account")
    begin
        RequestHeaders.Add('Authorization', 'Bearer ' + Account.GetAccessToken());
    end;
}
