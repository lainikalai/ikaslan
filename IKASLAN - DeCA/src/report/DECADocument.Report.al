report 50000 "DECA Document"
{
    Caption = 'Documento de control (DeCA)';
    DefaultLayout = RDLC;
    RDLCLayout = './src/report/DECADocument.rdl';
    UsageCategory = None;
    ApplicationArea = All;

    dataset
    {
        dataitem(DECAHeader; "DECA Header")
        {
            RequestFilterFields = "No.";

            column(No; "No.") { }
            column(VersionNo; Format("Version No.")) { }
            column(StatusTxt; StatusTxt) { }
            column(ShipperName; "Shipper Name") { }
            column(ShipperVAT; "Shipper VAT Registration No.") { }
            column(ShipperAddress; ShipperAddressTxt) { }
            column(CarrierName; "Carrier Name") { }
            column(CarrierVAT; "Carrier VAT Registration No.") { }
            column(TransportDate; Format("Transport Date")) { }
            column(VehiclePlate; "Vehicle Plate No.") { }
            column(TrailerPlate; "Trailer Plate No.") { }
            column(DriverName; "Driver Name") { }
            column(SpecialPermit; "Special Circulation Permit") { }
            column(Remarks; Remarks) { }
            column(DocumentURL; "Document URL") { }
            column(QRCode; QRCodeTxt) { }
            column(IssuedAt; Format("Issued At")) { }
            column(ReplacesTxt; ReplacesTxt) { }
            column(TotalWeight; Format("Total Gross Weight (kg)", 0, '<Precision,0:2><Standard Format,0>')) { }

            dataitem(DECALine; "DECA Line")
            {
                DataItemLink = "Document No." = field("No.");
                DataItemTableView = sorting("Document No.", "Line No.");

                column(LineNo; "Line No.") { }
                column(Origin; OriginTxt) { }
                column(Destination; DestinationTxt) { }
                column(Goods; "Goods Description") { }
                column(Weight; WeightTxt) { }
                column(SourceDocNo; "Source Document No.") { }

                trigger OnAfterGetRecord()
                begin
                    OriginTxt := ComposeAddress("Origin Name", "Origin Address", "Origin Post Code", "Origin City", '');
                    DestinationTxt := ComposeAddress("Destination Name", "Destination Address", "Destination Post Code", "Destination City", '');
                    if "Gross Weight (kg)" <> 0 then
                        WeightTxt := Format("Gross Weight (kg)", 0, '<Precision,0:2><Standard Format,0>') + ' kg'
                    else
                        WeightTxt := '';
                    if "Alternative Magnitude" <> '' then begin
                        if WeightTxt <> '' then
                            WeightTxt += ' / ';
                        WeightTxt += "Alternative Magnitude";
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            var
                BarcodeFontProvider2D: Interface "Barcode Font Provider 2D";
            begin
                CalcFields("Total Gross Weight (kg)");
                ShipperAddressTxt := ComposeAddress('', "Shipper Address" + ' ' + "Shipper Address 2", "Shipper Post Code", "Shipper City", "Shipper County");

                case Status of
                    Status::Draft:
                        StatusTxt := DraftLbl;
                    Status::Replaced:
                        StatusTxt := StrSubstNo(ReplacedLbl, "Replaced by DeCA No.");
                    else
                        StatusTxt := '';
                end;

                ReplacesTxt := '';
                if "Replaces DeCA No." <> '' then
                    ReplacesTxt := StrSubstNo(ReplacesLbl, "Replaces DeCA No.", "Modification Reason");

                // Código QR con la URL única del documento (fuente IDAutomation2D, incluida en BC SaaS)
                QRCodeTxt := '';
                if "Document URL" <> '' then begin
                    BarcodeFontProvider2D := Enum::"Barcode Font Provider 2D"::IDAutomation2D;
                    QRCodeTxt := BarcodeFontProvider2D.EncodeFont("Document URL", Enum::"Barcode Symbology 2D"::"QR-Code");
                end;
            end;
        }
    }

    var
        QRCodeTxt: Text;
        StatusTxt: Text;
        ReplacesTxt: Text;
        ShipperAddressTxt: Text;
        OriginTxt: Text;
        DestinationTxt: Text;
        WeightTxt: Text;
        DraftLbl: Label 'BORRADOR - NO VÁLIDO COMO DOCUMENTO DE CONTROL';
        ReplacedLbl: Label 'SUSTITUIDO POR EL DeCA %1 - DATOS NO VÁLIDOS', Comment = '%1 = nº DeCA';
        ReplacesLbl: Label 'Sustituye al DeCA %1. Motivo de la modificación: %2', Comment = '%1 = nº DeCA, %2 = motivo';

    local procedure ComposeAddress(PlaceName: Text; Address: Text; PostCode: Text; City: Text; County: Text): Text
    var
        Result: Text;
    begin
        Result := PlaceName.Trim();
        AppendPart(Result, Address.Trim(), ' - ');
        AppendPart(Result, (PostCode + ' ' + City).Trim(), ', ');
        if County.Trim() <> '' then
            Result += ' (' + County.Trim() + ')';
        exit(Result);
    end;

    local procedure AppendPart(var Result: Text; NewPart: Text; Separator: Text)
    begin
        if NewPart = '' then
            exit;
        if Result <> '' then
            Result += Separator;
        Result += NewPart;
    end;
}
