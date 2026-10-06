table 50450 "IKA Mail Pinned Target"
{
    // Entidades que cada usuario fija como zona de destino permanente en la ficha del email.
    Caption = 'Destino fijado';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "User ID"; Code[50])
        {
            Caption = 'Id. usuario';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(2; "Entity Type"; Enum "IKA Mail Entity Type")
        {
            Caption = 'Tipo de entidad';
        }
        field(3; "Entity No."; Code[20])
        {
            Caption = 'Nº entidad';
        }
        field(10; "Pinned At"; DateTime)
        {
            Caption = 'Fijado';
        }
    }

    keys
    {
        key(PK; "User ID", "Entity Type", "Entity No.")
        {
            Clustered = true;
        }
    }
}
