pageextension 99221 "IKA Mail Resource Card" extends "Resource Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part("IKA Mail Linked Emails"; "IKA Mail Linked Emails")
            {
                ApplicationArea = All;
                SubPageLink = "Entity Type" = const(Resource), "Entity No." = field("No.");
            }
        }
    }
}
