pageextension 50040 "DECA Posted Transfer Shipment" extends "Posted Transfer Shipment"
{
    actions
    {
        addlast(Processing)
        {
            action(DECACreate)
            {
                ApplicationArea = All;
                Caption = 'Crear DeCA';
                Image = Document;
                ToolTip = 'Crea el borrador del DeCA a partir de este envío de transferencia.';

                trigger OnAction()
                var
                    DECAHeader: Record "DECA Header";
                    DECAManagement: Codeunit "DECA Management";
                begin
                    DECAHeader.Get(DECAManagement.CreateFromTransferShipment(Rec));
                    Page.Run(Page::"DECA Card", DECAHeader);
                end;
            }
        }
    }
}
