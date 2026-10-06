enum 99211 "IKA Mail Target Kind"
{
    Caption = 'Tipo de destino';
    Extensible = false;

    value(0; Selected)
    {
        Caption = 'Seleccionado';
    }
    value(10; Suggested)
    {
        Caption = 'Sugerido';
    }
    value(20; Pinned)
    {
        Caption = 'Fijado';
    }
}
