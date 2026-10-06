table 99011 "IKA Sales Request Header"
{
    Caption = 'Solicitud de venta (agente)';
    DataClassification = CustomerContent;
    LookupPageId = "IKA Sales Requests";
    DrillDownPageId = "IKA Sales Requests";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº mov.';
            AutoIncrement = true;
            Editable = false;
        }
        field(2; Status; Enum "IKA Sales Req. Status")
        {
            Caption = 'Estado';
        }
        field(3; Source; Enum "IKA Sales Req. Source")
        {
            Caption = 'Origen';
        }
        // --- Datos del email ---
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
            Caption = 'Asunto';
        }
        field(16; Body; Blob)
        {
            Caption = 'Cuerpo';
        }
        field(17; "Mail Filter Line No."; Integer)
        {
            Caption = 'Nº línea filtro correo';
            TableRelation = "IKA Sales Agent Mail Filter";
            Editable = false;
        }
        field(18; "Order Index"; Integer)
        {
            Caption = 'Nº pedido dentro del email';
            Editable = false;
            InitValue = 1;
        }
        field(19; "Parent Entry No."; Integer)
        {
            Caption = 'Nº mov. solicitud origen';
            TableRelation = "IKA Sales Request Header";
            Editable = false;
        }
        // --- Datos extraídos por Claude (tal cual vienen) ---
        field(20; "Ext. Customer Code"; Text[100])
        {
            Caption = 'Código cliente (extraído)';
        }
        field(21; "Ext. Customer Name"; Text[100])
        {
            Caption = 'Nombre cliente (extraído)';
        }
        field(22; "Ext. VAT Registration No."; Text[30])
        {
            Caption = 'NIF (extraído)';
        }
        field(23; "Ext. Customer E-Mail"; Text[100])
        {
            Caption = 'Email cliente (extraído)';
        }
        field(24; "Ext. Ship-to Name"; Text[100])
        {
            Caption = 'Nombre envío (extraído)';
        }
        field(25; "Ext. Ship-to Address"; Text[100])
        {
            Caption = 'Dirección envío (extraída)';
        }
        field(26; "Ext. Ship-to City"; Text[30])
        {
            Caption = 'Población envío (extraída)';
        }
        field(27; "Ext. Ship-to Post Code"; Text[20])
        {
            Caption = 'C.P. envío (extraído)';
        }
        field(28; "Ext. Requested Delivery Date"; Text[30])
        {
            Caption = 'Fecha entrega (extraída)';
        }
        field(29; "Ext. Customer Order No."; Text[100])
        {
            Caption = 'Nº pedido cliente (extraído)';
        }
        // --- Datos resueltos en BC ---
        field(30; "Customer No."; Code[20])
        {
            Caption = 'Nº cliente';
            TableRelation = Customer;

            trigger OnValidate()
            begin
                if "Customer No." = '' then
                    "Customer Match Status" := "Customer Match Status"::" "
                else
                    if CurrFieldNo = FieldNo("Customer No.") then begin
                        "Customer Match Status" := "Customer Match Status"::Manual;
                        "Customer Match Method" := '';
                    end;
                if "Customer No." <> xRec."Customer No." then
                    "Ship-to Code" := '';
            end;
        }
        field(31; "Customer Name"; Text[100])
        {
            Caption = 'Nombre cliente';
            FieldClass = FlowField;
            CalcFormula = lookup(Customer.Name where("No." = field("Customer No.")));
            Editable = false;
        }
        field(32; "Customer Match Status"; Enum "IKA Match Status")
        {
            Caption = 'Estado coincidencia cliente';
            Editable = false;
        }
        field(33; "Customer Match Method"; Text[50])
        {
            Caption = 'Método coincidencia cliente';
            Editable = false;
        }
        field(34; "Ship-to Code"; Code[10])
        {
            Caption = 'Cód. dirección envío';
            TableRelation = "Ship-to Address".Code where("Customer No." = field("Customer No."));
        }
        field(35; "External Document No."; Code[35])
        {
            Caption = 'Nº documento externo';
        }
        field(36; "Requested Delivery Date"; Date)
        {
            Caption = 'Fecha entrega requerida';
        }
        field(37; Comments; Text[2048])
        {
            Caption = 'Observaciones';
        }
        // --- Claude ---
        field(40; Confidence; Decimal)
        {
            Caption = 'Confianza';
            DecimalPlaces = 0 : 2;
            Editable = false;
        }
        field(41; "Claude Warnings"; Text[2048])
        {
            Caption = 'Avisos de Claude';
            Editable = false;
        }
        field(42; "Claude Model"; Text[100])
        {
            Caption = 'Modelo Claude usado';
            Editable = false;
        }
        field(43; "Input Tokens"; Integer)
        {
            Caption = 'Tokens entrada';
            Editable = false;
        }
        field(44; "Output Tokens"; Integer)
        {
            Caption = 'Tokens salida';
            Editable = false;
        }
        field(45; "Extraction JSON"; Blob)
        {
            Caption = 'JSON extraído';
        }
        // --- Resultado ---
        field(50; "Sales Order No."; Code[20])
        {
            Caption = 'Nº pedido de venta';
            TableRelation = "Sales Header"."No." where("Document Type" = const(Order));
            Editable = false;
        }
        field(51; "Error Message"; Text[2048])
        {
            Caption = 'Mensaje de error / revisión';
        }
        field(52; "No. of Lines"; Integer)
        {
            Caption = 'Nº líneas';
            FieldClass = FlowField;
            CalcFormula = count("IKA Sales Request Line" where("Request Entry No." = field("Entry No.")));
            Editable = false;
        }
        field(53; "No. of Unresolved Lines"; Integer)
        {
            Caption = 'Nº líneas sin resolver';
            FieldClass = FlowField;
            CalcFormula = count("IKA Sales Request Line" where("Request Entry No." = field("Entry No."), Resolved = const(false)));
            Editable = false;
        }
        field(54; "No. of Attachments"; Integer)
        {
            Caption = 'Nº adjuntos';
            FieldClass = FlowField;
            CalcFormula = count("IKA Sales Request Attachment" where("Request Entry No." = field("Entry No.")));
            Editable = false;
        }
        field(55; "Possible Duplicate"; Boolean)
        {
            Caption = 'Posible duplicado';
            Editable = false;
        }
        field(60; "Created At"; DateTime)
        {
            Caption = 'Creada';
            Editable = false;
        }
        field(61; "Processed At"; DateTime)
        {
            Caption = 'Procesada';
            Editable = false;
        }
        field(62; "Moved in Mailbox"; Boolean)
        {
            Caption = 'Movido en buzón';
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(GraphMessage; "Graph Message Id")
        {
        }
        key(InternetMessage; "Internet Message Id")
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
        RequestLine: Record "IKA Sales Request Line";
        RequestAttachment: Record "IKA Sales Request Attachment";
    begin
        RequestLine.SetRange("Request Entry No.", "Entry No.");
        RequestLine.DeleteAll(true);
        RequestAttachment.SetRange("Request Entry No.", "Entry No.");
        RequestAttachment.DeleteAll(true);
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

    /// <summary>
    /// Entrada de la que cuelgan los adjuntos (si un email trae varios pedidos, los adjuntos
    /// se guardan solo en la primera solicitud).
    /// </summary>
    procedure GetAttachmentOwnerEntryNo(): Integer
    begin
        if "Parent Entry No." <> 0 then
            exit("Parent Entry No.");
        exit("Entry No.");
    end;

    procedure AddToErrorMessage(NewMessage: Text)
    begin
        if NewMessage = '' then
            exit;
        if "Error Message" = '' then
            "Error Message" := CopyStr(NewMessage, 1, MaxStrLen("Error Message"))
        else
            "Error Message" := CopyStr("Error Message" + ' | ' + NewMessage, 1, MaxStrLen("Error Message"));
    end;
}
