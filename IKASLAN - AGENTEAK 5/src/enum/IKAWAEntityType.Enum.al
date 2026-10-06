enum 50630 "IKA WA Entity Type"
{
    Caption = 'Tipo de entidad';
    Extensible = true;

    value(0; " ")
    {
        Caption = '(sin vincular)';
    }
    value(10; Customer)
    {
        Caption = 'Cliente';
    }
    value(20; Vendor)
    {
        Caption = 'Proveedor';
    }
    value(30; Contact)
    {
        Caption = 'Contacto';
    }
}
