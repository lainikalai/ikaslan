enum 50650 "IKA WA Header Type"
{
    Caption = 'Cabecera de plantilla';
    Extensible = true;

    value(0; " ")
    {
        Caption = 'Ninguna';
    }
    value(10; "Text Header")
    {
        Caption = 'Texto';
    }
    value(20; Document)
    {
        Caption = 'Documento';
    }
    value(30; Image)
    {
        Caption = 'Imagen';
    }
    value(40; Video)
    {
        Caption = 'Vídeo';
    }
}
