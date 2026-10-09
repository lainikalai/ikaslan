table 99426 "IKA CRM Activity Buffer"
{
    // Copia en memoria de los registros de actividades (activitypointer) leídos del CRM para mostrarlos en BC (no se guarda en la base de datos).
    Caption = 'Actividad del CRM';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Activity Id"; Guid)
        {
            Caption = 'Id (CRM)';
        }
        field(10; "Activity Type"; Text[50])
        {
            Caption = 'Tipo';
        }
        field(11; "Activity Type Code"; Text[100])
        {
            Caption = 'Tipo (nombre lógico)';
        }
        field(12; "Subject"; Text[250])
        {
            Caption = 'Asunto';
        }
        field(13; "Regarding"; Text[250])
        {
            Caption = 'Referente a';
        }
        field(14; "Scheduled Start"; DateTime)
        {
            Caption = 'Inicio programado';
        }
        field(15; "Scheduled End"; DateTime)
        {
            Caption = 'Vencimiento';
        }
        field(16; "Actual End"; DateTime)
        {
            Caption = 'Finalizada el';
        }
        field(17; "Status"; Text[50])
        {
            Caption = 'Estado';
        }
        field(18; "Owner"; Text[250])
        {
            Caption = 'Propietario';
        }
        field(19; "Created On"; DateTime)
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
        key(PK; "Activity Id")
        {
            Clustered = true;
        }
        key(Sorting; "Sorting No.")
        {
        }
    }
}
