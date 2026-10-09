codeunit 99071 "IKA Anthropic Usage Import"
{
    // Descarga de la Admin API de Anthropic (Usage & Cost API) el coste real facturado y los tokens
    // consumidos por día (UTC) y modelo, y los compara con el coste que BC ha calculado en sus registros.
    // Requiere una Admin API key (sk-ant-admin01-...) de una organización de Claude Console; las cuentas
    // individuales no la tienen. Anthropic no publica una API de precios: la tarifa real se deduce
    // dividiendo el coste facturado entre los tokens consumidos.
    //   GET /v1/organizations/cost_report           (importes en céntimos de USD, por descripción y workspace)
    //   GET /v1/organizations/usage_report/messages (tokens por modelo)

    var
        Setup: Record "IKA Sales Agent Setup";
        JsonHelper: Codeunit "IKA Sales Agent Json Helper";
        UriHelper: Codeunit Uri;
        AdminBaseUrlTok: Label 'https://api.anthropic.com/v1/organizations/', Locked = true;
        AnthropicVersionTok: Label '2023-06-01', Locked = true;
        OtherModelTok: Label '(otros conceptos)', Locked = true;
        NoAdminKeyErr: Label 'Falta la Admin API key de Anthropic. Créela en Claude Console > Settings > Admin keys (requiere una organización y el rol admin) y establézcala en la configuración de los agentes.';
        HttpErr: Label 'La Admin API de Anthropic devolvió el error HTTP %1: %2', Comment = '%1 = status, %2 = body';
        ConnectErr: Label 'No se pudo conectar con la Admin API de Anthropic: %1', Comment = '%1 = error';
        DateRangeErr: Label 'La fecha inicial no puede ser posterior a la final.';
        ImportedMsg: Label 'Importados %1 día(s): coste Anthropic %2 USD, coste calculado en BC %3 USD, diferencia %4 USD.\%5 línea(s) con tarifa real distinta de "Precios de Claude".', Comment = '%1 = days, %2 = anthropic, %3 = bc, %4 = difference, %5 = rate differences';
        NoRateChangesMsg: Label 'Las tarifas reales coinciden con las de "Precios de Claude". No hay nada que actualizar.';
        RateChangesQst: Label 'Se crearán estas tarifas nuevas a partir de la tarifa real facturada por Anthropic:%1\\¿Continuar?', Comment = '%1 = list of changes';
        RateChangeLbl: Label '\- %1 desde %2: entrada %3, salida %4 USD/millón (ahora %5 / %6)', Comment = '%1 = model, %2 = date, %3 = input, %4 = output, %5 = current input, %6 = current output';
        RatesCreatedMsg: Label 'Se han creado %1 tarifa(s) nueva(s).', Comment = '%1 = count';

    /// <summary>
    /// Importa los informes de Anthropic de los días indicados (UTC) y los compara con los registros de BC.
    /// Sustituye las líneas que ya hubiera de esos días.
    /// </summary>
    procedure ImportPeriod(FromDate: Date; ToDate: Date)
    var
        Comparison: Record "IKA Claude Cost Comparison";
        TotalAnthropic: Decimal;
        TotalBC: Decimal;
        RateDiffs: Integer;
    begin
        if FromDate > ToDate then
            Error(DateRangeErr);
        Setup.GetSetup();
        if not Setup.HasAdminApiKey() then
            Error(NoAdminKeyErr);

        Comparison.SetRange("Cost Date", FromDate, ToDate);
        Comparison.DeleteAll();

        ImportCostReport(FromDate, ToDate);
        ImportUsageReport(FromDate, ToDate);
        AddBCSalesLog(FromDate, ToDate);
        AddBCDeliveryNoteLog(FromDate, ToDate);

        if Comparison.FindSet(true) then
            repeat
                CompleteLine(Comparison);
                Comparison.Modify();
                TotalAnthropic += Comparison."Anthropic Cost (USD)";
                TotalBC += Comparison."BC Cost (USD)";
                if Comparison."Rate Differs" then
                    RateDiffs += 1;
            until Comparison.Next() = 0;

        if GuiAllowed() then
            Message(ImportedMsg, ToDate - FromDate + 1, Round(TotalAnthropic, 0.0001), Round(TotalBC, 0.0001), Round(TotalAnthropic - TotalBC, 0.0001), RateDiffs);
    end;

    // ---------------- Informe de costes ----------------

    local procedure ImportCostReport(FromDate: Date; ToDate: Date)
    var
        ResponseJson: JsonObject;
        DataArray: JsonArray;
        BucketToken: JsonToken;
        ResultArray: JsonArray;
        ResultToken: JsonToken;
        Url: Text;
        PageToken: Text;
    begin
        repeat
            Url := AdminBaseUrlTok + 'cost_report?starting_at=' + UtcStart(FromDate) + '&ending_at=' + UtcStart(ToDate + 1) +
                '&group_by[]=description&group_by[]=workspace_id&limit=31';
            if PageToken <> '' then
                Url += '&page=' + UriHelper.EscapeDataString(PageToken);
            ResponseJson := SendAdminRequest(Url);
            if JsonHelper.GetArray(ResponseJson, 'data', DataArray) then
                foreach BucketToken in DataArray do
                    if JsonHelper.GetArray(BucketToken.AsObject(), 'results', ResultArray) then
                        foreach ResultToken in ResultArray do
                            AddCostResult(BucketDate(BucketToken.AsObject()), ResultToken.AsObject());
            PageToken := NextPage(ResponseJson);
        until PageToken = '';
    end;

    local procedure AddCostResult(CostDate: Date; ResultJson: JsonObject)
    var
        Comparison: Record "IKA Claude Cost Comparison";
        AmountCents: Decimal;
        AmountUSD: Decimal;
        ModelId: Text;
    begin
        if not IsOurWorkspace(JsonHelper.GetText(ResultJson, 'workspace_id')) then
            exit;
        if not Evaluate(AmountCents, JsonHelper.GetText(ResultJson, 'amount'), 9) then
            exit;
        AmountUSD := AmountCents / 100;
        ModelId := JsonHelper.GetText(ResultJson, 'model');
        if ModelId = '' then
            ModelId := OtherModelTok;

        GetLine(Comparison, CostDate, ModelId);
        Comparison."Anthropic Cost (USD)" += AmountUSD;
        case JsonHelper.GetText(ResultJson, 'token_type') of
            'uncached_input_tokens':
                Comparison."Anthropic Input Cost (USD)" += AmountUSD;
            'output_tokens':
                Comparison."Anthropic Output Cost (USD)" += AmountUSD;
            else
                Comparison."Anthropic Other Cost (USD)" += AmountUSD;
        end;
        Comparison.Modify();
    end;

    // ---------------- Informe de uso (tokens) ----------------

    local procedure ImportUsageReport(FromDate: Date; ToDate: Date)
    var
        ResponseJson: JsonObject;
        DataArray: JsonArray;
        BucketToken: JsonToken;
        ResultArray: JsonArray;
        ResultToken: JsonToken;
        Url: Text;
        PageToken: Text;
    begin
        repeat
            Url := AdminBaseUrlTok + 'usage_report/messages?starting_at=' + UtcStart(FromDate) + '&ending_at=' + UtcStart(ToDate + 1) +
                '&bucket_width=1d&group_by[]=model&limit=31';
            if Setup."Anthropic Workspace Id" <> '' then
                Url += '&workspace_ids[]=' + UriHelper.EscapeDataString(Setup."Anthropic Workspace Id");
            if PageToken <> '' then
                Url += '&page=' + UriHelper.EscapeDataString(PageToken);
            ResponseJson := SendAdminRequest(Url);
            if JsonHelper.GetArray(ResponseJson, 'data', DataArray) then
                foreach BucketToken in DataArray do
                    if JsonHelper.GetArray(BucketToken.AsObject(), 'results', ResultArray) then
                        foreach ResultToken in ResultArray do
                            AddUsageResult(BucketDate(BucketToken.AsObject()), ResultToken.AsObject());
            PageToken := NextPage(ResponseJson);
        until PageToken = '';
    end;

    local procedure AddUsageResult(CostDate: Date; ResultJson: JsonObject)
    var
        Comparison: Record "IKA Claude Cost Comparison";
        ModelId: Text;
    begin
        ModelId := JsonHelper.GetText(ResultJson, 'model');
        if ModelId = '' then
            exit;
        GetLine(Comparison, CostDate, ModelId);
        Comparison."Anthropic Input Tokens" += JsonHelper.GetDecimal(ResultJson, 'uncached_input_tokens');
        Comparison."Anthropic Output Tokens" += JsonHelper.GetDecimal(ResultJson, 'output_tokens');
        Comparison."Anthropic Cache Tokens" += JsonHelper.GetDecimal(ResultJson, 'cache_read_input_tokens') +
            GetDecimalByPath(ResultJson, '$.cache_creation.ephemeral_5m_input_tokens') +
            GetDecimalByPath(ResultJson, '$.cache_creation.ephemeral_1h_input_tokens');
        Comparison.Modify();
    end;

    // ---------------- Registros de BC ----------------

    local procedure AddBCSalesLog(FromDate: Date; ToDate: Date)
    var
        SalesLog: Record "IKA Sales Agent Log";
    begin
        // Un día de margen por la diferencia horaria: cada llamada se asigna a su día UTC
        SalesLog.SetRange("Log Type", SalesLog."Log Type"::"Claude Call");
        SalesLog.SetRange("Created At", CreateDateTime(FromDate - 1, 0T), CreateDateTime(ToDate + 2, 0T));
        if SalesLog.FindSet() then
            repeat
                AddBCCall(FromDate, ToDate, SalesLog."Created At", SalesLog.Model, SalesLog."Input Tokens", SalesLog."Output Tokens", SalesLog."Cost (USD)");
            until SalesLog.Next() = 0;
    end;

    local procedure AddBCDeliveryNoteLog(FromDate: Date; ToDate: Date)
    var
        DNLog: Record "IKA DN Log";
    begin
        DNLog.SetRange("Log Type", DNLog."Log Type"::"Claude Call");
        DNLog.SetRange("Created At", CreateDateTime(FromDate - 1, 0T), CreateDateTime(ToDate + 2, 0T));
        if DNLog.FindSet() then
            repeat
                AddBCCall(FromDate, ToDate, DNLog."Created At", DNLog.Model, DNLog."Input Tokens", DNLog."Output Tokens", DNLog."Cost (USD)");
            until DNLog.Next() = 0;
    end;

    local procedure AddBCCall(FromDate: Date; ToDate: Date; CreatedAt: DateTime; ModelId: Text; InputTokens: Integer; OutputTokens: Integer; Cost: Decimal)
    var
        Comparison: Record "IKA Claude Cost Comparison";
        CallDate: Date;
    begin
        if (InputTokens = 0) and (OutputTokens = 0) then
            exit;
        CallDate := UtcDate(CreatedAt);
        if (CallDate < FromDate) or (CallDate > ToDate) or (ModelId = '') then
            exit;
        GetLine(Comparison, CallDate, ModelId);
        Comparison."BC Cost (USD)" += Cost;
        Comparison."BC Input Tokens" += InputTokens;
        Comparison."BC Output Tokens" += OutputTokens;
        Comparison."BC Calls" += 1;
        Comparison.Modify();
    end;

    // ---------------- Tarifas ----------------

    local procedure CompleteLine(var Comparison: Record "IKA Claude Cost Comparison")
    var
        ModelPrice: Record "IKA Claude Model Price";
    begin
        Comparison."Real Input Price per MTok" := 0;
        Comparison."Real Output Price per MTok" := 0;
        if Comparison."Anthropic Input Tokens" <> 0 then
            Comparison."Real Input Price per MTok" := Round(Comparison."Anthropic Input Cost (USD)" / Comparison."Anthropic Input Tokens" * 1000000, 0.0001);
        if Comparison."Anthropic Output Tokens" <> 0 then
            Comparison."Real Output Price per MTok" := Round(Comparison."Anthropic Output Cost (USD)" / Comparison."Anthropic Output Tokens" * 1000000, 0.0001);

        Comparison."BC Input Price per MTok" := 0;
        Comparison."BC Output Price per MTok" := 0;
        if ModelPrice.FindPrice(Comparison.Model, Comparison."Cost Date") then begin
            Comparison."BC Input Price per MTok" := ModelPrice."Input Price per MTok";
            Comparison."BC Output Price per MTok" := ModelPrice."Output Price per MTok";
        end;
        Comparison."Rate Differs" :=
            RateDiffers(Comparison."Real Input Price per MTok", Comparison."BC Input Price per MTok") or
            RateDiffers(Comparison."Real Output Price per MTok", Comparison."BC Output Price per MTok");
        Comparison."Difference (USD)" := Comparison."Anthropic Cost (USD)" - Comparison."BC Cost (USD)";
        Comparison."Imported At" := CurrentDateTime();
    end;

    local procedure RateDiffers(RealPrice: Decimal; TariffPrice: Decimal): Boolean
    begin
        if RealPrice = 0 then
            exit(false);
        if TariffPrice = 0 then
            exit(true);
        exit(Abs(RealPrice - TariffPrice) / TariffPrice * 100 > 0.5);
    end;

    /// <summary>
    /// Crea en "Precios de Claude" una tarifa nueva por cada modelo cuya tarifa real (la del último día importado
    /// con consumo) difiere de la vigente. Pide confirmación con la lista de cambios.
    /// </summary>
    procedure UpdateTariffsFromRealRates()
    var
        Comparison: Record "IKA Claude Cost Comparison";
        ModelPrice: Record "IKA Claude Model Price";
        NewPrice: Record "IKA Claude Model Price";
        Models: List of [Text];
        ModelId: Text;
        Changes: Text;
        Created: Integer;
    begin
        Comparison.SetFilter("Real Input Price per MTok", '<>0');
        Comparison.SetFilter("Real Output Price per MTok", '<>0');
        if Comparison.FindSet() then
            repeat
                if not Models.Contains(Comparison.Model) then
                    Models.Add(Comparison.Model);
            until Comparison.Next() = 0;

        foreach ModelId in Models do
            if FindLatestRates(ModelId, Comparison) then
                if Comparison."Rate Differs" then
                    Changes += StrSubstNo(RateChangeLbl, ModelId, Comparison."Cost Date",
                        Comparison."Real Input Price per MTok", Comparison."Real Output Price per MTok",
                        Comparison."BC Input Price per MTok", Comparison."BC Output Price per MTok");

        if Changes = '' then begin
            Message(NoRateChangesMsg);
            exit;
        end;
        if not Confirm(RateChangesQst, false, Changes) then
            exit;

        foreach ModelId in Models do
            if FindLatestRates(ModelId, Comparison) then
                if Comparison."Rate Differs" and not NewPrice.Get(CopyStr(ModelId, 1, MaxStrLen(NewPrice.Model)), Comparison."Cost Date") then begin
                    NewPrice.Init();
                    NewPrice.Model := CopyStr(ModelId, 1, MaxStrLen(NewPrice.Model));
                    NewPrice."Valid From" := Comparison."Cost Date";
                    if ModelPrice.FindPrice(ModelId, Comparison."Cost Date") then
                        NewPrice.Description := ModelPrice.Description;
                    NewPrice."Input Price per MTok" := Comparison."Real Input Price per MTok";
                    NewPrice."Output Price per MTok" := Comparison."Real Output Price per MTok";
                    NewPrice.Insert(true);
                    Created += 1;
                end;
        Message(RatesCreatedMsg, Created);
    end;

    local procedure FindLatestRates(ModelId: Text; var Comparison: Record "IKA Claude Cost Comparison"): Boolean
    begin
        Comparison.Reset();
        Comparison.SetRange(Model, CopyStr(ModelId, 1, MaxStrLen(Comparison.Model)));
        Comparison.SetFilter("Real Input Price per MTok", '<>0');
        Comparison.SetFilter("Real Output Price per MTok", '<>0');
        exit(Comparison.FindLast());
    end;

    // ---------------- Utilidades ----------------

    local procedure GetLine(var Comparison: Record "IKA Claude Cost Comparison"; CostDate: Date; ModelId: Text)
    begin
        if Comparison.Get(CostDate, CopyStr(ModelId, 1, MaxStrLen(Comparison.Model))) then
            exit;
        Comparison.Init();
        Comparison."Cost Date" := CostDate;
        Comparison.Model := CopyStr(ModelId, 1, MaxStrLen(Comparison.Model));
        Comparison.Insert();
    end;

    local procedure IsOurWorkspace(WorkspaceId: Text): Boolean
    begin
        if Setup."Anthropic Workspace Id" = '' then
            exit(true);
        exit(WorkspaceId = Setup."Anthropic Workspace Id");
    end;

    local procedure UtcStart(OnDate: Date): Text
    begin
        exit(Format(OnDate, 0, '<Year4>-<Month,2>-<Day,2>') + 'T00:00:00Z');
    end;

    local procedure BucketDate(BucketJson: JsonObject): Date
    var
        Result: Date;
    begin
        if Evaluate(Result, CopyStr(JsonHelper.GetText(BucketJson, 'starting_at'), 1, 10), 9) then;
        exit(Result);
    end;

    /// <summary>
    /// Día UTC de una fecha/hora (Format 9 devuelve la hora en UTC: 2026-10-07T21:30:00.000Z).
    /// </summary>
    local procedure UtcDate(Value: DateTime): Date
    var
        Result: Date;
    begin
        if Evaluate(Result, CopyStr(Format(Value, 0, 9), 1, 10), 9) then;
        exit(Result);
    end;

    local procedure NextPage(ResponseJson: JsonObject): Text
    begin
        if not JsonHelper.GetBoolean(ResponseJson, 'has_more') then
            exit('');
        exit(JsonHelper.GetText(ResponseJson, 'next_page'));
    end;

    local procedure GetDecimalByPath(JsonObj: JsonObject; Path: Text): Decimal
    var
        Token: JsonToken;
    begin
        if not JsonObj.SelectToken(Path, Token) then
            exit(0);
        if not Token.IsValue() then
            exit(0);
        if Token.AsValue().IsNull() then
            exit(0);
        exit(Token.AsValue().AsDecimal());
    end;

    local procedure SendAdminRequest(Url: Text) ResponseJson: JsonObject
    var
        Client: HttpClient;
        Response: HttpResponseMessage;
        ResponseText: Text;
    begin
        AddHeaders(Client);
        Client.Timeout := 120000;
        if not Client.Get(Url, Response) then
            Error(ConnectErr, GetLastErrorText());
        Response.Content.ReadAs(ResponseText);
        if not Response.IsSuccessStatusCode() then
            Error(HttpErr, Response.HttpStatusCode(), CopyStr(ResponseText, 1, 1000));
        if ResponseText <> '' then
            if ResponseJson.ReadFrom(ResponseText) then;
    end;

    [NonDebuggable]
    local procedure AddHeaders(var Client: HttpClient)
    begin
        Client.DefaultRequestHeaders.Add('x-api-key', Setup.GetAdminApiKey());
        Client.DefaultRequestHeaders.Add('anthropic-version', AnthropicVersionTok);
        Client.DefaultRequestHeaders.Add('User-Agent', 'IkaslanAgentsBC/2.0');
    end;
}
