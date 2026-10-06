pageextension 50000 "IKA Sales Order" extends "Sales Order"
{
    layout
    {
        addafter("External Document No.")
        {
            field("IKA Sales Request Entry No."; Rec."IKA Sales Request Entry No.")
            {
                ApplicationArea = All;
                Importance = Additional;
                ToolTip = 'Solicitud del agente de ventas (Claude) desde la que se creó este pedido.';

                trigger OnDrillDown()
                begin
                    OpenSalesRequest();
                end;
            }
        }
    }

    actions
    {
        addlast(navigation)
        {
            action("IKA Open Sales Request")
            {
                ApplicationArea = All;
                Caption = 'Solicitud del agente (Claude)';
                Image = Email;
                Enabled = Rec."IKA Sales Request Entry No." <> 0;
                ToolTip = 'Abre el email / solicitud de la que procede este pedido.';

                trigger OnAction()
                begin
                    OpenSalesRequest();
                end;
            }
        }
    }

    local procedure OpenSalesRequest()
    var
        RequestHeader: Record "IKA Sales Request Header";
    begin
        if RequestHeader.Get(Rec."IKA Sales Request Entry No.") then
            Page.Run(Page::"IKA Sales Request", RequestHeader);
    end;
}
