table 99421 "IKA CRM Opportunity Buffer"
{
    // Copia en memoria de los registros de oportunidades (opportunity) leídos del CRM para mostrarlos en BC (no se guarda en la base de datos).
    Caption = 'Oportunidad del CRM';
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Opportunity Id"; Guid)
        {
            Caption = 'Id (CRM)';
        }
        field(10; "Name"; Text[250])
        {
            Caption = 'Tema';
        }
        field(11; "Customer Name"; Text[250])
        {
            Caption = 'Cliente potencial / cuenta';
        }
        field(12; "Customer Id"; Guid)
        {
            Caption = 'Id cliente (CRM)';
        }
        field(13; "Estimated Value"; Decimal)
        {
            Caption = 'Ingresos estimados';
            AutoFormatType = 1;
        }
        field(14; "Est. Close Date"; Date)
        {
            Caption = 'Fecha de cierre estimada';
        }
        field(15; "Probability %"; Integer)
        {
            Caption = 'Probabilidad (%)';
        }
        field(16; "Sales Stage"; Text[100])
        {
            Caption = 'Fase de ventas';
        }
        field(17; "Status Reason"; Text[100])
        {
            Caption = 'Razón para el estado';
        }
        field(18; "Status"; Text[50])
        {
            Caption = 'Estado';
        }
        field(19; "Owner"; Text[250])
        {
            Caption = 'Propietario';
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
        key(PK; "Opportunity Id")
        {
            Clustered = true;
        }
        key(Sorting; "Sorting No.")
        {
        }
    }
}
