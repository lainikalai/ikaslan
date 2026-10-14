pageextension 50000 "DECA Shipping Agents" extends "Shipping Agents"
{
    layout
    {
        addafter(Name)
        {
            field("DECA Legal Name"; Rec."DECA Legal Name")
            {
                ApplicationArea = All;
                ToolTip = 'Denominación social del transportista efectivo. Si se deja vacía se usa el nombre.';
            }
            field("DECA VAT Registration No."; Rec."DECA VAT Registration No.")
            {
                ApplicationArea = All;
                ToolTip = 'NIF del transportista efectivo. Obligatorio en el DeCA.';
            }
            field("DECA E-Mail"; Rec."DECA E-Mail")
            {
                ApplicationArea = All;
                ToolTip = 'Dirección a la que se envía el DeCA por defecto.';
            }
        }
    }
}
