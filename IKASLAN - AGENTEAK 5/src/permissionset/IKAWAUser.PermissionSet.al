permissionset 50600 "IKA WA User"
{
    Caption = 'WhatsApp - usuarios';
    Assignable = true;

    Permissions =
        tabledata "IKA WA Setup" = RIMD,
        tabledata "IKA WA Account" = RIMD,
        tabledata "IKA WA Template" = RIMD,
        tabledata "IKA WA Template Param" = RIMD,
        tabledata "IKA WA Conversation" = RIMD,
        tabledata "IKA WA Message" = RIMD,
        tabledata "IKA WA Inbound Event" = RIMD,
        tabledata "Document Attachment" = RIM,
        table "IKA WA Setup" = X,
        table "IKA WA Account" = X,
        table "IKA WA Template" = X,
        table "IKA WA Template Param" = X,
        table "IKA WA Conversation" = X,
        table "IKA WA Message" = X,
        table "IKA WA Inbound Event" = X,
        codeunit "IKA WA Cloud API" = X,
        codeunit "IKA WA Inbound Processor" = X,
        codeunit "IKA WA Media Downloader" = X,
        codeunit "IKA WA Phone Mgt." = X,
        codeunit "IKA WA Document Sender" = X,
        codeunit "IKA WA Json Helper" = X,
        codeunit "IKA WA Job" = X,
        page "IKA WA Setup" = X,
        page "IKA WA Accounts" = X,
        page "IKA WA Templates" = X,
        page "IKA WA Template Params" = X,
        page "IKA WA Conversations" = X,
        page "IKA WA Entity Conversations" = X,
        page "IKA WA Conversation" = X,
        page "IKA WA Messages Part" = X,
        page "IKA WA Send" = X,
        page "IKA WA Inbound Events" = X,
        page "IKA WA Secret Input" = X;
}
