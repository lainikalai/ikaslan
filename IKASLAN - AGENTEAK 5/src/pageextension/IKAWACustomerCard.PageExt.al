pageextension 99301 "IKA WA Customer Card" extends "Customer Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part("IKA WA Conversations"; "IKA WA Entity Conversations")
            {
                ApplicationArea = All;
                SubPageLink = "Entity Type" = const(Customer), "Entity No." = field("No.");
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            group("IKA WA WhatsApp")
            {
                Caption = 'WhatsApp';
                Image = SendTo;

                action("IKA WA Send")
                {
                    ApplicationArea = All;
                    Caption = 'Enviar WhatsApp';
                    Image = SendTo;
                    ToolTip = 'Envía una plantilla o, si la ventana de 24 h está abierta, un mensaje libre.';

                    trigger OnAction()
                    var
                        DocumentSender: Codeunit "IKA WA Document Sender";
                    begin
                        DocumentSender.SendToEntity("IKA WA Entity Type"::Customer, Rec."No.");
                    end;
                }
                action("IKA WA Open WaMe")
                {
                    ApplicationArea = All;
                    Caption = 'Abrir en mi WhatsApp';
                    Image = Web;
                    ToolTip = 'Abre un chat con este teléfono en WhatsApp web o de escritorio (sin API).';

                    trigger OnAction()
                    var
                        PhoneMgt: Codeunit "IKA WA Phone Mgt.";
                    begin
                        PhoneMgt.OpenWaMe(PhoneMgt.GetEntityPhone("IKA WA Entity Type"::Customer, Rec."No."), '');
                    end;
                }
            }
        }
    }
}
