table 99401 "IKA CRM Setup"
{
    // Conexión con Microsoft Dynamics 365 Customer Engagement (Dataverse Web API) mediante un registro de
    // aplicación de Entra ID (client credentials) dado de alta como usuario de aplicación en el entorno del CRM.
    Caption = 'Configuración CRM';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Clave primaria';
        }
        field(10; "Environment URL"; Text[250])
        {
            Caption = 'URL del CRM';
            ToolTip = 'Dirección del entorno del CRM, p.ej. https://empresa.crm4.dynamics.com';

            trigger OnValidate()
            begin
                "Environment URL" := CopyStr(DelChr("Environment URL", '>', '/ '), 1, MaxStrLen("Environment URL"));
                if ("Environment URL" <> '') and (StrPos(LowerCase("Environment URL"), 'https://') <> 1) then
                    "Environment URL" := CopyStr('https://' + "Environment URL", 1, MaxStrLen("Environment URL"));
            end;
        }
        field(11; "API Version"; Text[10])
        {
            Caption = 'Versión de la API';
            InitValue = 'v9.2';
        }
        field(20; "Tenant Id"; Text[100])
        {
            Caption = 'Tenant Id (Entra ID)';
        }
        field(21; "Client Id"; Text[100])
        {
            Caption = 'Client Id (registro de aplicación)';
        }
        field(30; "Max. Records"; Integer)
        {
            Caption = 'Nº máx. de registros por consulta';
            InitValue = 200;
            MinValue = 1;
            MaxValue = 5000;
            ToolTip = 'Cuántos registros se traen del CRM como máximo en cada lista. Use la búsqueda para encontrar el resto.';
        }
        field(40; Enabled; Boolean)
        {
            Caption = 'Activado';
            ToolTip = 'Muestra el FactBox de CRM en las fichas de cliente, proveedor y contacto.';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    var
        SecretTok: Label 'IKA-CRM-CLIENT-SECRET', Locked = true;
        NoSecretErr: Label 'Falta el secreto de cliente. Use "Establecer secreto" en la Configuración CRM.';
        NotConfiguredErr: Label 'Complete la Configuración CRM: URL del CRM, Tenant Id, Client Id y secreto.';

    procedure GetSetup()
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
    end;

    procedure IsConfigured(): Boolean
    begin
        exit(("Environment URL" <> '') and ("Tenant Id" <> '') and ("Client Id" <> '') and HasClientSecret());
    end;

    procedure TestConfigured()
    begin
        if not IsConfigured() then
            Error(NotConfiguredErr);
    end;

    procedure GetApiUrl(): Text
    begin
        exit("Environment URL" + '/api/data/' + "API Version");
    end;

    /// <summary>
    /// Enlace para abrir un registro en el CRM (interfaz unificada).
    /// </summary>
    procedure GetRecordUrl(EntityLogicalName: Text; RecordId: Guid): Text
    begin
        exit("Environment URL" + '/main.aspx?pagetype=entityrecord&etn=' + EntityLogicalName + '&id=' + DelChr(Format(RecordId), '=', '{}'));
    end;

    procedure SetClientSecret(NewSecret: Text)
    begin
        if NewSecret = '' then begin
            if IsolatedStorage.Contains(SecretTok, DataScope::Company) then
                IsolatedStorage.Delete(SecretTok, DataScope::Company);
            exit;
        end;
        if EncryptionEnabled() then
            IsolatedStorage.SetEncrypted(SecretTok, NewSecret, DataScope::Company)
        else
            IsolatedStorage.Set(SecretTok, NewSecret, DataScope::Company);
    end;

    [NonDebuggable]
    procedure GetClientSecret() Value: Text
    begin
        if not IsolatedStorage.Get(SecretTok, DataScope::Company, Value) then
            Error(NoSecretErr);
    end;

    procedure HasClientSecret(): Boolean
    begin
        exit(IsolatedStorage.Contains(SecretTok, DataScope::Company));
    end;
}
