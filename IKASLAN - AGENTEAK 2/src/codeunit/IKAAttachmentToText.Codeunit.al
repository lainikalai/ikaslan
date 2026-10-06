codeunit 50070 "IKA Attachment To Text"
{
    Access = Internal;

    var
        SheetHeaderLbl: Label '--- Hoja: %1 ---', Comment = '%1 = sheet name';

    // Cómo se envía cada adjunto a Claude:
    //  - PDF e imágenes: en base64, Claude los lee de forma nativa.
    //  - Excel, CSV y texto: se convierten a texto plano en AL.

    procedure IsPdf(var RequestAttachment: Record "IKA Sales Request Attachment"): Boolean
    begin
        exit((LowerCase(RequestAttachment."Content Type") = 'application/pdf') or (RequestAttachment.GetExtension() = 'pdf'));
    end;

    procedure IsImage(var RequestAttachment: Record "IKA Sales Request Attachment"): Boolean
    begin
        exit(GetImageMediaType(RequestAttachment) <> '');
    end;

    procedure GetImageMediaType(var RequestAttachment: Record "IKA Sales Request Attachment"): Text
    begin
        case RequestAttachment.GetExtension() of
            'png':
                exit('image/png');
            'jpg', 'jpeg':
                exit('image/jpeg');
            'gif':
                exit('image/gif');
            'webp':
                exit('image/webp');
        end;
        case LowerCase(RequestAttachment."Content Type") of
            'image/png', 'image/jpeg', 'image/gif', 'image/webp':
                exit(LowerCase(RequestAttachment."Content Type"));
        end;
        exit('');
    end;

    procedure IsSpreadsheet(var RequestAttachment: Record "IKA Sales Request Attachment"): Boolean
    begin
        exit(RequestAttachment.GetExtension() in ['xlsx', 'xlsm']);
    end;

    procedure IsPlainText(var RequestAttachment: Record "IKA Sales Request Attachment"): Boolean
    begin
        if RequestAttachment.GetExtension() in ['csv', 'txt', 'tsv', 'xml', 'json', 'edi'] then
            exit(true);
        exit(LowerCase(CopyStr(RequestAttachment."Content Type", 1, 5)) = 'text/');
    end;

    procedure GetBase64(var RequestAttachment: Record "IKA Sales Request Attachment"): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
    begin
        RequestAttachment.CalcFields(Content);
        RequestAttachment.Content.CreateInStream(InStr);
        exit(Base64Convert.ToBase64(InStr));
    end;

    procedure GetPlainText(var RequestAttachment: Record "IKA Sales Request Attachment"): Text
    var
        TypeHelper: Codeunit "Type Helper";
        InStr: InStream;
    begin
        RequestAttachment.CalcFields(Content);
        RequestAttachment.Content.CreateInStream(InStr, TextEncoding::UTF8);
        exit(TypeHelper.ReadAsTextWithSeparator(InStr, TypeHelper.LFSeparator()));
    end;

    /// <summary>
    /// Convierte todas las hojas de un Excel a texto tipo CSV (separador ;) usando Excel Buffer.
    /// </summary>
    procedure SpreadsheetToText(var RequestAttachment: Record "IKA Sales Request Attachment"): Text
    var
        TempNameValueBuffer: Record "Name/Value Buffer" temporary;
        TempExcelBuffer: Record "Excel Buffer" temporary;
        InStr: InStream;
        Result: TextBuilder;
        CurrentRow: Integer;
        CurrentCol: Integer;
        RowText: Text;
    begin
        RequestAttachment.CalcFields(Content);
        RequestAttachment.Content.CreateInStream(InStr);
        TempExcelBuffer.GetSheetsNameListFromStream(InStr, TempNameValueBuffer);
        if not TempNameValueBuffer.FindSet() then
            exit('');

        repeat
            TempExcelBuffer.Reset();
            TempExcelBuffer.DeleteAll();
            RequestAttachment.Content.CreateInStream(InStr);
            TempExcelBuffer.OpenBookStream(InStr, TempNameValueBuffer.Value);
            TempExcelBuffer.ReadSheet();

            Result.AppendLine(StrSubstNo(SheetHeaderLbl, TempNameValueBuffer.Value));
            CurrentRow := 0;
            CurrentCol := 0;
            RowText := '';
            TempExcelBuffer.SetCurrentKey("Row No.", "Column No.");
            if TempExcelBuffer.FindSet() then
                repeat
                    if TempExcelBuffer."Row No." <> CurrentRow then begin
                        if CurrentRow <> 0 then
                            Result.AppendLine(RowText);
                        CurrentRow := TempExcelBuffer."Row No.";
                        CurrentCol := 0;
                        RowText := '';
                    end;
                    // Rellenar columnas vacías para conservar la posición
                    while CurrentCol < TempExcelBuffer."Column No." - 1 do begin
                        RowText += ';';
                        CurrentCol += 1;
                    end;
                    if CurrentCol > 0 then
                        RowText += ';';
                    RowText += EscapeCsv(TempExcelBuffer."Cell Value as Text");
                    CurrentCol := TempExcelBuffer."Column No.";
                until TempExcelBuffer.Next() = 0;
            if CurrentRow <> 0 then
                Result.AppendLine(RowText);
            TempExcelBuffer.CloseBook();
        until TempNameValueBuffer.Next() = 0;

        exit(Result.ToText());
    end;

    local procedure EscapeCsv(Value: Text): Text
    begin
        if (StrPos(Value, ';') > 0) or (StrPos(Value, '"') > 0) then
            exit('"' + Value.Replace('"', '""') + '"');
        exit(Value);
    end;
}
