table 99036 "IKA Claude Model Price"
{
    // Tarifas de la API de Claude por millón de tokens, por modelo y fecha de inicio (historial).
    // Cada llamada usa la tarifa vigente en su fecha y guarda en el registro el precio aplicado.
    // Cuando Anthropic cambie un precio, se añade una tarifa nueva con su "Válido desde"; una tarifa
    // que ya se ha usado no se puede modificar, para que los costes registrados sigan siendo comprobables.
    // Los valores iniciales son las tarifas estándar de la API de Anthropic en USD (septiembre de 2026).
    Caption = 'Tarifa de modelo de Claude';
    DataClassification = CustomerContent;
    LookupPageId = "IKA Claude Model Prices";
    DrillDownPageId = "IKA Claude Model Prices";

    fields
    {
        field(1; Model; Text[100])
        {
            Caption = 'Modelo';
            NotBlank = true;
        }
        field(2; "Valid From"; Date)
        {
            Caption = 'Válido desde';
            ToolTip = 'Fecha desde la que se aplica la tarifa. Vacío = desde siempre (hasta la siguiente tarifa del mismo modelo).';
        }
        field(10; Description; Text[100])
        {
            Caption = 'Descripción';
        }
        field(20; "Input Price per MTok"; Decimal)
        {
            Caption = 'Precio entrada (USD / millón de tokens)';
            DecimalPlaces = 2 : 4;
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckNotUsed();
            end;
        }
        field(30; "Output Price per MTok"; Decimal)
        {
            Caption = 'Precio salida (USD / millón de tokens)';
            DecimalPlaces = 2 : 4;
            MinValue = 0;

            trigger OnValidate()
            begin
                CheckNotUsed();
            end;
        }
    }

    keys
    {
        key(PK; Model, "Valid From")
        {
            Clustered = true;
        }
    }

    trigger OnRename()
    begin
        if xRec."Valid From" <> "Valid From" then
            xRec.CheckNotUsed();
    end;

    trigger OnDelete()
    begin
        CheckNotUsed();
    end;

    var
        PriceUsedErr: Label 'La tarifa de %1 válida desde %2 ya se ha usado en %3 llamada(s) registrada(s). Para un precio nuevo use "Nueva tarifa" con la fecha desde la que se aplica.', Comment = '%1 = model, %2 = valid from, %3 = no. of calls';

    /// <summary>
    /// Coste en USD con la tarifa vigente hoy. Ver CalcCostOnDate.
    /// </summary>
    procedure CalcCost(ModelId: Text; InputTokens: Integer; OutputTokens: Integer): Decimal
    var
        InputPrice: Decimal;
        OutputPrice: Decimal;
        ValidFrom: Date;
    begin
        exit(CalcCostOnDate(ModelId, InputTokens, OutputTokens, Today(), InputPrice, OutputPrice, ValidFrom));
    end;

    /// <summary>
    /// Coste en USD de una llamada con la tarifa vigente en OnDate. Devuelve también los precios aplicados
    /// y la fecha de inicio de esa tarifa. 0 si el modelo no tiene tarifa para esa fecha.
    /// </summary>
    procedure CalcCostOnDate(ModelId: Text; InputTokens: Integer; OutputTokens: Integer; OnDate: Date; var InputPrice: Decimal; var OutputPrice: Decimal; var ValidFrom: Date): Decimal
    var
        ModelPrice: Record "IKA Claude Model Price";
    begin
        InputPrice := 0;
        OutputPrice := 0;
        ValidFrom := 0D;
        ModelPrice.InitDefaultPrices();
        if not ModelPrice.FindPrice(ModelId, OnDate) then
            exit(0);
        InputPrice := ModelPrice."Input Price per MTok";
        OutputPrice := ModelPrice."Output Price per MTok";
        ValidFrom := ModelPrice."Valid From";
        exit(Round((InputTokens * InputPrice + OutputTokens * OutputPrice) / 1000000, 0.000001));
    end;

    /// <summary>
    /// Tarifa vigente en OnDate del modelo exacto o, si la respuesta trae un id más largo (p.ej. con fecha),
    /// del modelo que lo empieza.
    /// </summary>
    procedure FindPrice(ModelId: Text; OnDate: Date): Boolean
    var
        ModelPrice: Record "IKA Claude Model Price";
        BaseModel: Text;
    begin
        ModelId := LowerCase(DelChr(ModelId, '<>', ' '));
        if ModelId = '' then
            exit(false);
        if StrLen(ModelId) <= MaxStrLen(Model) then
            if FindPriceForModel(ModelId, OnDate) then
                exit(true);
        if ModelPrice.FindSet() then
            repeat
                BaseModel := LowerCase(ModelPrice.Model);
                if (BaseModel <> ModelId) and (StrPos(ModelId, BaseModel) = 1) then
                    if FindPriceForModel(ModelPrice.Model, OnDate) then
                        exit(true);
            until ModelPrice.Next() = 0;
        exit(false);
    end;

    local procedure FindPriceForModel(ModelId: Text; OnDate: Date): Boolean
    begin
        Reset();
        SetRange(Model, CopyStr(ModelId, 1, MaxStrLen(Model)));
        SetRange("Valid From", 0D, OnDate);
        exit(FindLast());
    end;

    /// <summary>
    /// Crea la tarifa de los modelos actuales que aún no tengan ninguna. No modifica las existentes.
    /// </summary>
    procedure InitDefaultPrices()
    begin
        AddDefault('claude-opus-5-5', 'Claude Opus 5.5', 4, 20);
        AddDefault('claude-sonnet-5-5', 'Claude Sonnet 5.5', 2, 10);
        AddDefault('claude-fable-5-1', 'Claude Fable 5.1', 10, 50);
        AddDefault('claude-haiku-4-5', 'Claude Haiku 4.5', 1, 5);
        AddDefault('claude-opus-5', 'Claude Opus 5', 5, 25);
        AddDefault('claude-sonnet-5', 'Claude Sonnet 5', 2, 10);
        AddDefault('claude-fable-5', 'Claude Fable 5', 10, 50);
    end;

    local procedure AddDefault(ModelId: Text[100]; NewDescription: Text[100]; InputPrice: Decimal; OutputPrice: Decimal)
    var
        ModelPrice: Record "IKA Claude Model Price";
    begin
        ModelPrice.SetRange(Model, ModelId);
        if not ModelPrice.IsEmpty() then
            exit;
        ModelPrice.Init();
        ModelPrice.Model := ModelId;
        ModelPrice."Valid From" := 0D;
        ModelPrice.Description := NewDescription;
        ModelPrice."Input Price per MTok" := InputPrice;
        ModelPrice."Output Price per MTok" := OutputPrice;
        ModelPrice.Insert();
    end;

    /// <summary>
    /// Número de llamadas registradas (pedidos y albaranes) que se calcularon con esta tarifa.
    /// </summary>
    procedure CountUses(): Integer
    var
        SalesLog: Record "IKA Sales Agent Log";
        DNLog: Record "IKA DN Log";
    begin
        SalesLog.SetRange(Model, Model);
        SalesLog.SetRange("Price Valid From", "Valid From");
        SalesLog.SetFilter("Input Price per MTok", '<>0');
        DNLog.SetRange(Model, Model);
        DNLog.SetRange("Price Valid From", "Valid From");
        DNLog.SetFilter("Input Price per MTok", '<>0');
        exit(SalesLog.Count() + DNLog.Count());
    end;

    procedure CheckNotUsed()
    var
        Uses: Integer;
    begin
        Uses := CountUses();
        if Uses > 0 then
            Error(PriceUsedErr, Model, "Valid From", Uses);
    end;
}
