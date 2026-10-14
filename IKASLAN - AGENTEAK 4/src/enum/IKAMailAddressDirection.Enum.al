enum 99221 "IKA Mail Address Direction"
{
    // Qué emails muestra el FactBox / lista "Emails enviados y recibidos".
    Extensible = true;
    Caption = 'Dirección del email';

    value(0; All)
    {
        Caption = 'Todos';
    }
    value(1; Received)
    {
        Caption = 'Recibidos';
    }
    value(2; Sent)
    {
        Caption = 'Enviados';
    }
}
