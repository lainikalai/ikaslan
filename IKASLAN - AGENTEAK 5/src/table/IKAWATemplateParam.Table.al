table 99316 "IKA WA Template Param"
{
    // De dónde sale cada variable {{n}} de una plantilla cuando se envía desde un tipo de documento.
    // Ej.: plantilla "factura_emitida" desde "Hist. cab. factura venta" (112):
    //   {{1}} = Nombre del destinatario, {{2}} = campo "Nº", {{3}} = campo "Importe IVA incl.".
    Caption = 'Variable de plantilla de WhatsApp';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Account Code"; Code[20])
        {
            Caption = 'Cuenta';
            TableRelation = "IKA WA Account";
        }
        field(2; "Template Name"; Text[100])
        {
            Caption = 'Plantilla';
        }
        field(3; "Language Code"; Text[10])
        {
            Caption = 'Idioma';
        }
        field(4; "Table ID"; Integer)
        {
            Caption = 'Id tabla origen';
            TableRelation = AllObjWithCaption."Object ID" where("Object Type" = const(Table));
            BlankZero = true;
        }
        field(5; "Parameter No."; Integer)
        {
            Caption = 'Nº variable';
            MinValue = 1;
        }
        field(10; Source; Enum "IKA WA Param Source")
        {
            Caption = 'Origen';
        }
        field(11; "Field No."; Integer)
        {
            Caption = 'Nº campo';
            TableRelation = Field."No." where(TableNo = field("Table ID"));
            BlankZero = true;
        }
        field(12; "Field Caption"; Text[80])
        {
            Caption = 'Campo';
            FieldClass = FlowField;
            CalcFormula = lookup(Field."Field Caption" where(TableNo = field("Table ID"), "No." = field("Field No.")));
            Editable = false;
        }
        field(13; "Constant Value"; Text[250])
        {
            Caption = 'Valor fijo';
        }
        field(20; "Table Caption"; Text[250])
        {
            Caption = 'Tabla';
            FieldClass = FlowField;
            CalcFormula = lookup(AllObjWithCaption."Object Caption" where("Object Type" = const(Table), "Object ID" = field("Table ID")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Account Code", "Template Name", "Language Code", "Table ID", "Parameter No.")
        {
            Clustered = true;
        }
    }
}
