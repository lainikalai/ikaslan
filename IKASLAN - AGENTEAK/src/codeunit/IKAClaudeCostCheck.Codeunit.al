codeunit 99066 "IKA Claude Cost Check"
{
    // Comprueba el coste registrado de las llamadas a Claude: lo recalcula con la tarifa vigente en la
    // fecha de cada llamada (historial de "Precios de Claude") y marca las que no cuadran.
    // No modifica el coste registrado: deja el recalculado al lado para poder compararlos.

    var
        Checked: Integer;
        Mismatches: Integer;
        WithoutPrice: Integer;
        TotalRegistered: Decimal;
        TotalRecalculated: Decimal;
        SummaryMsg: Label '%1 llamada(s) comprobada(s).\%2 con un coste que no cuadra con la tarifa vigente en su fecha (filtre por "Coste no cuadra").\%3 sin precio aplicado guardado (registradas antes de guardar la tarifa en cada llamada).\\Coste registrado: %4 USD\Coste recalculado: %5 USD', Comment = '%1 = checked, %2 = mismatches, %3 = without stored price, %4 = registered total, %5 = recalculated total';

    procedure CheckSalesLog(var SalesLog: Record "IKA Sales Agent Log")
    var
        AppliedInputPrice: Decimal;
        AppliedOutputPrice: Decimal;
        AppliedValidFrom: Date;
    begin
        ClearTotals();
        SalesLog.SetRange("Log Type", SalesLog."Log Type"::"Claude Call");
        if SalesLog.FindSet(true) then
            repeat
                if (SalesLog."Input Tokens" <> 0) or (SalesLog."Output Tokens" <> 0) then begin
                    SalesLog."Recalculated Cost (USD)" := Recalculate(SalesLog.Model, SalesLog."Input Tokens", SalesLog."Output Tokens", SalesLog."Created At",
                        AppliedInputPrice, AppliedOutputPrice, AppliedValidFrom);
                    SalesLog."Cost Mismatch" := IsMismatch(SalesLog."Cost (USD)", SalesLog."Recalculated Cost (USD)",
                        SalesLog."Input Price per MTok", SalesLog."Output Price per MTok", SalesLog."Price Valid From",
                        AppliedInputPrice, AppliedOutputPrice, AppliedValidFrom);
                    SalesLog.Modify();
                end;
            until SalesLog.Next() = 0;
        ShowSummary();
    end;

    procedure CheckDNLog(var DNLog: Record "IKA DN Log")
    var
        AppliedInputPrice: Decimal;
        AppliedOutputPrice: Decimal;
        AppliedValidFrom: Date;
    begin
        ClearTotals();
        DNLog.SetRange("Log Type", DNLog."Log Type"::"Claude Call");
        if DNLog.FindSet(true) then
            repeat
                if (DNLog."Input Tokens" <> 0) or (DNLog."Output Tokens" <> 0) then begin
                    DNLog."Recalculated Cost (USD)" := Recalculate(DNLog.Model, DNLog."Input Tokens", DNLog."Output Tokens", DNLog."Created At",
                        AppliedInputPrice, AppliedOutputPrice, AppliedValidFrom);
                    DNLog."Cost Mismatch" := IsMismatch(DNLog."Cost (USD)", DNLog."Recalculated Cost (USD)",
                        DNLog."Input Price per MTok", DNLog."Output Price per MTok", DNLog."Price Valid From",
                        AppliedInputPrice, AppliedOutputPrice, AppliedValidFrom);
                    DNLog.Modify();
                end;
            until DNLog.Next() = 0;
        ShowSummary();
    end;

    local procedure Recalculate(ModelId: Text; InputTokens: Integer; OutputTokens: Integer; CreatedAt: DateTime; var InputPrice: Decimal; var OutputPrice: Decimal; var ValidFrom: Date): Decimal
    var
        ModelPrice: Record "IKA Claude Model Price";
    begin
        exit(ModelPrice.CalcCostOnDate(ModelId, InputTokens, OutputTokens, DT2Date(CreatedAt), InputPrice, OutputPrice, ValidFrom));
    end;

    /// <summary>
    /// No cuadra si el coste o la tarifa aplicada difieren de los de la tarifa vigente en la fecha de la llamada.
    /// Las llamadas antiguas sin precio guardado solo se comparan por coste.
    /// </summary>
    local procedure IsMismatch(RegisteredCost: Decimal; RecalculatedCost: Decimal; StoredInputPrice: Decimal; StoredOutputPrice: Decimal; StoredValidFrom: Date; InputPrice: Decimal; OutputPrice: Decimal; ValidFrom: Date): Boolean
    var
        Mismatch: Boolean;
    begin
        Checked += 1;
        TotalRegistered += RegisteredCost;
        TotalRecalculated += RecalculatedCost;
        Mismatch := Abs(RegisteredCost - RecalculatedCost) > 0.000001;
        if (StoredInputPrice = 0) and (StoredOutputPrice = 0) then
            WithoutPrice += 1
        else
            if (StoredInputPrice <> InputPrice) or (StoredOutputPrice <> OutputPrice) or (StoredValidFrom <> ValidFrom) then
                Mismatch := true;
        if Mismatch then
            Mismatches += 1;
        exit(Mismatch);
    end;

    local procedure ClearTotals()
    begin
        Checked := 0;
        Mismatches := 0;
        WithoutPrice := 0;
        TotalRegistered := 0;
        TotalRecalculated := 0;
    end;

    local procedure ShowSummary()
    begin
        if GuiAllowed() then
            Message(SummaryMsg, Checked, Mismatches, WithoutPrice, Round(TotalRegistered, 0.0001), Round(TotalRecalculated, 0.0001));
    end;
}
