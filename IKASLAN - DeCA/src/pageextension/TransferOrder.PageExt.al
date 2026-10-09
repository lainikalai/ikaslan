pageextension 50030 "DECA Transfer Order" extends "Transfer Order"
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
                ToolTip = 'Crea el borrador del DeCA a partir de este pedido de transferencia.';

                trigger OnAction()
                var
                    DECAHeader: Record "DECA Header";
                    DECAManagement: Codeunit "DECA Management";
                begin
                    DECAHeader.Get(DECAManagement.CreateFromTransferOrder(Rec));
                    Page.Run(Page::"DECA Card", DECAHeader);
                end;
            }
        }
    }
}
