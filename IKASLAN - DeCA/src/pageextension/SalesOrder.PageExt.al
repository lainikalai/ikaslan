pageextension 50010 "DECA Sales Order" extends "Sales Order"
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
                ToolTip = 'Crea el borrador del DeCA a partir de este pedido, antes de que salga la mercancía.';

                trigger OnAction()
                var
                    DECAHeader: Record "DECA Header";
                    DECAManagement: Codeunit "DECA Management";
                begin
                    DECAHeader.Get(DECAManagement.CreateFromSalesOrder(Rec));
                    Page.Run(Page::"DECA Card", DECAHeader);
                end;
            }
        }
    }
}
