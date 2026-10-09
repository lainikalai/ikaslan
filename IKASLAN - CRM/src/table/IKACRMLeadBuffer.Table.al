table 99416 "IKA CRM Lead Buffer"
{
    // Copia en memoria de los registros de clientes potenciales (lead) leídos del CRM para mostrarlos en BC (no se guarda en la base de datos).
    Caption = 'Cliente potencial del CRM';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Lead Id"; Guid)
        {
            Caption = 'Id (CRM)';
        }
        field(10; "Topic"; Text[250])
        {
            Caption = 'Tema';
        }
        field(11; "Full Name"; Text[250])
        {
            Caption = 'Nombre';
        }
        field(12; "Company Name"; Text[250])
        {
            Caption = 'Empresa';
        }
        field(13; "Phone"; Text[100])
        {
            Caption = 'Teléfono';
        }
        field(14; "Mobile Phone"; Text[100])
        {
            Caption = 'Móvil';
        }
        field(15; "E-Mail"; Text[100])
        {
            Caption = 'Correo electrónico';
        }
        field(16; "Lead Source"; Text[100])
        {
            Caption = 'Origen';
        }
        field(17; "Rating"; Text[50])
        {
            Caption = 'Calificación';
        }
        field(18; "Status Reason"; Text[100])
        {
            Caption = 'Razón para el estado';
        }
        field(19; "Status"; Text[50])
        {
            Caption = 'Estado';
        }
        field(20; "Owner"; Text[250])
        {
            Caption = 'Propietario';
        }
        field(21; "Created On"; DateTime)
        {
            Caption = 'Creado el';
        }
        field(100; "Sorting No."; Integer)
        {
            Caption = 'Orden';
        }
    }

    keys
    {
        key(PK; "Lead Id")
        {
            Clustered = true;
        }
        key(Sorting; "Sorting No.")
        {
        }
    }
}
