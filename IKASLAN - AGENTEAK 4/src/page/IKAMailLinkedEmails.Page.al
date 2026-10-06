page 99231 "IKA Mail Linked Emails"
{
    // FactBox para las fichas de cliente, proveedor, banco, etc.
    Caption = 'Emails vinculados';
    PageType = ListPart;
    SourceTable = "IKA Mail Link";
    SourceTableView = sorting("Entity Type", "Entity No.", "Linked At") order(descending);
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = All;
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    var
                        MailLinks: Page "IKA Mail Links";
                    begin
                        MailLinks.OpenEmailOfLink(Rec);
                    end;
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                }
                field("From Address"; Rec."From Address")
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
            action(OpenEmail)
            {
                ApplicationArea = All;
                Caption = 'Abrir email';
                Image = Email;
                ToolTip = 'Abre el email de origen.';

                trigger OnAction()
                var
                    MailLinks: Page "IKA Mail Links";
                begin
                    MailLinks.OpenEmailOfLink(Rec);
                end;
            }
        }
    }
}
