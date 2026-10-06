table 99201 "IKA Mail Setup"
{
    Caption = 'Configuración correo Outlook';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Clave primaria';
        }
        field(10; "Graph Tenant Id"; Text[100])
        {
            Caption = 'Tenant Id (Entra ID)';
        }
        field(20; "Graph Client Id"; Text[100])
        {
            Caption = 'Client Id (registro de aplicación)';
        }
        field(30; "Default Mailbox Code"; Code[20])
        {
            Caption = 'Buzón por defecto';
            TableRelation = "IKA Mail Mailbox";
        }
        field(40; "Messages per Sync"; Integer)
        {
            Caption = 'Emails por sincronización';
            InitValue = 50;
            MinValue = 1;
            MaxValue = 500;
        }
        field(50; "Mark as Read on Open"; Boolean)
        {
            Caption = 'Marcar como leído al abrir';
            InitValue = true;
        }
        field(60; "Load Inline Images"; Boolean)
        {
            Caption = 'Mostrar imágenes incrustadas';
            InitValue = true;
        }
        field(61; "Max Inline Image (KB)"; Integer)
        {
            Caption = 'Tamaño máx. imagen incrustada (KB)';
            InitValue = 500;
        }
        field(70; "Block Remote Images"; Boolean)
        {
            Caption = 'Bloquear imágenes externas';
            InitValue = true;
            ToolTip = 'Evita que el email cargue imágenes de internet (píxeles de seguimiento). Las imágenes incrustadas sí se muestran.';
        }
        field(80; "Max Attach Size (MB)"; Integer)
        {
            Caption = 'Tamaño máx. para adjuntar a entidad (MB)';
            InitValue = 25;
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
        GraphSecretTok: Label 'IKA-MAIL-GRAPH-SECRET', Locked = true;
        NotConfiguredErr: Label 'Falta configurar Microsoft Graph en la página %1.', Comment = '%1 = setup caption';

    procedure GetSetup()
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
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
    procedure SetGraphClientSecret(NewSecret: Text)
    begin
        if NewSecret = '' then begin
            if IsolatedStorage.Contains(GraphSecretTok, DataScope::Company) then
                IsolatedStorage.Delete(GraphSecretTok, DataScope::Company);
            exit;
        end;
        if EncryptionEnabled() then
            IsolatedStorage.SetEncrypted(GraphSecretTok, NewSecret, DataScope::Company)
        else
            IsolatedStorage.Set(GraphSecretTok, NewSecret, DataScope::Company);
    end;

    [NonDebuggable]
    procedure GetGraphClientSecret() Value: Text
    begin
        if not IsolatedStorage.Get(GraphSecretTok, DataScope::Company, Value) then
            exit('');
    end;

    procedure HasGraphClientSecret(): Boolean
    begin
        exit(IsolatedStorage.Contains(GraphSecretTok, DataScope::Company));
    end;
}
