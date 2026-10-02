enum 50040 "IKA Sales Req. Source"
{
    Caption = 'Origen solicitud de venta';
    Extensible = true;

    value(0; Manual)
    {
        Caption = 'Manual';
    }
    value(10; Email)
    {
        Caption = 'Email (Outlook)';
    }
}
