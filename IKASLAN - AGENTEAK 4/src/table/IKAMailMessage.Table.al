table 50420 "IKA Mail Message"
{
    // Copia local (caché) de los datos básicos de cada email. El cuerpo y los adjuntos se descargan
    // de Graph al abrir el email, no al sincronizar, para que la sincronización sea rápida.
    Caption = 'Email';
    DataClassification = CustomerContent;
    LookupPageId = "IKA Mail Messages";
    DrillDownPageId = "IKA Mail Messages";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº mov.';
            AutoIncrement = true;
        }
        field(2; "Mailbox Code"; Code[20])
        {
            Caption = 'Buzón';
            TableRelation = "IKA Mail Mailbox";
        }
        field(10; "Graph Id"; Text[250])
        {
            Caption = 'Id (Graph)';
        }
        field(11; "Internet Message Id"; Text[250])
        {
            Caption = 'Internet Message-ID';
        }
        field(12; "Conversation Id"; Text[250])
        {
            Caption = 'Id conversación';
        }
        field(20; "Received At"; DateTime)
        {
            Caption = 'Recibido';
        }
        field(21; "From Address"; Text[250])
        {
            Caption = 'De (email)';
            ExtendedDatatype = EMail;
        }
        field(22; "From Name"; Text[250])
        {
            Caption = 'De';
        }
        field(23; "To Recipients"; Text[2048])
        {
            Caption = 'Para';
        }
        field(24; "Cc Recipients"; Text[2048])
        {
            Caption = 'CC';
        }
        field(25; Subject; Text[250])
        {
            Caption = 'Asunto';
        }
        field(26; "Body Preview"; Text[250])
        {
            Caption = 'Vista previa';
        }
        field(27; "Is Read"; Boolean)
        {
            Caption = 'Leído';
        }
        field(28; "Has Attachments"; Boolean)
        {
            Caption = 'Con adjuntos';
        }
        field(29; Importance; Text[20])
        {
            Caption = 'Importancia';
        }
        field(30; "Web Link"; Text[2048])
        {
            Caption = 'Enlace Outlook Web';
            ExtendedDatatype = URL;
        }
        field(40; "Body Html"; Blob)
        {
            Caption = 'Cuerpo (HTML)';
        }
        field(41; "Details Loaded"; Boolean)
        {
            Caption = 'Detalle descargado';
        }
        field(50; "No. of Links"; Integer)
        {
            Caption = 'Vínculos';
            FieldClass = FlowField;
            CalcFormula = count("IKA Mail Link" where("Message Entry No." = field("Entry No.")));
            Editable = false;
        }
        field(51; "No. of Attachments"; Integer)
        {
            Caption = 'Nº adjuntos';
            FieldClass = FlowField;
            CalcFormula = count("IKA Mail Attachment" where("Message Entry No." = field("Entry No."), "Is Inline" = const(false)));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(GraphId; "Mailbox Code", "Graph Id")
        {
        }
        key(Received; "Mailbox Code", "Received At")
        {
        }
        key(FromAddress; "From Address")
        {
        }
    }

    trigger OnDelete()
    var
        MailAttachment: Record "IKA Mail Attachment";
    begin
        MailAttachment.SetRange("Message Entry No.", "Entry No.");
        MailAttachment.DeleteAll(true);
    end;

    procedure SetBodyHtml(NewText: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Body Html");
        "Body Html".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(NewText);
    end;

    procedure GetBodyHtml(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
    begin
        CalcFields("Body Html");
        if not "Body Html".HasValue() then
            exit('');
        "Body Html".CreateInStream(InStr, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator()));
    end;
}
