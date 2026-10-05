enum 50050 "IKA Sales Mail Account Type"
{
    Caption = 'Tipo de cuenta';
    Extensible = false;

    value(0; Personal)
    {
        Caption = 'Personal (de un usuario)';
    }
    value(10; Shared)
    {
        Caption = 'Compartida';
    }
}
