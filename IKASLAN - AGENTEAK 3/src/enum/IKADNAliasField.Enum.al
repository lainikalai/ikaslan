enum 99126 "IKA DN Alias Field"
{
    Caption = 'Campo del albarán';
    Extensible = true;

    value(0; "Delivery Note No.")
    {
        Caption = 'Nº albarán';
    }
    value(10; "Delivery Note Date")
    {
        Caption = 'Fecha albarán';
    }
    value(20; "Order Reference")
    {
        Caption = 'Nº pedido (nuestro)';
    }
    value(30; "Vendor Item Code")
    {
        Caption = 'Código artículo proveedor';
    }
    value(40; "Our Item Code")
    {
        Caption = 'Código artículo nuestro';
    }
    value(50; Description)
    {
        Caption = 'Descripción';
    }
    value(60; Quantity)
    {
        Caption = 'Cantidad';
    }
    value(70; "Unit of Measure")
    {
        Caption = 'Unidad de medida';
    }
    value(80; "Unit Price")
    {
        Caption = 'Precio unitario';
    }
    value(90; "Discount %")
    {
        Caption = '% Descuento';
    }
    value(100; "Lot No.")
    {
        Caption = 'Lote';
    }
    value(110; "Expiration Date")
    {
        Caption = 'Fecha caducidad';
    }
    value(120; "Our Customer Code")
    {
        Caption = 'Nuestro nº de cliente en el proveedor';
    }
}
