pageextension 50401 "IKA Mail Vendor Card" extends "Vendor Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part("IKA Mail Linked Emails"; "IKA Mail Linked Emails")
            {
                ApplicationArea = All;
                SubPageLink = "Entity Type" = const(Vendor), "Entity No." = field("No.");
            }
        }
    }
}
