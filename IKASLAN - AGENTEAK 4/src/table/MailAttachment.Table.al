table 50430 "IKA Mail Attachment"
{
    Caption = 'Adjunto de email';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Message Entry No."; Integer)
        {
            Caption = 'Nº mov. email';
            TableRelation = "IKA Mail Message";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Nº línea';
        }
        field(10; "Graph Attachment Id"; Text[250])
        {
            Caption = 'Id adjunto (Graph)';
        }
        field(11; Name; Text[250])
        {
            Caption = 'Nombre';
        }
        field(12; "Content Type"; Text[100])
        {
            Caption = 'Tipo de contenido';
        }
        field(13; "Size (Bytes)"; Integer)
        {
            Caption = 'Tamaño (bytes)';
        }
        field(14; "Is Inline"; Boolean)
        {
            Caption = 'Incrustado';
        }
        field(15; "Content Id"; Text[250])
        {
            Caption = 'Content-ID';
        }
        field(16; "Attachment Kind"; Option)
        {
            Caption = 'Clase';
            OptionMembers = File,Item,Reference;
            OptionCaption = 'Fichero,Elemento de Outlook,Referencia (OneDrive)';
        }
        field(20; Content; Blob)
        {
            Caption = 'Contenido';
        }
        field(21; "Content Loaded"; Boolean)
        {
            Caption = 'Contenido descargado';
        }
    }

    keys
    {
        key(PK; "Message Entry No.", "Line No.")
        {
            Clustered = true;
        }
    }

    procedure GetFileName(): Text
    begin
        // Los emails adjuntos (itemAttachment) se descargan en formato MIME (.eml)
        if ("Attachment Kind" = "Attachment Kind"::Item) and not LowerCase(Name).EndsWith('.eml') then
            exit(Name + '.eml');
        exit(Name);
    end;

    procedure GetSizeText(): Text
    begin
        if "Size (Bytes)" < 1024 then
            exit(Format("Size (Bytes)") + ' B');
        if "Size (Bytes)" < 1048576 then
            exit(Format(Round("Size (Bytes)" / 1024, 1)) + ' KB');
        exit(Format(Round("Size (Bytes)" / 1048576, 0.1)) + ' MB');
    end;
}
