table 99306 "IKA WA Account"
{
    // Número de WhatsApp Business dado de alta en la plataforma de Meta (Cloud API).
    // Misma filosofía que las cuentas de Outlook 365 de AGENTEAK 2/3/4: código, datos de la cuenta,
    // credencial en Isolated Storage, acceso opcional restringido a un usuario y prueba de conexión.
    Caption = 'Cuenta de WhatsApp Business';
    DataClassification = CustomerContent;
    LookupPageId = "IKA WA Accounts";
    DrillDownPageId = "IKA WA Accounts";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Código';
            NotBlank = true;
        }
        field(10; Description; Text[100])
        {
            Caption = 'Descripción';
        }
        field(20; "Display Phone Number"; Text[30])
        {
            Caption = 'Número visible';
            ToolTip = 'Número de WhatsApp de la empresa tal como lo ven los clientes, p.ej. +34 600 123 456.';
        }
        field(30; "Phone Number ID"; Text[50])
        {
            Caption = 'Phone Number ID (Meta)';
            ToolTip = 'Identificador del número en WhatsApp Manager / Meta for Developers (no es el número de teléfono).';
        }
        field(40; "Business Account ID"; Text[50])
        {
            Caption = 'WhatsApp Business Account ID';
            ToolTip = 'Id de la cuenta de WhatsApp Business (WABA). Necesario para sincronizar las plantillas.';
        }
        field(50; Enabled; Boolean)
        {
            Caption = 'Activa';
            InitValue = true;
        }
        field(60; "Restricted to User ID"; Code[50])
        {
            Caption = 'Solo para el usuario';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
            ToolTip = 'Vacío = cuenta compartida, visible para todos los usuarios con el permiso de la extensión.';
        }
        field(70; "Last Template Sync"; DateTime)
        {
            Caption = 'Última sincronización de plantillas';
            Editable = false;
        }
        field(80; "No. of Conversations"; Integer)
        {
            Caption = 'Nº conversaciones';
            FieldClass = FlowField;
            CalcFormula = count("IKA WA Conversation" where("Account Code" = field(Code)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
        key(PhoneNumberId; "Phone Number ID")
        {
        }
    }

    trigger OnDelete()
    begin
        SetAccessToken('');
    end;

    var
        TokenTok: Label 'IKA-WA-TOKEN-%1', Locked = true, Comment = '%1 = account code';
        NoAccessErr: Label 'No tiene acceso a la cuenta de WhatsApp %1.', Comment = '%1 = account code';
        NoTokenErr: Label 'La cuenta de WhatsApp %1 no tiene token de acceso. Use "Establecer token".', Comment = '%1 = account code';

    /// <summary>
    /// Token de acceso de Meta. Debe ser un token permanente de un "usuario del sistema" de
    /// Meta Business Manager con los permisos whatsapp_business_messaging y whatsapp_business_management.
    /// </summary>
    [NonDebuggable]
    procedure SetAccessToken(NewToken: Text)
    var
        StorageKey: Text;
    begin
        StorageKey := StrSubstNo(TokenTok, Code);
        if NewToken = '' then begin
            if IsolatedStorage.Contains(StorageKey, DataScope::Company) then
                IsolatedStorage.Delete(StorageKey, DataScope::Company);
            exit;
        end;
        if EncryptionEnabled() then
            IsolatedStorage.SetEncrypted(StorageKey, NewToken, DataScope::Company)
        else
            IsolatedStorage.Set(StorageKey, NewToken, DataScope::Company);
    end;

    [NonDebuggable]
    procedure GetAccessToken() Value: Text
    begin
        if not IsolatedStorage.Get(StrSubstNo(TokenTok, Code), DataScope::Company, Value) then
            Error(NoTokenErr, Code);
    end;

    procedure HasAccessToken(): Boolean
    begin
        exit(IsolatedStorage.Contains(StrSubstNo(TokenTok, Code), DataScope::Company));
    end;

    procedure HasAccess(): Boolean
    begin
        exit(("Restricted to User ID" = '') or ("Restricted to User ID" = UpperCase(UserId())));
    end;

    procedure CheckAccess()
    begin
        if not HasAccess() then
            Error(NoAccessErr, Code);
    end;

    procedure GetAllowedFilter(): Text
    var
        Account: Record "IKA WA Account";
        Result: Text;
    begin
        if Account.FindSet() then
            repeat
                if Account.Enabled and Account.HasAccess() then begin
                    if Result <> '' then
                        Result += '|';
                    Result += '''' + Account.Code + '''';
                end;
            until Account.Next() = 0;
        exit(Result);
    end;

    /// <summary>
    /// Cuenta a usar por defecto: la de la configuración o, si no, la primera activa a la que se tiene acceso.
    /// </summary>
    procedure GetDefault(): Boolean
    var
        Setup: Record "IKA WA Setup";
    begin
        Setup.GetSetup();
        if Setup."Default Account Code" <> '' then
            if Get(Setup."Default Account Code") then
                if Enabled and HasAccess() then
                    exit(true);
        Reset();
        SetRange(Enabled, true);
        if FindSet() then
            repeat
                if HasAccess() then
                    exit(true);
            until Next() = 0;
        exit(false);
    end;
}
