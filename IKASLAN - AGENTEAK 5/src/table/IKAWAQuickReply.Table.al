table 99336 "IKA WA Quick Reply"
{
    // Textos predefinidos que se insertan con un clic en la caja de texto del chat.
    Caption = 'Respuesta rápida de WhatsApp';
    DataClassification = CustomerContent;
    LookupPageId = "IKA WA Quick Replies";
    DrillDownPageId = "IKA WA Quick Replies";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Código';
            NotBlank = true;
            ToolTip = 'Identifica la respuesta rápida.';
        }
        field(2; Description; Text[30])
        {
            Caption = 'Texto del botón';
            ToolTip = 'Lo que se ve en el botón del chat. Si se deja en blanco, se usa el código.';
        }
        field(3; "Message Text"; Text[1024])
        {
            Caption = 'Texto';
            ToolTip = 'Texto que se inserta. Variables: {nombre} = cliente, proveedor o contacto de la conversación; {comercial} = comercial asignado; {usuario} = usuario que escribe.';
        }
        field(4; "Sorting Order"; Integer)
        {
            Caption = 'Orden';
            ToolTip = 'Orden en que aparecen los botones en el chat.';
        }
        field(5; Enabled; Boolean)
        {
            Caption = 'Activa';
            ToolTip = 'Solo las activas aparecen en el chat.';
            InitValue = true;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
        key(Sorting; "Sorting Order", "Code")
        {
        }
    }
}
