pageextension 99006 "IKA Customer Card" extends "Customer Card"
{
    layout
    {
        addlast(Content)
        {
            group("IKA Sales Agent")
            {
                Caption = 'Agente de ventas (Claude)';

                field("IKA Extraction Instructions"; Rec."IKA Extraction Instructions")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Cómo leer los pedidos de este cliente. Se envía a Claude solo con sus emails. Ej.: "El código de artículo es la columna Su referencia. La fecha de entrega va en cada línea. Las cantidades vienen en cajas de 12".';
                }
            }
        }
    }
}
