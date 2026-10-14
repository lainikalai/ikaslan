table 99406 "IKA CRM Account Buffer"
{
    // Copia en memoria de los registros de cuentas (account) leídos del CRM para mostrarlos en BC (no se guarda en la base de datos).
    Caption = 'Cuenta del CRM';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Account Id"; Guid)
        {
            Caption = 'Id (CRM)';
        }
        field(10; "Name"; Text[250])
        {
            Caption = 'Nombre';
        }
        field(11; "Account Number"; Text[100])
        {
            Caption = 'Nº de cuenta';
        }
        field(12; "Relationship Type"; Text[100])
        {
            Caption = 'Tipo de relación';
        }
        field(13; "Phone"; Text[100])
        {
            Caption = 'Teléfono';
        }
        field(14; "E-Mail"; Text[100])
        {
            Caption = 'Correo electrónico';
        }
        field(15; "Website"; Text[250])
        {
            Caption = 'Sitio web';
        }
        field(16; "Address"; Text[250])
        {
            Caption = 'Dirección';
        }
        field(17; "City"; Text[100])
        {
            Caption = 'Ciudad';
        }
        field(18; "Post Code"; Text[30])
        {
            Caption = 'C.P.';
        }
        field(19; "County"; Text[100])
        {
            Caption = 'Provincia';
        }
        field(20; "Country"; Text[100])
        {
            Caption = 'País';
        }
        field(21; "Primary Contact"; Text[250])
        {
            Caption = 'Contacto principal';
        }
        field(22; "Industry"; Text[100])
        {
            Caption = 'Sector';
        }
        field(23; "Owner"; Text[250])
        {
            Caption = 'Propietario';
        }
        field(24; "Status"; Text[50])
        {
            Caption = 'Estado';
        }
        field(25; "Modified On"; DateTime)
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
        key(PK; "Account Id")
        {
            Clustered = true;
        }
        key(Sorting; "Sorting No.")
        {
        }
    }
}
