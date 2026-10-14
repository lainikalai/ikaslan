enum 99131 "IKA Item Code Type"
{
    Caption = 'Tipo de código de artículo';
    Extensible = true;

    value(0; Auto)
    {
        Caption = 'Automático';
    }
    value(10; "Vendor Item No.")
    {
        Caption = 'Código del cliente / proveedor';
    }
    value(20; "Our Item No.")
    {
        Caption = 'Nuestro nº de producto';
    }
    value(30; EAN)
    {
        Caption = 'EAN / código de barras';
    }
}
