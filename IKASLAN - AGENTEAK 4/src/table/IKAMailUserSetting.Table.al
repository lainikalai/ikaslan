table 99251 "IKA Mail User Setting"
{
    // Preferencias de cada usuario en la vista tipo Outlook: panel de lectura visible o no,
    // y la cuenta y la carpeta que tenía abiertas (para volver a ellas).
    Caption = 'Preferencias de correo del usuario';
    DataClassification = EndUserIdentifiableInformation;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'Usuario';
        }
        field(10; "Hide Reading Pane"; Boolean)
        {
            Caption = 'Ocultar panel de lectura';
        }
        field(20; "Last Mailbox Code"; Code[20])
        {
            Caption = 'Última cuenta';
            TableRelation = "IKA Mail Mailbox";
        }
        field(21; "Last Folder Id"; Text[250])
        {
            Caption = 'Última carpeta (Id Graph)';
        }
    }

    keys
    {
        key(PK; "User ID")
        {
            Clustered = true;
        }
    }

    procedure GetForCurrentUser()
    begin
        if Get(CopyStr(UserId(), 1, MaxStrLen("User ID"))) then
            exit;
        Init();
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        Insert();
    end;
}
