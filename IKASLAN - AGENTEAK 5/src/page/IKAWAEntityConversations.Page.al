page 99326 "IKA WA Entity Conversations"
{
    // FactBox para las fichas de cliente, proveedor y contacto.
    Caption = 'WhatsApp';
    PageType = ListPart;
    SourceTable = "IKA WA Conversation";
    SourceTableView = sorting("Last Message At") order(descending);
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Last Message At"; Rec."Last Message At")
                {
                    ApplicationArea = All;
                }
                field("Last Message Preview"; Rec."Last Message Preview")
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    begin
                        Page.Run(Page::"IKA WA Conversation", Rec);
                    end;
                }
                field("No. of Unread"; Rec."No. of Unread")
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    Style = Strong;
                }
                field("Phone No."; Rec."Phone No.")
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
            action(Open)
            {
                ApplicationArea = All;
                Caption = 'Abrir conversación';
                Image = View;
                ToolTip = 'Abre la conversación de WhatsApp.';

                trigger OnAction()
                begin
                    Page.Run(Page::"IKA WA Conversation", Rec);
                end;
            }
        }
    }
}
