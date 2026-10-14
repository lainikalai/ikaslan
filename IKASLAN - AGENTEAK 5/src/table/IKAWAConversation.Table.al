table 99321 "IKA WA Conversation"
{
    // Una conversación = un número de teléfono de cliente/proveedor/contacto en una cuenta de WhatsApp.
    Caption = 'Conversación de WhatsApp';
    DataClassification = CustomerContent;
    LookupPageId = "IKA WA Conversations";
    DrillDownPageId = "IKA WA Conversations";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº mov.';
            AutoIncrement = true;
        }
        field(2; "Account Code"; Code[20])
        {
            Caption = 'Cuenta';
            TableRelation = "IKA WA Account";
        }
        field(3; "Phone No."; Text[30])
        {
            Caption = 'Teléfono (WhatsApp)';
            ToolTip = 'Número en formato internacional sin "+" ni espacios, p.ej. 34600123456.';
        }
        field(4; "Profile Name"; Text[100])
        {
            Caption = 'Nombre en WhatsApp';
        }
        field(10; "Entity Type"; Enum "IKA WA Entity Type")
        {
            Caption = 'Tipo de entidad';

            trigger OnValidate()
            begin
                if "Entity Type" <> xRec."Entity Type" then
                    SetEntity("Entity Type", '');
            end;
        }
        field(11; "Entity No."; Code[20])
        {
            Caption = 'Nº entidad';
            TableRelation = if ("Entity Type" = const(Customer)) Customer
            else
            if ("Entity Type" = const(Vendor)) Vendor
            else
            if ("Entity Type" = const(Contact)) Contact
            else
            if ("Entity Type" = const(SalespersonPurchaser)) "Salesperson/Purchaser";

            trigger OnValidate()
            begin
                SetEntity("Entity Type", "Entity No.");
            end;
        }
        field(12; "Entity Name"; Text[100])
        {
            Caption = 'Nombre entidad';
            Editable = false;
        }
        field(13; "Salesperson Code"; Code[20])
        {
            Caption = 'Comercial asignado';
            TableRelation = "Salesperson/Purchaser";
            ToolTip = 'Comercial responsable de la conversación: el vendedor del cliente o contacto, o el comprador del proveedor. Se rellena al vincular la entidad y se puede cambiar.';
        }
        field(20; "Last Message At"; DateTime)
        {
            Caption = 'Último mensaje';
        }
        field(21; "Last Inbound At"; DateTime)
        {
            Caption = 'Último mensaje del cliente';
            ToolTip = 'Durante 24 horas desde este momento se puede responder con texto libre y ficheros; después, solo con plantillas.';
        }
        field(22; "Last Message Preview"; Text[250])
        {
            Caption = 'Último mensaje (texto)';
        }
        field(23; "No. of Unread"; Integer)
        {
            Caption = 'No leídos';
        }
        field(30; "No. of Messages"; Integer)
        {
            Caption = 'Nº mensajes';
            FieldClass = FlowField;
            CalcFormula = count("IKA WA Message" where("Conversation Entry No." = field("Entry No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Phone; "Account Code", "Phone No.")
        {
        }
        key(LastMessage; "Last Message At")
        {
        }
        key(Entity; "Entity Type", "Entity No.")
        {
        }
        key(Salesperson; "Salesperson Code", "Last Message At")
        {
        }
    }

    trigger OnDelete()
    var
        WAMessage: Record "IKA WA Message";
    begin
        WAMessage.SetRange("Conversation Entry No.", "Entry No.");
        WAMessage.DeleteAll();
    end;

    /// <summary>
    /// Ventana de atención al cliente de WhatsApp: 24 h desde el último mensaje recibido del cliente.
    /// </summary>
    procedure IsWindowOpen(): Boolean
    begin
        if "Last Inbound At" = 0DT then
            exit(false);
        exit(CurrentDateTime() - "Last Inbound At" < 24 * 60 * 60 * 1000);
    end;

    procedure GetWindowText(): Text
    var
        Remaining: Duration;
        OpenLbl: Label 'Abierta (quedan %1 h)', Comment = '%1 = hours';
        ClosedLbl: Label 'Cerrada: solo plantillas';
    begin
        if not IsWindowOpen() then
            exit(ClosedLbl);
        Remaining := 24 * 60 * 60 * 1000 - (CurrentDateTime() - "Last Inbound At");
        exit(StrSubstNo(OpenLbl, Round(Remaining / 3600000, 1, '<')));
    end;

    /// <summary>
    /// Vincula la conversación a un cliente, proveedor, contacto o vendedor/comprador: nombre y comercial asignado.
    /// Con Nº en blanco la desvincula.
    /// </summary>
    procedure SetEntity(NewEntityType: Enum "IKA WA Entity Type"; NewEntityNo: Code[20])
    var
        PhoneMgt: Codeunit "IKA WA Phone Mgt.";
    begin
        "Entity Type" := NewEntityType;
        "Entity No." := NewEntityNo;
        "Entity Name" := PhoneMgt.GetEntityName(NewEntityType, NewEntityNo);
        "Salesperson Code" := PhoneMgt.GetEntitySalespersonCode(NewEntityType, NewEntityNo);
    end;

    /// <summary>
    /// Pone a cero los no leídos y, si está configurado, envía el "leído" a WhatsApp del último mensaje recibido.
    /// </summary>
    procedure MarkAsRead()
    var
        Setup: Record "IKA WA Setup";
        WAMessage: Record "IKA WA Message";
    begin
        if "No. of Unread" = 0 then
            exit;
        Setup.GetSetup();
        if Setup."Send Read Receipts" then begin
            WAMessage.SetCurrentKey("Conversation Entry No.", "Sent At");
            WAMessage.SetRange("Conversation Entry No.", "Entry No.");
            WAMessage.SetRange(Direction, WAMessage.Direction::Inbound);
            if WAMessage.FindLast() then
                if not TrySendReadReceipt(WAMessage) then; // no es crítico
        end;
        "No. of Unread" := 0;
        Modify();
    end;

    [TryFunction]
    local procedure TrySendReadReceipt(WAMessage: Record "IKA WA Message")
    var
        CloudApi: Codeunit "IKA WA Cloud API";
    begin
        CloudApi.MarkAsRead(WAMessage."Account Code", WAMessage."WA Message ID");
    end;

    procedure FindOrCreate(AccountCode: Code[20]; PhoneNo: Text): Boolean
    begin
        Reset();
        SetCurrentKey("Account Code", "Phone No.");
        SetRange("Account Code", AccountCode);
        SetRange("Phone No.", CopyStr(PhoneNo, 1, MaxStrLen("Phone No.")));
        if FindFirst() then
            exit(false);
        Init();
        "Entry No." := 0;
        "Account Code" := AccountCode;
        "Phone No." := CopyStr(PhoneNo, 1, MaxStrLen("Phone No."));
        Insert(true);
        exit(true);
    end;
}
