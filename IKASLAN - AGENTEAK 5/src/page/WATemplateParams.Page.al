page 50625 "IKA WA Template Params"
{
    Caption = 'Variables de la plantilla';
    PageType = List;
    SourceTable = "IKA WA Template Param";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Table ID"; Rec."Table ID")
                {
                    ApplicationArea = All;
                    ToolTip = 'Documento desde el que se envía: 112 = Hist. factura venta, 36 = Pedido/Oferta venta, 110 = Hist. albarán venta, 38 = Pedido compra. 0 = cualquiera.';
                }
                field("Table Caption"; Rec."Table Caption")
                {
                    ApplicationArea = All;
                }
                field("Parameter No."; Rec."Parameter No.")
                {
                    ApplicationArea = All;
                }
                field(Source; Rec.Source)
                {
                    ApplicationArea = All;
                }
                field("Field No."; Rec."Field No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Campo del documento cuyo valor se pone en la variable (p.ej. "Nº", "Importe IVA incl.", "Fecha vencimiento").';
                }
                field("Field Caption"; Rec."Field Caption")
                {
                    ApplicationArea = All;
                }
                field("Constant Value"; Rec."Constant Value")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    // Los campos de cuenta, plantilla e idioma se rellenan solos con el RunPageLink de la página de plantillas.
}
