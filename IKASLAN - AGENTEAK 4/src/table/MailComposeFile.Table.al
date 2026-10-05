table 50470 "IKA Mail Compose File"
{
    // Ficheros que el usuario añade al responder o reenviar (tabla temporal).
    Caption = 'Fichero a enviar';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Nº línea';
        }
        field(10; "File Name"; Text[250])
        {
            Caption = 'Fichero';
        }
        field(11; "Content Type"; Text[100])
        {
            Caption = 'Tipo de contenido';
        }
        field(12; "Size (Bytes)"; Integer)
        {
            Caption = 'Tamaño (bytes)';
        }
        field(20; Content; Blob)
        {
            Caption = 'Contenido';
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
    }
}
