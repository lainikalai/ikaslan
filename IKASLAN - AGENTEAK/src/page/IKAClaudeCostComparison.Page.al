page 99056 "IKA Claude Cost Comparison"
{
    Caption = 'Costes reales de Claude (Anthropic)';
    PageType = List;
    SourceTable = "IKA Claude Cost Comparison";
    SourceTableView = sorting("Cost Date", Model) order(descending);
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Cost Date"; Rec."Cost Date")
                {
                    ApplicationArea = All;
                }
                field(Model; Rec.Model)
                {
                    ApplicationArea = All;
                }
                field("Anthropic Cost (USD)"; Rec."Anthropic Cost (USD)")
                {
                    ApplicationArea = All;
                }
                field("BC Cost (USD)"; Rec."BC Cost (USD)")
                {
                    ApplicationArea = All;
                }
                field("Difference (USD)"; Rec."Difference (USD)")
                {
                    ApplicationArea = All;
                    StyleExpr = DifferenceStyle;
                }
                field("Real Input Price per MTok"; Rec."Real Input Price per MTok")
                {
                    ApplicationArea = All;
                    StyleExpr = RateStyle;
                }
                field("BC Input Price per MTok"; Rec."BC Input Price per MTok")
                {
                    ApplicationArea = All;
                }
                field("Real Output Price per MTok"; Rec."Real Output Price per MTok")
                {
                    ApplicationArea = All;
                    StyleExpr = RateStyle;
                }
                field("BC Output Price per MTok"; Rec."BC Output Price per MTok")
                {
                    ApplicationArea = All;
                }
                field("Rate Differs"; Rec."Rate Differs")
                {
                    ApplicationArea = All;
                    StyleExpr = RateStyle;
                }
                field("Anthropic Input Tokens"; Rec."Anthropic Input Tokens")
                {
                    ApplicationArea = All;
                }
                field("BC Input Tokens"; Rec."BC Input Tokens")
                {
                    ApplicationArea = All;
                }
                field("Anthropic Output Tokens"; Rec."Anthropic Output Tokens")
                {
                    ApplicationArea = All;
                }
                field("BC Output Tokens"; Rec."BC Output Tokens")
                {
                    ApplicationArea = All;
                }
                field("BC Calls"; Rec."BC Calls")
                {
                    ApplicationArea = All;
                }
                field("Anthropic Input Cost (USD)"; Rec."Anthropic Input Cost (USD)")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Anthropic Output Cost (USD)"; Rec."Anthropic Output Cost (USD)")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Anthropic Other Cost (USD)"; Rec."Anthropic Other Cost (USD)")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Anthropic Cache Tokens"; Rec."Anthropic Cache Tokens")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Imported At"; Rec."Imported At")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ImportFromAnthropic)
            {
                ApplicationArea = All;
                Caption = 'Importar de Anthropic';
                Image = Import;
                ToolTip = 'Descarga de la Admin API de Anthropic el coste facturado y los tokens de los días indicados y los compara con el coste calculado en BC. Los datos aparecen en Anthropic unos 5 minutos después de cada llamada.';

                trigger OnAction()
                var
                    PeriodDialog: Page "IKA Cost Period Dialog";
                    UsageImport: Codeunit "IKA Anthropic Usage Import";
                begin
                    if PeriodDialog.RunModal() <> Action::OK then
                        exit;
                    UsageImport.ImportPeriod(PeriodDialog.GetFromDate(), PeriodDialog.GetToDate());
                    CurrPage.Update(false);
                end;
            }
            action(UpdateTariffs)
            {
                ApplicationArea = All;
                Caption = 'Actualizar tarifas con las reales';
                Image = PriceAdjustment;
                ToolTip = 'Si la tarifa real facturada por Anthropic difiere de la de "Precios de Claude", crea una tarifa nueva con la real a partir del día en que se detectó. Pide confirmación.';

                trigger OnAction()
                var
                    UsageImport: Codeunit "IKA Anthropic Usage Import";
                begin
                    UsageImport.UpdateTariffsFromRealRates();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(ModelPrices)
            {
                ApplicationArea = All;
                Caption = 'Precios de Claude';
                Image = Price;
                RunObject = page "IKA Claude Model Prices";
                ToolTip = 'Tarifas por modelo con las que BC calcula el coste de cada llamada.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(ImportFromAnthropic_Promoted; ImportFromAnthropic) { }
                actionref(UpdateTariffs_Promoted; UpdateTariffs) { }
                actionref(ModelPrices_Promoted; ModelPrices) { }
            }
        }
    }

    var
        DifferenceStyle: Text;
        RateStyle: Text;

    trigger OnAfterGetRecord()
    begin
        if Abs(Rec."Difference (USD)") >= 0.01 then
            DifferenceStyle := 'Unfavorable'
        else
            DifferenceStyle := 'Favorable';
        if Rec."Rate Differs" then
            RateStyle := 'Unfavorable'
        else
            RateStyle := 'Standard';
    end;
}
