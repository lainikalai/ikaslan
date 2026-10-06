table 99106 "IKA DN Vendor Template"
{
    // "Plantilla" de proveedor: en lugar de coordenadas de campos (frágiles ante cambios de
    // formato), guarda CONOCIMIENTO que se pasa a Claude: cómo identificar los documentos del
    // proveedor, cómo llama a cada campo (alias), reglas propias y un albarán validado de ejemplo.
    Caption = 'Plantilla de albarán de proveedor';
    DataClassification = CustomerContent;
    LookupPageId = "IKA DN Vendor Templates";
    DrillDownPageId = "IKA DN Vendor Templates";

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Nº proveedor';
            TableRelation = Vendor;
            NotBlank = true;
        }
        field(2; "Vendor Name"; Text[100])
        {
            Caption = 'Nombre proveedor';
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Editable = false;
        }
        field(10; Active; Boolean)
        {
            Caption = 'Activa';
            InitValue = true;
        }
        // --- Identificación del origen ---
        field(20; "Sender Filter"; Text[250])
        {
            Caption = 'Filtro remitente';
            ToolTip = 'Patrón con comodines * y ?, p.ej. *@proveedor.com. Los emails que lo cumplan se asignan a este proveedor.';
        }
        field(21; "Subject Filter"; Text[250])
        {
            Caption = 'Filtro asunto';
            ToolTip = 'Patrón con comodines. Vacío = cualquier asunto.';
        }
        field(22; "File Name Filter"; Text[250])
        {
            Caption = 'Filtro nombre fichero';
            ToolTip = 'Patrón con comodines para ficheros de la carpeta, p.ej. ALB_PROV1_*.pdf.';
        }
        field(23; Priority; Integer)
        {
            Caption = 'Prioridad';
        }
        // --- Conocimiento para Claude ---
        field(30; "Item Code Type"; Enum "IKA DN Item Code Type")
        {
            Caption = 'El código de artículo del albarán es';
        }
        field(31; "Prices Included"; Option)
        {
            Caption = 'Albarán valorado';
            OptionMembers = Unknown,Yes,No;
            OptionCaption = 'Desconocido,Sí,No';
        }
        field(40; Instructions; Text[2048])
        {
            Caption = 'Instrucciones para Claude';
            ToolTip = 'Reglas propias del proveedor, p.ej.: "El nº de nuestro pedido aparece como Su ref. en la cabecera"; "Las cantidades están en cajas de 6 unidades".';
        }
        field(50; "Example JSON"; Blob)
        {
            Caption = 'Ejemplo (albarán validado)';
        }
        field(51; "Example Document Entry No."; Integer)
        {
            Caption = 'Nº mov. albarán de ejemplo';
            TableRelation = "IKA DN Document";
            Editable = false;
        }
        // --- Estadística ---
        field(60; "No. of Documents"; Integer)
        {
            Caption = 'Nº albaranes procesados';
            FieldClass = FlowField;
            CalcFormula = count("IKA DN Document" where("Vendor No." = field("Vendor No.")));
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Vendor No.")
        {
            Clustered = true;
        }
        key(Priority; Priority, "Vendor No.")
        {
        }
    }

    trigger OnDelete()
    var
        FieldAlias: Record "IKA DN Field Alias";
    begin
        FieldAlias.SetRange("Vendor No.", "Vendor No.");
        FieldAlias.DeleteAll(true);
    end;

    procedure FindByEmail(SenderAddress: Text; Subject: Text): Boolean
    begin
        Reset();
        SetCurrentKey(Priority, "Vendor No.");
        SetRange(Active, true);
        SetFilter("Sender Filter", '<>%1', '');
        if FindSet() then
            repeat
                if MatchesPattern(SenderAddress, "Sender Filter") and MatchesPattern(Subject, "Subject Filter") then
                    exit(true);
            until Next() = 0;
        exit(false);
    end;

    procedure FindByFileName(FileName: Text): Boolean
    begin
        Reset();
        SetCurrentKey(Priority, "Vendor No.");
        SetRange(Active, true);
        SetFilter("File Name Filter", '<>%1', '');
        if FindSet() then
            repeat
                if MatchesPattern(FileName, "File Name Filter") then
                    exit(true);
            until Next() = 0;
        exit(false);
    end;

    procedure SetExampleJson(NewText: Text; DocumentEntryNo: Integer)
    var
        OutStr: OutStream;
    begin
        Clear("Example JSON");
        "Example JSON".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(NewText);
        "Example Document Entry No." := DocumentEntryNo;
    end;

    procedure GetExampleJson(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
    begin
        CalcFields("Example JSON");
        if not "Example JSON".HasValue() then
            exit('');
        "Example JSON".CreateInStream(InStr, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator()));
    end;

    /// <summary>
    /// Comparación con comodines (* y ?) sin distinguir mayúsculas. Patrón vacío = cualquier valor.
    /// </summary>
    procedure MatchesPattern(Value: Text; Pattern: Text): Boolean
    var
        ValuePos: Integer;
        PatternPos: Integer;
        StarPatternPos: Integer;
        StarValuePos: Integer;
    begin
        if Pattern = '' then
            exit(true);
        Value := LowerCase(Value);
        Pattern := LowerCase(Pattern);
        ValuePos := 1;
        PatternPos := 1;
        while ValuePos <= StrLen(Value) do
            if (PatternPos <= StrLen(Pattern)) and ((CopyStr(Pattern, PatternPos, 1) = '?') or (CopyStr(Pattern, PatternPos, 1) = CopyStr(Value, ValuePos, 1))) then begin
                ValuePos += 1;
                PatternPos += 1;
            end else
                if (PatternPos <= StrLen(Pattern)) and (CopyStr(Pattern, PatternPos, 1) = '*') then begin
                    StarPatternPos := PatternPos;
                    StarValuePos := ValuePos;
                    PatternPos += 1;
                end else
                    if StarPatternPos <> 0 then begin
                        PatternPos := StarPatternPos + 1;
                        StarValuePos += 1;
                        ValuePos := StarValuePos;
                    end else
                        exit(false);

        while (PatternPos <= StrLen(Pattern)) and (CopyStr(Pattern, PatternPos, 1) = '*') do
            PatternPos += 1;
        exit(PatternPos > StrLen(Pattern));
    end;
}
