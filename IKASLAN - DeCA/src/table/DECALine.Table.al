/// <summary>
/// Cada línea es un envío. Varios envíos pueden ir en un mismo DeCA si cargador contractual
/// y transportista efectivo coinciden (Resolución 5/6/2026, apartado sexto).
/// </summary>
table 50020 "DECA Line"
{
    Caption = 'Envío DeCA';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Nº DeCA';
            TableRelation = "DECA Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Nº línea';
        }
        field(3; "Source Document No."; Code[20])
        {
            Caption = 'Nº documento origen';
        }

        // c) Lugar de origen y destino del envío
        field(10; "Origin Name"; Text[100])
        {
            Caption = 'Origen: nombre';
        }
        field(11; "Origin Address"; Text[100])
        {
            Caption = 'Origen: dirección';
        }
        field(12; "Origin Post Code"; Code[20])
        {
            Caption = 'Origen: C.P.';
        }
        field(13; "Origin City"; Text[30])
        {
            Caption = 'Origen: población';
        }
        field(20; "Destination Name"; Text[100])
        {
            Caption = 'Destino: nombre';
        }
        field(21; "Destination Address"; Text[100])
        {
            Caption = 'Destino: dirección';
        }
        field(22; "Destination Post Code"; Code[20])
        {
            Caption = 'Destino: C.P.';
        }
        field(23; "Destination City"; Text[30])
        {
            Caption = 'Destino: población';
        }

        // d) Naturaleza y peso de la mercancía
        field(30; "Goods Description"; Text[250])
        {
            Caption = 'Naturaleza de la mercancía';
        }
        field(31; "Gross Weight (kg)"; Decimal)
        {
            Caption = 'Peso (kg)';
            DecimalPlaces = 0 : 2;
            MinValue = 0;
        }
        field(32; "Alternative Magnitude"; Text[50])
        {
            Caption = 'Magnitud alternativa al peso';
        }
    }

    keys
    {
        key(PK; "Document No.", "Line No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        TestHeaderDraft();
    end;

    trigger OnModify()
    begin
        TestHeaderDraft();
    end;

    trigger OnDelete()
    begin
        TestHeaderDraft();
    end;

    local procedure TestHeaderDraft()
    var
        DECAHeader: Record "DECA Header";
    begin
        DECAHeader.Get("Document No.");
        DECAHeader.TestStatusDraft();
    end;
}
