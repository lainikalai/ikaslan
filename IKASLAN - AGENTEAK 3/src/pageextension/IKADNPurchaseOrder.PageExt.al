pageextension 50200 "IKA DN Purchase Order" extends "Purchase Order"
{
    layout
    {
        addafter("Vendor Shipment No.")
        {
            field("IKA DN Document Entry No."; Rec."IKA DN Document Entry No.")
            {
                ApplicationArea = All;
                Importance = Additional;
                ToolTip = 'Último albarán del agente (Claude) aplicado a este pedido.';

                trigger OnDrillDown()
                var
                    DNDocument: Record "IKA DN Document";
                begin
                    if DNDocument.Get(Rec."IKA DN Document Entry No.") then
                        Page.Run(Page::"IKA DN Document", DNDocument);
                end;
            }
        }
    }

    actions
    {
        addlast(navigation)
        {
            action("IKA DN Delivery Notes")
            {
                ApplicationArea = All;
                Caption = 'Albaranes del proveedor (Claude)';
                Image = Document;
                ToolTip = 'Líneas de albaranes recibidos que se han conciliado con este pedido.';

                trigger OnAction()
                var
                    DocumentLine: Record "IKA DN Document Line";
                    DNDocument: Record "IKA DN Document";
                begin
                    DocumentLine.SetRange("Purchase Order No.", Rec."No.");
                    if DocumentLine.FindSet() then
                        repeat
                            if DNDocument.Get(DocumentLine."Document Entry No.") then
                                DNDocument.Mark(true);
                        until DocumentLine.Next() = 0;
                    DNDocument.MarkedOnly(true);
                    Page.Run(Page::"IKA DN Documents", DNDocument);
                end;
            }
        }
    }
}
