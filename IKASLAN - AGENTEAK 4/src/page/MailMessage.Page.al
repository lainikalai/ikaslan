page 50430 "IKA Mail Message"
{
    // Ficha del email: cabecera, destino seleccionado y el área de trabajo (control add-in) con
    // el cuerpo, los elementos arrastrables (email .eml y adjuntos) y las zonas de destino.
    Caption = 'Email';
    PageType = Card;
    SourceTable = "IKA Mail Message";
    UsageCategory = None;
    InsertAllowed = false;
    DeleteAllowed = false;
    DataCaptionFields = Subject;

    layout
    {
        area(Content)
        {
            group(Header)
            {
                Caption = 'Email';
                Editable = false;

                field("From Name"; Rec."From Name")
                {
                    ApplicationArea = All;
                }
                field("From Address"; Rec."From Address")
                {
                    ApplicationArea = All;
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                }
                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = All;
                }
                field("To Recipients"; Rec."To Recipients")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                }
                field("Cc Recipients"; Rec."Cc Recipients")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                }
                field("No. of Attachments"; Rec."No. of Attachments")
                {
                    ApplicationArea = All;
                }
                field("No. of Links"; Rec."No. of Links")
                {
                    ApplicationArea = All;
                    ToolTip = 'Ficheros de este email adjuntados a entidades de BC.';
                }
            }
            group(Target)
            {
                Caption = 'Destino';

                field(TargetType; TargetType)
                {
                    ApplicationArea = All;
                    Caption = 'Tipo de entidad';
                    ToolTip = 'Tipo de entidad a la que quiere adjuntar el email o sus ficheros.';

                    trigger OnValidate()
                    begin
                        TargetNo := '';
                        TargetName := '';
                        RefreshTargets();
                    end;
                }
                field(TargetNo; TargetNo)
                {
                    ApplicationArea = All;
                    Caption = 'Nº entidad';
                    ToolTip = 'Aparecerá como zona de destino en el área de trabajo.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        EntityNo: Code[20];
                    begin
                        EntityNo := TargetNo;
                        if not EntityMgt.Lookup(TargetType, EntityNo) then
                            exit(false);
                        Text := EntityNo;
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        TargetName := EntityMgt.GetName(TargetType, TargetNo);
                        RefreshTargets();
                    end;
                }
                field(TargetName; TargetName)
                {
                    ApplicationArea = All;
                    Caption = 'Nombre';
                    Editable = false;
                }
            }
            usercontrol(Workspace; "IKA Mail Workspace")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    AddinReady := true;
                    RefreshAddin(true);
                end;

                trigger ItemDropped(ItemId: Text; TargetId: Text)
                var
                    EntityType: Enum "IKA Mail Entity Type";
                    EntityNo: Code[20];
                    ResultText: Text;
                begin
                    TempDropTarget.ParseTargetId(TargetId, EntityType, EntityNo);
                    ResultText := AttachMgt.AttachItem(Rec, ItemId, EntityType, EntityNo);
                    AfterAttach(ResultText);
                end;

                trigger FileDropped(TargetId: Text; FileName: Text; Base64Content: Text)
                var
                    EntityType: Enum "IKA Mail Entity Type";
                    EntityNo: Code[20];
                    ResultText: Text;
                begin
                    TempDropTarget.ParseTargetId(TargetId, EntityType, EntityNo);
                    ResultText := AttachMgt.AttachExternalFile(Rec, FileName, Base64Content, EntityType, EntityNo);
                    AfterAttach(ResultText);
                end;

                trigger DownloadRequested(ItemId: Text)
                begin
                    DownloadItem(ItemId);
                end;

                trigger PinToggled(TargetId: Text)
                var
                    PinnedTarget: Record "IKA Mail Pinned Target";
                    EntityType: Enum "IKA Mail Entity Type";
                    EntityNo: Code[20];
                begin
                    TempDropTarget.ParseTargetId(TargetId, EntityType, EntityNo);
                    if PinnedTarget.Get(UserId(), EntityType, EntityNo) then
                        AttachMgt.UnpinTarget(EntityType, EntityNo)
                    else
                        AttachMgt.PinTarget(EntityType, EntityNo);
                    RefreshTargets();
                end;

                trigger OpenTargetRequested(TargetId: Text)
                var
                    EntityType: Enum "IKA Mail Entity Type";
                    EntityNo: Code[20];
                begin
                    TempDropTarget.ParseTargetId(TargetId, EntityType, EntityNo);
                    EntityMgt.OpenCard(EntityType, EntityNo);
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Reply)
            {
                ApplicationArea = All;
                Caption = 'Responder';
                Image = Reply;
                ToolTip = 'Responde al remitente desde la cuenta de Outlook.';

                trigger OnAction()
                begin
                    Compose("IKA Mail Compose Mode"::Reply);
                end;
            }
            action(ReplyAll)
            {
                ApplicationArea = All;
                Caption = 'Responder a todos';
                Image = ReplyAll;
                ToolTip = 'Responde al remitente y al resto de destinatarios.';

                trigger OnAction()
                begin
                    Compose("IKA Mail Compose Mode"::ReplyAll);
                end;
            }
            action(Forward)
            {
                ApplicationArea = All;
                Caption = 'Reenviar';
                Image = Forward;
                ToolTip = 'Reenvía el email (con sus adjuntos).';

                trigger OnAction()
                begin
                    Compose("IKA Mail Compose Mode"::Forward);
                end;
            }
            action(AttachEmail)
            {
                ApplicationArea = All;
                Caption = 'Adjuntar email al destino';
                Image = Attach;
                ToolTip = 'Adjunta el email completo (.eml) a la entidad indicada en Destino (alternativa al arrastre).';

                trigger OnAction()
                begin
                    CheckTarget();
                    AfterAttach(AttachMgt.AttachItem(Rec, AttachMgt.GetEmailItemId(), TargetType, TargetNo));
                end;
            }
            action(AttachAllFiles)
            {
                ApplicationArea = All;
                Caption = 'Adjuntar todos los ficheros al destino';
                Image = Attachments;
                ToolTip = 'Adjunta todos los adjuntos del email a la entidad indicada en Destino.';

                trigger OnAction()
                var
                    AttachedMsg: Label '%1 fichero(s) adjuntado(s) a %2 %3.', Comment = '%1 = count, %2 = type, %3 = no.';
                    AttachedCount: Integer;
                begin
                    CheckTarget();
                    AttachedCount := AttachMgt.AttachAllFiles(Rec, TargetType, TargetNo);
                    AfterAttach(StrSubstNo(AttachedMsg, AttachedCount, TargetType, TargetNo));
                end;
            }
            action(PinTarget)
            {
                ApplicationArea = All;
                Caption = 'Fijar destino';
                Image = Bookmark;
                ToolTip = 'Mantiene la entidad de Destino como zona fija en todos los emails.';

                trigger OnAction()
                begin
                    CheckTarget();
                    AttachMgt.PinTarget(TargetType, TargetNo);
                    RefreshTargets();
                end;
            }
            action(DownloadEml)
            {
                ApplicationArea = All;
                Caption = 'Descargar email (.eml)';
                Image = Download;
                ToolTip = 'Descarga el email completo para abrirlo con Outlook.';

                trigger OnAction()
                begin
                    DownloadItem(AttachMgt.GetEmailItemId());
                end;
            }
            action(OpenInOutlook)
            {
                ApplicationArea = All;
                Caption = 'Abrir en Outlook';
                Image = Web;
                Enabled = Rec."Web Link" <> '';
                ToolTip = 'Abre el email en Outlook en la web.';

                trigger OnAction()
                begin
                    Hyperlink(Rec."Web Link");
                end;
            }
            action(MarkUnread)
            {
                ApplicationArea = All;
                Caption = 'Marcar como no leído';
                Image = Undo;
                ToolTip = 'Marca el email como no leído en Outlook.';

                trigger OnAction()
                begin
                    GraphClient.SetReadFlag(Rec, false);
                end;
            }
            action(Reload)
            {
                ApplicationArea = All;
                Caption = 'Recargar';
                Image = Refresh;
                ToolTip = 'Vuelve a descargar el cuerpo y los adjuntos desde Outlook.';

                trigger OnAction()
                begin
                    GraphClient.LoadMessageDetails(Rec, true);
                    Rec.Get(Rec."Entry No.");
                    RefreshAddin(true);
                end;
            }
        }
        area(Navigation)
        {
            action(Links)
            {
                ApplicationArea = All;
                Caption = 'Vínculos con entidades';
                Image = Links;
                RunObject = page "IKA Mail Links";
                RunPageLink = "Message Entry No." = field("Entry No.");
                ToolTip = 'A qué entidades se ha adjuntado este email o sus ficheros.';
            }
            action(OpenTarget)
            {
                ApplicationArea = All;
                Caption = 'Abrir ficha del destino';
                Image = Card;
                ToolTip = 'Abre la ficha de la entidad indicada en Destino.';

                trigger OnAction()
                begin
                    CheckTarget();
                    EntityMgt.OpenCard(TargetType, TargetNo);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Email)
            {
                Caption = 'Email';

                actionref(Reply_Promoted; Reply) { }
                actionref(ReplyAll_Promoted; ReplyAll) { }
                actionref(Forward_Promoted; Forward) { }
                actionref(OpenInOutlook_Promoted; OpenInOutlook) { }
                actionref(DownloadEml_Promoted; DownloadEml) { }
            }
            group(Category_Attach)
            {
                Caption = 'Adjuntar a entidad';

                actionref(AttachEmail_Promoted; AttachEmail) { }
                actionref(AttachAllFiles_Promoted; AttachAllFiles) { }
                actionref(PinTarget_Promoted; PinTarget) { }
                actionref(OpenTarget_Promoted; OpenTarget) { }
                actionref(Links_Promoted; Links) { }
            }
        }
    }

    var
        TempDropTarget: Record "IKA Mail Drop Target" temporary;
        GraphClient: Codeunit "IKA Mail Graph Client";
        AttachMgt: Codeunit "IKA Mail Attach Mgt.";
        EntityMgt: Codeunit "IKA Mail Entity Mgt.";
        TargetType: Enum "IKA Mail Entity Type";
        TargetNo: Code[20];
        TargetName: Text[100];
        AddinReady: Boolean;
        LoadedEntryNo: Integer;
        NoTargetErr: Label 'Indique el tipo y nº de entidad en "Destino".';

    trigger OnAfterGetCurrRecord()
    begin
        if Rec."Entry No." = LoadedEntryNo then
            exit;
        LoadCurrentMessage();
    end;

    local procedure LoadCurrentMessage()
    var
        Setup: Record "IKA Mail Setup";
        Mailbox: Record "IKA Mail Mailbox";
    begin
        LoadedEntryNo := Rec."Entry No.";
        Mailbox.Get(Rec."Mailbox Code");
        Mailbox.CheckAccess();
        Setup.GetSetup();

        GraphClient.LoadMessageDetails(Rec, false);
        if Setup."Mark as Read on Open" and not Rec."Is Read" then
            GraphClient.SetReadFlag(Rec, true);
        Rec.Get(Rec."Entry No.");

        // Destino inicial: la primera sugerencia por el remitente
        if TargetNo = '' then begin
            AttachMgt.BuildTargets(Rec, TargetType, '', TempDropTarget);
            TempDropTarget.SetRange(Kind, TempDropTarget.Kind::Suggested);
            TempDropTarget.SetCurrentKey("Sort Order");
            if TempDropTarget.FindFirst() then begin
                TargetType := TempDropTarget."Entity Type";
                TargetNo := TempDropTarget."Entity No.";
                TargetName := TempDropTarget.Name;
            end;
            TempDropTarget.Reset();
        end;

        if AddinReady then
            RefreshAddin(true);
    end;

    local procedure RefreshAddin(IncludeBody: Boolean)
    begin
        if not AddinReady then
            exit;
        if IncludeBody then
            CurrPage.Workspace.SetBody(AttachMgt.BuildViewerHtml(Rec));
        CurrPage.Workspace.SetItems(AttachMgt.BuildItemsJson(Rec));
        RefreshTargets();
    end;

    local procedure RefreshTargets()
    begin
        if not AddinReady then
            exit;
        AttachMgt.BuildTargets(Rec, TargetType, TargetNo, TempDropTarget);
        CurrPage.Workspace.SetTargets(AttachMgt.TargetsToJson(TempDropTarget));
    end;

    local procedure AfterAttach(ResultText: Text)
    begin
        Rec.CalcFields("No. of Links");
        CurrPage.Workspace.SetItems(AttachMgt.BuildItemsJson(Rec));
        CurrPage.Workspace.ShowStatus(ResultText, false);
        CurrPage.Update(false);
    end;

    local procedure CheckTarget()
    begin
        if TargetNo = '' then
            Error(NoTargetErr);
    end;

    local procedure Compose(Mode: Enum "IKA Mail Compose Mode")
    var
        MailCompose: Page "IKA Mail Compose";
    begin
        MailCompose.SetMessage(Rec, Mode);
        MailCompose.RunModal();
    end;

    local procedure DownloadItem(ItemId: Text)
    var
        MailAttachment: Record "IKA Mail Attachment";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        FileName: Text;
        AttachmentLineNo: Integer;
    begin
        if ItemId = AttachMgt.GetEmailItemId() then begin
            GraphClient.GetMimeContent(Rec, TempBlob);
            TempBlob.CreateInStream(InStr);
            FileName := AttachMgt.GetEmailFileName(Rec);
        end else begin
            Evaluate(AttachmentLineNo, CopyStr(ItemId, 5));
            MailAttachment.Get(Rec."Entry No.", AttachmentLineNo);
            GraphClient.LoadAttachmentContent(MailAttachment);
            MailAttachment.CalcFields(Content);
            MailAttachment.Content.CreateInStream(InStr);
            FileName := MailAttachment.GetFileName();
        end;
        DownloadFromStream(InStr, '', '', '', FileName);
    end;
}
