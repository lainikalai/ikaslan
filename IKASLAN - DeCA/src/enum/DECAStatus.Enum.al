enum 50000 "DECA Status"
{
    Extensible = true;
    Caption = 'Estado DeCA';

    value(0; Draft) { Caption = 'Borrador'; }
    value(1; Issued) { Caption = 'Emitido'; }
    value(2; Replaced) { Caption = 'Sustituido'; }
}
