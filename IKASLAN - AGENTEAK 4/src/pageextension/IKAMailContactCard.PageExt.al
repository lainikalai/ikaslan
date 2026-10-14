pageextension 99211 "IKA Mail Contact Card" extends "Contact Card"
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
                SubPageLink = "Entity Type" = const(Contact), "Entity No." = field("No.");
            }
            // Esta ficha no trae el FactBox de adjuntos estándar en todas las versiones.
            // Si al compilar o en pantalla aparece duplicado, borre esta parte.
            part("IKA Attached Documents"; "Doc. Attachment List Factbox")
            {
                ApplicationArea = All;
                Caption = 'Documentos adjuntos';
                SubPageLink = "Table ID" = const(5050), "No." = field("No.");
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        AddressSearch: Codeunit "IKA Mail Address Search";
        Addresses: Text;
    begin
        // Emails recibidos y enviados (dos FactBoxes) con los emails del contacto ("E-Mail" y "E-Mail 2")
        Addresses := AddressSearch.JoinAddresses(Rec."E-Mail", Rec."E-Mail 2");
        CurrPage."IKA Mail Received Emails".Page.SetContext(Addresses, '', Enum::"IKA Mail Address Direction"::Received);
        CurrPage."IKA Mail Sent Emails".Page.SetContext(Addresses, '', Enum::"IKA Mail Address Direction"::Sent);
    end;
}
