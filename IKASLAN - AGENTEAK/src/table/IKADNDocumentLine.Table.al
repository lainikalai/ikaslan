table 99121 "IKA DN Document Line"
{
    Caption = 'Línea albarán de proveedor (agente)';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document Entry No."; Integer)
        {
            Caption = 'Nº mov. albarán';
            TableRelation = "IKA DN Document";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Nº línea';
        }
        // --- Extraído por Claude ---
        field(10; "Ext. Vendor Item Code"; Text[50])
        {
            Caption = 'Cód. artículo proveedor (extraído)';
        }
        field(11; "Ext. Our Item Code"; Text[50])
        {
            Caption = 'Nuestro cód. artículo (extraído)';
        }
        field(12; "Ext. EAN"; Text[50])
        {
            Caption = 'EAN (extraído)';
        }
        field(13; "Ext. Description"; Text[250])
        {
            Caption = 'Descripción (extraída)';
        }
        field(14; Quantity; Decimal)
        {
            Caption = 'Cantidad albarán';
            DecimalPlaces = 0 : 5;
        }
        field(15; "Ext. Unit of Measure"; Text[30])
        {
            Caption = 'Unidad (extraída)';
        }
        field(16; "Unit Price"; Decimal)
        {
            Caption = 'Precio albarán';
            DecimalPlaces = 2 : 5;
        }
        field(17; "Discount %"; Decimal)
        {
            Caption = '% Dto. albarán';
            DecimalPlaces = 0 : 5;
        }
        field(18; "Line Amount"; Decimal)
        {
            Caption = 'Importe línea albarán';
            DecimalPlaces = 2 : 2;
        }
        field(19; "Ext. Order Reference"; Text[50])
        {
            Caption = 'Pedido indicado en línea (extraído)';
        }
        field(20; "Lot No."; Code[50])
        {
            Caption = 'Lote';
        }
        field(21; "Ext. Expiration Date"; Text[30])
        {
            Caption = 'Caducidad (extraída)';
        }
        field(22; "Ext. Notes"; Text[250])
        {
            Caption = 'Notas (extraídas)';
        }
        field(23; "Ext. Delivery Date"; Text[30])
        {
            Caption = 'Fecha entrega línea (extraída)';
        }
        field(25; "Ext. Position"; Text[20])
        {
            Caption = 'Posición';
            ToolTip = 'Nº de posición o de línea que indica el documento (Pos., Línea...). Si coincide con el nº de línea del pedido (p.ej. posición 2 = línea 20000) se usa para elegir la línea de pedido.';
        }
        field(24; "Delivery Date"; Date)
        {
            Caption = 'Fecha entrega línea';
            ToolTip = 'Fecha de entrega que indica el documento en esta línea. Ayuda a elegir la línea de pedido cuando el mismo producto aparece varias veces.';
        }
        // --- Producto resuelto ---
        field(30; "Item No."; Code[20])
        {
            Caption = 'Nº producto';
            TableRelation = Item;

            trigger OnValidate()
            begin
                if "Item No." <> xRec."Item No." then begin
                    "Variant Code" := '';
                    "Unit of Measure Code" := '';
                end;
                if CurrFieldNo = FieldNo("Item No.") then begin
                    "Item Match Method" := '';
                    if "Item No." = '' then
                        "Item Match Status" := "Item Match Status"::" "
                    else
                        "Item Match Status" := "Item Match Status"::Manual;
                    ClearOrderMatch();
                end;
            end;
        }
        field(31; "Variant Code"; Code[10])
        {
            Caption = 'Cód. variante';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(32; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Cód. unidad medida';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(33; "Item Description"; Text[100])
        {
            Caption = 'Descripción producto';
            FieldClass = FlowField;
            CalcFormula = lookup(Item.Description where("No." = field("Item No.")));
            Editable = false;
        }
        field(34; "Item Match Status"; Enum "IKA DN Match Status")
        {
            Caption = 'Estado coincidencia producto';
            Editable = false;
        }
        field(35; "Item Match Method"; Text[50])
        {
            Caption = 'Método coincidencia producto';
            Editable = false;
        }
        field(36; "Expiration Date"; Date)
        {
            Caption = 'Fecha caducidad';
        }
        // --- Conciliación con pedido de compra ---
        field(40; "Purchase Order No."; Code[20])
        {
            Caption = 'Nº pedido compra';
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Order));

            trigger OnValidate()
            begin
                if "Purchase Order No." <> xRec."Purchase Order No." then
                    "Purchase Order Line No." := 0;
                if "Purchase Order No." = '' then
                    ClearOrderMatch();
            end;
        }
        field(41; "Purchase Order Line No."; Integer)
        {
            Caption = 'Nº línea pedido compra';
            TableRelation = "Purchase Line"."Line No." where("Document Type" = const(Order), "Document No." = field("Purchase Order No."));

            trigger OnValidate()
            begin
                if CurrFieldNo = FieldNo("Purchase Order Line No.") then begin
                    "Order Match Status" := "Order Match Status"::Manual;
                    "Order Match Method" := '';
                end;
            end;
        }
        field(42; "Order Match Status"; Enum "IKA DN Match Status")
        {
            Caption = 'Estado conciliación pedido';
            Editable = false;
        }
        field(43; "Order Match Method"; Text[50])
        {
            Caption = 'Método conciliación';
            Editable = false;
        }
        field(44; "Order Matched"; Boolean)
        {
            Caption = 'Conciliada';
            Editable = false;
        }
        field(45; "Order Outstanding Qty."; Decimal)
        {
            Caption = 'Pendiente en pedido';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(46; "Order Unit Cost"; Decimal)
        {
            Caption = 'Coste en pedido';
            DecimalPlaces = 2 : 5;
            Editable = false;
        }
        field(47; "Order Discount %"; Decimal)
        {
            Caption = '% Dto. en pedido';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(48; "Order Unit of Measure"; Code[10])
        {
            Caption = 'Unidad en pedido';
            Editable = false;
        }
        field(49; "Qty. to Receive (Order UoM)"; Decimal)
        {
            Caption = 'Cant. a recibir (unidad pedido)';
            DecimalPlaces = 0 : 5;
        }
        // --- Discrepancias ---
        field(60; "Has Discrepancy"; Boolean)
        {
            Caption = 'Con discrepancia';
            Editable = false;
        }
        field(61; "Qty. Discrepancy"; Boolean)
        {
            Caption = 'Discrepancia cantidad';
            Editable = false;
        }
        field(62; "Price Discrepancy"; Boolean)
        {
            Caption = 'Discrepancia precio';
            Editable = false;
        }
        field(63; "Discrepancy Text"; Text[250])
        {
            Caption = 'Detalle discrepancia';
            Editable = false;
        }
        field(64; "Accept Discrepancy"; Boolean)
        {
            Caption = 'Aceptar discrepancia';
            ToolTip = 'Marque para dar por buena la discrepancia y permitir aplicar el albarán.';
        }
    }

    keys
    {
        key(PK; "Document Entry No.", "Line No.")
        {
            Clustered = true;
        }
        key(PurchLine; "Purchase Order No.", "Purchase Order Line No.")
        {
        }
    }

    procedure ClearOrderMatch()
    begin
        "Order Matched" := false;
        "Order Match Status" := "Order Match Status"::" ";
        "Order Match Method" := '';
        "Order Outstanding Qty." := 0;
        "Order Unit Cost" := 0;
        "Order Discount %" := 0;
        "Order Unit of Measure" := '';
        "Qty. to Receive (Order UoM)" := 0;
        "Has Discrepancy" := false;
        "Qty. Discrepancy" := false;
        "Price Discrepancy" := false;
        "Discrepancy Text" := '';
    end;

    procedure GetDisplayText(): Text
    var
        Result: Text;
    begin
        Result := "Ext. Vendor Item Code";
        if "Ext. Description" <> '' then
            if Result = '' then
                Result := "Ext. Description"
            else
                Result += ' - ' + "Ext. Description";
        exit(Result);
    end;
}
