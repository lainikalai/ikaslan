pageextension 50406 "IKA Mail Employee Card" extends "Employee Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part("IKA Mail Linked Emails"; "IKA Mail Linked Emails")
            {
                ApplicationArea = All;
                SubPageLink = "Entity Type" = const(Employee), "Entity No." = field("No.");
            }
        }
    }
}
