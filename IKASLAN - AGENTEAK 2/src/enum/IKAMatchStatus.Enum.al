enum 50010 "IKA Match Status"
{
    Caption = 'Estado de coincidencia';
    Extensible = true;

    value(0; " ")
    {
        Caption = 'Sin resolver';
    }
    value(10; Matched)
    {
        Caption = 'Encontrado';
    }
    value(20; Ambiguous)
    {
        Caption = 'Ambiguo';
    }
    value(30; "Not Found")
    {
        Caption = 'No encontrado';
    }
    value(40; Manual)
    {
        Caption = 'Asignado manualmente';
    }
}
