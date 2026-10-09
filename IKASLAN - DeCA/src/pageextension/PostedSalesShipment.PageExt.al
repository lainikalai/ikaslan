pageextension 50020 "DECA Posted Sales Shipment" extends "Posted Sales Shipment"
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
                ToolTip = 'Crea el borrador del DeCA a partir de este albarán.';

                trigger OnAction()
                var
                    DECAHeader: Record "DECA Header";
                    SalesShipmentHeader: Record "Sales Shipment Header";
                    DECAManagement: Codeunit "DECA Management";
                begin
                    SalesShipmentHeader.SetRange("No.", Rec."No.");
                    DECAHeader.Get(DECAManagement.CreateFromSalesShipments(SalesShipmentHeader));
                    Page.Run(Page::"DECA Card", DECAHeader);
                end;
            }
        }
    }
}
