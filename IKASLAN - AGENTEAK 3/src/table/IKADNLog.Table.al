table 99131 "IKA DN Log"
{
    Caption = 'Registro agente de albaranes';
    DataClassification = CustomerContent;
    LookupPageId = "IKA DN Log";
    DrillDownPageId = "IKA DN Log";

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Nº mov.';
            AutoIncrement = true;
        }
        field(2; "Document Entry No."; Integer)
        {
            Caption = 'Nº mov. albarán';
            TableRelation = "IKA DN Document";
        }
        field(3; "Created At"; DateTime)
        {
            Caption = 'Fecha/hora';
        }
        field(4; "Log Type"; Enum "IKA DN Log Type")
        {
            Caption = 'Tipo';
        }
        field(5; Message; Text[2048])
        {
            Caption = 'Mensaje';
        }
        field(6; "Request Payload"; Blob)
        {
            Caption = 'Petición';
        }
        field(7; "Response Payload"; Blob)
        {
            Caption = 'Respuesta';
        }
        field(8; "HTTP Status"; Integer)
        {
            Caption = 'Estado HTTP';
        }
        field(9; "Input Tokens"; Integer)
        {
            Caption = 'Tokens entrada';
        }
        field(10; "Output Tokens"; Integer)
        {
            Caption = 'Tokens salida';
        }
        field(11; Duration; Duration)
        {
            Caption = 'Duración';
        }
        field(12; "User ID"; Code[50])
        {
            Caption = 'Id. usuario';
            DataClassification = EndUserIdentifiableInformation;
        }
        field(13; Model; Text[100])
        {
            Caption = 'Modelo';
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
        key(Document; "Document Entry No.")
        {
        }
    }

    trigger OnInsert()
    begin
        "Created At" := CurrentDateTime();
        "User ID" := CopyStr(UserId(), 1, MaxStrLen("User ID"));
    end;

    procedure SetPayloads(RequestText: Text; ResponseText: Text)
    var
        OutStr: OutStream;
    begin
        if RequestText <> '' then begin
            "Request Payload".CreateOutStream(OutStr, TextEncoding::UTF8);
            OutStr.WriteText(RequestText);
        end;
        if ResponseText <> '' then begin
            "Response Payload".CreateOutStream(OutStr, TextEncoding::UTF8);
            OutStr.WriteText(ResponseText);
        end;
    end;

    procedure DownloadPayload(Which: Option Request,Response)
    var
        InStr: InStream;
        FileName: Text;
    begin
        if Which = Which::Request then begin
            CalcFields("Request Payload");
            "Request Payload".CreateInStream(InStr, TextEncoding::UTF8);
            FileName := StrSubstNo('request_%1.json', "Entry No.");
        end else begin
            CalcFields("Response Payload");
            "Response Payload".CreateInStream(InStr, TextEncoding::UTF8);
            FileName := StrSubstNo('response_%1.json', "Entry No.");
        end;
        DownloadFromStream(InStr, '', '', '', FileName);
    end;
}
