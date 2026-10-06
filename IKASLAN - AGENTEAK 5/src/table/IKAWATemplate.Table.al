table 50620 "IKA WA Template"
{
    // Plantilla de mensaje aprobada por Meta. Se crean en WhatsApp Manager y aquí se sincronizan.
    // Son obligatorias para escribir primero a un cliente o fuera de la ventana de 24 horas.
    Caption = 'Plantilla de WhatsApp';
    DataClassification = CustomerContent;
    LookupPageId = "IKA WA Templates";
    DrillDownPageId = "IKA WA Templates";

    fields
    {
        field(1; "Account Code"; Code[20])
        {
            Caption = 'Cuenta';
            TableRelation = "IKA WA Account";
        }
        field(2; Name; Text[100])
        {
            Caption = 'Nombre';
        }
        field(3; "Language Code"; Text[10])
        {
            Caption = 'Idioma';
            ToolTip = 'Código de idioma de Meta, p.ej. es, es_ES, en_US, eu.';
        }
        field(10; Category; Text[30])
        {
            Caption = 'Categoría';
            ToolTip = 'UTILITY (avisos de pedido, facturas...), MARKETING o AUTHENTICATION. Determina el precio por mensaje.';
        }
        field(11; Status; Enum "IKA WA Template Status")
        {
            Caption = 'Estado';
        }
        field(20; "Header Type"; Enum "IKA WA Header Type")
        {
            Caption = 'Cabecera';
            ToolTip = 'Si la cabecera es Documento, al enviar se adjunta el PDF del documento de BC.';
        }
        field(21; "Body Text"; Text[2048])
        {
            Caption = 'Texto';
            ToolTip = 'Texto de la plantilla con sus variables {{1}}, {{2}}...';
        }
        field(22; "No. of Body Parameters"; Integer)
        {
            Caption = 'Nº variables';
        }
        field(30; Description; Text[100])
        {
            Caption = 'Uso';
            ToolTip = 'Para qué se usa en la empresa, p.ej. "Envío de factura".';
        }
    }

    keys
    {
        key(PK; "Account Code", Name, "Language Code")
        {
            Clustered = true;
        }
    }

    trigger OnDelete()
    var
        TemplateParam: Record "IKA WA Template Param";
    begin
        TemplateParam.SetRange("Account Code", "Account Code");
        TemplateParam.SetRange("Template Name", Name);
        TemplateParam.SetRange("Language Code", "Language Code");
        TemplateParam.DeleteAll();
    end;

    /// <summary>
    /// Cuenta las variables {{n}} del texto.
    /// </summary>
    procedure CountBodyParameters(): Integer
    var
        i: Integer;
    begin
        i := 1;
        while StrPos("Body Text", '{{' + Format(i) + '}}') > 0 do
            i += 1;
        exit(i - 1);
    end;
}
