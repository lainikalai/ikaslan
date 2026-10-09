table 99001 "IKA Sales Agent Setup"
{
    Caption = 'Configuración agentes (Claude)';
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
        field(90; "Anthropic Workspace Id"; Text[50])
        {
            Caption = 'Workspace de Anthropic (Id)';
            ToolTip = 'Id del workspace (wrkspc_...) donde está la API key de los agentes: Console > Settings > Workspaces. Se usa para comparar solo el coste de ese workspace. Vacío = toda la organización.';
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
        // =====================================================================
        // Albaranes de proveedor (agente de recepción)
        // =====================================================================
        field(300; "DN Enabled"; Boolean)
        {
            Caption = 'Agente de albaranes activado';
        }
        field(310; "DN Mail Enabled"; Boolean)
        {
            Caption = 'Leer buzón de albaranes';
            InitValue = true;
        }
        field(311; "DN Mail Account Code"; Code[20])
        {
            Caption = 'Cuenta de Outlook 365 (albaranes)';
            TableRelation = "IKA Sales Mail Account";
            ToolTip = 'Cuenta (buzón) de la que se leen los albaranes. Puede ser la misma que la de pedidos: los filtros de correo deciden qué es cada email.';
        }
        field(312; "DN Processed Folder"; Text[100])
        {
            Caption = 'Carpeta procesados (albaranes)';
        }
        field(313; "DN Error Folder"; Text[100])
        {
            Caption = 'Carpeta errores (albaranes)';
        }
        field(314; "DN Only Unread"; Boolean)
        {
            Caption = 'Solo no leídos (albaranes)';
            InitValue = true;
        }
        field(315; "DN Mark as Read"; Boolean)
        {
            Caption = 'Marcar como leído (albaranes)';
            InitValue = true;
        }
        field(320; "DN Folder Enabled"; Boolean)
        {
            Caption = 'Leer carpeta de ficheros';
        }
        field(321; "Drive Site"; Text[250])
        {
            Caption = 'Sitio SharePoint';
            ToolTip = 'Formato: empresa.sharepoint.com:/sites/Compras. Se usa para obtener el Drive Id si este está vacío.';
        }
        field(322; "Drive Id"; Text[250])
        {
            Caption = 'Drive Id';
        }
        field(323; "Folder Inbox Path"; Text[250])
        {
            Caption = 'Ruta carpeta entrada';
            ToolTip = 'Ruta dentro de la biblioteca, p.ej. Albaranes/Entrada';
        }
        field(324; "Folder Processed Path"; Text[250])
        {
            Caption = 'Ruta carpeta procesados';
        }
        field(325; "Folder Error Path"; Text[250])
        {
            Caption = 'Ruta carpeta errores';
        }
        field(330; "DN Max Documents per Run"; Integer)
        {
            Caption = 'Máx. documentos por ejecución (albaranes)';
            InitValue = 20;
            MinValue = 1;
            MaxValue = 100;
        }
        field(331; "DN Max File Size (KB)"; Integer)
        {
            Caption = 'Tamaño máx. fichero (KB) (albaranes)';
            InitValue = 20480;
        }
        field(340; "Price Tolerance %"; Decimal)
        {
            Caption = '% tolerancia precio';
            InitValue = 0.5;
            DecimalPlaces = 0 : 2;
            MinValue = 0;
        }
        field(341; "Allow Over-Receipt"; Boolean)
        {
            Caption = 'Permitir recibir más que lo pendiente';
        }
        field(342; "Search Other Open Orders"; Boolean)
        {
            Caption = 'Buscar en otros pedidos abiertos del proveedor';
            InitValue = true;
            ToolTip = 'Si una línea no indica pedido o no está en el pedido indicado, buscar el producto en otros pedidos abiertos del mismo proveedor.';
        }
        field(343; "DN Allow Description Match"; Boolean)
        {
            Caption = 'Permitir buscar producto por descripción (albaranes)';
            InitValue = true;
        }
        field(344; "DN Min. Confidence"; Decimal)
        {
            Caption = 'Confianza mínima (albaranes)';
            InitValue = 0.9;
            MinValue = 0;
            MaxValue = 1;
            DecimalPlaces = 0 : 2;
        }
        field(350; "Auto Apply to Orders"; Boolean)
        {
            Caption = 'Aplicar automáticamente a pedidos de compra';
            ToolTip = 'Si el albarán queda conciliado sin discrepancias, rellena "Cant. a recibir" y "Nº albarán proveedor" en los pedidos de compra.';
        }
        field(351; "Reset Qty. to Receive"; Boolean)
        {
            Caption = 'Poner a 0 "Cant. a recibir" del resto de líneas';
            InitValue = true;
        }
        field(352; "Auto Post Receipt"; Boolean)
        {
            Caption = 'Registrar recepción automáticamente';
            ToolTip = 'Tras aplicar el albarán, registra la recepción (sin factura). Recomendado solo cuando el proceso esté muy probado.';
        }
        field(360; "DN Job Interval (min)"; Integer)
        {
            Caption = 'Intervalo cola de proyectos (min) (albaranes)';
            InitValue = 15;
            MinValue = 1;
        }
        field(370; "DN Extra Instructions"; Text[2048])
        {
            Caption = 'Instrucciones adicionales para Claude (albaranes)';
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
        AdminKeyTok: Label 'IKA-AGENTS-ANTHROPIC-ADMINKEY', Locked = true;
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

    /// <summary>
    /// Admin API key de Anthropic (sk-ant-admin01-...): solo para leer los informes de uso y coste reales.
    /// Los agentes no la usan para llamar a Claude.
    /// </summary>
    [NonDebuggable]
    procedure SetAdminApiKey(NewKey: Text)
    begin
        SetSecret(AdminKeyTok, NewKey);
    end;

    [NonDebuggable]
    procedure GetAdminApiKey(): Text
    begin
        exit(GetSecret(AdminKeyTok));
    end;

    procedure HasAdminApiKey(): Boolean
    begin
        exit(IsolatedStorage.Contains(AdminKeyTok, DataScope::Company));
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
