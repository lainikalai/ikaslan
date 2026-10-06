page 50220 "IKA DN Field Aliases"
{
    Caption = 'Alias de campos de albarán';
    PageType = List;
    SourceTable = "IKA DN Field Alias";
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Vacío = alias válido para todos los proveedores.';
                }
                field("Alias Field"; Rec."Alias Field")
                {
                    ApplicationArea = All;
                }
                field(Alias; Rec.Alias)
                {
                    ApplicationArea = All;
                    ToolTip = 'Texto tal como aparece en el albarán, p.ej. "Su pedido", "Vuestra ref.", "Nº Lote".';
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
        VendorFilter: Text;
    begin
        VendorFilter := Rec.GetFilter("Vendor No.");
        if (VendorFilter <> '') and (StrLen(VendorFilter) <= MaxStrLen(Rec."Vendor No.")) and (StrPos(VendorFilter, '''') = 0) then
            Rec."Vendor No." := CopyStr(VendorFilter, 1, MaxStrLen(Rec."Vendor No."));
    end;
}
