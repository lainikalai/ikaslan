pageextension 99276 "IKA Mail Posted Purch. Receipt" extends "Posted Purchase Receipt"
{
    // FactBoxes "Emails recibidos" y "Emails enviados": emails con el proveedor (y el contacto del documento)
    // cuyo asunto contiene el nº del albarán, del pedido o el nº de albarán del proveedor.
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
        Addresses := AddressSearch.GetVendorAddresses(Rec."Buy-from Vendor No.", Rec."Buy-from Contact No.");
        SubjectFilter := AddressSearch.GetDocumentSubjectFilter(Rec."No.", Rec."Order No.", Rec."Vendor Shipment No.");
        CurrPage."IKA Mail Received Emails".Page.SetContext(Addresses, SubjectFilter, Enum::"IKA Mail Address Direction"::Received);
        CurrPage."IKA Mail Sent Emails".Page.SetContext(Addresses, SubjectFilter, Enum::"IKA Mail Address Direction"::Sent);
    end;
}
