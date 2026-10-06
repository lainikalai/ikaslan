pageextension 99241 "IKA Mail Job Card" extends "Job Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part("IKA Mail Linked Emails"; "IKA Mail Linked Emails")
            {
                ApplicationArea = All;
                SubPageLink = "Entity Type" = const(Job), "Entity No." = field("No.");
            }
        }
    }
}
