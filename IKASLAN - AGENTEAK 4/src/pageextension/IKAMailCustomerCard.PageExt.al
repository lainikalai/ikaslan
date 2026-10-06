pageextension 50400 "IKA Mail Customer Card" extends "Customer Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part("IKA Mail Linked Emails"; "IKA Mail Linked Emails")
            {
                ApplicationArea = All;
                SubPageLink = "Entity Type" = const(Customer), "Entity No." = field("No.");
            }
        }
    }
}
