pageextension 99326 "IKA WA Posted Sales Shipment" extends "Posted Sales Shipment"
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
                    SalesShipmentHeader: Record "Sales Shipment Header";
                    DocumentSender: Codeunit "IKA WA Document Sender";
                begin
                    SalesShipmentHeader := Rec;
                    SalesShipmentHeader.SetRecFilter();
                    DocumentSender.SendSalesDocument(SalesShipmentHeader, "Report Selection Usage"::"S.Shipment", Rec."Sell-to Customer No.", Rec."No.", 'Albaran');
                end;
            }
        }
    }
}
