page 99221 "IKA Mail Compose"
{
    // Nuevo email, responder, responder a todos y reenviar. Al responder o reenviar, Outlook genera el
    // borrador con el email original citado (y, al reenviar, con sus adjuntos); aquí solo se escribe el
    // texto, se ajustan los destinatarios y se añaden ficheros.
    Caption = 'Redactar';
    PageType = Card;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Mensaje';

                field(ModeText; Format(Mode))
                {
                    ApplicationArea = All;
                    Caption = 'Acción';
                    Editable = false;
                    ToolTip = 'Nuevo email, responder, responder a todos o reenviar.';
                }
                field(FromText; FromText)
                {
                    ApplicationArea = All;
                    Caption = 'De';
                    Editable = false;
                    ToolTip = 'Cuenta de Outlook 365 desde la que se envía.';
                }
                field(ToText; ToText)
                {
                    ApplicationArea = All;
                    Caption = 'Para';
                    ToolTip = 'Direcciones separadas por punto y coma. Admite el formato Nombre <email>.';
                }
                field(CcText; CcText)
                {
                    ApplicationArea = All;
                    Caption = 'CC';
                }
                field(SubjectText; SubjectText)
                {
                    ApplicationArea = All;
                    Caption = 'Asunto';
                    Editable = IsNewMail;
                    ToolTip = 'En un email nuevo, escriba el asunto. Al responder o reenviar, Outlook lo pone automáticamente (RE: / RV:).';
                }
                field(CommentText; CommentText)
                {
                    ApplicationArea = All;
                    Caption = 'Texto';
                    MultiLine = true;
                    ToolTip = 'Texto del email. Al responder o reenviar, se añade encima del email original citado.';
                }
                field(FilesText; FilesText)
                {
                    ApplicationArea = All;
                    Caption = 'Ficheros añadidos';
                    Editable = false;
                    MultiLine = true;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Send)
            {
                ApplicationArea = All;
                Caption = 'Enviar';
                Image = SendMail;
                ToolTip = 'Envía el email desde la cuenta de Outlook. Quedará en Elementos enviados.';

                trigger OnAction()
                var
                    GraphClient: Codeunit "IKA Mail Graph Client";
                    SentMsg: Label 'Email enviado.';
                    NoSubjectQst: Label 'El email no tiene asunto. ¿Enviarlo igualmente?';
                begin
                    if IsNewMail then begin
                        if DelChr(SubjectText, '<>', ' ') = '' then
                            if not Confirm(NoSubjectQst, false) then
                                exit;
                        GraphClient.SendNewMail(MailboxCode, ToText, CcText, SubjectText, CommentText, TempComposeFile);
                    end else
                        GraphClient.SendCompose(MailMessage, Mode, ToText, CcText, CommentText, TempComposeFile);
                    Message(SentMsg);
                    CurrPage.Close();
                end;
            }
            action(AddFile)
            {
                ApplicationArea = All;
                Caption = 'Añadir fichero';
                Image = Attach;
                ToolTip = 'Añade un fichero (máx. 3 MB).';

                trigger OnAction()
                var
                    FileName: Text;
                    InStr: InStream;
                    OutStr: OutStream;
                    NextLineNo: Integer;
                begin
                    if not UploadIntoStream('', '', '', FileName, InStr) then
                        exit;
                    NextLineNo := 1;
                    if TempComposeFile.FindLast() then
                        NextLineNo := TempComposeFile."Line No." + 1;
                    TempComposeFile.Init();
                    TempComposeFile."Line No." := NextLineNo;
                    TempComposeFile."File Name" := CopyStr(GetFileNameOnly(FileName), 1, MaxStrLen(TempComposeFile."File Name"));
                    TempComposeFile."Content Type" := 'application/octet-stream';
                    TempComposeFile.Content.CreateOutStream(OutStr);
                    CopyStream(OutStr, InStr);
                    TempComposeFile.Insert();
                    TempComposeFile.CalcFields(Content);
                    TempComposeFile."Size (Bytes)" := TempComposeFile.Content.Length();
                    TempComposeFile.Modify();
                    UpdateFilesText();
                end;
            }
            action(ClearFiles)
            {
                ApplicationArea = All;
                Caption = 'Quitar ficheros';
                Image = Delete;
                ToolTip = 'Quita los ficheros añadidos.';

                trigger OnAction()
                begin
                    TempComposeFile.DeleteAll();
                    UpdateFilesText();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(Send_Promoted; Send) { }
                actionref(AddFile_Promoted; AddFile) { }
                actionref(ClearFiles_Promoted; ClearFiles) { }
            }
        }
    }

    var
        MailMessage: Record "IKA Mail Message";
        TempComposeFile: Record "IKA Mail Compose File" temporary;
        Mode: Enum "IKA Mail Compose Mode";
        MailboxCode: Code[20];
        IsNewMail: Boolean;
        FromText: Text;
        ToText: Text;
        CcText: Text;
        SubjectText: Text;
        CommentText: Text;
        FilesText: Text;

    procedure SetMessage(NewMailMessage: Record "IKA Mail Message"; NewMode: Enum "IKA Mail Compose Mode")
    var
        Mailbox: Record "IKA Mail Mailbox";
    begin
        MailMessage := NewMailMessage;
        Mode := NewMode;
        Mailbox.Get(MailMessage."Mailbox Code");
        MailboxCode := Mailbox.Code;
        FromText := Mailbox.Address;
        case Mode of
            Mode::Reply:
                begin
                    ToText := FormatAddress(MailMessage."From Name", MailMessage."From Address");
                    SubjectText := 'RE: ' + MailMessage.Subject;
                end;
            Mode::ReplyAll:
                begin
                    ToText := JoinRecipients(FormatAddress(MailMessage."From Name", MailMessage."From Address"),
                        RemoveAddress(MailMessage."To Recipients", Mailbox.Address));
                    CcText := RemoveAddress(MailMessage."Cc Recipients", Mailbox.Address);
                    SubjectText := 'RE: ' + MailMessage.Subject;
                end;
            Mode::Forward:
                SubjectText := 'RV: ' + MailMessage.Subject;
        end;
    end;

    /// <summary>
    /// Email nuevo desde la cuenta indicada (opcionalmente con destinatario y asunto propuestos).
    /// </summary>
    procedure SetNewMail(NewMailboxCode: Code[20]; NewToText: Text; NewSubjectText: Text)
    var
        Mailbox: Record "IKA Mail Mailbox";
    begin
        Mailbox.Get(NewMailboxCode);
        Mailbox.CheckAccess();
        Mode := Mode::New;
        IsNewMail := true;
        MailboxCode := Mailbox.Code;
        FromText := Mailbox.Address;
        ToText := NewToText;
        SubjectText := NewSubjectText;
    end;

    local procedure FormatAddress(Name: Text; Address: Text): Text
    begin
        if (Name = '') or (Name = Address) then
            exit(Address);
        exit(Name + ' <' + Address + '>');
    end;

    local procedure JoinRecipients(Text1: Text; Text2: Text): Text
    begin
        if Text2 = '' then
            exit(Text1);
        if Text1 = '' then
            exit(Text2);
        exit(Text1 + '; ' + Text2);
    end;

    /// <summary>
    /// Quita la dirección de la propia cuenta de una lista de destinatarios.
    /// </summary>
    local procedure RemoveAddress(Recipients: Text; AddressToRemove: Text): Text
    var
        Part: Text;
        Result: Text;
    begin
        foreach Part in Recipients.Split(';') do
            if DelChr(Part, '<>', ' ') <> '' then
                if StrPos(LowerCase(Part), LowerCase(AddressToRemove)) = 0 then
                    Result := JoinRecipients(Result, DelChr(Part, '<>', ' '));
        exit(Result);
    end;

    local procedure UpdateFilesText()
    begin
        FilesText := '';
        if TempComposeFile.FindSet() then
            repeat
                if FilesText <> '' then
                    FilesText += ', ';
                FilesText += TempComposeFile."File Name";
            until TempComposeFile.Next() = 0;
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
