pageextension 99341 "IKA WA Salesperson Card" extends "Salesperson/Purchaser Card"
{
    layout
    {
        addfirst(factboxes)
        {
            part("IKA WA Conversations"; "IKA WA Entity Conversations")
            {
                ApplicationArea = All;
                SubPageLink = "Entity Type" = const(SalespersonPurchaser), "Entity No." = field(Code);
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
                    ToolTip = 'Envía una plantilla o, si la ventana de 24 h está abierta, un mensaje libre a este vendedor/comprador.';

                    trigger OnAction()
                    var
                        DocumentSender: Codeunit "IKA WA Document Sender";
                    begin
                        DocumentSender.SendToEntity("IKA WA Entity Type"::SalespersonPurchaser, Rec.Code);
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
                        PhoneMgt.OpenWaMe(PhoneMgt.GetEntityPhone("IKA WA Entity Type"::SalespersonPurchaser, Rec.Code), '');
                    end;
                }
                action("IKA WA Assigned Conversations")
                {
                    ApplicationArea = All;
                    Caption = 'Conversaciones asignadas';
                    Image = Documents;
                    ToolTip = 'Conversaciones de WhatsApp de clientes, proveedores y contactos de los que es responsable.';

                    trigger OnAction()
                    var
                        Conversation: Record "IKA WA Conversation";
                    begin
                        Conversation.SetRange("Salesperson Code", Rec.Code);
                        Page.Run(Page::"IKA WA Conversations", Conversation);
                    end;
                }
            }
        }
    }
}
