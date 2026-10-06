page 50620 "IKA WA Templates"
{
    Caption = 'Plantillas de WhatsApp';
    PageType = List;
    SourceTable = "IKA WA Template";
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Account Code"; Rec."Account Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field(Category; Rec.Category)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Header Type"; Rec."Header Type")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("No. of Body Parameters"; Rec."No. of Body Parameters")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Body Text"; Rec."Body Text")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Parameters)
            {
                ApplicationArea = All;
                Caption = 'Variables';
                Image = SetupList;
                RunObject = page "IKA WA Template Params";
                RunPageLink = "Account Code" = field("Account Code"), "Template Name" = field(Name), "Language Code" = field("Language Code");
                ToolTip = 'De dónde sale cada variable {{n}} según el documento desde el que se envía.';
            }
        }
        area(Promoted)
        {
            group(Category_Navigate)
            {
                Caption = 'Navegar';

                actionref(Parameters_Promoted; Parameters) { }
            }
        }
    }

    var
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Approved:
                StatusStyle := 'Favorable';
            Rec.Status::Rejected, Rec.Status::Disabled, Rec.Status::Paused:
                StatusStyle := 'Unfavorable';
            else
                StatusStyle := 'Standard';
        end;
    end;
}
