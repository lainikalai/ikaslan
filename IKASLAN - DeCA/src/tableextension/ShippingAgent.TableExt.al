tableextension 50000 "DECA Shipping Agent" extends "Shipping Agent"
{
    fields
    {
        field(50000; "DECA Legal Name"; Text[100])
        {
            Caption = 'Denominación social (DeCA)';
            DataClassification = CustomerContent;
        }
        field(50001; "DECA VAT Registration No."; Text[20])
        {
            Caption = 'NIF (DeCA)';
            DataClassification = CustomerContent;
        }
        field(50002; "DECA E-Mail"; Text[250])
        {
            Caption = 'Email envío DeCA';
            DataClassification = CustomerContent;
            ExtendedDatatype = EMail;
        }
    }
}
