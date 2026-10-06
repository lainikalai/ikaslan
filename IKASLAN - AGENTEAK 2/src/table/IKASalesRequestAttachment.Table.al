table 99021 "IKA Sales Request Attachment"
{
    Caption = 'Adjunto solicitud de venta (agente)';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Request Entry No."; Integer)
        {
            Caption = 'Nº mov. solicitud';
            TableRelation = "IKA Sales Request Header";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Nº línea';
        }
        field(10; "File Name"; Text[250])
        {
            Caption = 'Nombre fichero';
        }
        field(11; "Content Type"; Text[100])
        {
            Caption = 'Tipo de contenido';
        }
        field(12; "Size (Bytes)"; Integer)
        {
            Caption = 'Tamaño (bytes)';
        }
        field(13; Content; Blob)
        {
            Caption = 'Contenido';
        }
        field(14; "Graph Attachment Id"; Text[250])
        {
            Caption = 'Id adjunto (Graph)';
        }
        field(15; "Is Inline"; Boolean)
        {
            Caption = 'En línea (firma/logo)';
        }
        field(16; "Sent to Claude"; Boolean)
        {
            Caption = 'Enviado a Claude';
        }
        field(17; "Skip Reason"; Text[250])
        {
            Caption = 'Motivo no enviado';
        }
    }

    keys
    {
        key(PK; "Request Entry No.", "Line No.")
        {
            Clustered = true;
        }
    }

    procedure GetNextLineNo(RequestEntryNo: Integer): Integer
    var
        RequestAttachment: Record "IKA Sales Request Attachment";
    begin
        RequestAttachment.SetRange("Request Entry No.", RequestEntryNo);
        if RequestAttachment.FindLast() then
            exit(RequestAttachment."Line No." + 10000);
        exit(10000);
    end;

    procedure GetExtension(): Text
    var
        DotPos: Integer;
        FileName: Text;
    begin
        FileName := "File Name";
        DotPos := StrLen(FileName);
        while (DotPos > 0) and (CopyStr(FileName, DotPos, 1) <> '.') do
            DotPos -= 1;
        if DotPos = 0 then
            exit('');
        exit(LowerCase(CopyStr(FileName, DotPos + 1)));
    end;

    procedure ImportFromClient(RequestEntryNo: Integer)
    var
        FileName: Text;
        InStr: InStream;
        OutStr: OutStream;
        UploadTitleLbl: Label 'Seleccione el fichero del pedido (PDF, imagen, Excel, CSV o texto)';
    begin
        if not UploadIntoStream(UploadTitleLbl, '', '', FileName, InStr) then
            exit;
        Init();
        "Request Entry No." := RequestEntryNo;
        "Line No." := GetNextLineNo(RequestEntryNo);
        "File Name" := CopyStr(GetFileNameOnly(FileName), 1, MaxStrLen("File Name"));
        "Content Type" := CopyStr(GuessContentType(GetExtension()), 1, MaxStrLen("Content Type"));
        Content.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
        Insert(true);
        CalcFields(Content);
        "Size (Bytes)" := Content.Length();
        Modify();
    end;

    procedure ExportToClient()
    var
        InStr: InStream;
        FileName: Text;
    begin
        CalcFields(Content);
        if not Content.HasValue() then
            exit;
        Content.CreateInStream(InStr);
        FileName := "File Name";
        DownloadFromStream(InStr, '', '', '', FileName);
    end;

    procedure GuessContentType(Extension: Text): Text
    begin
        case LowerCase(Extension) of
            'pdf':
                exit('application/pdf');
            'png':
                exit('image/png');
            'jpg', 'jpeg':
                exit('image/jpeg');
            'gif':
                exit('image/gif');
            'webp':
                exit('image/webp');
            'xlsx':
                exit('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
            'csv':
                exit('text/csv');
            'txt':
                exit('text/plain');
            else
                exit('application/octet-stream');
        end;
    end;

    local procedure GetFileNameOnly(FullPath: Text): Text
    var
        Pos: Integer;
    begin
        Pos := StrLen(FullPath);
        while (Pos > 0) and not (CopyStr(FullPath, Pos, 1) in ['\', '/']) do
            Pos -= 1;
        exit(CopyStr(FullPath, Pos + 1));
    end;
}
