enum 50410 "IKA Mail Compose Mode"
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
}
