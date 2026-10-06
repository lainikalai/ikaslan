table 50460 "IKA Mail Drop Target"
{
    // Tabla temporal con las zonas de destino que se muestran en la ficha del email.
    Caption = 'Zona de destino';
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entity Type"; Enum "IKA Mail Entity Type")
        {
            Caption = 'Tipo de entidad';
        }
        field(2; "Entity No."; Code[20])
        {
            Caption = 'Nº entidad';
        }
        field(10; Name; Text[100])
        {
            Caption = 'Nombre';
        }
        field(11; Kind; Enum "IKA Mail Target Kind")
        {
            Caption = 'Tipo de destino';
        }
        field(12; "Sort Order"; Integer)
        {
            Caption = 'Orden';
        }
    }

    keys
    {
        key(PK; "Entity Type", "Entity No.")
        {
            Clustered = true;
        }
        key(Sort; "Sort Order")
        {
        }
    }

    procedure GetTargetId(): Text
    begin
        exit(Format("Entity Type".AsInteger()) + '|' + "Entity No.");
    end;

    procedure ParseTargetId(TargetId: Text; var EntityType: Enum "IKA Mail Entity Type"; var EntityNo: Code[20])
    var
        Parts: List of [Text];
        Ordinal: Integer;
    begin
        Parts := TargetId.Split('|');
        Evaluate(Ordinal, Parts.Get(1));
        EntityType := Enum::"IKA Mail Entity Type".FromInteger(Ordinal);
        EntityNo := CopyStr(Parts.Get(2), 1, MaxStrLen(EntityNo));
    end;
}
