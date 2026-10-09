page 99046 "IKA Extraction Instructions"
{
    Caption = 'Instrucciones de extracción';
    PageType = StandardDialog;

    layout
    {
        area(Content)
        {
            field(FilterDescription; FilterDescription)
            {
                ApplicationArea = All;
                Caption = 'Filtro';
                Editable = false;
                ToolTip = 'Filtro de correo al que pertenecen las instrucciones.';
            }
            field(Instructions; Instructions)
            {
                ApplicationArea = All;
                Caption = 'Instrucciones';
                MultiLine = true;
                ToolTip = 'Describa cómo organiza el cliente sus pedidos. Ej.: "Nuestro código de artículo está en la columna Su referencia. El nº de pedido aparece tras Pedido de compra nº. Cada línea tiene su fecha de entrega en la columna F. Entrega."';
            }
        }
    }

    var
        Instructions: Text;
        FilterDescription: Text;

    procedure SetInstructions(NewInstructions: Text; NewFilterDescription: Text)
    begin
        Instructions := NewInstructions;
        FilterDescription := NewFilterDescription;
    end;

    procedure GetInstructions(): Text
    begin
        exit(Instructions);
    end;
}
