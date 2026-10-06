table 99136 "IKA DN Mail Account"
{
    // Cuenta de Outlook 365 que se muestra en BC: la del propio usuario o un buzón compartido.
    // Por defecto usa el registro de aplicación de la configuración general; una cuenta de otro
    // tenant de Microsoft 365 puede llevar sus propias credenciales de Entra ID.
    Caption = 'Cuenta de Outlook 365';
    DataClassification = CustomerContent;
    LookupPageId = "IKA DN Mail Accounts";
    DrillDownPageId = "IKA DN Mail Accounts";
    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Código';
            NotBlank = true;
        }
        field(10; Address; Text[250])
        {
            Caption = 'Dirección';
            ExtendedDatatype = EMail;
        }
        field(20; Description; Text[100])
        {
            Caption = 'Descripción';
        }
        field(25; "Account Type"; Enum "IKA DN Mail Account Type")
        {
            Caption = 'Tipo de cuenta';

            trigger OnValidate()
            begin
                if ("Account Type" = "Account Type"::Personal) and ("Restricted to User ID" = '') then
                    "Restricted to User ID" := CopyStr(UpperCase(UserId()), 1, MaxStrLen("Restricted to User ID"));
            end;
        }
        field(26; Enabled; Boolean)
        {
            Caption = 'Activa';
            InitValue = true;
        }
        field(30; Folder; Text[100])
        {
            Caption = 'Carpeta';
            InitValue = 'inbox';
            ToolTip = 'Carpeta que lee el agente: inbox o el nombre de una subcarpeta de la bandeja de entrada.';
        }
        field(40; "Restricted to User ID"; Code[50])
        {
            Caption = 'Solo para el usuario';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
            ValidateTableRelation = false;
            ToolTip = 'Vacío = buzón compartido visible para todos los usuarios con el permiso de la extensión.';
        }
        field(45; "Use Own Credentials"; Boolean)
        {
            Caption = 'Credenciales propias';
            ToolTip = 'Actívelo para una cuenta de otro tenant de Microsoft 365: se usarán el Tenant Id, Client Id y secreto de esta cuenta en lugar de los de la configuración general.';
        }
        field(46; "Tenant Id"; Text[100])
        {
            Caption = 'Tenant Id (Entra ID)';
        }
        field(47; "Client Id"; Text[100])
        {
            Caption = 'Client Id (registro de aplicación)';
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    begin
        SetClientSecret('');
    end;

    var
        NoAccessErr: Label 'No tiene acceso al buzón %1.', Comment = '%1 = mailbox code';
        NoUserEmailErr: Label 'El usuario %1 no tiene email de autenticación ni de contacto en la ficha de usuario.', Comment = '%1 = user id';
        AccountExistsMsg: Label 'Ya existe la cuenta %1 para %2.', Comment = '%1 = code, %2 = address';
        SecretTok: Label 'IKA-DN-MAIL-SECRET-%1', Locked = true, Comment = '%1 = mailbox code';

    /// <summary>
    /// Crea la cuenta personal del usuario actual a partir del email de su ficha de usuario de BC.
    /// </summary>
    procedure AddCurrentUserAccount(): Code[20]
    var
        User: Record User;
        Mailbox: Record "IKA DN Mail Account";
        Email: Text;
        NewCode: Code[20];
        BaseCode: Code[20];
        Counter: Integer;
    begin
        User.SetRange("User Security ID", UserSecurityId());
        if User.FindFirst() then begin
            Email := User."Authentication Email";
            if Email = '' then
                Email := User."Contact Email";
        end;
        if Email = '' then
            Error(NoUserEmailErr, UserId());

        Mailbox.SetRange(Address, CopyStr(Email, 1, MaxStrLen(Mailbox.Address)));
        if Mailbox.FindFirst() then begin
            Message(AccountExistsMsg, Mailbox.Code, Mailbox.Address);
            exit(Mailbox.Code);
        end;

        NewCode := CopyStr(UpperCase(DelChr(CopyStr(Email, 1, StrPos(Email, '@') - 1), '=', '.-_ ')), 1, MaxStrLen(NewCode));
        if NewCode = '' then
            NewCode := CopyStr(UpperCase(UserId()), 1, MaxStrLen(NewCode));
        BaseCode := CopyStr(NewCode, 1, 17);
        while Mailbox.Get(NewCode) do begin
            Counter += 1;
            NewCode := CopyStr(BaseCode + Format(Counter), 1, MaxStrLen(NewCode));
        end;

        Mailbox.Init();
        Mailbox.Code := NewCode;
        Mailbox.Address := CopyStr(Email, 1, MaxStrLen(Mailbox.Address));
        Mailbox.Description := CopyStr(User."Full Name", 1, MaxStrLen(Mailbox.Description));
        Mailbox."Account Type" := Mailbox."Account Type"::Personal;
        Mailbox."Restricted to User ID" := CopyStr(UpperCase(UserId()), 1, MaxStrLen(Mailbox."Restricted to User ID"));
        Mailbox.Insert(true);
        exit(Mailbox.Code);
    end;

    [NonDebuggable]
    procedure SetClientSecret(NewSecret: Text)
    var
        StorageKey: Text;
    begin
        StorageKey := StrSubstNo(SecretTok, Code);
        if NewSecret = '' then begin
            if IsolatedStorage.Contains(StorageKey, DataScope::Company) then
                IsolatedStorage.Delete(StorageKey, DataScope::Company);
            exit;
        end;
        if EncryptionEnabled() then
            IsolatedStorage.SetEncrypted(StorageKey, NewSecret, DataScope::Company)
        else
            IsolatedStorage.Set(StorageKey, NewSecret, DataScope::Company);
    end;

    [NonDebuggable]
    procedure GetClientSecret() Value: Text
    begin
        if not IsolatedStorage.Get(StrSubstNo(SecretTok, Code), DataScope::Company, Value) then
            exit('');
    end;

    procedure HasClientSecret(): Boolean
    begin
        exit(IsolatedStorage.Contains(StrSubstNo(SecretTok, Code), DataScope::Company));
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

    /// <summary>
    /// Filtro con los códigos de buzón visibles para el usuario actual ('' si no tiene ninguno).
    /// </summary>
    procedure GetAllowedFilter(): Text
    var
        Mailbox: Record "IKA DN Mail Account";
        Result: Text;
    begin
        if Mailbox.FindSet() then
            repeat
                if Mailbox.Enabled and Mailbox.HasAccess() then begin
                    if Result <> '' then
                        Result += '|';
                    Result += '''' + Mailbox.Code + '''';
                end;
            until Mailbox.Next() = 0;
        exit(Result);
    end;
}
