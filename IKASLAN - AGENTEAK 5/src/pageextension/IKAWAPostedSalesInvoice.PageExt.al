pageextension 99316 "IKA WA Posted Sales Invoice" extends "Posted Sales Invoice"
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
                    SalesInvoiceHeader: Record "Sales Invoice Header";
                    DocumentSender: Codeunit "IKA WA Document Sender";
                begin
                    SalesInvoiceHeader := Rec;
                    SalesInvoiceHeader.SetRecFilter();
                    DocumentSender.SendSalesDocument(SalesInvoiceHeader, "Report Selection Usage"::"S.Invoice", Rec."Sell-to Customer No.", Rec."No.", 'Factura');
                end;
            }
        }
    }
}
