page 99241 "IKA Mail Folders"
{
    // Árbol de carpetas de Outlook de una cuenta. Se usa como selector en la bandeja y al mover emails.
    Caption = 'Carpetas de Outlook';
    PageType = List;
    SourceTable = "IKA Mail Folder";
    SourceTableView = sorting("Mailbox Code", "Sorting Order");
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                IndentationColumn = Rec.Level;
                IndentationControls = "Display Name";
                ShowAsTree = true;
                TreeInitialState = ExpandAll;

                field("Display Name"; Rec."Display Name")
                {
                    ApplicationArea = All;
                    StyleExpr = RowStyle;
                    ToolTip = 'Nombre de la carpeta en Outlook.';
                }
                field("Unread Items"; Rec."Unread Items")
                {
                    ApplicationArea = All;
                    Style = Strong;
                    ToolTip = 'Emails sin leer en la carpeta (según la última actualización).';
                }
                field("Total Items"; Rec."Total Items")
                {
                    ApplicationArea = All;
                    ToolTip = 'Emails en la carpeta (según la última actualización).';
                }
                field(Path; Rec.Path)
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Ruta completa de la carpeta.';
                }
                field("Mailbox Code"; Rec."Mailbox Code")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Cuenta de Outlook 365.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RefreshFolders)
            {
                ApplicationArea = All;
                Caption = 'Actualizar carpetas';
                Image = Refresh;
                ShortcutKey = 'F5';
                ToolTip = 'Vuelve a leer de Outlook las carpetas de la cuenta y sus contadores de emails.';

                trigger OnAction()
                var
                    Mailbox: Record "IKA Mail Mailbox";
                    GraphClient: Codeunit "IKA Mail Graph Client";
                    MailboxCode: Code[20];
                begin
                    Rec.FilterGroup(2);
                    MailboxCode := CopyStr(Rec.GetFilter("Mailbox Code"), 1, MaxStrLen(MailboxCode));
                    Rec.FilterGroup(0);
                    if MailboxCode = '' then
                        MailboxCode := Rec."Mailbox Code";
                    Mailbox.Get(MailboxCode);
                    GraphClient.SyncFolders(Mailbox);
                    CurrPage.Update(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(RefreshFolders_Promoted; RefreshFolders) { }
            }
        }
    }

    var
        RowStyle: Text;

    trigger OnAfterGetRecord()
    begin
        if Rec."Unread Items" > 0 then
            RowStyle := 'Strong'
        else
            RowStyle := 'Standard';
    end;
}
