enum 99001 "IKA Sales Req. Status"
{
    Caption = 'Estado solicitud de venta';
    Extensible = true;

    value(0; New)
    {
        Caption = 'Nueva';
    }
    value(10; Extracted)
    {
        Caption = 'Extraída';
    }
    value(20; "Needs Review")
    {
        Caption = 'Requiere revisión';
    }
    value(30; Ready)
    {
        Caption = 'Lista para crear';
    }
    value(40; "Order Created")
    {
        Caption = 'Pedido creado';
    }
    value(50; Error)
    {
        Caption = 'Error';
    }
    value(60; Ignored)
    {
        Caption = 'Ignorada';
    }
}
