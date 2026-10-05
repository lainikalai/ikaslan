page 50420 "IKA Mail Messages"
{
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
            action(Sync)
            {
                ApplicationArea = All;
                Caption = 'Sincronizar';
                Image = Refresh;
                ShortcutKey = 'F5';
                ToolTip = 'Descarga los últimos emails de la cuenta actual.';

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

                actionref(Sync_Promoted; Sync) { }
                actionref(LoadOlder_Promoted; LoadOlder) { }
                actionref(ChangeAccount_Promoted; ChangeAccount) { }
                actionref(AllAccounts_Promoted; AllAccounts) { }
                actionref(MarkRead_Promoted; MarkRead) { }
                actionref(MarkUnread_Promoted; MarkUnread) { }
            }
            group(Category_Navigate)
            {
                Caption = 'Navegar';

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
        RowStyle: Text;
        NoAccountsMsg: Label 'Todavía no hay ninguna cuenta de Outlook 365 configurada a la que tenga acceso. Añada su cuenta en la página que se abre a continuación.';
        SyncedMsg: Label '%1 emails sincronizados de %2.', Comment = '%1 = count, %2 = mailbox';
        SelectAccountErr: Label 'Elija una cuenta con "Cambiar cuenta" para sincronizar.';

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
            SetCurrentMailbox(Mailbox.Code)
        else
            if Mailbox.FindFirst() then
                SetCurrentMailbox(Mailbox.Code);
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec."Is Read" then
            RowStyle := 'Standard'
        else
            RowStyle := 'Strong';
    end;

    local procedure SetCurrentMailbox(MailboxCode: Code[20])
    var
        Mailbox: Record "IKA Mail Mailbox";
    begin
        CurrentMailboxCode := MailboxCode;
        if MailboxCode = '' then begin
            Rec.SetRange("Mailbox Code");
            CurrPage.Caption := 'Correo Outlook 365';
        end else begin
            Mailbox.Get(MailboxCode);
            Mailbox.CheckAccess();
            Rec.SetRange("Mailbox Code", MailboxCode);
            CurrPage.Caption := 'Correo Outlook 365 - ' + Mailbox.Address;
        end;
        CurrPage.Update(false);
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
        SyncedCount := GraphClient.SyncMessages(Mailbox, LoadOlderMessages);
        CurrPage.Update(false);
        if LoadOlderMessages then
            Message(SyncedMsg, SyncedCount, Mailbox.Address);
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
