pageextension 50405 "IKA Mail Item Card" extends "Item Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part("IKA Mail Linked Emails"; "IKA Mail Linked Emails")
            {
                ApplicationArea = All;
                SubPageLink = "Entity Type" = const(Item), "Entity No." = field("No.");
            }
        }
    }
}
