pageextension 99321 "IKA WA Sales Order" extends "Sales Order"
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
                    SalesHeader: Record "Sales Header";
                    DocumentSender: Codeunit "IKA WA Document Sender";
                begin
                    SalesHeader := Rec;
                    SalesHeader.SetRecFilter();
                    DocumentSender.SendSalesDocument(SalesHeader, "Report Selection Usage"::"S.Order", Rec."Sell-to Customer No.", Rec."No.", 'Pedido');
                end;
            }
        }
    }
}
