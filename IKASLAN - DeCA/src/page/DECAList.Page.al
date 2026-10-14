page 50010 "DECA List"
{
    Caption = 'DeCA';
    PageType = List;
    SourceTable = "DECA Header";
    SourceTableView = sorting("No.") order(descending);
    CardPageId = "DECA Card";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Main)
            {
                field("No."; Rec."No.") { ApplicationArea = All; ToolTip = 'Número del DeCA.'; }
                field(Status; Rec.Status) { ApplicationArea = All; ToolTip = 'Estado del DeCA.'; }
                field("Transport Date"; Rec."Transport Date") { ApplicationArea = All; ToolTip = 'Fecha de realización del transporte.'; }
                field("Shipper Name"; Rec."Shipper Name") { ApplicationArea = All; ToolTip = 'Cargador contractual.'; }
                field("Carrier Name"; Rec."Carrier Name") { ApplicationArea = All; ToolTip = 'Transportista efectivo.'; }
                field("Vehicle Plate No."; Rec."Vehicle Plate No.") { ApplicationArea = All; ToolTip = 'Matrícula del vehículo.'; }
                field("Total Gross Weight (kg)"; Rec."Total Gross Weight (kg)") { ApplicationArea = All; ToolTip = 'Peso total de los envíos.'; }
                field("Source Type"; Rec."Source Type") { ApplicationArea = All; ToolTip = 'Documento del que procede.'; }
                field("Source No."; Rec."Source No.") { ApplicationArea = All; ToolTip = 'Número del documento de origen.'; }
                field("Issued At"; Rec."Issued At") { ApplicationArea = All; ToolTip = 'Fecha y hora de creación del fichero.'; }
                field("Service End Date"; Rec."Service End Date") { ApplicationArea = All; ToolTip = 'Fecha fin del servicio.'; }
                field("URL Disabled"; Rec."URL Disabled") { ApplicationArea = All; ToolTip = 'Indica si la descarga por URL ya está desactivada.'; }
                field("Replaces DeCA No."; Rec."Replaces DeCA No.") { ApplicationArea = All; ToolTip = 'DeCA al que sustituye.'; }
            }
        }
    }
}
