enum 50020 "DECA Source Type"
{
    Extensible = true;
    Caption = 'Tipo de origen DeCA';

    value(0; Manual) { Caption = 'Manual'; }
    value(1; "Sales Order") { Caption = 'Pedido de venta'; }
    value(2; "Sales Shipment") { Caption = 'Albarán de venta registrado'; }
    value(3; "Transfer Order") { Caption = 'Pedido de transferencia'; }
    value(4; "Transfer Shipment") { Caption = 'Envío de transferencia registrado'; }
}
