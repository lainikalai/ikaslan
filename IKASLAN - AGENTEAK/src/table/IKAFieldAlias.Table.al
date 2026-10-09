table 99111 "IKA Field Alias"
{
    // Nombres con los que aparece cada campo en los documentos ("Su pedido", "Vuestra ref.", "Lote"...).
    // Por tipo de documento (pedidos de clientes / albaranes de proveedores). Con "Nº cliente/proveedor"
    // vacío el alias es global para ese tipo.
    Caption = 'Alias de campo de documento';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Type"; Enum "IKA Mail Filter Type")
        {
            Caption = 'Tipo de documento';
        }
        field(2; "Partner No."; Code[20])
        {
            Caption = 'Nº cliente / proveedor';
            TableRelation = if ("Document Type" = const("Sales Order")) Customer
            else
            if ("Document Type" = const("Delivery Note")) Vendor;
        }
        field(3; "Alias Field"; Enum "IKA Alias Field")
        {
            Caption = 'Campo';
        }
        field(4; Alias; Text[100])
        {
            Caption = 'Texto en el documento';
            NotBlank = true;
        }
        field(10; Note; Text[250])
        {
            Caption = 'Nota';
        }
    }

    keys
    {
        key(PK; "Document Type", "Partner No.", "Alias Field", Alias)
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Devuelve los alias (globales + del cliente/proveedor) del tipo de documento, en formato legible para el prompt.
    /// </summary>
    procedure GetAliasesText(DocumentType: Enum "IKA Mail Filter Type"; PartnerNo: Code[20]): Text
    var
        FieldAlias: Record "IKA Field Alias";
        Result: TextBuilder;
    begin
        FieldAlias.SetRange("Document Type", DocumentType);
        FieldAlias.SetFilter("Partner No.", '%1|%2', '', PartnerNo);
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
