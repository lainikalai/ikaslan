table 50010 "DECA Header"
{
    Caption = 'DeCA';
    DataClassification = CustomerContent;
    LookupPageId = "DECA List";
    DrillDownPageId = "DECA List";

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'Nº';
        }
        field(2; Status; Enum "DECA Status")
        {
            Caption = 'Estado';
            Editable = false;
        }
        field(3; "Version No."; Integer)
        {
            Caption = 'Versión';
            Editable = false;
        }
        field(4; "Replaces DeCA No."; Code[20])
        {
            Caption = 'Sustituye al DeCA nº';
            TableRelation = "DECA Header";
            Editable = false;
        }
        field(5; "Replaced by DeCA No."; Code[20])
        {
            Caption = 'Sustituido por DeCA nº';
            TableRelation = "DECA Header";
            Editable = false;
        }
        field(6; "Modification Reason"; Text[250])
        {
            Caption = 'Motivo de la modificación';
        }
        field(7; "Source Type"; Enum "DECA Source Type")
        {
            Caption = 'Tipo de origen';
            Editable = false;
        }
        field(8; "Source No."; Code[20])
        {
            Caption = 'Nº documento origen';
            Editable = false;
        }
        field(9; "No. Series"; Code[20])
        {
            Caption = 'Nº serie';
            TableRelation = "No. Series";
            Editable = false;
        }

        // a) Cargador contractual: nombre, NIF y domicilio
        field(20; "Shipper Customer No."; Code[20])
        {
            Caption = 'Nº cliente cargador';
            TableRelation = Customer;

            trigger OnValidate()
            var
                Customer: Record Customer;
            begin
                if "Shipper Customer No." = '' then
                    exit;
                Customer.Get("Shipper Customer No.");
                "Shipper Name" := Customer.Name;
                "Shipper VAT Registration No." := Customer."VAT Registration No.";
                "Shipper Address" := Customer.Address;
                "Shipper Address 2" := Customer."Address 2";
                "Shipper Post Code" := Customer."Post Code";
                "Shipper City" := Customer.City;
                "Shipper County" := Customer.County;
            end;
        }
        field(21; "Shipper Name"; Text[100])
        {
            Caption = 'Nombre cargador contractual';
        }
        field(22; "Shipper VAT Registration No."; Text[20])
        {
            Caption = 'NIF cargador contractual';
        }
        field(23; "Shipper Address"; Text[100])
        {
            Caption = 'Domicilio cargador';
        }
        field(24; "Shipper Address 2"; Text[50])
        {
            Caption = 'Domicilio cargador 2';
        }
        field(25; "Shipper Post Code"; Code[20])
        {
            Caption = 'C.P. cargador';
        }
        field(26; "Shipper City"; Text[30])
        {
            Caption = 'Población cargador';
        }
        field(27; "Shipper County"; Text[30])
        {
            Caption = 'Provincia cargador';
        }

        // b) Transportista efectivo: nombre y NIF
        field(30; "Shipping Agent Code"; Code[10])
        {
            Caption = 'Cód. transportista';
            TableRelation = "Shipping Agent";

            trigger OnValidate()
            var
                ShippingAgent: Record "Shipping Agent";
            begin
                if "Shipping Agent Code" = '' then
                    exit;
                ShippingAgent.Get("Shipping Agent Code");
                if ShippingAgent."DECA Legal Name" <> '' then
                    "Carrier Name" := ShippingAgent."DECA Legal Name"
                else
                    "Carrier Name" := ShippingAgent.Name;
                "Carrier VAT Registration No." := ShippingAgent."DECA VAT Registration No.";
                if ShippingAgent."DECA E-Mail" <> '' then
                    "Driver E-Mail" := ShippingAgent."DECA E-Mail";
            end;
        }
        field(31; "Carrier Name"; Text[100])
        {
            Caption = 'Nombre transportista efectivo';
        }
        field(32; "Carrier VAT Registration No."; Text[20])
        {
            Caption = 'NIF transportista efectivo';
        }

        // e), f), g), h)
        field(40; "Transport Date"; Date)
        {
            Caption = 'Fecha del transporte';

            trigger OnValidate()
            begin
                if ("Service End Date" <> 0D) and ("Service End Date" < "Transport Date") then
                    "Service End Date" := 0D;
            end;
        }
        field(41; "Service End Date"; Date)
        {
            Caption = 'Fecha fin del servicio';

            trigger OnValidate()
            begin
                if ("Service End Date" <> 0D) and ("Service End Date" < "Transport Date") then
                    Error(EndBeforeStartErr);
                TestField("URL Disabled", false);
            end;
        }
        field(42; "Vehicle Plate No."; Code[20])
        {
            Caption = 'Matrícula vehículo';
        }
        field(43; "Trailer Plate No."; Code[20])
        {
            Caption = 'Matrícula remolque/semirremolque';
        }
        field(44; "Driver Name"; Text[100])
        {
            Caption = 'Conductor';
        }
        field(45; "Driver E-Mail"; Text[250])
        {
            Caption = 'Email de envío (conductor/transportista)';
            ExtendedDatatype = EMail;
        }
        field(46; "Special Circulation Permit"; Text[100])
        {
            Caption = 'Autorización especial de circulación';
        }
        field(47; Remarks; Text[250])
        {
            Caption = 'Observaciones';
        }

        // Emisión
        field(60; "Document URL"; Text[1024])
        {
            Caption = 'URL del documento';
            ExtendedDatatype = URL;
            Editable = false;
        }
        field(61; "Blob Name"; Text[250])
        {
            Caption = 'Nombre del fichero en el repositorio';
            Editable = false;
        }
        field(62; "Issued At"; DateTime)
        {
            Caption = 'Fecha y hora de creación del fichero';
            Editable = false;
        }
        field(63; "Issued By"; Code[50])
        {
            Caption = 'Emitido por';
            DataClassification = EndUserIdentifiableInformation;
            Editable = false;
        }
        field(64; "URL Disabled"; Boolean)
        {
            Caption = 'Descarga desactivada';
            Editable = false;
        }
        field(65; "URL Disabled At"; DateTime)
        {
            Caption = 'Fecha y hora desactivación';
            Editable = false;
        }
        field(66; "PDF Content"; Blob)
        {
            Caption = 'PDF';
        }
        field(70; "Total Gross Weight (kg)"; Decimal)
        {
            Caption = 'Peso total (kg)';
            FieldClass = FlowField;
            CalcFormula = sum("DECA Line"."Gross Weight (kg)" where("Document No." = field("No.")));
            DecimalPlaces = 0 : 2;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
        key(Disable; Status, "URL Disabled", "Service End Date") { }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", "Transport Date", "Shipper Name", "Carrier Name", Status) { }
    }

    var
        EndBeforeStartErr: Label 'La fecha fin del servicio no puede ser anterior a la fecha del transporte.';
        RetentionErr: Label 'El DeCA %1 está emitido y debe conservarse al menos un año. No se puede eliminar.', Comment = '%1 = nº DeCA';

    trigger OnInsert()
    var
        DECASetup: Record "DECA Setup";
        NoSeries: Codeunit "No. Series";
    begin
        DECASetup.GetSetup();
        if "No." = '' then begin
            DECASetup.TestField("DeCA Nos.");
            "No. Series" := DECASetup."DeCA Nos.";
            "No." := NoSeries.GetNextNo("No. Series", WorkDate());
        end;
        if "Version No." = 0 then
            "Version No." := 1;
        if "Transport Date" = 0D then
            "Transport Date" := WorkDate();
        InitCompanyParty(DECASetup);
    end;

    trigger OnDelete()
    var
        DECALine: Record "DECA Line";
    begin
        // Resolución 5/6/2026, apartado segundo.4: conservación mínima de un año
        if (Status <> Status::Draft) and ("Issued At" > CreateDateTime(CalcDate('<-1Y>', Today()), 0T)) then
            Error(RetentionErr, "No.");
        DECALine.SetRange("Document No.", "No.");
        DECALine.DeleteAll();
    end;

    /// <summary>Rellena con los datos de la empresa la figura que esta ocupa (cargador o transportista), si está vacía.</summary>
    local procedure InitCompanyParty(DECASetup: Record "DECA Setup")
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        case DECASetup."Company Role" of
            DECASetup."Company Role"::Shipper:
                if "Shipper Name" = '' then begin
                    "Shipper Name" := CompanyInformation.Name;
                    "Shipper VAT Registration No." := CompanyInformation."VAT Registration No.";
                    "Shipper Address" := CompanyInformation.Address;
                    "Shipper Address 2" := CompanyInformation."Address 2";
                    "Shipper Post Code" := CompanyInformation."Post Code";
                    "Shipper City" := CompanyInformation.City;
                    "Shipper County" := CompanyInformation.County;
                end;
            DECASetup."Company Role"::Carrier:
                if "Carrier Name" = '' then begin
                    "Carrier Name" := CompanyInformation.Name;
                    "Carrier VAT Registration No." := CompanyInformation."VAT Registration No.";
                end;
        end;
    end;

    procedure TestStatusDraft()
    begin
        TestField(Status, Status::Draft);
    end;

    procedure HasPdf(): Boolean
    begin
        CalcFields("PDF Content");
        exit("PDF Content".HasValue());
    end;
}
