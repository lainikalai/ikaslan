table 50440 "IKA Mail Link"
{
    // Registro de cada fichero (email completo o adjunto) que se ha adjuntado a una entidad de BC.
    // El fichero en sí se guarda en los adjuntos estándar (Document Attachment).
    Caption = 'Vínculo email - entidad';
    DataClassification = CustomerContent;
    LookupPageId = "IKA Mail Links";
    DrillDownPageId = "IKA Mail Links";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº mov.';
            AutoIncrement = true;
        }
        field(10; "Message Entry No."; Integer)
        {
            Caption = 'Nº mov. email';
            TableRelation = "IKA Mail Message";
        }
        field(11; "Attachment Line No."; Integer)
        {
            Caption = 'Nº línea adjunto';
            ToolTip = '0 = el email completo (.eml).';
        }
        field(12; "File Name"; Text[250])
        {
            Caption = 'Fichero';
        }
        field(13; Subject; Text[250])
        {
            Caption = 'Asunto del email';
        }
        field(14; "From Address"; Text[250])
        {
            Caption = 'De';
        }
        field(15; "Received At"; DateTime)
        {
            Caption = 'Recibido';
        }
        field(20; "Entity Type"; Enum "IKA Mail Entity Type")
        {
            Caption = 'Tipo de entidad';
        }
        field(21; "Entity No."; Code[20])
        {
            Caption = 'Nº entidad';
        }
        field(22; "Table ID"; Integer)
        {
            Caption = 'Id tabla';
        }
        field(23; "Document Attachment ID"; Integer)
        {
            Caption = 'Id adjunto BC';
        }
        field(30; "Linked At"; DateTime)
        {
            Caption = 'Vinculado';
        }
        field(31; "Linked By"; Code[50])
        {
            Caption = 'Vinculado por';
            DataClassification = EndUserIdentifiableInformation;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Entity; "Entity Type", "Entity No.", "Linked At")
        {
        }
        key(Message; "Message Entry No.", "Attachment Line No.")
        {
        }
    }

    trigger OnInsert()
    begin
        "Linked At" := CurrentDateTime();
        "Linked By" := CopyStr(UserId(), 1, MaxStrLen("Linked By"));
    end;
}
