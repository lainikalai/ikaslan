table 99411 "IKA CRM Contact Buffer"
{
    // Copia en memoria de los registros de contactos (contact) leídos del CRM para mostrarlos en BC (no se guarda en la base de datos).
    Caption = 'Contacto del CRM';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Contact Id"; Guid)
        {
            Caption = 'Id (CRM)';
        }
        field(10; "Full Name"; Text[250])
        {
            Caption = 'Nombre completo';
        }
        field(11; "Job Title"; Text[100])
        {
            Caption = 'Puesto';
        }
        field(12; "Company Name"; Text[250])
        {
            Caption = 'Empresa';
        }
        field(13; "Company Id"; Guid)
        {
            Caption = 'Id empresa (CRM)';
        }
        field(14; "Phone"; Text[100])
        {
            Caption = 'Teléfono';
        }
        field(15; "Mobile Phone"; Text[100])
        {
            Caption = 'Móvil';
        }
        field(16; "E-Mail"; Text[100])
        {
            Caption = 'Correo electrónico';
        }
        field(17; "City"; Text[100])
        {
            Caption = 'Ciudad';
        }
        field(18; "Owner"; Text[250])
        {
            Caption = 'Propietario';
        }
        field(19; "Status"; Text[50])
        {
            Caption = 'Estado';
        }
        field(20; "Modified On"; DateTime)
        {
            Caption = 'Modificado el';
        }
        field(100; "Sorting No."; Integer)
        {
            Caption = 'Orden';
        }
    }

    keys
    {
        key(PK; "Contact Id")
        {
            Clustered = true;
        }
        key(Sorting; "Sorting No.")
        {
        }
    }
}
