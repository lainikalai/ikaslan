permissionset 99201 "IKA Mail Workspace"
{
    Caption = 'Correo Outlook 365 en BC';
    Assignable = true;

    Permissions =
        tabledata "IKA Mail Setup" = RIMD,
        tabledata "IKA Mail Mailbox" = RIMD,
        tabledata "IKA Mail Message" = RIMD,
        tabledata "IKA Mail Attachment" = RIMD,
        tabledata "IKA Mail Link" = RIMD,
        tabledata "IKA Mail Pinned Target" = RIMD,
        tabledata "IKA Mail Drop Target" = RIMD,
        tabledata "IKA Mail Compose File" = RIMD,
        tabledata "Document Attachment" = RIM,
        table "IKA Mail Setup" = X,
        table "IKA Mail Mailbox" = X,
        table "IKA Mail Message" = X,
        table "IKA Mail Attachment" = X,
        table "IKA Mail Link" = X,
        table "IKA Mail Pinned Target" = X,
        table "IKA Mail Drop Target" = X,
        table "IKA Mail Compose File" = X,
        codeunit "IKA Mail Graph Client" = X,
        codeunit "IKA Mail Entity Mgt." = X,
        codeunit "IKA Mail Attach Mgt." = X,
        codeunit "IKA Mail Json Helper" = X,
        page "IKA Mail Setup" = X,
        page "IKA Mail Mailboxes" = X,
        page "IKA Mail Messages" = X,
        page "IKA Mail Message" = X,
        page "IKA Mail Compose" = X,
        page "IKA Mail Links" = X,
        page "IKA Mail Linked Emails" = X,
        page "IKA Mail Secret Input" = X;
}
