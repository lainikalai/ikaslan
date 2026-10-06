codeunit 99131 "IKA DN Json Helper"
{
    Access = Internal;

    procedure GetText(JObject: JsonObject; PropertyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(PropertyName, JToken) then
            exit('');
        if not JToken.IsValue() then
            exit('');
        if JToken.AsValue().IsNull() or JToken.AsValue().IsUndefined() then
            exit('');
        exit(JToken.AsValue().AsText());
    end;

    procedure GetDecimal(JObject: JsonObject; PropertyName: Text): Decimal
    var
        JToken: JsonToken;
        Result: Decimal;
    begin
        if not JObject.Get(PropertyName, JToken) then
            exit(0);
        if not JToken.IsValue() then
            exit(0);
        if JToken.AsValue().IsNull() or JToken.AsValue().IsUndefined() then
            exit(0);
        if TryAsDecimal(JToken.AsValue(), Result) then
            exit(Result);
        // Valor recibido como texto ("12,5" o "12.5")
        if Evaluate(Result, ConvertStr(JToken.AsValue().AsText(), ',', '.'), 9) then
            exit(Result);
        exit(0);
    end;

    procedure GetInteger(JObject: JsonObject; PropertyName: Text): Integer
    begin
        exit(Round(GetDecimal(JObject, PropertyName), 1));
    end;

    procedure GetBoolean(JObject: JsonObject; PropertyName: Text): Boolean
    var
        JToken: JsonToken;
    begin
        if not JObject.Get(PropertyName, JToken) then
            exit(false);
        if not JToken.IsValue() then
            exit(false);
        if JToken.AsValue().IsNull() or JToken.AsValue().IsUndefined() then
            exit(false);
        exit(JToken.AsValue().AsBoolean());
    end;

    procedure GetObject(JObject: JsonObject; PropertyName: Text; var Result: JsonObject): Boolean
    var
        JToken: JsonToken;
    begin
        Clear(Result);
        if not JObject.Get(PropertyName, JToken) then
            exit(false);
        if not JToken.IsObject() then
            exit(false);
        Result := JToken.AsObject();
        exit(true);
    end;

    procedure GetArray(JObject: JsonObject; PropertyName: Text; var Result: JsonArray): Boolean
    var
        JToken: JsonToken;
    begin
        Clear(Result);
        if not JObject.Get(PropertyName, JToken) then
            exit(false);
        if not JToken.IsArray() then
            exit(false);
        Result := JToken.AsArray();
        exit(true);
    end;

    procedure GetTextByPath(JObject: JsonObject; Path: Text): Text
    var
        JToken: JsonToken;
    begin
        if not JObject.SelectToken(Path, JToken) then
            exit('');
        if not JToken.IsValue() then
            exit('');
        if JToken.AsValue().IsNull() or JToken.AsValue().IsUndefined() then
            exit('');
        exit(JToken.AsValue().AsText());
    end;

    procedure ArrayToText(JArray: JsonArray; Separator: Text): Text
    var
        JToken: JsonToken;
        Result: Text;
    begin
        foreach JToken in JArray do
            if JToken.IsValue() then
                if not (JToken.AsValue().IsNull() or JToken.AsValue().IsUndefined()) then begin
                    if Result <> '' then
                        Result += Separator;
                    Result += JToken.AsValue().AsText();
                end;
        exit(Result);
    end;

    procedure ToText(JObject: JsonObject): Text
    var
        Result: Text;
    begin
        JObject.WriteTo(Result);
        exit(Result);
    end;

    [TryFunction]
    local procedure TryAsDecimal(JValue: JsonValue; var Result: Decimal)
    begin
        Result := JValue.AsDecimal();
    end;
}
