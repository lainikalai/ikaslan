enum 99201 "IKA Mail Entity Type"
{
    Caption = 'Tipo de entidad';
    Extensible = true;

    value(0; Customer)
    {
        Caption = 'Cliente';
    }
    value(10; Vendor)
    {
        Caption = 'Proveedor';
    }
    value(20; Contact)
    {
        Caption = 'Contacto';
    }
    value(30; "Bank Account")
    {
        Caption = 'Banco';
    }
    value(40; Resource)
    {
        Caption = 'Recurso';
    }
    value(50; Item)
    {
        Caption = 'Producto';
    }
    value(60; Employee)
    {
        Caption = 'Empleado';
    }
    value(70; "Fixed Asset")
    {
        Caption = 'Activo fijo';
    }
    value(80; Job)
    {
        Caption = 'Proyecto';
    }
}
