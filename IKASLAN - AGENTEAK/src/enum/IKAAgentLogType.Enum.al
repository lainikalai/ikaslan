enum 99011 "IKA Agent Log Type"
{
    Caption = 'Tipo de registro';
    Extensible = true;

    value(0; Information)
    {
        Caption = 'Información';
    }
    value(10; Warning)
    {
        Caption = 'Advertencia';
    }
    value(20; Error)
    {
        Caption = 'Error';
    }
    value(30; "Claude Call")
    {
        Caption = 'Llamada a Claude';
    }
    value(40; "Graph Call")
    {
        Caption = 'Llamada a Graph';
    }
}
