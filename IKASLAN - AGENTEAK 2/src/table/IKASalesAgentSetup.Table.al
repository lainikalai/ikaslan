table 50000 "IKA Sales Agent Setup"
{
    Caption = 'Configuración agente de ventas (Claude)';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Clave primaria';
        }
        field(10; Enabled; Boolean)
        {
            Caption = 'Activado';
        }
        // --- Claude (Anthropic) ---
        field(20; "Claude Model"; Text[100])
        {
            Caption = 'Modelo Claude';
            InitValue = 'claude-opus-5-5';
        }
        field(30; "Claude Effort"; Enum "IKA Claude Effort")
        {
            Caption = 'Esfuerzo Claude';
            InitValue = Medium;
        }
        field(40; "Claude Max Tokens"; Integer)
        {
            Caption = 'Máx. tokens de respuesta';
            InitValue = 16000;
            MinValue = 1024;
        }
        field(50; "Claude Endpoint"; Text[250])
        {
            Caption = 'URL API Claude';
            InitValue = 'https://api.anthropic.com/v1/messages';
        }
        field(60; "Use Refusal Fallback"; Boolean)
        {
            Caption = 'Usar fallback de modelo ante rechazos';
            InitValue = true;
        }
        field(70; "Extra Instructions"; Text[2048])
        {
            Caption = 'Instrucciones adicionales para Claude';
        }
        field(80; "Claude Timeout (sec)"; Integer)
        {
            Caption = 'Timeout llamada Claude (seg)';
            InitValue = 300;
            MinValue = 30;
        }
        // --- Microsoft Graph / Outlook ---
        field(100; "Graph Tenant Id"; Text[100])
        {
            Caption = 'Tenant Id (Entra ID)';
        }
        field(110; "Graph Client Id"; Text[100])
        {
            Caption = 'Client Id (registro de aplicación)';
        }
        field(120; "Mail Account Code"; Code[20])
        {
            Caption = 'Cuenta de Outlook 365';
            TableRelation = "IKA Sales Mail Account";
            ToolTip = 'Cuenta (buzón) de la que se leen los pedidos. Se configura en "Cuentas de Outlook 365".';
        }
        field(140; "Processed Folder"; Text[100])
        {
            Caption = 'Carpeta procesados';
        }
        field(150; "Error Folder"; Text[100])
        {
            Caption = 'Carpeta errores';
        }
        field(160; "Only Unread"; Boolean)
        {
            Caption = 'Solo no leídos';
            InitValue = true;
        }
        field(170; "Max Emails per Run"; Integer)
        {
            Caption = 'Máx. emails por ejecución';
            InitValue = 20;
            MinValue = 1;
            MaxValue = 100;
        }
        field(180; "Mark as Read"; Boolean)
        {
            Caption = 'Marcar como leído al importar';
            InitValue = true;
        }
        field(190; "Max Attachment Size (KB)"; Integer)
        {
            Caption = 'Tamaño máx. adjunto (KB)';
            InitValue = 10240;
        }
        // --- Comportamiento ---
        field(200; "Auto Create Orders"; Boolean)
        {
            Caption = 'Crear pedidos automáticamente';
        }
        field(210; "Min. Confidence Auto Create"; Decimal)
        {
            Caption = 'Confianza mínima para auto-crear';
            InitValue = 0.9;
            MinValue = 0;
            MaxValue = 1;
            DecimalPlaces = 0 : 2;
        }
        field(220; "Allow Description Match"; Boolean)
        {
            Caption = 'Permitir buscar producto por descripción';
            InitValue = true;
        }
        field(230; "Unmatched Lines as Comments"; Boolean)
        {
            Caption = 'Líneas no identificadas como comentario';
            InitValue = true;
        }
        field(240; "Job Interval (min)"; Integer)
        {
            Caption = 'Intervalo cola de proyectos (min)';
            InitValue = 10;
            MinValue = 1;
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
        ClaudeApiKeyTok: Label 'IKA-SALESAGENT-CLAUDE-APIKEY', Locked = true;
        GraphSecretTok: Label 'IKA-SALESAGENT-GRAPH-SECRET', Locked = true;
        NotConfiguredErr: Label 'El agente de ventas no está configurado. Abra la página %1.', Comment = '%1 = setup page caption';

    procedure GetSetup()
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
    end;

    procedure TestSetupForClaude()
    begin
        GetSetup();
        TestField("Claude Model");
        TestField("Claude Endpoint");
        if not HasClaudeApiKey() then
            Error(NotConfiguredErr, TableCaption());
    end;

    procedure TestSetupForGraph()
    begin
        GetSetup();
        TestField("Mail Account Code");
    end;

    /// <summary>
    /// Credenciales generales de Graph (las usan las cuentas que no tienen credenciales propias).
    /// </summary>
    procedure TestGeneralCredentials()
    begin
        GetSetup();
        TestField("Graph Tenant Id");
        TestField("Graph Client Id");
        if not HasGraphClientSecret() then
            Error(NotConfiguredErr, TableCaption());
    end;

    [NonDebuggable]
    procedure SetClaudeApiKey(NewKey: Text)
    begin
        SetSecret(ClaudeApiKeyTok, NewKey);
    end;

    [NonDebuggable]
    procedure GetClaudeApiKey(): Text
    begin
        exit(GetSecret(ClaudeApiKeyTok));
    end;

    procedure HasClaudeApiKey(): Boolean
    begin
        exit(IsolatedStorage.Contains(ClaudeApiKeyTok, DataScope::Company));
    end;

    [NonDebuggable]
    procedure SetGraphClientSecret(NewSecret: Text)
    begin
        SetSecret(GraphSecretTok, NewSecret);
    end;

    [NonDebuggable]
    procedure GetGraphClientSecret(): Text
    begin
        exit(GetSecret(GraphSecretTok));
    end;

    procedure HasGraphClientSecret(): Boolean
    begin
        exit(IsolatedStorage.Contains(GraphSecretTok, DataScope::Company));
    end;

    procedure GetEffortText(): Text
    begin
        case "Claude Effort" of
            "Claude Effort"::Low:
                exit('low');
            "Claude Effort"::High:
                exit('high');
            "Claude Effort"::XHigh:
                exit('xhigh');
            "Claude Effort"::Max:
                exit('max');
            else
                exit('medium');
        end;
    end;

    [NonDebuggable]
    local procedure SetSecret(StorageKey: Text; Value: Text)
    begin
        if Value = '' then begin
            if IsolatedStorage.Contains(StorageKey, DataScope::Company) then
                IsolatedStorage.Delete(StorageKey, DataScope::Company);
            exit;
        end;
        if EncryptionEnabled() then
            IsolatedStorage.SetEncrypted(StorageKey, Value, DataScope::Company)
        else
            IsolatedStorage.Set(StorageKey, Value, DataScope::Company);
    end;

    [NonDebuggable]
    local procedure GetSecret(StorageKey: Text) Value: Text
    begin
        if not IsolatedStorage.Get(StorageKey, DataScope::Company, Value) then
            exit('');
    end;
}
