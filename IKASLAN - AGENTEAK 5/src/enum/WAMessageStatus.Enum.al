enum 50610 "IKA WA Message Status"
{
    Caption = 'Estado mensaje';
    Extensible = true;

    value(0; Received)
    {
        Caption = 'Recibido';
    }
    value(10; Sent)
    {
        Caption = 'Enviado';
    }
    value(20; Delivered)
    {
        Caption = 'Entregado';
    }
    value(30; Read)
    {
        Caption = 'Leído';
    }
    value(40; Failed)
    {
        Caption = 'Error';
    }
}
