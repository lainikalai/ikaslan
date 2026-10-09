table 99431 "IKA CRM Link"
{
    // Vínculo entre un cliente, proveedor o contacto de BC y su cuenta o contacto del CRM.
    Caption = 'Vínculo con CRM';
    DataClassification = CustomerContent;
    LookupPageId = "IKA CRM Links";
    DrillDownPageId = "IKA CRM Links";

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Id tabla BC';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'Nº en BC';
        }
        field(10; "CRM Entity"; Enum "IKA CRM Entity")
        {
            Caption = 'Entidad del CRM';
        }
        field(11; "CRM Id"; Guid)
        {
            Caption = 'Id en el CRM';
        }
        field(12; "CRM Name"; Text[250])
        {
            Caption = 'Nombre en el CRM';
        }
        field(20; "Linked At"; DateTime)
        {
            Caption = 'Vinculado el';
        }
        field(21; "Linked By"; Code[50])
        {
            Caption = 'Vinculado por';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Table ID", "No.")
        {
            Clustered = true;
        }
        key(CRM; "CRM Entity", "CRM Id")
        {
        }
    }

    procedure GetBCTypeText(): Text
    var
        CustomerLbl: Label 'Cliente';
        VendorLbl: Label 'Proveedor';
        ContactLbl: Label 'Contacto';
    begin
        case "Table ID" of
            Database::Customer:
                exit(CustomerLbl);
            Database::Vendor:
                exit(VendorLbl);
            Database::Contact:
                exit(ContactLbl);
        end;
        exit(Format("Table ID"));
    end;
}
