table 99206 "IKA Mail Mailbox"
{
    // Cuenta de Outlook 365 que se muestra en BC: la del propio usuario o un buzón compartido.
    // Por defecto usa el registro de aplicación de la configuración general; una cuenta de otro
    // tenant de Microsoft 365 puede llevar sus propias credenciales de Entra ID.
    Caption = 'Cuenta de Outlook 365';
    DataClassification = CustomerContent;
    LookupPageId = "IKA Mail Mailboxes";
    DrillDownPageId = "IKA Mail Mailboxes";

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
        field(25; "Account Type"; Enum "IKA Mail Account Type")
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
            ToolTip = 'Carpeta que se muestra al abrir la bandeja: elíjala de la lista de carpetas de Outlook, o escriba inbox, sentitems, archive... o el nombre de una subcarpeta de la bandeja de entrada.';

            trigger OnValidate()
            begin
                SetFolderId(FindFolderIdByName(Folder));
            end;
        }
        field(31; "Folder Id"; Text[250])
        {
            Caption = 'Id carpeta (Graph)';
            Editable = false;
            ToolTip = 'Id de Outlook de la carpeta por defecto. Se obtiene al elegir la carpeta o en la primera sincronización.';
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
        field(50; "Last Sync At"; DateTime)
        {
            Caption = 'Última sincronización';
            Editable = false;
        }
        field(60; "No. of Messages"; Integer)
        {
            Caption = 'Nº emails';
            FieldClass = FlowField;
            CalcFormula = count("IKA Mail Message" where("Mailbox Code" = field(Code)));
            Editable = false;
        }
        field(61; "No. of Unread"; Integer)
        {
            Caption = 'No leídos';
            FieldClass = FlowField;
            CalcFormula = count("IKA Mail Message" where("Mailbox Code" = field(Code), "Is Read" = const(false)));
            Editable = false;
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
    var
        MailMessage: Record "IKA Mail Message";
        MailFolder: Record "IKA Mail Folder";
    begin
        MailMessage.SetRange("Mailbox Code", Code);
        MailMessage.DeleteAll(true);
        MailFolder.SetRange("Mailbox Code", Code);
        MailFolder.DeleteAll();
        SetClientSecret('');
    end;

    /// <summary>
    /// Cambia la carpeta por defecto. Los emails guardados sin carpeta (anteriores al selector de carpetas)
    /// eran de la carpeta por defecto anterior: se les asigna antes del cambio.
    /// </summary>
    procedure SetFolderId(NewFolderId: Text)
    var
        MailMessage: Record "IKA Mail Message";
    begin
        if NewFolderId = "Folder Id" then
            exit;
        if "Folder Id" <> '' then begin
            MailMessage.SetRange("Mailbox Code", Code);
            MailMessage.SetRange("Folder Id", '');
            MailMessage.ModifyAll("Folder Id", "Folder Id");
        end;
        "Folder Id" := CopyStr(NewFolderId, 1, MaxStrLen("Folder Id"));
    end;

    /// <summary>
    /// Id de la carpeta ya descargada con esa ruta o, si el nombre es único, con ese nombre. '' si no se sabe:
    /// se resolverá con Graph en la próxima sincronización.
    /// </summary>
    local procedure FindFolderIdByName(FolderName: Text): Text[250]
    var
        MailFolder: Record "IKA Mail Folder";
    begin
        if FolderName = '' then
            exit('');
        MailFolder.SetRange("Mailbox Code", Code);
        MailFolder.SetRange(Path, CopyStr(FolderName, 1, MaxStrLen(MailFolder.Path)));
        if MailFolder.FindFirst() then
            exit(MailFolder."Folder Id");
        MailFolder.SetRange(Path);
        MailFolder.SetRange("Display Name", CopyStr(FolderName, 1, MaxStrLen(MailFolder."Display Name")));
        if MailFolder.Count() = 1 then begin
            MailFolder.FindFirst();
            exit(MailFolder."Folder Id");
        end;
        exit('');
    end;

    var
        NoAccessErr: Label 'No tiene acceso al buzón %1.', Comment = '%1 = mailbox code';
        NoUserEmailErr: Label 'No se encuentra un email válido para el usuario %1. Rellene "Email de autenticación" o "Email de contacto" en la ficha de Usuarios, o "Correo electrónico" en Configuración de usuarios; o dé de alta la cuenta a mano con su dirección.', Comment = '%1 = user id';
        AccountExistsMsg: Label 'Ya existe la cuenta %1 para %2.', Comment = '%1 = code, %2 = address';
        SecretTok: Label 'IKA-MAIL-SECRET-%1', Locked = true, Comment = '%1 = mailbox code';

    /// <summary>
    /// Crea la cuenta personal del usuario actual a partir del email de su ficha de usuario de BC.
    /// </summary>
    procedure AddCurrentUserAccount(): Code[20]
    var
        User: Record User;
        Mailbox: Record "IKA Mail Mailbox";
        Email: Text;
        NewCode: Code[20];
        BaseCode: Code[20];
        Counter: Integer;
    begin
        Email := GetCurrentUserEmail();
        if Email = '' then
            Error(NoUserEmailErr, UserId());

        Mailbox.SetRange(Address, CopyStr(Email, 1, MaxStrLen(Mailbox.Address)));
        if Mailbox.FindFirst() then begin
            Message(AccountExistsMsg, Mailbox.Code, Mailbox.Address);
            exit(Mailbox.Code);
        end;

        // Código a partir de la parte anterior a la @ (solo letras y números)
        NewCode := CopyStr(OnlyLettersAndDigits(CopyStr(Email, 1, StrPos(Email, '@') - 1)), 1, MaxStrLen(NewCode));
        if NewCode = '' then
            NewCode := CopyStr(OnlyLettersAndDigits(UserId()), 1, MaxStrLen(NewCode));
        if NewCode = '' then
            NewCode := 'MICUENTA';
        BaseCode := CopyStr(NewCode, 1, 17);
        while Mailbox.Get(NewCode) do begin
            Counter += 1;
            NewCode := CopyStr(BaseCode + Format(Counter), 1, MaxStrLen(NewCode));
        end;

        User.SetRange("User Security ID", UserSecurityId());
        if User.FindFirst() then;
        Mailbox.Init();
        Mailbox.Code := NewCode;
        Mailbox.Address := CopyStr(Email, 1, MaxStrLen(Mailbox.Address));
        Mailbox.Description := CopyStr(User."Full Name", 1, MaxStrLen(Mailbox.Description));
        Mailbox."Account Type" := Mailbox."Account Type"::Personal;
        Mailbox."Restricted to User ID" := CopyStr(UpperCase(UserId()), 1, MaxStrLen(Mailbox."Restricted to User ID"));
        Mailbox.Insert(true);
        exit(Mailbox.Code);
    end;

    /// <summary>
    /// Primer email válido (con @) del usuario actual: email de autenticación, email de contacto
    /// o el correo electrónico de "Configuración de usuarios". '' si no tiene ninguno.
    /// </summary>
    procedure GetCurrentUserEmail(): Text
    var
        User: Record User;
        UserSetup: Record "User Setup";
    begin
        User.SetRange("User Security ID", UserSecurityId());
        if User.FindFirst() then begin
            if IsValidEmail(User."Authentication Email") then
                exit(DelChr(User."Authentication Email", '<>', ' '));
            if IsValidEmail(User."Contact Email") then
                exit(DelChr(User."Contact Email", '<>', ' '));
        end;
        if UserSetup.Get(UserId()) then
            if IsValidEmail(UserSetup."E-Mail") then
                exit(DelChr(UserSetup."E-Mail", '<>', ' '));
        exit('');
    end;

    local procedure IsValidEmail(Email: Text): Boolean
    var
        AtPos: Integer;
    begin
        Email := DelChr(Email, '<>', ' ');
        AtPos := StrPos(Email, '@');
        exit((AtPos > 1) and (AtPos < StrLen(Email)) and (StrPos(Email, ' ') = 0));
    end;

    local procedure OnlyLettersAndDigits(Value: Text): Text
    var
        Result: Text;
        Ch: Text[1];
        i: Integer;
    begin
        Value := UpperCase(Value);
        for i := 1 to StrLen(Value) do begin
            Ch := CopyStr(Value, i, 1);
            if Ch in ['A' .. 'Z', '0' .. '9'] then
                Result += Ch;
        end;
        exit(Result);
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
        Mailbox: Record "IKA Mail Mailbox";
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
