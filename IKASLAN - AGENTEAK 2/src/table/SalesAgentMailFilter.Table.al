table 50010 "IKA Sales Agent Mail Filter"
{
    Caption = 'Filtro de correo agente de ventas';
    DataClassification = CustomerContent;
    LookupPageId = "IKA Sales Agent Mail Filters";
    DrillDownPageId = "IKA Sales Agent Mail Filters";

    fields
    {
        field(1; "Line No."; Integer)
        {
            Caption = 'Nº línea';
            AutoIncrement = true;
        }
        field(10; Active; Boolean)
        {
            Caption = 'Activo';
            InitValue = true;
        }
        field(20; Description; Text[100])
        {
            Caption = 'Descripción';
        }
        field(30; "Sender Filter"; Text[250])
        {
            Caption = 'Filtro remitente';
            ToolTip = 'Patrón con comodines * y ?. Ej.: *@cliente.com o compras@cliente.com. Vacío = cualquier remitente.';
        }
        field(40; "Subject Filter"; Text[250])
        {
            Caption = 'Filtro asunto';
            ToolTip = 'Patrón con comodines * y ?. Ej.: *pedido*. Vacío = cualquier asunto. No distingue mayúsculas.';
        }
        field(50; "Customer No."; Code[20])
        {
            Caption = 'Nº cliente asociado';
            TableRelation = Customer;
            ToolTip = 'Si se informa, los emails que cumplan el filtro se asignan directamente a este cliente.';
        }
        field(60; Priority; Integer)
        {
            Caption = 'Prioridad';
            ToolTip = 'Los filtros se evalúan de menor a mayor prioridad; gana el primero que coincide.';
        }
    }

    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
        key(Priority; Priority, "Line No.")
        {
        }
    }

    procedure FindMatchingFilter(SenderAddress: Text; Subject: Text): Boolean
    begin
        Reset();
        SetCurrentKey(Priority, "Line No.");
        SetRange(Active, true);
        if FindSet() then
            repeat
                if MatchesPattern(SenderAddress, "Sender Filter") and MatchesPattern(Subject, "Subject Filter") then
                    exit(true);
            until Next() = 0;
        exit(false);
    end;

    /// <summary>
    /// Comparación con comodines (* = cualquier secuencia, ? = un carácter), sin distinguir mayúsculas.
    /// Un patrón vacío coincide con cualquier valor.
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
