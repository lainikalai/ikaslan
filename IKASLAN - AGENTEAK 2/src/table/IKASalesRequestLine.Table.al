table 50030 "IKA Sales Request Line"
{
    Caption = 'Línea solicitud de venta (agente)';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Request Entry No."; Integer)
        {
            Caption = 'Nº mov. solicitud';
            TableRelation = "IKA Sales Request Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Nº línea';
        }
        // --- Extraído por Claude ---
        field(10; "Ext. Customer Item Code"; Text[50])
        {
            Caption = 'Cód. producto cliente (extraído)';
        }
        field(11; "Ext. Item No."; Text[50])
        {
            Caption = 'Nº producto nuestro (extraído)';
        }
        field(12; "Ext. Description"; Text[250])
        {
            Caption = 'Descripción (extraída)';
        }
        field(13; "Ext. Unit of Measure"; Text[30])
        {
            Caption = 'Unidad de medida (extraída)';
        }
        field(14; Quantity; Decimal)
        {
            Caption = 'Cantidad';
            DecimalPlaces = 0 : 5;
        }
        field(15; "Ext. Notes"; Text[250])
        {
            Caption = 'Notas (extraídas)';
        }
        // --- Resuelto en BC ---
        field(20; "Item No."; Code[20])
        {
            Caption = 'Nº producto';
            TableRelation = Item;

            trigger OnValidate()
            begin
                if "Item No." <> xRec."Item No." then begin
                    "Variant Code" := '';
                    "Unit of Measure Code" := '';
                end;
                Resolved := "Item No." <> '';
                if CurrFieldNo = FieldNo("Item No.") then begin
                    "Match Method" := '';
                    if "Item No." = '' then
                        "Match Status" := "Match Status"::" "
                    else
                        "Match Status" := "Match Status"::Manual;
                end;
            end;
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Cód. variante';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(22; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Cód. unidad medida';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(23; "Item Description"; Text[100])
        {
            Caption = 'Descripción producto';
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
            Editable = false;
        }
        field(24; "Match Status"; Enum "IKA Match Status")
        {
            Caption = 'Estado coincidencia';
            Editable = false;
        }
        field(25; "Match Method"; Text[50])
        {
            Caption = 'Método coincidencia';
            Editable = false;
        }
        field(26; Resolved; Boolean)
        {
            Caption = 'Resuelta';
            Editable = false;
        }
        field(27; "Resolution Note"; Text[250])
        {
            Caption = 'Nota de resolución';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Request Entry No.", "Line No.")
        {
            Clustered = true;
        }
    }

    procedure GetDisplayText(): Text
    var
        Result: Text;
    begin
        if "Ext. Customer Item Code" <> '' then
            Result := "Ext. Customer Item Code";
        if "Ext. Item No." <> '' then
            Result := JoinText(Result, "Ext. Item No.");
        if "Ext. Description" <> '' then
            Result := JoinText(Result, "Ext. Description");
        exit(Result);
    end;

    local procedure JoinText(Text1: Text; Text2: Text): Text
    begin
        if Text1 = '' then
            exit(Text2);
        exit(Text1 + ' - ' + Text2);
    end;
}
