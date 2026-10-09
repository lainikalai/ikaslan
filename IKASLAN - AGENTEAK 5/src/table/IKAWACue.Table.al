table 99341 "IKA WA Cue"
{
    // Pila de actividades de WhatsApp para las Áreas de trabajo. Los filtros se ponen al abrir la página.
    Caption = 'Actividades de WhatsApp';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Clave primaria';
        }
        field(10; "Unread Conversations"; Integer)
        {
            Caption = 'No leídas';
            FieldClass = FlowField;
            CalcFormula = count("IKA WA Conversation" where("No. of Unread" = filter(> 0), "Account Code" = field("Account Filter")));
            Editable = false;
        }
        field(11; "My Unread Conversations"; Integer)
        {
            Caption = 'Mis no leídas';
            FieldClass = FlowField;
            CalcFormula = count("IKA WA Conversation" where("No. of Unread" = filter(> 0), "Account Code" = field("Account Filter"), "Salesperson Code" = field("Salesperson Filter")));
            Editable = false;
        }
        field(12; "Windows Closing Soon"; Integer)
        {
            Caption = 'Ventana cierra en < 4 h';
            FieldClass = FlowField;
            CalcFormula = count("IKA WA Conversation" where("Last Inbound At" = field("Window Closing Filter"), "Account Code" = field("Account Filter")));
            Editable = false;
        }
        field(13; "Not Linked Conversations"; Integer)
        {
            Caption = 'Sin vincular';
            FieldClass = FlowField;
            CalcFormula = count("IKA WA Conversation" where("Entity No." = const(''), "Account Code" = field("Account Filter")));
            Editable = false;
        }
        field(20; "Account Filter"; Code[20])
        {
            Caption = 'Filtro cuenta';
            FieldClass = FlowFilter;
        }
        field(21; "Salesperson Filter"; Code[20])
        {
            Caption = 'Filtro comercial';
            FieldClass = FlowFilter;
        }
        field(22; "Window Closing Filter"; DateTime)
        {
            Caption = 'Filtro ventana';
            FieldClass = FlowFilter;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
