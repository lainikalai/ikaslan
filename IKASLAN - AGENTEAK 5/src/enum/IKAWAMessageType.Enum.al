enum 50620 "IKA WA Message Type"
{
    Caption = 'Tipo de mensaje';
    Extensible = true;

    value(0; "Plain Text")
    {
        Caption = 'Texto';
    }
    value(10; Template)
    {
        Caption = 'Plantilla';
    }
    value(20; Document)
    {
        Caption = 'Documento';
    }
    value(30; Image)
    {
        Caption = 'Imagen';
    }
    value(40; Audio)
    {
        Caption = 'Audio';
    }
    value(50; Video)
    {
        Caption = 'Vídeo';
    }
    value(60; Sticker)
    {
        Caption = 'Sticker';
    }
    value(70; Location)
    {
        Caption = 'Ubicación';
    }
    value(80; Contacts)
    {
        Caption = 'Contacto';
    }
    value(90; Interactive)
    {
        Caption = 'Respuesta interactiva';
    }
    value(100; Button)
    {
        Caption = 'Botón';
    }
    value(110; Reaction)
    {
        Caption = 'Reacción';
    }
    value(120; Other)
    {
        Caption = 'Otro';
    }
}
