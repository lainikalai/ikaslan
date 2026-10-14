pageextension 50025 "DECA Posted Sales Shipments" extends "Posted Sales Shipments"
{
    actions
    {
        addlast(Processing)
        {
            action(DECACreate)
            {
                ApplicationArea = All;
                Caption = 'Crear DeCA agrupado';
                Image = Document;
                ToolTip = 'Crea un único DeCA con un envío por cada albarán seleccionado. Todos deben ir con el mismo transportista.';

                trigger OnAction()
                var
                    DECAHeader: Record "DECA Header";
                    SalesShipmentHeader: Record "Sales Shipment Header";
                    DECAManagement: Codeunit "DECA Management";
                begin
                    CurrPage.SetSelectionFilter(SalesShipmentHeader);
                    DECAHeader.Get(DECAManagement.CreateFromSalesShipments(SalesShipmentHeader));
                    Page.Run(Page::"DECA Card", DECAHeader);
                end;
            }
        }
    }
}
