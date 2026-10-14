pageextension 99201 "IKA Mail Customer Card" extends "Customer Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part("IKA Mail Received Emails"; "IKA Mail Address Emails")
            {
                ApplicationArea = All;
                Caption = 'Emails recibidos';
            }
            part("IKA Mail Sent Emails"; "IKA Mail Address Emails")
            {
                ApplicationArea = All;
                Caption = 'Emails enviados';
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
        // Emails recibidos y enviados (dos FactBoxes) con el email de la ficha (vacío = el usuario escribe uno en el FactBox)
        CurrPage."IKA Mail Received Emails".Page.SetContext(Rec."E-Mail", '', Enum::"IKA Mail Address Direction"::Received);
        CurrPage."IKA Mail Sent Emails".Page.SetContext(Rec."E-Mail", '', Enum::"IKA Mail Address Direction"::Sent);
    end;
}
