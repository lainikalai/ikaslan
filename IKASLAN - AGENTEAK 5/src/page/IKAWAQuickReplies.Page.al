page 99361 "IKA WA Quick Replies"
{
    Caption = 'Respuestas rápidas de WhatsApp';
    PageType = List;
    SourceTable = "IKA WA Quick Reply";
    SourceTableView = sorting("Sorting Order", "Code");
    UsageCategory = Administration;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Sorting Order"; Rec."Sorting Order")
                {
                    ApplicationArea = All;
                }
                field("Code"; Rec."Code")
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                }
                field("Message Text"; Rec."Message Text")
                {
                    ApplicationArea = All;
                }
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
