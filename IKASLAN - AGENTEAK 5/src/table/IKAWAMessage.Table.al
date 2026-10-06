table 50650 "IKA WA Message"
{
    Caption = 'Mensaje de WhatsApp';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº mov.';
            AutoIncrement = true;
        }
        field(2; "Conversation Entry No."; Integer)
        {
            Caption = 'Nº conversación';
            TableRelation = "IKA WA Conversation";
        }
        field(3; "Account Code"; Code[20])
        {
            Caption = 'Cuenta';
            TableRelation = "IKA WA Account";
        }
        field(10; Direction; Enum "IKA WA Direction")
        {
            Caption = 'Dirección';
        }
        field(11; "Message Type"; Enum "IKA WA Message Type")
        {
            Caption = 'Tipo';
        }
        field(12; Status; Enum "IKA WA Message Status")
        {
            Caption = 'Estado';
        }
        field(13; "WA Message ID"; Text[250])
        {
            Caption = 'Id mensaje (wamid)';
        }
        field(14; "Context Message ID"; Text[250])
        {
            Caption = 'Responde a (wamid)';
        }
        field(15; "Sent At"; DateTime)
        {
            Caption = 'Fecha/hora';
        }
        field(20; "Message Text"; Text[2048])
        {
            Caption = 'Texto';
        }
        field(21; "Message Text (Cont.)"; Text[2048])
        {
            Caption = 'Texto (cont.)';
        }
        field(22; "Template Name"; Text[100])
        {
            Caption = 'Plantilla';
        }
        field(30; "Media ID"; Text[100])
        {
            Caption = 'Id fichero (Meta)';
        }
        field(31; "File Name"; Text[250])
        {
            Caption = 'Fichero';
        }
        field(32; "MIME Type"; Text[100])
        {
            Caption = 'Tipo de fichero';
        }
        field(33; "Media Content"; Blob)
        {
            Caption = 'Contenido del fichero';
        }
        field(34; "Media Downloaded"; Boolean)
        {
            Caption = 'Fichero descargado';
        }
        field(35; "Attached to Entity"; Boolean)
        {
            Caption = 'Adjuntado a la entidad';
        }
        field(40; "Error Text"; Text[2048])
        {
            Caption = 'Error';
        }
        field(41; "Sent By"; Code[50])
        {
            Caption = 'Enviado por';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(50; "Source Table ID"; Integer)
        {
            Caption = 'Id tabla documento';
            BlankZero = true;
        }
        field(51; "Source Document No."; Code[20])
        {
            Caption = 'Nº documento';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Conversation; "Conversation Entry No.", "Sent At")
        {
        }
        key(WAMessageId; "WA Message ID")
        {
        }
    }

    procedure SetFullText(NewText: Text)
    begin
        "Message Text" := CopyStr(NewText, 1, MaxStrLen("Message Text"));
        "Message Text (Cont.)" := CopyStr(NewText, MaxStrLen("Message Text") + 1, MaxStrLen("Message Text (Cont.)"));
    end;

    procedure GetFullText(): Text
    begin
        exit("Message Text" + "Message Text (Cont.)");
    end;

    procedure GetDisplayText(): Text
    begin
        case "Message Type" of
            "Message Type"::Template:
                if "Message Text" <> '' then
                    exit("Message Text")
                else
                    exit('[Plantilla ' + "Template Name" + ']');
            "Message Type"::Document, "Message Type"::Image, "Message Type"::Audio, "Message Type"::Video, "Message Type"::Sticker:
                if "Message Text" <> '' then
                    exit('[' + Format("Message Type") + '] ' + "File Name" + ' - ' + "Message Text")
                else
                    exit('[' + Format("Message Type") + '] ' + "File Name");
        end;
        exit(GetFullText());
    end;

    procedure HasMedia(): Boolean
    begin
        exit("Media ID" <> '');
    end;
}
