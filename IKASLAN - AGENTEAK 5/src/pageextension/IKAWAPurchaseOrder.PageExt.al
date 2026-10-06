pageextension 50607 "IKA WA Purchase Order" extends "Purchase Order"
{
    actions
    {
        addlast(processing)
        {
            action("IKA WA Send Document")
            {
                ApplicationArea = All;
                Caption = 'Enviar por WhatsApp';
                Image = SendTo;
                ToolTip = 'Genera el PDF (informe de "Selección de informes") y lo envía por WhatsApp, con una plantilla o como mensaje libre.';

                trigger OnAction()
                var
                    PurchaseHeader: Record "Purchase Header";
                    DocumentSender: Codeunit "IKA WA Document Sender";
                begin
                    PurchaseHeader := Rec;
                    PurchaseHeader.SetRecFilter();
                    DocumentSender.SendPurchaseDocument(PurchaseHeader, "Report Selection Usage"::"P.Order", Rec."Buy-from Vendor No.", Rec."No.", 'Pedido compra');
                end;
            }
        }
    }
}
