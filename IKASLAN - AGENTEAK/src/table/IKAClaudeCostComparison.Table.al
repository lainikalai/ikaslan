table 99041 "IKA Claude Cost Comparison"
{
    // Coste real facturado por Anthropic (informes de uso y coste de la Admin API) frente al coste
    // calculado en BC, por día (UTC) y modelo. De los informes se deduce también la tarifa efectiva real.
    Caption = 'Comparación de costes de Claude';
    DataClassification = CustomerContent;
    LookupPageId = "IKA Claude Cost Comparison";
    DrillDownPageId = "IKA Claude Cost Comparison";

    fields
    {
        field(1; "Cost Date"; Date)
        {
            Caption = 'Fecha (UTC)';
        }
        field(2; Model; Text[100])
        {
            Caption = 'Modelo';
        }
        // --- Anthropic ---
        field(10; "Anthropic Cost (USD)"; Decimal)
        {
            Caption = 'Coste Anthropic (USD)';
            DecimalPlaces = 2 : 6;
            ToolTip = 'Coste facturado por Anthropic ese día para ese modelo (todos los tipos de token).';
        }
        field(11; "Anthropic Input Cost (USD)"; Decimal)
        {
            Caption = 'Coste entrada Anthropic (USD)';
            DecimalPlaces = 2 : 6;
        }
        field(12; "Anthropic Output Cost (USD)"; Decimal)
        {
            Caption = 'Coste salida Anthropic (USD)';
            DecimalPlaces = 2 : 6;
        }
        field(13; "Anthropic Other Cost (USD)"; Decimal)
        {
            Caption = 'Otros costes Anthropic (USD)';
            DecimalPlaces = 2 : 6;
            ToolTip = 'Caché, búsqueda web, ejecución de código y otros conceptos.';
        }
        field(20; "Anthropic Input Tokens"; Decimal)
        {
            Caption = 'Tokens entrada Anthropic';
            DecimalPlaces = 0 : 0;
        }
        field(21; "Anthropic Output Tokens"; Decimal)
        {
            Caption = 'Tokens salida Anthropic';
            DecimalPlaces = 0 : 0;
        }
        field(22; "Anthropic Cache Tokens"; Decimal)
        {
            Caption = 'Tokens de caché Anthropic';
            DecimalPlaces = 0 : 0;
        }
        field(30; "Real Input Price per MTok"; Decimal)
        {
            Caption = 'Tarifa real entrada (USD / millón)';
            DecimalPlaces = 2 : 4;
            ToolTip = 'Coste de entrada facturado / tokens de entrada × 1.000.000.';
        }
        field(31; "Real Output Price per MTok"; Decimal)
        {
            Caption = 'Tarifa real salida (USD / millón)';
            DecimalPlaces = 2 : 4;
            ToolTip = 'Coste de salida facturado / tokens de salida × 1.000.000.';
        }
        // --- Business Central ---
        field(40; "BC Cost (USD)"; Decimal)
        {
            Caption = 'Coste calculado en BC (USD)';
            DecimalPlaces = 2 : 6;
        }
        field(41; "BC Input Tokens"; Decimal)
        {
            Caption = 'Tokens entrada BC';
            DecimalPlaces = 0 : 0;
        }
        field(42; "BC Output Tokens"; Decimal)
        {
            Caption = 'Tokens salida BC';
            DecimalPlaces = 0 : 0;
        }
        field(43; "BC Calls"; Integer)
        {
            Caption = 'Llamadas BC';
        }
        field(50; "BC Input Price per MTok"; Decimal)
        {
            Caption = 'Tarifa BC entrada (USD / millón)';
            DecimalPlaces = 2 : 4;
            ToolTip = 'Tarifa de "Precios de Claude" vigente ese día.';
        }
        field(51; "BC Output Price per MTok"; Decimal)
        {
            Caption = 'Tarifa BC salida (USD / millón)';
            DecimalPlaces = 2 : 4;
        }
        // --- Resultado ---
        field(60; "Difference (USD)"; Decimal)
        {
            Caption = 'Diferencia (USD)';
            DecimalPlaces = 2 : 6;
            ToolTip = 'Coste Anthropic - coste calculado en BC. Puede incluir llamadas hechas con la misma API key fuera de BC (pruebas en la consola, otras aplicaciones).';
        }
        field(61; "Rate Differs"; Boolean)
        {
            Caption = 'Tarifa distinta';
            ToolTip = 'La tarifa real facturada difiere más de un 0,5 % de la tarifa de "Precios de Claude" vigente ese día.';
        }
        field(70; "Imported At"; DateTime)
        {
            Caption = 'Importado';
        }
    }

    keys
    {
        key(PK; "Cost Date", Model)
        {
            Clustered = true;
        }
    }
}
