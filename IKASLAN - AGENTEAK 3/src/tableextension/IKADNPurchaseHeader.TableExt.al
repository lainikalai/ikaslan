tableextension 99101 "IKA DN Purchase Header" extends "Purchase Header"
{
    fields
    {
        field(99101; "IKA DN Document Entry No."; Integer)
        {
            Caption = 'Último albarán aplicado (agente)';
            DataClassification = CustomerContent;
            TableRelation = "IKA DN Document";
            Editable = false;
        }
        field(99102; "IKA DN No. of Documents"; Integer)
        {
            Caption = 'Albaranes de proveedor (agente)';
            FieldClass = FlowField;
            CalcFormula = count("IKA DN Document Line" where("Purchase Order No." = field("No.")));
            Editable = false;
        }
    }
}
