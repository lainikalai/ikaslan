table 99006 "IKA Sales Agent Mail Filter"
{
    Caption = 'Filtro de correo agentes (Claude)';
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
        field(5; "Document Type"; Enum "IKA Mail Filter Type")
        {
            Caption = 'Tipo de documento';
            ToolTip = 'Pedidos de venta de clientes o albaranes de proveedores. Decide qué agente procesa los emails que cumplen el filtro.';
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
            ToolTip = 'Patrón con comodines * y ?. Ej.: *@cliente.com o compras@cliente.com. Vacío = cualquier remitente. Varias opciones con | (o) y condiciones que deben cumplirse todas con & (y).';
        }
        field(40; "Subject Filter"; Text[250])
        {
            Caption = 'Filtro asunto';
            ToolTip = 'Patrón con comodines * y ?. Ej.: *pedido*. Vacío = cualquier asunto. No distingue mayúsculas ni acentos. | = o: *Pedido*RAMOS*|*Albarán*RAMOS*. & = y: *Pedido*&*RAMOS*.';
        }
        field(42; "Body Filter"; Text[250])
        {
            Caption = 'Filtro cuerpo';
            ToolTip = 'Texto que debe aparecer en el cuerpo del email, con comodines: *PC26* o *pedido de compra*. | = o, & = y. Vacío = no se filtra por el cuerpo. No distingue mayúsculas ni acentos.';
        }
        field(45; "File Name Filter"; Text[250])
        {
            Caption = 'Filtro nombre fichero';
            ToolTip = 'Solo albaranes de la carpeta de SharePoint/OneDrive: patrón con comodines, p.ej. ALB_PROV1_*.pdf.';
        }
        field(50; "Customer No."; Code[20])
        {
            Caption = 'Nº cliente asociado';
            TableRelation = Customer;
            ToolTip = 'Si se informa, los emails que cumplan el filtro se asignan directamente a este cliente.';
        }
        field(51; "Vendor No."; Code[20])
        {
            Caption = 'Nº proveedor asociado';
            TableRelation = Vendor;
            ToolTip = 'Albaranes: si se informa, los documentos que cumplan el filtro se asignan directamente a este proveedor.';
        }
        field(60; Priority; Integer)
        {
            Caption = 'Prioridad';
            ToolTip = 'Los filtros se evalúan de menor a mayor prioridad; gana el primero que coincide.';
        }
        field(70; "Extraction Instructions"; Text[2048])
        {
            Caption = 'Instrucciones de extracción';
            ToolTip = 'Cómo vienen los documentos (PDF) que cumplen este filtro: dónde está el nº de pedido o de albarán, qué columna es cada código, fechas, unidades... Se envía a Claude con estos emails. Pulse ... para editarlo en una ventana.';
        }
        field(80; "Item Code Type"; Enum "IKA Item Code Type")
        {
            Caption = 'El código de artículo del documento es';
            ToolTip = 'Qué representa el código de artículo que imprime este cliente o proveedor. Automático = que lo deduzca Claude.';
        }
        field(81; "Prices Included"; Option)
        {
            Caption = 'Documento valorado';
            OptionMembers = Unknown,Yes,No;
            OptionCaption = 'Desconocido,Sí,No';
        }
        field(90; "Example JSON"; Blob)
        {
            Caption = 'Ejemplo validado';
        }
        field(91; "Example Entry No."; Integer)
        {
            Caption = 'Nº mov. del ejemplo';
            Editable = false;
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

    /// <summary>
    /// Primer filtro activo del tipo indicado (por prioridad) que cumple remitente y asunto. Los filtros
    /// sin remitente, asunto ni cuerpo (solo de nombre de fichero) no se aplican al correo.
    /// </summary>
    procedure FindMatchingFilter(DocumentType: Enum "IKA Mail Filter Type"; SenderAddress: Text; Subject: Text; BodyText: Text): Boolean
    begin
        Reset();
        SetCurrentKey(Priority, "Line No.");
        SetRange("Document Type", DocumentType);
        SetRange(Active, true);
        if FindSet() then
            repeat
                if ("Sender Filter" <> '') or ("Subject Filter" <> '') or ("Body Filter" <> '') then
                    if MatchesFilter(SenderAddress, "Sender Filter") and MatchesFilter(Subject, "Subject Filter") and MatchesBody(BodyText) then
                        exit(true);
            until Next() = 0;
        exit(false);
    end;

    /// <summary>
    /// El filtro de cuerpo busca el texto en cualquier parte del cuerpo: se le añade * delante y detrás si no lo lleva.
    /// </summary>
    local procedure MatchesBody(BodyText: Text): Boolean
    var
        Alternative: Text;
        Condition: Text;
        BodyFilter: Text;
        Part: Text;
    begin
        if DelChr("Body Filter", '=', ' ') = '' then
            exit(true);
        foreach Alternative in "Body Filter".Split('|') do begin
            Part := '';
            foreach Condition in Alternative.Split('&') do
                if Condition.Trim() <> '' then begin
                    if Part <> '' then
                        Part += '&';
                    Part += '*' + Condition.Trim().TrimStart('*').TrimEnd('*') + '*';
                end;
            if Part <> '' then begin
                if BodyFilter <> '' then
                    BodyFilter += '|';
                BodyFilter += Part;
            end;
        end;
        exit(MatchesFilter(BodyText, BodyFilter));
    end;

    procedure FindByFileName(DocumentType: Enum "IKA Mail Filter Type"; FileName: Text): Boolean
    begin
        Reset();
        SetCurrentKey(Priority, "Line No.");
        SetRange("Document Type", DocumentType);
        SetRange(Active, true);
        SetFilter("File Name Filter", '<>%1', '');
        if FindSet() then
            repeat
                if MatchesFilter(FileName, "File Name Filter") then
                    exit(true);
            until Next() = 0;
        exit(false);
    end;

    /// <summary>
    /// Cliente (pedidos) o proveedor (albaranes) asociado al filtro.
    /// </summary>
    procedure GetPartnerNo(): Code[20]
    begin
        if "Document Type" = "Document Type"::"Delivery Note" then
            exit("Vendor No.");
        exit("Customer No.");
    end;

    procedure SetExampleJson(NewText: Text; EntryNo: Integer)
    var
        OutStr: OutStream;
    begin
        Clear("Example JSON");
        "Example JSON".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(NewText);
        "Example Entry No." := EntryNo;
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

    procedure ClearExample()
    begin
        Clear("Example JSON");
        "Example Entry No." := 0;
    end;

    procedure HasExample(): Boolean
    begin
        CalcFields("Example JSON");
        exit("Example JSON".HasValue());
    end;

    /// <summary>
    /// Filtro con varias opciones: la barra vertical separa alternativas (o) y el ampersand condiciones que
    /// deben cumplirse todas (y), que se evalúan antes, como en los filtros de BC. Vacío = cualquier valor.
    /// </summary>
    procedure MatchesFilter(Value: Text; FilterText: Text): Boolean
    var
        Alternative: Text;
        Condition: Text;
        AllMatch: Boolean;
    begin
        if DelChr(FilterText, '=', ' ') = '' then
            exit(true);
        foreach Alternative in FilterText.Split('|') do
            if DelChr(Alternative, '=', ' ') <> '' then begin
                AllMatch := true;
                foreach Condition in Alternative.Split('&') do
                    if not MatchesPattern(Value, Condition.Trim()) then
                        AllMatch := false;
                if AllMatch then
                    exit(true);
            end;
        exit(false);
    end;

    /// <summary>
    /// Comparación con comodines (* = cualquier secuencia, ? = un carácter), sin distinguir mayúsculas ni acentos.
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
        Value := RemoveAccents(LowerCase(Value));
        Pattern := RemoveAccents(LowerCase(Pattern));
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

    local procedure RemoveAccents(Value: Text): Text
    begin
        exit(ConvertStr(Value, 'áéíóúàèìòùäëïöüâêîôûñç', 'aeiouaeiouaeiouaeiounc'));
    end;
}
