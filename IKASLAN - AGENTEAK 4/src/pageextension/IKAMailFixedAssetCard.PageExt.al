pageextension 99236 "IKA Mail Fixed Asset Card" extends "Fixed Asset Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part("IKA Mail Linked Emails"; "IKA Mail Linked Emails")
            {
                ApplicationArea = All;
                SubPageLink = "Entity Type" = const("Fixed Asset"), "Entity No." = field("No.");
            }
        }
    }
}
