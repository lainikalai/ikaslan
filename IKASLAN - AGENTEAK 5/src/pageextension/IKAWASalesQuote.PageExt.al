pageextension 99331 "IKA WA Sales Quote" extends "Sales Quote"
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
                    DocumentSender.SendSalesDocument(SalesHeader, "Report Selection Usage"::"S.Quote", Rec."Sell-to Customer No.", Rec."No.", 'Oferta');
                end;
            }
        }
    }
}
