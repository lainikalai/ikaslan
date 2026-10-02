table 50230 "IKA DN Document"
{
    Caption = 'Albarán de proveedor (agente)';
    DataClassification = CustomerContent;
    LookupPageId = "IKA DN Documents";
    DrillDownPageId = "IKA DN Documents";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº mov.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; Status; Enum "IKA DN Status")
        {
            Caption = 'Estado';
        }
        field(3; Source; Enum "IKA DN Source")
        {
            Caption = 'Origen';
        }
        // --- Origen: email ---
        field(10; "Graph Message Id"; Text[250])
        {
            Caption = 'Id mensaje (Graph)';
            Editable = false;
        }
        field(11; "Internet Message Id"; Text[250])
        {
            Caption = 'Internet Message-ID';
            Editable = false;
        }
        field(12; "Received At"; DateTime)
        {
            Caption = 'Recibido';
        }
        field(13; "Sender Address"; Text[250])
        {
            Caption = 'Email remitente';
            ExtendedDatatype = EMail;
        }
        field(14; "Sender Name"; Text[250])
        {
            Caption = 'Nombre remitente';
        }
        field(15; Subject; Text[250])
        {
            Caption = 'Asunto / fichero';
        }
        field(16; Body; Blob)
        {
            Caption = 'Cuerpo';
        }
        // --- Origen: carpeta ---
        field(17; "Drive Item Id"; Text[250])
        {
            Caption = 'Id fichero (Graph)';
            Editable = false;
        }
        field(18; "Source File Name"; Text[250])
        {
            Caption = 'Fichero origen';
            Editable = false;
        }
        field(19; "Moved at Source"; Boolean)
        {
            Caption = 'Movido en origen';
            Editable = false;
        }
        field(20; "Parent Entry No."; Integer)
        {
            Caption = 'Nº mov. documento origen';
            TableRelation = "IKA DN Document";
            Editable = false;
        }
        field(21; "Note Index"; Integer)
        {
            Caption = 'Nº albarán dentro del documento';
            InitValue = 1;
            Editable = false;
        }
        field(22; "Template Vendor No."; Code[20])
        {
            Caption = 'Plantilla aplicada';
            TableRelation = "IKA DN Vendor Template";
            Editable = false;
        }
        // --- Extraído por Claude ---
        field(30; "Ext. Vendor Name"; Text[100])
        {
            Caption = 'Proveedor (extraído)';
        }
        field(31; "Ext. Vendor VAT No."; Text[30])
        {
            Caption = 'NIF proveedor (extraído)';
        }
        field(32; "Ext. Vendor E-Mail"; Text[100])
        {
            Caption = 'Email proveedor (extraído)';
        }
        field(33; "Ext. Our Customer Code"; Text[50])
        {
            Caption = 'Nuestro nº cliente (extraído)';
        }
        field(34; "Ext. Delivery Note No."; Text[50])
        {
            Caption = 'Nº albarán (extraído)';
        }
        field(35; "Ext. Delivery Note Date"; Text[30])
        {
            Caption = 'Fecha albarán (extraída)';
        }
        field(36; "Ext. Order References"; Text[250])
        {
            Caption = 'Pedidos indicados (extraídos)';
        }
        field(37; "Ext. Total Amount"; Decimal)
        {
            Caption = 'Importe total (extraído)';
        }
        field(38; "Ext. Currency"; Text[10])
        {
            Caption = 'Divisa (extraída)';
        }
        field(39; "Prices Included"; Boolean)
        {
            Caption = 'Albarán valorado';
        }
        // --- Resuelto en BC ---
        field(40; "Vendor No."; Code[20])
        {
            Caption = 'Nº proveedor';
            TableRelation = Vendor;

            trigger OnValidate()
            begin
                if "Vendor No." = '' then
                    "Vendor Match Status" := "Vendor Match Status"::" "
                else
                    if CurrFieldNo = FieldNo("Vendor No.") then begin
                        "Vendor Match Status" := "Vendor Match Status"::Manual;
                        "Vendor Match Method" := '';
                    end;
            end;
        }
        field(41; "Vendor Name"; Text[100])
        {
            Caption = 'Nombre proveedor';
            FieldClass = FlowField;
            CalcFormula = lookup(Vendor.Name where("No." = field("Vendor No.")));
            Editable = false;
        }
        field(42; "Vendor Match Status"; Enum "IKA DN Match Status")
        {
            Caption = 'Estado coincidencia proveedor';
            Editable = false;
        }
        field(43; "Vendor Match Method"; Text[50])
        {
            Caption = 'Método coincidencia proveedor';
            Editable = false;
        }
        field(44; "Vendor Shipment No."; Code[35])
        {
            Caption = 'Nº albarán proveedor';
        }
        field(45; "Delivery Note Date"; Date)
        {
            Caption = 'Fecha albarán';
        }
        field(46; "Purchase Order No."; Code[20])
        {
            Caption = 'Pedido de compra principal';
            TableRelation = "Purchase Header"."No." where("Document Type" = const(Order), "Buy-from Vendor No." = field("Vendor No."));
        }
        field(47; "No. of Orders"; Integer)
        {
            Caption = 'Nº pedidos afectados';
            Editable = false;
        }
        // --- Claude ---
        field(50; Confidence; Decimal)
        {
            Caption = 'Confianza';
            DecimalPlaces = 0 : 2;
            Editable = false;
        }
        field(51; "Claude Warnings"; Text[2048])
        {
            Caption = 'Avisos de Claude';
            Editable = false;
        }
        field(52; "Claude Model"; Text[100])
        {
            Caption = 'Modelo Claude usado';
            Editable = false;
        }
        field(53; "Input Tokens"; Integer)
        {
            Caption = 'Tokens entrada';
            Editable = false;
        }
        field(54; "Output Tokens"; Integer)
        {
            Caption = 'Tokens salida';
            Editable = false;
        }
        field(55; "Extraction JSON"; Blob)
        {
            Caption = 'JSON extraído';
        }
        // --- Resultado / control ---
        field(60; "Review Notes"; Text[2048])
        {
            Caption = 'Pendiente de revisar';
        }
        field(61; "Possible Duplicate"; Boolean)
        {
            Caption = 'Posible duplicado';
            Editable = false;
        }
        field(62; "No. of Lines"; Integer)
        {
            Caption = 'Nº líneas';
            FieldClass = FlowField;
            CalcFormula = count("IKA DN Document Line" where("Document Entry No." = field("Entry No.")));
            Editable = false;
        }
        field(63; "No. of Unmatched Lines"; Integer)
        {
            Caption = 'Nº líneas sin conciliar';
            FieldClass = FlowField;
            CalcFormula = count("IKA DN Document Line" where("Document Entry No." = field("Entry No."), "Order Matched" = const(false)));
            Editable = false;
        }
        field(64; "No. of Discrepancies"; Integer)
        {
            Caption = 'Nº líneas con discrepancias';
            FieldClass = FlowField;
            CalcFormula = count("IKA DN Document Line" where("Document Entry No." = field("Entry No."), "Has Discrepancy" = const(true)));
            Editable = false;
        }
        field(65; "No. of Files"; Integer)
        {
            Caption = 'Nº ficheros';
            FieldClass = FlowField;
            CalcFormula = count("IKA DN File" where("Document Entry No." = field("Entry No.")));
            Editable = false;
        }
        field(70; "Created At"; DateTime)
        {
            Caption = 'Creado';
            Editable = false;
        }
        field(71; "Processed At"; DateTime)
        {
            Caption = 'Procesado';
            Editable = false;
        }
        field(72; "Applied At"; DateTime)
        {
            Caption = 'Aplicado';
            Editable = false;
        }
        field(73; "Applied By"; Code[50])
        {
            Caption = 'Aplicado por';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(74; "Posted Receipt Nos."; Text[250])
        {
            Caption = 'Recepciones registradas';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(InternetMessage; "Internet Message Id")
        {
        }
        key(DriveItem; "Drive Item Id")
        {
        }
        key(VendorShipment; "Vendor No.", "Vendor Shipment No.")
        {
        }
        key(Status; Status, "Received At")
        {
        }
    }

    trigger OnInsert()
    begin
        "Created At" := CurrentDateTime();
    end;

    trigger OnDelete()
    var
        DocumentLine: Record "IKA DN Document Line";
        DNFile: Record "IKA DN File";
    begin
        DocumentLine.SetRange("Document Entry No.", "Entry No.");
        DocumentLine.DeleteAll(true);
        DNFile.SetRange("Document Entry No.", "Entry No.");
        DNFile.DeleteAll(true);
    end;

    procedure SetBodyText(NewText: Text)
    var
        OutStr: OutStream;
    begin
        Clear(Body);
        Body.CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(NewText);
    end;

    procedure GetBodyText(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
    begin
        CalcFields(Body);
        if not Body.HasValue() then
            exit('');
        Body.CreateInStream(InStr, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator()));
    end;

    procedure SetExtractionJson(NewText: Text)
    var
        OutStr: OutStream;
    begin
        Clear("Extraction JSON");
        "Extraction JSON".CreateOutStream(OutStr, TextEncoding::UTF8);
        OutStr.WriteText(NewText);
    end;

    procedure GetExtractionJson(): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
    begin
        CalcFields("Extraction JSON");
        if not "Extraction JSON".HasValue() then
            exit('');
        "Extraction JSON".CreateInStream(InStr, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator()));
    end;

    procedure GetFileOwnerEntryNo(): Integer
    begin
        if "Parent Entry No." <> 0 then
            exit("Parent Entry No.");
        exit("Entry No.");
    end;

    procedure AddReviewNote(NewNote: Text)
    begin
        if NewNote = '' then
            exit;
        if "Review Notes" = '' then
            "Review Notes" := CopyStr(NewNote, 1, MaxStrLen("Review Notes"))
        else
            "Review Notes" := CopyStr("Review Notes" + ' | ' + NewNote, 1, MaxStrLen("Review Notes"));
    end;
}
