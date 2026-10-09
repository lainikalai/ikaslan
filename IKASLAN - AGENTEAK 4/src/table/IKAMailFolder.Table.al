table 99241 "IKA Mail Folder"
{
    // Carpetas de Outlook de cada cuenta (árbol completo, con subcarpetas a cualquier nivel).
    // Se descargan con "Actualizar carpetas"; el orden es el de Outlook: bandeja de entrada,
    // borradores, enviados, eliminados, no deseado, archivo y después el resto por nombre.
    Caption = 'Carpeta de Outlook';
    DataClassification = CustomerContent;
    LookupPageId = "IKA Mail Folders";
    DrillDownPageId = "IKA Mail Folders";

    fields
    {
        field(1; "Mailbox Code"; Code[20])
        {
            Caption = 'Buzón';
            TableRelation = "IKA Mail Mailbox";
        }
        field(2; "Folder Id"; Text[250])
        {
            Caption = 'Id (Graph)';
        }
        field(10; "Display Name"; Text[250])
        {
            Caption = 'Carpeta';
        }
        field(11; "Parent Folder Id"; Text[250])
        {
            Caption = 'Id carpeta padre';
        }
        field(12; Path; Text[1024])
        {
            Caption = 'Ruta';
        }
        field(13; Level; Integer)
        {
            Caption = 'Nivel';
        }
        field(14; "Sorting Order"; Integer)
        {
            Caption = 'Orden';
        }
        field(15; "Well-known Name"; Text[30])
        {
            Caption = 'Carpeta estándar';
            ToolTip = 'inbox, drafts, sentitems, deleteditems, junkemail o archive.';
        }
        field(16; "Sort Key"; Text[250])
        {
            Caption = 'Clave de orden';
        }
        field(20; "Total Items"; Integer)
        {
            Caption = 'Emails';
            BlankZero = true;
        }
        field(21; "Unread Items"; Integer)
        {
            Caption = 'No leídos';
            BlankZero = true;
        }
        field(22; "Child Folder Count"; Integer)
        {
            Caption = 'Subcarpetas';
            BlankZero = true;
        }
        field(30; "Last Refreshed At"; DateTime)
        {
            Caption = 'Actualizada';
        }
    }

    keys
    {
        key(PK; "Mailbox Code", "Folder Id")
        {
            Clustered = true;
        }
        key(Sorting; "Mailbox Code", "Sorting Order")
        {
        }
        key(SortKey; "Mailbox Code", "Sort Key")
        {
        }
    }

    /// <summary>
    /// Muestra el árbol de carpetas de la cuenta (lo descarga de Outlook si todavía no se ha hecho)
    /// y devuelve la elegida. La carpeta indicada en CurrentFolderId aparece seleccionada.
    /// </summary>
    procedure SelectFolder(MailboxCode: Code[20]; CurrentFolderId: Text; var SelectedFolder: Record "IKA Mail Folder"): Boolean
    var
        Mailbox: Record "IKA Mail Mailbox";
        MailFolder: Record "IKA Mail Folder";
        GraphClient: Codeunit "IKA Mail Graph Client";
    begin
        Mailbox.Get(MailboxCode);
        Mailbox.CheckAccess();
        MailFolder.SetRange("Mailbox Code", MailboxCode);
        if MailFolder.IsEmpty() then begin
            GraphClient.SyncFolders(Mailbox);
            Commit(); // antes de abrir la página modal
        end;

        MailFolder.SetCurrentKey("Mailbox Code", "Sorting Order");
        MailFolder.FilterGroup(2);
        MailFolder.SetRange("Mailbox Code", MailboxCode);
        MailFolder.FilterGroup(0);
        if CurrentFolderId <> '' then
            if MailFolder.Get(MailboxCode, CopyStr(CurrentFolderId, 1, MaxStrLen(MailFolder."Folder Id"))) then;
        if Page.RunModal(Page::"IKA Mail Folders", MailFolder) <> Action::LookupOK then
            exit(false);
        SelectedFolder := MailFolder;
        exit(true);
    end;
}
