table 99331 "IKA WA Inbound Event"
{
    // Cola de entrada. La Azure Function recibe el webhook de Meta, comprueba la firma, lo divide en
    // eventos sencillos (un mensaje o un cambio de estado) y los inserta aquí a través de la página API
    // "IKA WA Inbound API". Después la codeunit "IKA WA Inbound Processor" los convierte en mensajes.
    Caption = 'Evento entrante de WhatsApp';
    DataClassification = CustomerContent;
    LookupPageId = "IKA WA Inbound Events";
    DrillDownPageId = "IKA WA Inbound Events";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº mov.';
            AutoIncrement = true;
        }
        field(2; "Event Kind"; Enum "IKA WA Event Kind")
        {
            Caption = 'Tipo de evento';
        }
        field(3; "Received At"; DateTime)
        {
            Caption = 'Recibido en BC';
        }
        field(10; "Phone Number ID"; Text[50])
        {
            Caption = 'Phone Number ID (cuenta)';
        }
        field(11; "From Phone"; Text[30])
        {
            Caption = 'Teléfono';
            ToolTip = 'Remitente (mensajes) o destinatario (estados).';
        }
        field(12; "Profile Name"; Text[100])
        {
            Caption = 'Nombre en WhatsApp';
        }
        field(13; "WA Message ID"; Text[250])
        {
            Caption = 'Id mensaje (wamid)';
        }
        field(14; "Context Message ID"; Text[250])
        {
            Caption = 'Responde a (wamid)';
        }
        field(15; "Unix Timestamp"; BigInteger)
        {
            Caption = 'Marca de tiempo (Unix)';
        }
        field(20; "Message Type"; Text[30])
        {
            Caption = 'Tipo de mensaje';
        }
        field(21; "Text Part 1"; Text[2048])
        {
            Caption = 'Texto (1)';
        }
        field(22; "Text Part 2"; Text[2048])
        {
            Caption = 'Texto (2)';
        }
        field(23; "Media ID"; Text[100])
        {
            Caption = 'Id fichero';
        }
        field(24; "MIME Type"; Text[100])
        {
            Caption = 'Tipo de fichero';
        }
        field(25; "File Name"; Text[250])
        {
            Caption = 'Nombre de fichero';
        }
        field(30; "Status Value"; Text[30])
        {
            Caption = 'Estado (sent/delivered/read/failed)';
        }
        field(31; "Error Text"; Text[2048])
        {
            Caption = 'Error informado por Meta';
        }
        field(40; Processed; Boolean)
        {
            Caption = 'Procesado';
        }
        field(41; "Processing Error"; Text[2048])
        {
            Caption = 'Error al procesar';
        }
        field(42; "Message Entry No."; Integer)
        {
            Caption = 'Nº mensaje';
            TableRelation = "IKA WA Message";
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Processed; Processed, "Entry No.")
        {
        }
    }

    trigger OnInsert()
    begin
        "Received At" := CurrentDateTime();
    end;

    procedure GetEventDateTime(): DateTime
    var
        TypeHelper: Codeunit "Type Helper";
    begin
        if "Unix Timestamp" = 0 then
            exit("Received At");
        exit(TypeHelper.EvaluateUnixTimestamp("Unix Timestamp"));
    end;
}
