page 99211 "IKA Mail Messages"
{
    // Bandeja: emails de una cuenta y una carpeta (Carpeta... muestra el árbol de carpetas de Outlook).
    // Al abrir se muestra la carpeta por defecto de la cuenta (campo Carpeta de la cuenta).
    Caption = 'Correo Outlook 365';
    PageType = List;
    SourceTable = "IKA Mail Message";
    SourceTableView = sorting("Mailbox Code", "Received At") order(descending);
    CardPageId = "IKA Mail Message";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = All;
                    StyleExpr = RowStyle;
                }
                field("From Name"; Rec."From Name")
                {
                    ApplicationArea = All;
                    StyleExpr = RowStyle;
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = All;
                    StyleExpr = RowStyle;
                }
                field("Has Attachments"; Rec."Has Attachments")
                {
                    ApplicationArea = All;
                    Caption = '📎';
                }
                field("No. of Links"; Rec."No. of Links")
                {
                    ApplicationArea = All;
                    ToolTip = 'Ficheros de este email adjuntados a entidades de BC.';
                }
                field("Body Preview"; Rec."Body Preview")
                {
                    ApplicationArea = All;
                }
                field("From Address"; Rec."From Address")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("To Recipients"; Rec."To Recipients")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Is Read"; Rec."Is Read")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field(Importance; Rec.Importance)
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Folder Name"; Rec."Folder Name")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Carpeta de Outlook en la que está el email.';
                }
                field("Mailbox Code"; Rec."Mailbox Code")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NewMail)
            {
                ApplicationArea = All;
                Caption = 'Nuevo email';
                Image = NewDocument;
                ToolTip = 'Redacta un email nuevo desde la cuenta actual. Quedará en Elementos enviados.';

                trigger OnAction()
                var
                    MailCompose: Page "IKA Mail Compose";
                begin
                    if CurrentMailboxCode = '' then
                        Error(SelectAccountFirstErr);
                    MailCompose.SetNewMail(CurrentMailboxCode, '', '');
                    MailCompose.RunModal();
                end;
            }
            action(Sync)
            {
                ApplicationArea = All;
                Caption = 'Sincronizar';
                Image = Refresh;
                ShortcutKey = 'F5';
                ToolTip = 'Descarga los últimos emails de la carpeta actual.';

                trigger OnAction()
                begin
                    SyncCurrent(false);
                end;
            }
            action(LoadOlder)
            {
                ApplicationArea = All;
                Caption = 'Cargar anteriores';
                Image = PreviousRecord;
                ToolTip = 'Descarga emails más antiguos que el más antiguo de la lista.';

                trigger OnAction()
                begin
                    SyncCurrent(true);
                end;
            }
            action(ChooseFolder)
            {
                ApplicationArea = All;
                Caption = 'Carpeta...';
                Image = ViewDocumentLine;
                ShortcutKey = 'Ctrl+Shift+F';
                ToolTip = 'Elige otra carpeta de Outlook de esta cuenta (bandeja de entrada, enviados, subcarpetas...).';

                trigger OnAction()
                var
                    MailFolder: Record "IKA Mail Folder";
                    SelectedFolder: Record "IKA Mail Folder";
                begin
                    if CurrentMailboxCode = '' then
                        Error(SelectAccountFirstErr);
                    if not MailFolder.SelectFolder(CurrentMailboxCode, GetShownFolderId(), SelectedFolder) then
                        exit;
                    SetCurrentFolder(CurrentMailboxCode, SelectedFolder."Folder Id");
                    // Primera vez en esta carpeta: se descargan sus emails
                    if not HasLocalMessages() then
                        SyncCurrent(false);
                end;
            }
            action(DefaultFolder)
            {
                ApplicationArea = All;
                Caption = 'Carpeta por defecto';
                Image = Home;
                ToolTip = 'Vuelve a la carpeta por defecto de la cuenta (normalmente, la bandeja de entrada).';

                trigger OnAction()
                begin
                    if CurrentMailboxCode = '' then
                        Error(SelectAccountFirstErr);
                    SetCurrentFolder(CurrentMailboxCode, '');
                end;
            }
            action(MoveToFolder)
            {
                ApplicationArea = All;
                Caption = 'Mover a carpeta...';
                Image = MoveToNextPeriod;
                ToolTip = 'Mueve los emails seleccionados a otra carpeta de Outlook.';

                trigger OnAction()
                begin
                    MoveSelected();
                end;
            }
            action(ChangeAccount)
            {
                ApplicationArea = All;
                Caption = 'Cambiar cuenta';
                Image = ChangeTo;
                ToolTip = 'Muestra los emails de otra cuenta de Outlook 365.';

                trigger OnAction()
                var
                    Mailbox: Record "IKA Mail Mailbox";
                begin
                    Mailbox.SetFilter(Code, Mailbox.GetAllowedFilter());
                    if Page.RunModal(0, Mailbox) = Action::LookupOK then
                        SetCurrentMailbox(Mailbox.Code);
                end;
            }
            action(AllAccounts)
            {
                ApplicationArea = All;
                Caption = 'Todas mis cuentas';
                Image = AllLines;
                ToolTip = 'Muestra juntos los emails de todas las cuentas a las que tiene acceso.';

                trigger OnAction()
                begin
                    SetCurrentMailbox('');
                end;
            }
            action(MarkRead)
            {
                ApplicationArea = All;
                Caption = 'Marcar como leído';
                Image = Approve;
                ToolTip = 'Marca los emails seleccionados como leídos en Outlook.';

                trigger OnAction()
                begin
                    SetReadSelected(true);
                end;
            }
            action(MarkUnread)
            {
                ApplicationArea = All;
                Caption = 'Marcar como no leído';
                Image = Undo;
                ToolTip = 'Marca los emails seleccionados como no leídos en Outlook.';

                trigger OnAction()
                begin
                    SetReadSelected(false);
                end;
            }
        }
        area(Navigation)
        {
            action(Explorer)
            {
                ApplicationArea = All;
                Caption = 'Vista Outlook';
                Image = ViewDetails;
                RunObject = page "IKA Mail Explorer";
                ToolTip = 'Carpetas, emails y panel de lectura en una sola página, como en Outlook.';
            }
            action(Accounts)
            {
                ApplicationArea = All;
                Caption = 'Cuentas de Outlook 365';
                Image = Email;
                RunObject = page "IKA Mail Mailboxes";
                ToolTip = 'Configurar las cuentas.';
            }
            action(Links)
            {
                ApplicationArea = All;
                Caption = 'Vínculos con entidades';
                Image = Links;
                RunObject = page "IKA Mail Links";
                RunPageLink = "Message Entry No." = field("Entry No.");
                ToolTip = 'A qué entidades se ha adjuntado este email o sus ficheros.';
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

                actionref(NewMail_Promoted; NewMail) { }
                actionref(Sync_Promoted; Sync) { }
                actionref(ChooseFolder_Promoted; ChooseFolder) { }
                actionref(DefaultFolder_Promoted; DefaultFolder) { }
                actionref(MoveToFolder_Promoted; MoveToFolder) { }
                actionref(LoadOlder_Promoted; LoadOlder) { }
                actionref(ChangeAccount_Promoted; ChangeAccount) { }
                actionref(AllAccounts_Promoted; AllAccounts) { }
                actionref(MarkRead_Promoted; MarkRead) { }
                actionref(MarkUnread_Promoted; MarkUnread) { }
            }
            group(Category_Navigate)
            {
                Caption = 'Navegar';

                actionref(Explorer_Promoted; Explorer) { }
                actionref(Accounts_Promoted; Accounts) { }
                actionref(Links_Promoted; Links) { }
                actionref(Setup_Promoted; Setup) { }
            }
        }
    }

    views
    {
        view(Unread)
        {
            Caption = 'No leídos';
            Filters = where("Is Read" = const(false));
        }
        view(WithAttachments)
        {
            Caption = 'Con adjuntos';
            Filters = where("Has Attachments" = const(true));
        }
        view(NotLinked)
        {
            Caption = 'Con adjuntos sin vincular';
            Filters = where("Has Attachments" = const(true), "No. of Links" = const(0));
        }
    }

    var
        CurrentMailboxCode: Code[20];
        CurrentFolderId: Text;
        RowStyle: Text;
        NoAccountsMsg: Label 'Todavía no hay ninguna cuenta de Outlook 365 configurada a la que tenga acceso. Añada su cuenta en la página que se abre a continuación.';
        SyncedMsg: Label '%1 emails sincronizados de %2.', Comment = '%1 = count, %2 = mailbox';
        SelectAccountErr: Label 'Elija una cuenta con "Cambiar cuenta" para sincronizar.';
        SelectAccountFirstErr: Label 'Elija primero una cuenta con "Cambiar cuenta".';
        MovedMsg: Label '%1 email(s) movido(s) a %2.', Comment = '%1 = count, %2 = folder';
        PageCaptionLbl: Label 'Correo Outlook 365', Locked = true;

    trigger OnOpenPage()
    var
        Setup: Record "IKA Mail Setup";
        Mailbox: Record "IKA Mail Mailbox";
        AllowedFilter: Text;
    begin
        AllowedFilter := Mailbox.GetAllowedFilter();
        if AllowedFilter = '' then begin
            Message(NoAccountsMsg);
            Page.Run(Page::"IKA Mail Mailboxes");
            Error('');
        end;
        // Seguridad: solo los buzones permitidos al usuario
        Rec.FilterGroup(2);
        Rec.SetFilter("Mailbox Code", AllowedFilter);
        Rec.FilterGroup(0);

        if Rec.GetFilter("Mailbox Code") <> '' then
            exit;
        Setup.GetSetup();
        Mailbox.SetFilter(Code, AllowedFilter);
        if (Setup."Default Mailbox Code" <> '') and Mailbox.Get(Setup."Default Mailbox Code") and Mailbox.HasAccess() then
            CurrentMailboxCode := Mailbox.Code
        else
            if Mailbox.FindFirst() then
                CurrentMailboxCode := Mailbox.Code;
        CurrentFolderId := '';
        ApplyFilters();
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec."Is Read" then
            RowStyle := 'Standard'
        else
            RowStyle := 'Strong';
    end;

    local procedure SetCurrentMailbox(MailboxCode: Code[20])
    begin
        SetCurrentFolder(MailboxCode, '');
    end;

    /// <summary>
    /// Cuenta y carpeta que se muestran. Con FolderId vacío, la carpeta por defecto de la cuenta.
    /// </summary>
    local procedure SetCurrentFolder(MailboxCode: Code[20]; FolderId: Text)
    begin
        CurrentMailboxCode := MailboxCode;
        CurrentFolderId := FolderId;
        ApplyFilters();
        CurrPage.Update(false);
    end;

    local procedure ApplyFilters()
    var
        Mailbox: Record "IKA Mail Mailbox";
        FolderId: Text;
    begin
        if CurrentMailboxCode = '' then begin
            Rec.SetRange("Mailbox Code");
            Rec.SetRange("Folder Id");
            CurrPage.Caption := PageCaptionLbl;
            exit;
        end;
        Mailbox.Get(CurrentMailboxCode);
        Mailbox.CheckAccess();
        Rec.SetRange("Mailbox Code", CurrentMailboxCode);
        FolderId := GetShownFolderId();
        case FolderId of
            '':
                // Carpeta por defecto todavía sin resolver (antes de la primera sincronización)
                Rec.SetRange("Folder Id");
            Mailbox."Folder Id":
                // Los emails guardados antes de existir el selector de carpetas no tienen carpeta: son de la carpeta por defecto
                Rec.SetFilter("Folder Id", '%1|%2', FolderId, '');
            else
                Rec.SetRange("Folder Id", FolderId);
        end;
        CurrPage.Caption := PageCaptionLbl + ' - ' + Mailbox.Address + ' - ' + GetFolderCaption(Mailbox, FolderId);
    end;

    /// <summary>
    /// Id de la carpeta que se está mostrando ('' si es la carpeta por defecto y aún no se conoce su Id).
    /// </summary>
    local procedure GetShownFolderId(): Text
    var
        Mailbox: Record "IKA Mail Mailbox";
    begin
        if CurrentFolderId <> '' then
            exit(CurrentFolderId);
        if (CurrentMailboxCode <> '') and Mailbox.Get(CurrentMailboxCode) then
            exit(Mailbox."Folder Id");
        exit('');
    end;

    local procedure GetFolderCaption(Mailbox: Record "IKA Mail Mailbox"; FolderId: Text): Text
    var
        MailFolder: Record "IKA Mail Folder";
    begin
        if FolderId <> '' then
            if MailFolder.Get(Mailbox.Code, CopyStr(FolderId, 1, MaxStrLen(MailFolder."Folder Id"))) then
                exit(MailFolder.Path);
        exit(Mailbox.Folder);
    end;

    local procedure HasLocalMessages(): Boolean
    var
        MailMessage: Record "IKA Mail Message";
    begin
        MailMessage.CopyFilters(Rec);
        exit(not MailMessage.IsEmpty());
    end;

    local procedure SyncCurrent(LoadOlderMessages: Boolean)
    var
        Mailbox: Record "IKA Mail Mailbox";
        GraphClient: Codeunit "IKA Mail Graph Client";
        SyncedCount: Integer;
    begin
        if CurrentMailboxCode = '' then
            Error(SelectAccountErr);
        Mailbox.Get(CurrentMailboxCode);
        SyncedCount := GraphClient.SyncFolderMessages(Mailbox, CurrentFolderId, LoadOlderMessages);
        ApplyFilters(); // la primera sincronización resuelve el Id de la carpeta por defecto
        CurrPage.Update(false);
        if LoadOlderMessages then
            Message(SyncedMsg, SyncedCount, Mailbox.Address);
    end;

    local procedure MoveSelected()
    var
        MailMessage: Record "IKA Mail Message";
        MailFolder: Record "IKA Mail Folder";
        DestinationFolder: Record "IKA Mail Folder";
        GraphClient: Codeunit "IKA Mail Graph Client";
        MovedCount: Integer;
    begin
        if CurrentMailboxCode = '' then
            Error(SelectAccountFirstErr);
        CurrPage.SetSelectionFilter(MailMessage);
        MailMessage.SetRange("Mailbox Code", CurrentMailboxCode);
        if MailMessage.IsEmpty() then
            exit;
        if not MailFolder.SelectFolder(CurrentMailboxCode, '', DestinationFolder) then
            exit;
        if MailMessage.FindSet() then
            repeat
                if MailMessage."Folder Id" <> DestinationFolder."Folder Id" then begin
                    GraphClient.MoveMessage(MailMessage, DestinationFolder."Folder Id");
                    MovedCount += 1;
                end;
            until MailMessage.Next() = 0;
        CurrPage.Update(false);
        Message(MovedMsg, MovedCount, DestinationFolder.Path);
    end;

    local procedure SetReadSelected(IsRead: Boolean)
    var
        MailMessage: Record "IKA Mail Message";
        GraphClient: Codeunit "IKA Mail Graph Client";
    begin
        CurrPage.SetSelectionFilter(MailMessage);
        if MailMessage.FindSet() then
            repeat
                if MailMessage."Is Read" <> IsRead then
                    GraphClient.SetReadFlag(MailMessage, IsRead);
            until MailMessage.Next() = 0;
        CurrPage.Update(false);
    end;
}
