page 99116 "IKA Field Aliases"
{
    Caption = 'Alias de campos de documentos';
    PageType = List;
    SourceTable = "IKA Field Alias";
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Pedidos de venta de clientes o albaranes de proveedores.';
                }
                field("Partner No."; Rec."Partner No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cliente (pedidos) o proveedor (albaranes). Vacío = alias válido para todos.';
                }
                field("Alias Field"; Rec."Alias Field")
                {
                    ApplicationArea = All;
                }
                field(Alias; Rec.Alias)
                {
                    ApplicationArea = All;
                    ToolTip = 'Texto tal como aparece en el documento, p.ej. "Su pedido", "Vuestra ref.", "Nº Lote", "F. Entrega".';
                }
                field(Note; Rec.Note)
                {
                    ApplicationArea = All;
                    ToolTip = 'Aclaración opcional para Claude, p.ej. "aparece en el pie de página".';
                }
            }
        }
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        PartnerFilter: Text;
        TypeFilter: Text;
    begin
        TypeFilter := Rec.GetFilter("Document Type");
        if TypeFilter <> '' then
            if Evaluate(Rec."Document Type", TypeFilter) then;
        PartnerFilter := Rec.GetFilter("Partner No.");
        if (PartnerFilter <> '') and (StrLen(PartnerFilter) <= MaxStrLen(Rec."Partner No.")) and (StrPos(PartnerFilter, '''') = 0) then
            Rec."Partner No." := CopyStr(PartnerFilter, 1, MaxStrLen(Rec."Partner No."));
    end;
}
