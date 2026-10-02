enum 50260 "IKA DN Item Code Type"
{
    Caption = 'Tipo de código de artículo';
    Extensible = true;

    value(0; Auto)
    {
        Caption = 'Automático';
    }
    value(10; "Vendor Item No.")
    {
        Caption = 'Código del proveedor';
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
