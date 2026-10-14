page 99061 "IKA Cost Period Dialog"
{
    Caption = 'Importar costes de Anthropic';
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            field(FromDate; FromDate)
            {
                ApplicationArea = All;
                Caption = 'Desde (UTC)';
                ToolTip = 'Primer día que se importa. Anthropic agrupa los costes por día en hora UTC.';
            }
            field(ToDate; ToDate)
            {
                ApplicationArea = All;
                Caption = 'Hasta (UTC)';
                ToolTip = 'Último día que se importa (incluido).';
            }
        }
    }

    var
        FromDate: Date;
        ToDate: Date;

    trigger OnOpenPage()
    begin
        ToDate := Today();
        FromDate := Today() - 6;
    end;

    procedure GetFromDate(): Date
    begin
        exit(FromDate);
    end;

    procedure GetToDate(): Date
    begin
        exit(ToDate);
    end;
}
