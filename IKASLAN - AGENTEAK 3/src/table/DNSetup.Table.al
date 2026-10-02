table 50200 "IKA DN Setup"
{
    Caption = 'Configuración agente de albaranes (Claude)';
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
        // --- Claude ---
        field(20; "Claude Model"; Text[100])
        {
            Caption = 'Modelo Claude';
            InitValue = 'claude-opus-5-5';
        }
        field(30; "Claude Effort"; Enum "IKA DN Claude Effort")
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
            Caption = 'Instrucciones generales adicionales';
        }
        field(80; "Claude Timeout (sec)"; Integer)
        {
            Caption = 'Timeout llamada Claude (seg)';
            InitValue = 300;
            MinValue = 30;
        }
        // --- Microsoft Graph (común a correo y carpeta) ---
        field(100; "Graph Tenant Id"; Text[100])
        {
            Caption = 'Tenant Id (Entra ID)';
        }
        field(110; "Graph Client Id"; Text[100])
        {
            Caption = 'Client Id (registro de aplicación)';
        }
        // --- Correo ---
        field(120; "Mail Enabled"; Boolean)
        {
            Caption = 'Leer buzón de correo';
        }
        field(121; "Mailbox Address"; Text[250])
        {
            Caption = 'Buzón a leer';
            ExtendedDatatype = EMail;
        }
        field(122; "Mail Source Folder"; Text[100])
        {
            Caption = 'Carpeta origen (correo)';
            InitValue = 'inbox';
        }
        field(123; "Mail Processed Folder"; Text[100])
        {
            Caption = 'Carpeta procesados (correo)';
        }
        field(124; "Mail Error Folder"; Text[100])
        {
            Caption = 'Carpeta errores (correo)';
        }
        field(125; "Only Unread"; Boolean)
        {
            Caption = 'Solo no leídos';
            InitValue = true;
        }
        field(126; "Mark as Read"; Boolean)
        {
            Caption = 'Marcar como leído al importar';
            InitValue = true;
        }
        field(127; "Accept Unknown Senders"; Boolean)
        {
            Caption = 'Aceptar remitentes sin plantilla';
            ToolTip = 'Si está activo, se importan también emails de remitentes sin plantilla de proveedor cuyo asunto cumpla el filtro genérico.';
        }
        field(128; "Generic Subject Filter"; Text[250])
        {
            Caption = 'Filtro de asunto genérico';
            InitValue = '*albar*';
        }
        // --- Carpeta (SharePoint / OneDrive) ---
        field(140; "Folder Enabled"; Boolean)
        {
            Caption = 'Leer carpeta de ficheros';
        }
        field(141; "Drive Site"; Text[250])
        {
            Caption = 'Sitio SharePoint';
            ToolTip = 'Formato: empresa.sharepoint.com:/sites/Compras. Se usa para obtener el Drive Id si este está vacío.';
        }
        field(142; "Drive Id"; Text[250])
        {
            Caption = 'Drive Id';
        }
        field(143; "Folder Inbox Path"; Text[250])
        {
            Caption = 'Ruta carpeta entrada';
            ToolTip = 'Ruta dentro de la biblioteca, p.ej. Albaranes/Entrada';
        }
        field(144; "Folder Processed Path"; Text[250])
        {
            Caption = 'Ruta carpeta procesados';
        }
        field(145; "Folder Error Path"; Text[250])
        {
            Caption = 'Ruta carpeta errores';
        }
        // --- Límites ---
        field(170; "Max Documents per Run"; Integer)
        {
            Caption = 'Máx. documentos por ejecución';
            InitValue = 20;
            MinValue = 1;
            MaxValue = 100;
        }
        field(180; "Max Attachment Size (KB)"; Integer)
        {
            Caption = 'Tamaño máx. fichero (KB)';
            InitValue = 20480;
        }
        // --- Conciliación ---
        field(200; "Price Tolerance %"; Decimal)
        {
            Caption = '% tolerancia precio';
            InitValue = 0.5;
            DecimalPlaces = 0 : 2;
            MinValue = 0;
        }
        field(210; "Allow Over-Receipt"; Boolean)
        {
            Caption = 'Permitir recibir más que lo pendiente';
        }
        field(220; "Search Other Open Orders"; Boolean)
        {
            Caption = 'Buscar en otros pedidos abiertos del proveedor';
            InitValue = true;
            ToolTip = 'Si una línea no indica pedido o no está en el pedido indicado, buscar el producto en otros pedidos abiertos del mismo proveedor.';
        }
        field(230; "Allow Description Match"; Boolean)
        {
            Caption = 'Permitir buscar producto por descripción';
            InitValue = true;
        }
        field(240; "Min. Confidence"; Decimal)
        {
            Caption = 'Confianza mínima';
            InitValue = 0.9;
            MinValue = 0;
            MaxValue = 1;
            DecimalPlaces = 0 : 2;
        }
        // --- Aplicación al pedido ---
        field(300; "Auto Apply to Orders"; Boolean)
        {
            Caption = 'Aplicar automáticamente a pedidos';
            ToolTip = 'Si el albarán queda conciliado sin discrepancias, rellena "Cant. a recibir" y "Nº albarán proveedor" en los pedidos de compra.';
        }
        field(310; "Reset Qty. to Receive"; Boolean)
        {
            Caption = 'Poner a 0 "Cant. a recibir" del resto de líneas';
            InitValue = true;
        }
        field(320; "Auto Post Receipt"; Boolean)
        {
            Caption = 'Registrar recepción automáticamente';
            ToolTip = 'Tras aplicar el albarán, registra la recepción (sin factura). Recomendado solo cuando el proceso esté muy probado.';
        }
        field(330; "Job Interval (min)"; Integer)
        {
            Caption = 'Intervalo cola de proyectos (min)';
            InitValue = 15;
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
        ClaudeApiKeyTok: Label 'IKA-DNAGENT-CLAUDE-APIKEY', Locked = true;
        GraphSecretTok: Label 'IKA-DNAGENT-GRAPH-SECRET', Locked = true;
        NotConfiguredErr: Label 'Falta configurar la clave o secreto en la página %1.', Comment = '%1 = setup caption';

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
