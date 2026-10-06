page 99006 "IKA Sales Agent Mail Filters"
{
    Caption = 'Filtros de correo agente de ventas';
    PageType = List;
    SourceTable = "IKA Sales Agent Mail Filter";
    SourceTableView = sorting(Priority, "Line No.");
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica si el filtro está en uso.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción libre del filtro.';
                }
                field("Sender Filter"; Rec."Sender Filter")
                {
                    ApplicationArea = All;
                }
                field("Subject Filter"; Rec."Subject Filter")
                {
                    ApplicationArea = All;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
