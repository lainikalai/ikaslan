pageextension 99201 "IKA Mail Customer Card" extends "Customer Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part("IKA Mail Address Emails"; "IKA Mail Address Emails")
            {
                ApplicationArea = All;
            }
            part("IKA Mail Linked Emails"; "IKA Mail Linked Emails")
            {
                ApplicationArea = All;
                SubPageLink = "Entity Type" = const(Customer), "Entity No." = field("No.");
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        // Emails enviados y recibidos con el email de la ficha (vacío = el usuario escribe uno en el FactBox)
        CurrPage."IKA Mail Address Emails".Page.SetContext(Rec."E-Mail", '');
    end;
}
