codeunit 99401 "IKA CRM Web API"
{
    // Cliente de la API web de Dataverse (Microsoft Dynamics 365 Customer Engagement), solo lectura.
    // Autenticación de aplicación (client credentials): el registro de aplicación de Entra ID debe estar dado
    // de alta en el entorno del CRM como "usuario de aplicación" con un rol de seguridad que permita leer
    // cuentas, contactos, clientes potenciales, oportunidades y actividades.
    // Se piden los valores con formato (nombres de búsquedas y etiquetas de conjuntos de opciones) con
    // Prefer: odata.include-annotations="OData.Community.Display.V1.FormattedValue".

    var
        Setup: Record "IKA CRM Setup";
        JsonHelper: Codeunit "IKA CRM Json Helper";
        UriHelper: Codeunit Uri;
        CachedToken: Text;
        CachedTokenExpiry: DateTime;
        TokenUrlTok: Label 'https://login.microsoftonline.com/%1/oauth2/v2.0/token', Locked = true;
        TokenErr: Label 'No se pudo obtener el token para el CRM: %1', Comment = '%1 = error';
        CrmErr: Label 'Error del CRM (HTTP %1): %2', Comment = '%1 = status, %2 = message';
        ConnectErr: Label 'No se pudo conectar con el CRM: %1', Comment = '%1 = error';
        ForbiddenHintLbl: Label ' Compruebe que el registro de aplicación está dado de alta como usuario de aplicación en el entorno del CRM y que tiene un rol de seguridad con permiso de lectura.';
        ConnectionOkLbl: Label 'Conexión correcta con %1 (%2). Usuario de aplicación: %3.', Comment = '%1 = organization, %2 = url, %3 = user';

    /// <summary>
    /// GET sobre la API (ruta relativa a /api/data/vX.Y, p.ej. "accounts?$select=name").
    /// </summary>
    procedure Get(RelativeUrl: Text) ResponseJson: JsonObject
    begin
        ResponseJson := SendRequest(GetBaseUrl() + '/' + RelativeUrl);
    end;

    /// <summary>
    /// Valor de una consulta $filter u otro parámetro, codificado para la URL.
    /// </summary>
    procedure EncodeQueryValue(Value: Text): Text
    begin
        exit(UriHelper.EscapeDataString(Value));
    end;

    procedure TestConnection(): Text
    var
        WhoAmIJson: JsonObject;
        OrgJson: JsonObject;
        UserJson: JsonObject;
        OrgName: Text;
        UserName: Text;
    begin
        WhoAmIJson := Get('WhoAmI');
        OrgJson := Get('organizations(' + JsonHelper.GetText(WhoAmIJson, 'OrganizationId') + ')?$select=name');
        OrgName := JsonHelper.GetText(OrgJson, 'name');
        UserJson := Get('systemusers(' + JsonHelper.GetText(WhoAmIJson, 'UserId') + ')?$select=fullname');
        UserName := JsonHelper.GetText(UserJson, 'fullname');
        exit(StrSubstNo(ConnectionOkLbl, OrgName, Setup."Environment URL", UserName));
    end;

    local procedure GetBaseUrl(): Text
    begin
        Setup.GetSetup();
        Setup.TestConfigured();
        exit(Setup.GetApiUrl());
    end;

    local procedure SendRequest(Url: Text) ResponseJson: JsonObject
    var
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Headers: HttpHeaders;
        ResponseText: Text;
        ErrorText: Text;
    begin
        Request.Method('GET');
        Request.SetRequestUri(Url);
        Request.GetHeaders(Headers);
        AddAuthorization(Headers);
        Headers.Add('Accept', 'application/json');
        Headers.Add('OData-MaxVersion', '4.0');
        Headers.Add('OData-Version', '4.0');
        Headers.Add('Prefer', 'odata.include-annotations="OData.Community.Display.V1.FormattedValue"');
        Client.Timeout := 60000;
        if not Client.Send(Request, Response) then
            Error(ConnectErr, GetLastErrorText());
        Response.Content.ReadAs(ResponseText);
        if not Response.IsSuccessStatusCode() then begin
            ErrorText := GetCrmErrorMessage(ResponseText);
            if Response.HttpStatusCode() in [401, 403] then
                ErrorText += ForbiddenHintLbl;
            Error(CrmErr, Response.HttpStatusCode(), ErrorText);
        end;
        if ResponseText <> '' then
            if ResponseJson.ReadFrom(ResponseText) then;
    end;

    local procedure GetCrmErrorMessage(ResponseText: Text): Text
    var
        ErrorJson: JsonObject;
        ErrorMessage: Text;
    begin
        if ErrorJson.ReadFrom(ResponseText) then
            ErrorMessage := JsonHelper.GetTextByPath(ErrorJson, '$.error.message');
        if ErrorMessage = '' then
            ErrorMessage := CopyStr(ResponseText, 1, 1000);
        exit(ErrorMessage);
    end;

    [NonDebuggable]
    local procedure AddAuthorization(var Headers: HttpHeaders)
    begin
        Headers.Add('Authorization', 'Bearer ' + GetAccessToken());
    end;

    /// <summary>
    /// Token de aplicación para el entorno del CRM (scope = URL del CRM + /.default). Se reutiliza mientras no caduque.
    /// </summary>
    [NonDebuggable]
    local procedure GetAccessToken(): Text
    var
        Client: HttpClient;
        Content: HttpContent;
        ContentHeaders: HttpHeaders;
        Response: HttpResponseMessage;
        ResponseJson: JsonObject;
        BodyText: Text;
        ResponseText: Text;
        ExpiresIn: Integer;
    begin
        if (CachedToken <> '') and (CurrentDateTime() < CachedTokenExpiry) then
            exit(CachedToken);
        Setup.GetSetup();
        Setup.TestConfigured();
        BodyText := 'grant_type=client_credentials' +
            '&client_id=' + UriHelper.EscapeDataString(Setup."Client Id") +
            '&client_secret=' + UriHelper.EscapeDataString(Setup.GetClientSecret()) +
            '&scope=' + UriHelper.EscapeDataString(Setup."Environment URL" + '/.default');
        Content.WriteFrom(BodyText);
        Content.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/x-www-form-urlencoded');
        if not Client.Post(StrSubstNo(TokenUrlTok, Setup."Tenant Id"), Content, Response) then
            Error(TokenErr, GetLastErrorText());
        Response.Content.ReadAs(ResponseText);
        if not Response.IsSuccessStatusCode() then
            Error(TokenErr, CopyStr(ResponseText, 1, 1000));
        ResponseJson.ReadFrom(ResponseText);
        CachedToken := JsonHelper.GetText(ResponseJson, 'access_token');
        ExpiresIn := JsonHelper.GetInteger(ResponseJson, 'expires_in');
        if ExpiresIn <= 0 then
            ExpiresIn := 3600;
        // Margen de 5 minutos
        CachedTokenExpiry := CurrentDateTime() + (ExpiresIn - 300) * 1000;
        exit(CachedToken);
    end;
}
