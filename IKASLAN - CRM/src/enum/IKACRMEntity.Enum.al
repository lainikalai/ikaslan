enum 99401 "IKA CRM Entity"
{
    Caption = 'Entidad del CRM';
    Extensible = true;

    value(0; " ")
    {
        Caption = ' ';
    }
    value(10; Account)
    {
        Caption = 'Cuenta';
    }
    value(20; Contact)
    {
        Caption = 'Contacto';
    }
    value(30; Lead)
    {
        Caption = 'Cliente potencial';
    }
    value(40; Opportunity)
    {
        Caption = 'Oportunidad';
    }
}
