enum 99101 "IKA DN Status"
{
    Caption = 'Estado albarán';
    Extensible = true;

    value(0; New)
    {
        Caption = 'Nuevo';
    }
    value(10; Extracted)
    {
        Caption = 'Extraído';
    }
    value(20; "Needs Review")
    {
        Caption = 'Requiere revisión';
    }
    value(30; Matched)
    {
        Caption = 'Conciliado';
    }
    value(40; Applied)
    {
        Caption = 'Aplicado a pedido';
    }
    value(45; Received)
    {
        Caption = 'Recepción registrada';
    }
    value(50; Error)
    {
        Caption = 'Error';
    }
    value(60; Ignored)
    {
        Caption = 'Ignorado';
    }
}
