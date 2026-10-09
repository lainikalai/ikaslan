tableextension 99006 "IKA Customer" extends Customer
{
    fields
    {
        field(99001; "IKA Extraction Instructions"; Text[2048])
        {
            Caption = 'Instrucciones de extracción (Claude)';
            DataClassification = CustomerContent;
        }
    }
}
