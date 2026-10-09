enum 99206 "IKA Mail Compose Mode"
{
    Caption = 'Modo de redacción';
    Extensible = false;

    value(0; Reply)
    {
        Caption = 'Responder';
    }
    value(10; ReplyAll)
    {
        Caption = 'Responder a todos';
    }
    value(20; Forward)
    {
        Caption = 'Reenviar';
    }
    value(30; New)
    {
        Caption = 'Nuevo email';
    }
}
