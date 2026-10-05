page 50650 "IKA WA Send"
{
    // Diálogo de envío por WhatsApp. Si la ventana de 24 h está cerrada (o no hay conversación),
    // solo se puede usar una plantilla aprobada; si está abierta, también texto libre y el documento.
    Caption = 'Enviar por WhatsApp';
    PageType = Card;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(Recipient)
            {
                Caption = 'Destinatario';

                field(AccountCode; AccountCode)
                {
                    ApplicationArea = All;
                    Caption = 'Cuenta de WhatsApp';
                    TableRelation = "IKA WA Account";

                    trigger OnValidate()
                    begin
                        TemplateName := '';
                        LanguageCode := '';
                        UpdateConversationInfo();
                        UpdateTemplateInfo();
                    end;
                }
                field(RecipientName; RecipientName)
                {
                    ApplicationArea = All;
                    Caption = 'Nombre';
                    Editable = false;
                }
                field(PhoneNo; PhoneNo)
                {
                    ApplicationArea = All;
                    Caption = 'Teléfono';
                    ToolTip = 'Formato internacional, p.ej. 34600123456. Se toma del móvil de la ficha.';

                    trigger OnValidate()
                    begin
                        PhoneNo := PhoneMgt.NormalizePhone(PhoneNo);
                        UpdateConversationInfo();
                    end;
                }
                field(WindowText; WindowText)
                {
                    ApplicationArea = All;
                    Caption = 'Ventana de 24 h';
                    Editable = false;
                    StyleExpr = WindowStyle;
                    ToolTip = 'Con la ventana cerrada WhatsApp solo permite enviar plantillas aprobadas.';
                }
            }
            group(TemplateGroup)
            {
                Caption = 'Mensaje';

                field(UseTemplate; UseTemplate)
                {
                    ApplicationArea = All;
                    Caption = 'Usar plantilla';
                    Editable = WindowOpen;
                    ToolTip = 'Obligatorio si la ventana de 24 h está cerrada.';
                }
                field(TemplateName; TemplateName)
                {
                    ApplicationArea = All;
                    Caption = 'Plantilla';
                    Editable = UseTemplate;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        WATemplate: Record "IKA WA Template";
                    begin
                        WATemplate.SetRange("Account Code", AccountCode);
                        WATemplate.SetRange(Status, WATemplate.Status::Approved);
                        if Page.RunModal(Page::"IKA WA Templates", WATemplate) <> Action::LookupOK then
                            exit(false);
                        TemplateName := WATemplate.Name;
                        LanguageCode := WATemplate."Language Code";
                        Text := WATemplate.Name;
                        UpdateTemplateInfo();
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        UpdateTemplateInfo();
                    end;
                }
                field(LanguageCode; LanguageCode)
                {
                    ApplicationArea = All;
                    Caption = 'Idioma';
                    Editable = false;
                }
                field(Param1; Params[1])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,{{1}}';
                    Visible = ParamCount >= 1;
                    Editable = UseTemplate;

                    trigger OnValidate()
                    begin
                        UpdatePreview();
                    end;
                }
                field(Param2; Params[2])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,{{2}}';
                    Visible = ParamCount >= 2;
                    Editable = UseTemplate;

                    trigger OnValidate()
                    begin
                        UpdatePreview();
                    end;
                }
                field(Param3; Params[3])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,{{3}}';
                    Visible = ParamCount >= 3;
                    Editable = UseTemplate;

                    trigger OnValidate()
                    begin
                        UpdatePreview();
                    end;
                }
                field(Param4; Params[4])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,{{4}}';
                    Visible = ParamCount >= 4;
                    Editable = UseTemplate;

                    trigger OnValidate()
                    begin
                        UpdatePreview();
                    end;
                }
                field(Param5; Params[5])
                {
                    ApplicationArea = All;
                    CaptionClass = '3,{{5}}';
                    Visible = ParamCount >= 5;
                    Editable = UseTemplate;

                    trigger OnValidate()
                    begin
                        UpdatePreview();
                    end;
                }
                field(Preview; Preview)
                {
                    ApplicationArea = All;
                    Caption = 'Vista previa';
                    MultiLine = true;
                    Editable = false;
                    Visible = UseTemplate;
                }
                field(FreeText; FreeText)
                {
                    ApplicationArea = All;
                    Caption = 'Texto';
                    MultiLine = true;
                    Editable = not UseTemplate;
                    ToolTip = 'Mensaje libre (solo con la ventana de 24 h abierta). Si se envía el documento, este texto va como pie.';
                }
            }
            group(DocumentGroup)
            {
                Caption = 'Documento';
                Visible = HasDocument;

                field(AttachDocument; AttachDocument)
                {
                    ApplicationArea = All;
                    Caption = 'Enviar el documento (PDF)';
                    ToolTip = 'Con plantilla, el PDF va en la cabecera si la plantilla es de tipo Documento.';
                }
                field(FileName; FileName)
                {
                    ApplicationArea = All;
                    Caption = 'Nombre del fichero';
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
                Image = SendTo;
                ToolTip = 'Envía el mensaje por WhatsApp.';

                trigger OnAction()
                begin
                    SendMessage();
                    Message(SentMsg);
                    CurrPage.Close();
                end;
            }
            action(PreviewPdf)
            {
                ApplicationArea = All;
                Caption = 'Ver PDF';
                Image = Document;
                Enabled = HasDocument;
                ToolTip = 'Descarga el PDF que se va a enviar.';

                trigger OnAction()
                var
                    InStr: InStream;
                    DownloadName: Text;
                begin
                    DocumentBlob.CreateInStream(InStr);
                    DownloadName := FileName;
                    DownloadFromStream(InStr, '', '', '', DownloadName);
                end;
            }
            action(OpenWaMe)
            {
                ApplicationArea = All;
                Caption = 'Abrir en mi WhatsApp';
                Image = Web;
                ToolTip = 'Alternativa sin API: abre WhatsApp (web o escritorio) con el texto escrito, para enviarlo desde su propio WhatsApp.';

                trigger OnAction()
                begin
                    if UseTemplate then
                        PhoneMgt.OpenWaMe(PhoneNo, Preview)
                    else
                        PhoneMgt.OpenWaMe(PhoneNo, FreeText);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(Send_Promoted; Send) { }
                actionref(PreviewPdf_Promoted; PreviewPdf) { }
                actionref(OpenWaMe_Promoted; OpenWaMe) { }
            }
        }
    }

    var
        WATemplate: Record "IKA WA Template";
        DocumentSender: Codeunit "IKA WA Document Sender";
        PhoneMgt: Codeunit "IKA WA Phone Mgt.";
        DocumentBlob: Codeunit "Temp Blob";
        SourceRecordId: RecordId;
        EntityType: Enum "IKA WA Entity Type";
        EntityNo: Code[20];
        DocumentNo: Code[20];
        AccountCode: Code[20];
        TemplateName: Text[100];
        LanguageCode: Text[10];
        PhoneNo: Text[30];
        RecipientName: Text[100];
        WindowText: Text;
        WindowStyle: Text;
        Preview: Text;
        FreeText: Text;
        FileName: Text[250];
        Params: array[5] of Text[250];
        ParamCount: Integer;
        UseTemplate: Boolean;
        WindowOpen: Boolean;
        HasDocument: Boolean;
        AttachDocument: Boolean;
        SentMsg: Label 'Mensaje enviado. El estado (entregado, leído) se actualizará al recibir la confirmación de WhatsApp.';
        NoTemplateErr: Label 'Elija una plantilla aprobada.';
        NeedsDocumentErr: Label 'La plantilla %1 lleva un documento en la cabecera: marque "Enviar el documento".', Comment = '%1 = template';
        NoAccountErr: Label 'No hay ninguna cuenta de WhatsApp configurada a la que tenga acceso.';

    procedure SetContext(NewEntityType: Enum "IKA WA Entity Type"; NewEntityNo: Code[20]; NewPhoneNo: Text; var TempBlob: Codeunit "Temp Blob"; NewFileName: Text; NewSourceRecordId: RecordId; NewDocumentNo: Code[20])
    var
        Account: Record "IKA WA Account";
        InStr: InStream;
        OutStr: OutStream;
    begin
        EntityType := NewEntityType;
        EntityNo := NewEntityNo;
        RecipientName := PhoneMgt.GetEntityName(EntityType, EntityNo);
        PhoneNo := CopyStr(NewPhoneNo, 1, MaxStrLen(PhoneNo));
        SourceRecordId := NewSourceRecordId;
        DocumentNo := NewDocumentNo;
        FileName := CopyStr(NewFileName, 1, MaxStrLen(FileName));

        HasDocument := TempBlob.HasValue();
        if HasDocument then begin
            TempBlob.CreateInStream(InStr);
            DocumentBlob.CreateOutStream(OutStr);
            CopyStream(OutStr, InStr);
            AttachDocument := true;
        end;

        if not Account.GetDefault() then
            Error(NoAccountErr);
        AccountCode := Account.Code;
        UpdateConversationInfo();
    end;

    local procedure UpdateConversationInfo()
    var
        Conversation: Record "IKA WA Conversation";
    begin
        WindowOpen := false;
        Conversation.SetCurrentKey("Account Code", "Phone No.");
        Conversation.SetRange("Account Code", AccountCode);
        Conversation.SetRange("Phone No.", PhoneNo);
        if Conversation.FindFirst() then begin
            WindowOpen := Conversation.IsWindowOpen();
            WindowText := Conversation.GetWindowText();
        end else
            WindowText := Conversation.GetWindowText();
        if WindowOpen then
            WindowStyle := 'Favorable'
        else begin
            WindowStyle := 'Attention';
            UseTemplate := true;
        end;
    end;

    local procedure UpdateTemplateInfo()
    var
        Values: List of [Text];
        i: Integer;
    begin
        Clear(Params);
        ParamCount := 0;
        Preview := '';
        if (TemplateName = '') or (AccountCode = '') then
            exit;
        WATemplate.SetRange("Account Code", AccountCode);
        WATemplate.SetRange(Name, TemplateName);
        if LanguageCode <> '' then
            WATemplate.SetRange("Language Code", LanguageCode);
        if not WATemplate.FindFirst() then
            exit;
        LanguageCode := WATemplate."Language Code";
        ParamCount := WATemplate."No. of Body Parameters";
        Values := DocumentSender.GetParameterValues(WATemplate, SourceRecordId, RecipientName);
        for i := 1 to Values.Count() do
            if i <= ArrayLen(Params) then
                Params[i] := CopyStr(Values.Get(i), 1, MaxStrLen(Params[i]));
        UpdatePreview();
    end;

    local procedure UpdatePreview()
    var
        i: Integer;
    begin
        Preview := WATemplate."Body Text";
        for i := 1 to ArrayLen(Params) do
            Preview := Preview.Replace('{{' + Format(i) + '}}', Params[i]);
    end;

    local procedure SendMessage()
    var
        Conversation: Record "IKA WA Conversation";
        CloudApi: Codeunit "IKA WA Cloud API";
        EmptyBlob: Codeunit "Temp Blob";
        Values: List of [Text];
        i: Integer;
    begin
        PhoneNo := CopyStr(PhoneMgt.NormalizePhone(PhoneNo), 1, MaxStrLen(PhoneNo));
        if Conversation.FindOrCreate(AccountCode, PhoneNo) or (Conversation."Entity No." = '') then
            if EntityNo <> '' then begin
                Conversation."Entity Type" := EntityType;
                Conversation."Entity No." := EntityNo;
                Conversation."Entity Name" := RecipientName;
                Conversation.Modify();
            end;

        if UseTemplate then begin
            if TemplateName = '' then
                Error(NoTemplateErr);
            for i := 1 to ParamCount do
                Values.Add(Params[i]);
            if WATemplate."Header Type" in [WATemplate."Header Type"::Document, WATemplate."Header Type"::Image, WATemplate."Header Type"::Video] then begin
                if not (HasDocument and AttachDocument) then
                    Error(NeedsDocumentErr, TemplateName);
                CloudApi.SendTemplate(Conversation, WATemplate, Values, DocumentBlob, FileName, SourceRecordId.TableNo, DocumentNo);
            end else
                CloudApi.SendTemplate(Conversation, WATemplate, Values, EmptyBlob, '', SourceRecordId.TableNo, DocumentNo);
            exit;
        end;

        if HasDocument and AttachDocument then
            CloudApi.SendFile(Conversation, DocumentBlob, FileName, FreeText, SourceRecordId.TableNo, DocumentNo)
        else
            CloudApi.SendText(Conversation, FreeText);
    end;
}
