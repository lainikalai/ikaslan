table 50220 "IKA DN Field Alias"
{
    // Nombres con los que aparece cada campo en los albaranes ("Su pedido", "Vuestra ref.", "Lote"...).
    // Con "Nº proveedor" vacío el alias es global (vale para todos los proveedores).
    Caption = 'Alias de campo de albarán';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Nº proveedor';
            TableRelation = Vendor;
        }
        field(2; "Alias Field"; Enum "IKA DN Alias Field")
        {
            Caption = 'Campo';
        }
        field(3; Alias; Text[100])
        {
            Caption = 'Texto en el albarán';
            NotBlank = true;
        }
        field(10; Note; Text[250])
        {
            Caption = 'Nota';
        }
    }

    keys
    {
        key(PK; "Vendor No.", "Alias Field", Alias)
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Devuelve las líneas de alias (globales + del proveedor) en formato legible para el prompt.
    /// </summary>
    procedure GetAliasesText(VendorNo: Code[20]): Text
    var
        FieldAlias: Record "IKA DN Field Alias";
        Result: TextBuilder;
    begin
        FieldAlias.SetFilter("Vendor No.", '%1|%2', '', VendorNo);
        if FieldAlias.FindSet() then
            repeat
                Result.Append('- ' + Format(FieldAlias."Alias Field") + ': "' + FieldAlias.Alias + '"');
                if FieldAlias.Note <> '' then
                    Result.Append(' (' + FieldAlias.Note + ')');
                Result.AppendLine();
            until FieldAlias.Next() = 0;
        exit(Result.ToText());
    end;
}
