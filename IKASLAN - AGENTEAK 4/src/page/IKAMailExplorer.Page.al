page 99251 "IKA Mail Explorer"
{
    // Vista tipo Outlook: árbol de carpetas, emails de la carpeta y panel de lectura (ocultable),
    // en el control add-in "IKA Mail Explorer". Recuerda por usuario la cuenta, la carpeta y si el
    // panel de lectura está visible. La ficha del email (doble clic) sigue siendo la del arrastre a BC.
    Caption = 'Correo Outlook 365 (vista Outlook)';
    PageType = Card;
    // La tabla de preferencias del usuario solo sirve para que BC no muestre en la cabecera los iconos de
    // editar, nuevo y eliminar registro, que aquí no tienen sentido (la papelera de BC no borra emails).
    SourceTable = "IKA Mail User Setting";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    LinksAllowed = false;

    layout
    {
        area(Content)
        {
            usercontrol(Explorer; "IKA Mail Explorer")
            {
                ApplicationArea = All;

                trigger ControlReady()
                var
                    UserSetting: Record "IKA Mail User Setting";
                    WantedFolderId: Text;
                    MailboxCode: Code[20];
                begin
                    AddinReady := true;
                    CurrPage.Explorer.SetReadingPane(ReadingPaneVisible);
                    UserSetting.GetForCurrentUser();
                    MailboxCode := ExplorerMgt.GetInitialMailbox(UserSetting);
                    if MailboxCode = UserSetting."Last Mailbox Code" then
                        WantedFolderId := UserSetting."Last Folder Id";
                    OpenMailbox(MailboxCode, WantedFolderId);
                end;

                trigger MailboxSelected(MailboxCode: Text)
                begin
                    OpenMailbox(CopyStr(MailboxCode, 1, 20), '');
                end;

                trigger FolderSelected(FolderId: Text)
                begin
                    CurrentFolderId := FolderId;
                    SelectedEntryNo := 0;
                    ShowFolder(true);
                end;

                trigger MessageSelected(EntryNo: Integer)
                begin
                    SelectedEntryNo := EntryNo;
                    if ReadingPaneVisible then
                        ShowSelectedMessage();
                end;

                trigger MessageOpened(EntryNo: Integer)
                begin
                    ExplorerMgt.OpenCard(EntryNo);
                end;

                trigger NewMessageRequested()
                begin
                    NewMail();
                end;

                trigger SyncRequested()
                begin
                    SyncCurrentFolder(false);
                end;

                trigger LoadOlderRequested()
                begin
                    SyncCurrentFolder(true);
                end;

                trigger RefreshFoldersRequested()
                begin
                    RefreshFolders();
                end;

                trigger ComposeRequested(EntryNo: Integer; Mode: Text)
                begin
                    ExplorerMgt.Compose(EntryNo, Mode);
                end;

                trigger MoveRequested(EntryNo: Integer)
                begin
                    if not ExplorerMgt.MoveMessage(EntryNo) then
                        exit;
                    if EntryNo = SelectedEntryNo then begin
                        SelectedEntryNo := 0;
                        CurrPage.Explorer.SetMessage('');
                    end;
                    RenderFolders();
                    RenderMessages();
                    CurrPage.Explorer.ShowStatus(MovedMsg, false);
                end;

                trigger DeleteRequested(EntryNo: Integer; NextEntryNo: Integer)
                begin
                    DeleteMessage(EntryNo, NextEntryNo);
                end;

                trigger ToggleReadRequested(EntryNo: Integer)
                var
                    MailMessage: Record "IKA Mail Message";
                begin
                    ExplorerMgt.ToggleRead(EntryNo, MailMessage);
                    CurrPage.Explorer.UpdateMessage(ExplorerMgt.BuildMessageItemJson(MailMessage));
                end;

                trigger OpenInOutlookRequested(EntryNo: Integer)
                begin
                    ExplorerMgt.OpenInOutlook(EntryNo);
                end;

                trigger DownloadAttachmentRequested(EntryNo: Integer; LineNo: Integer)
                begin
                    ExplorerMgt.DownloadAttachment(EntryNo, LineNo);
                end;

                trigger DownloadEmlRequested(EntryNo: Integer)
                begin
                    ExplorerMgt.DownloadEml(EntryNo);
                end;

                trigger ReadingPaneToggled(Visible: Boolean)
                begin
                    SetReadingPane(Visible, false);
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NewMailAction)
            {
                ApplicationArea = All;
                Caption = 'Nuevo email';
                Image = NewDocument;
                ToolTip = 'Redacta un email nuevo desde la cuenta que se está viendo. Quedará en Elementos enviados.';

                trigger OnAction()
                begin
                    NewMail();
                end;
            }
            action(Sync)
            {
                ApplicationArea = All;
                Caption = 'Sincronizar';
                Image = Refresh;
                ShortcutKey = 'F5';
                ToolTip = 'Descarga los últimos emails de la carpeta que se está viendo.';

                trigger OnAction()
                begin
                    SyncCurrentFolder(false);
                end;
            }
            action(LoadOlder)
            {
                ApplicationArea = All;
                Caption = 'Cargar anteriores';
                Image = PreviousRecord;
                ToolTip = 'Descarga emails más antiguos de la carpeta que se está viendo.';

                trigger OnAction()
                begin
                    SyncCurrentFolder(true);
                end;
            }
            action(RefreshFoldersAction)
            {
                ApplicationArea = All;
                Caption = 'Actualizar carpetas';
                Image = RefreshLines;
                ToolTip = 'Vuelve a leer de Outlook el árbol de carpetas y sus contadores.';

                trigger OnAction()
                begin
                    RefreshFolders();
                end;
            }
            action(DeleteMessageAction)
            {
                ApplicationArea = All;
                Caption = 'Eliminar';
                Image = Delete;
                ToolTip = 'Mueve el email seleccionado a Elementos eliminados. Si ya está en Elementos eliminados, lo borra definitivamente (pide confirmación). En la lista de emails también funciona la tecla Supr.';

                trigger OnAction()
                begin
                    if SelectedEntryNo = 0 then
                        Error(NoMessageSelectedErr);
                    DeleteMessage(SelectedEntryNo, ExplorerMgt.GetNextEntryNo(CurrentMailboxCode, CurrentFolderId, DefaultFolderId, SelectedEntryNo));
                end;
            }
            action(ToggleReadingPane)
            {
                ApplicationArea = All;
                Caption = 'Panel de lectura';
                Image = ViewDetails;
                ShortcutKey = 'Ctrl+Shift+R';
                ToolTip = 'Muestra u oculta el panel de la derecha con el email seleccionado. Con el panel oculto, el email se abre con doble clic o Intro.';

                trigger OnAction()
                begin
                    SetReadingPane(not ReadingPaneVisible, true);
                end;
            }
        }
        area(Navigation)
        {
            action(ClassicInbox)
            {
                ApplicationArea = All;
                Caption = 'Bandeja en lista';
                Image = List;
                RunObject = page "IKA Mail Messages";
                ToolTip = 'Abre la bandeja de correo clásica (lista de BC, con filtros y selección múltiple).';
            }
            action(Accounts)
            {
                ApplicationArea = All;
                Caption = 'Cuentas de Outlook 365';
                Image = Email;
                RunObject = page "IKA Mail Mailboxes";
                ToolTip = 'Configurar las cuentas.';
            }
            action(Setup)
            {
                ApplicationArea = All;
                Caption = 'Configuración';
                Image = Setup;
                RunObject = page "IKA Mail Setup";
                ToolTip = 'Configuración de Microsoft Graph y del visor.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(NewMail_Promoted; NewMailAction) { }
                actionref(Sync_Promoted; Sync) { }
                actionref(LoadOlder_Promoted; LoadOlder) { }
                actionref(RefreshFolders_Promoted; RefreshFoldersAction) { }
                actionref(DeleteMessage_Promoted; DeleteMessageAction) { }
                actionref(ToggleReadingPane_Promoted; ToggleReadingPane) { }
            }
            group(Category_Navigate)
            {
                Caption = 'Navegar';

                actionref(ClassicInbox_Promoted; ClassicInbox) { }
                actionref(Accounts_Promoted; Accounts) { }
                actionref(Setup_Promoted; Setup) { }
            }
        }
    }

    var
        ExplorerMgt: Codeunit "IKA Mail Explorer Mgt.";
        AddinReady: Boolean;
        ReadingPaneVisible: Boolean;
        CurrentMailboxCode: Code[20];
        CurrentFolderId: Text;
        DefaultFolderId: Text;
        SelectedEntryNo: Integer;
        NoAccountsMsg: Label 'Todavía no hay ninguna cuenta de Outlook 365 configurada a la que tenga acceso. Añada su cuenta en la página que se abre a continuación.';
        SyncedMsg: Label '%1 email(s) descargado(s).', Comment = '%1 = count';
        MovedMsg: Label 'Email movido.';
        MovedToDeletedMsg: Label 'Email movido a Elementos eliminados.';
        DeletedForeverMsg: Label 'Email eliminado definitivamente.';
        NoMessageSelectedErr: Label 'Seleccione primero un email de la lista.';

    trigger OnOpenPage()
    var
        Mailbox: Record "IKA Mail Mailbox";
        UserSetting: Record "IKA Mail User Setting";
    begin
        if Mailbox.GetAllowedFilter() = '' then begin
            Message(NoAccountsMsg);
            Page.Run(Page::"IKA Mail Mailboxes");
            Error('');
        end;
        UserSetting.GetForCurrentUser();
        ReadingPaneVisible := not UserSetting."Hide Reading Pane";
        Rec.FilterGroup(2);
        Rec.SetRange("User ID", UserSetting."User ID");
        Rec.FilterGroup(0);
    end;

    /// <summary>
    /// Elimina el email (a Elementos eliminados o definitivamente) y selecciona NextEntryNo, para poder
    /// eliminar varios seguidos.
    /// </summary>
    local procedure DeleteMessage(EntryNo: Integer; NextEntryNo: Integer)
    var
        Permanent: Boolean;
    begin
        if not ExplorerMgt.DeleteMessage(EntryNo, Permanent) then begin
            CurrPage.Explorer.SetBusy(false);
            exit;
        end;
        SelectedEntryNo := NextEntryNo;
        RenderFolders();
        RenderMessages();
        if ReadingPaneVisible and (SelectedEntryNo <> 0) then
            ShowSelectedMessage()
        else
            CurrPage.Explorer.SetMessage('');
        if Permanent then
            CurrPage.Explorer.ShowStatus(DeletedForeverMsg, false)
        else
            CurrPage.Explorer.ShowStatus(MovedToDeletedMsg, false);
    end;

    local procedure NewMail()
    begin
        if CurrentMailboxCode = '' then
            exit;
        ExplorerMgt.ComposeNew(CurrentMailboxCode);
        // Si se envía desde la carpeta de enviados, que aparezca al momento
        if ExplorerMgt.IsSentItemsFolder(CurrentMailboxCode, CurrentFolderId) then
            SyncCurrentFolder(false);
    end;

    local procedure OpenMailbox(MailboxCode: Code[20]; WantedFolderId: Text)
    begin
        if MailboxCode = '' then
            exit;
        CurrentMailboxCode := MailboxCode;
        SelectedEntryNo := 0;
        CurrPage.Explorer.SetMailboxes(ExplorerMgt.BuildMailboxesJson(CurrentMailboxCode));
        CurrentFolderId := ExplorerMgt.PrepareMailbox(CurrentMailboxCode, WantedFolderId, DefaultFolderId);
        ShowFolder(true);
    end;

    /// <summary>
    /// Pinta la carpeta actual. La primera vez que se abre una carpeta se descargan sus emails.
    /// </summary>
    local procedure ShowFolder(SyncIfEmpty: Boolean)
    begin
        if SyncIfEmpty and not ExplorerMgt.HasLocalMessages(CurrentMailboxCode, CurrentFolderId, DefaultFolderId) then
            ExplorerMgt.SyncFolder(CurrentMailboxCode, CurrentFolderId, false);
        RenderFolders();
        CurrPage.Explorer.SetMessage('');
        RenderMessages();
        ExplorerMgt.SaveLocation(CurrentMailboxCode, CurrentFolderId);
    end;

    local procedure RenderFolders()
    begin
        CurrPage.Explorer.SetFolders(ExplorerMgt.BuildFoldersJson(CurrentMailboxCode, CurrentFolderId));
    end;

    local procedure RenderMessages()
    begin
        CurrPage.Explorer.SetMessages(ExplorerMgt.BuildMessagesJson(CurrentMailboxCode, CurrentFolderId, DefaultFolderId, SelectedEntryNo));
    end;

    local procedure SyncCurrentFolder(LoadOlderMessages: Boolean)
    var
        SyncedCount: Integer;
    begin
        if not AddinReady or (CurrentMailboxCode = '') then
            exit;
        SyncedCount := ExplorerMgt.SyncFolder(CurrentMailboxCode, CurrentFolderId, LoadOlderMessages);
        RenderFolders();
        RenderMessages();
        CurrPage.Explorer.ShowStatus(StrSubstNo(SyncedMsg, SyncedCount), false);
    end;

    local procedure RefreshFolders()
    var
        MailFolder: Record "IKA Mail Folder";
    begin
        if not AddinReady or (CurrentMailboxCode = '') then
            exit;
        ExplorerMgt.RefreshFolders(CurrentMailboxCode);
        // La carpeta que se veía puede haberse borrado o renombrado en Outlook
        if not MailFolder.Get(CurrentMailboxCode, CopyStr(CurrentFolderId, 1, MaxStrLen(MailFolder."Folder Id"))) then begin
            CurrentFolderId := DefaultFolderId;
            SelectedEntryNo := 0;
            ShowFolder(false);
        end else
            RenderFolders();
        CurrPage.Explorer.SetBusy(false);
    end;

    local procedure ShowSelectedMessage()
    var
        MailMessage: Record "IKA Mail Message";
    begin
        if SelectedEntryNo = 0 then
            exit;
        ExplorerMgt.OpenMessage(SelectedEntryNo, MailMessage);
        CurrPage.Explorer.SetMessage(ExplorerMgt.BuildMessageDetailJson(MailMessage));
        CurrPage.Explorer.SetBody(ExplorerMgt.GetViewerHtml(MailMessage));
        CurrPage.Explorer.UpdateMessage(ExplorerMgt.BuildMessageItemJson(MailMessage));
    end;

    /// <summary>
    /// Muestra u oculta el panel de lectura y lo recuerda para el usuario.
    /// </summary>
    local procedure SetReadingPane(Visible: Boolean; UpdateAddin: Boolean)
    begin
        ReadingPaneVisible := Visible;
        ExplorerMgt.SaveReadingPane(Visible);
        if not AddinReady then
            exit;
        if UpdateAddin then
            CurrPage.Explorer.SetReadingPane(Visible);
        if Visible then
            ShowSelectedMessage();
    end;
}
