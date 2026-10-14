pageextension 99256 "IKA Mail Posted Sales Shipment" extends "Posted Sales Shipment"
{
    // FactBoxes "Emails recibidos" y "Emails enviados": emails con el cliente (y el contacto del documento)
    // cuyo asunto contiene el nº del albarán, del pedido o la referencia del cliente.
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
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        AddressSearch: Codeunit "IKA Mail Address Search";
        Addresses: Text;
        SubjectFilter: Text;
    begin
        Addresses := AddressSearch.GetCustomerAddresses(Rec."Sell-to Customer No.", Rec."Sell-to Contact No.");
        SubjectFilter := AddressSearch.GetDocumentSubjectFilter(Rec."No.", Rec."Order No.", Rec."External Document No.");
        CurrPage."IKA Mail Received Emails".Page.SetContext(Addresses, SubjectFilter, Enum::"IKA Mail Address Direction"::Received);
        CurrPage."IKA Mail Sent Emails".Page.SetContext(Addresses, SubjectFilter, Enum::"IKA Mail Address Direction"::Sent);
    end;
}
