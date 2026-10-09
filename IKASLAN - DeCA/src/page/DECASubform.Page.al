page 50030 "DECA Subform"
{
    Caption = 'Envíos';
    PageType = ListPart;
    SourceTable = "DECA Line";
    AutoSplitKey = true;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Main)
            {
                field("Origin Name"; Rec."Origin Name") { ApplicationArea = All; ToolTip = 'Nombre del lugar de origen.'; }
                field("Origin Address"; Rec."Origin Address") { ApplicationArea = All; ToolTip = 'Dirección de origen.'; }
                field("Origin Post Code"; Rec."Origin Post Code") { ApplicationArea = All; ToolTip = 'Código postal de origen.'; }
                field("Origin City"; Rec."Origin City") { ApplicationArea = All; ToolTip = 'Población de origen.'; }
                field("Destination Name"; Rec."Destination Name") { ApplicationArea = All; ToolTip = 'Nombre del lugar de destino.'; }
                field("Destination Address"; Rec."Destination Address") { ApplicationArea = All; ToolTip = 'Dirección de destino.'; }
                field("Destination Post Code"; Rec."Destination Post Code") { ApplicationArea = All; ToolTip = 'Código postal de destino.'; }
                field("Destination City"; Rec."Destination City") { ApplicationArea = All; ToolTip = 'Población de destino.'; }
                field("Goods Description"; Rec."Goods Description") { ApplicationArea = All; ToolTip = 'Naturaleza de la mercancía transportada.'; }
                field("Gross Weight (kg)"; Rec."Gross Weight (kg)") { ApplicationArea = All; ToolTip = 'Peso de la mercancía en kilogramos.'; }
                field("Alternative Magnitude"; Rec."Alternative Magnitude") { ApplicationArea = All; ToolTip = 'Otra magnitud (por ejemplo, 12 palés o 30 m3) cuando sea difícil determinar el peso exacto.'; }
                field("Source Document No."; Rec."Source Document No.") { ApplicationArea = All; ToolTip = 'Documento de origen del envío.'; }
            }
        }
    }
}
