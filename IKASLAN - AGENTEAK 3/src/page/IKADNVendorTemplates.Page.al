page 50210 "IKA DN Vendor Templates"
{
    Caption = 'Plantillas de albarán de proveedor';
    PageType = List;
    SourceTable = "IKA DN Vendor Template";
    CardPageId = "IKA DN Vendor Template";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                }
                field("Sender Filter"; Rec."Sender Filter")
                {
                    ApplicationArea = All;
                }
                field("File Name Filter"; Rec."File Name Filter")
                {
                    ApplicationArea = All;
                }
                field("Item Code Type"; Rec."Item Code Type")
                {
                    ApplicationArea = All;
                }
                field("Example Document Entry No."; Rec."Example Document Entry No.")
                {
                    ApplicationArea = All;
                }
                field("No. of Documents"; Rec."No. of Documents")
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
