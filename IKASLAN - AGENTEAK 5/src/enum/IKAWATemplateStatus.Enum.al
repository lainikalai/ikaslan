enum 50640 "IKA WA Template Status"
{
    Caption = 'Estado plantilla';
    Extensible = true;

    value(0; Unknown)
    {
        Caption = 'Desconocido';
    }
    value(10; Approved)
    {
        Caption = 'Aprobada';
    }
    value(20; Pending)
    {
        Caption = 'Pendiente';
    }
    value(30; Rejected)
    {
        Caption = 'Rechazada';
    }
    value(40; Paused)
    {
        Caption = 'En pausa';
    }
    value(50; Disabled)
    {
        Caption = 'Desactivada';
    }
}
