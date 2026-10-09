enum 99031 "IKA Mail Filter Type"
{
    Caption = 'Tipo de documento';
    Extensible = true;

    value(0; "Sales Order")
    {
        Caption = 'Pedido de venta (clientes)';
    }
    value(10; "Delivery Note")
    {
        Caption = 'Albarán de compra (proveedores)';
    }
}
