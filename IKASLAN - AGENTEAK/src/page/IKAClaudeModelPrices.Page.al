page 99051 "IKA Claude Model Prices"
{
    Caption = 'Precios de Claude';
    PageType = List;
    SourceTable = "IKA Claude Model Price";
    SourceTableView = sorting(Model, "Valid From");
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Model; Rec.Model)
                {
                    ApplicationArea = All;
                    ToolTip = 'Id del modelo tal como lo devuelve la API, p.ej. claude-opus-5-5.';
                }
                field("Valid From"; Rec."Valid From")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Input Price per MTok"; Rec."Input Price per MTok")
                {
                    ApplicationArea = All;
                    ToolTip = 'Precio en USD por millón de tokens de entrada (prompt, email, adjuntos).';
                }
                field("Output Price per MTok"; Rec."Output Price per MTok")
                {
                    ApplicationArea = All;
                    ToolTip = 'Precio en USD por millón de tokens de salida (respuesta de Claude, incluido su razonamiento).';
                }
                field(Uses; Uses)
                {
                    ApplicationArea = All;
                    Caption = 'Llamadas con esta tarifa';
                    Editable = false;
                    BlankZero = true;
                    ToolTip = 'Llamadas registradas (pedidos y albaranes) cuyo coste se calculó con esta tarifa. Una tarifa usada ya no se puede modificar ni borrar.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NewRate)
            {
                ApplicationArea = All;
                Caption = 'Nueva tarifa';
                Image = PriceAdjustment;
                ToolTip = 'Crea una tarifa nueva del modelo seleccionado a partir de una fecha (por defecto, hoy), copiando los precios actuales para que los modifique. Las llamadas anteriores conservan la tarifa con la que se calcularon.';

                trigger OnAction()
                var
                    NewPrice: Record "IKA Claude Model Price";
                begin
                    Rec.TestField(Model);
                    if NewPrice.Get(Rec.Model, Today()) then
                        Error(RateExistsErr, Rec.Model, Today());
                    NewPrice := Rec;
                    NewPrice."Valid From" := Today();
                    NewPrice.Insert(true);
                    CurrPage.SetRecord(NewPrice);
                    CurrPage.Update(false);
                end;
            }
            action(LoadDefaults)
            {
                ApplicationArea = All;
                Caption = 'Cargar modelos actuales';
                Image = Price;
                ToolTip = 'Añade los modelos actuales de Claude con sus precios estándar. Los modelos que ya tienen alguna tarifa no se modifican.';

                trigger OnAction()
                begin
                    Rec.InitDefaultPrices();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(NewRate_Promoted; NewRate) { }
                actionref(LoadDefaults_Promoted; LoadDefaults) { }
            }
        }
    }

    var
        Uses: Integer;
        RateExistsErr: Label 'Ya existe una tarifa de %1 válida desde %2. Modifique esa.', Comment = '%1 = model, %2 = date';

    trigger OnOpenPage()
    begin
        Rec.InitDefaultPrices();
    end;

    trigger OnAfterGetRecord()
    begin
        Uses := Rec.CountUses();
    end;
}
