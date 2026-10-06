table 99301 "IKA WA Setup"
{
    Caption = 'Configuración WhatsApp';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Clave primaria';
        }
        field(10; "Default Account Code"; Code[20])
        {
            Caption = 'Cuenta de WhatsApp por defecto';
            TableRelation = "IKA WA Account";
        }
        field(20; "Graph API Base URL"; Text[100])
        {
            Caption = 'URL API de Meta';
            InitValue = 'https://graph.facebook.com';
        }
        field(21; "Graph API Version"; Text[10])
        {
            Caption = 'Versión API de Meta';
            InitValue = 'v23.0';
            ToolTip = 'Versión de la Graph API de Meta (p.ej. v23.0). Meta retira versiones antiguas; revísela una vez al año.';
        }
        field(30; "Default Country Code"; Text[5])
        {
            Caption = 'Prefijo de país por defecto';
            InitValue = '34';
            ToolTip = 'Se añade a los teléfonos guardados sin prefijo internacional (p.ej. 600123456 -> 34600123456).';
        }
        field(40; "Download Inbound Media"; Boolean)
        {
            Caption = 'Descargar ficheros recibidos';
            InitValue = true;
            ToolTip = 'Descarga a BC las fotos, PDF y audios recibidos (Meta solo los conserva un tiempo limitado).';
        }
        field(41; "Max Media Size (MB)"; Integer)
        {
            Caption = 'Tamaño máx. fichero (MB)';
            InitValue = 16;
        }
        field(50; "Send Read Receipts"; Boolean)
        {
            Caption = 'Marcar como leído al abrir';
            InitValue = true;
            ToolTip = 'Al abrir una conversación en BC, el cliente ve el doble check azul.';
        }
        field(60; "Auto Link by Phone"; Boolean)
        {
            Caption = 'Vincular por teléfono automáticamente';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }

    procedure GetSetup()
    begin
        if not Get() then begin
            Init();
            Insert();
        end;
    end;

    procedure GetApiUrl(): Text
    begin
        GetSetup();
        exit(DelChr("Graph API Base URL", '>', '/') + '/' + "Graph API Version");
    end;
}
