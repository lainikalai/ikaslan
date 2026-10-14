tableextension 99001 "IKA Sales Header" extends "Sales Header"
{
    fields
    {
        field(99001; "IKA Sales Request Entry No."; Integer)
        {
            Caption = 'Nº solicitud agente de ventas';
            DataClassification = CustomerContent;
            TableRelation = "IKA Sales Request Header";
            Editable = false;
        }
    }
}
