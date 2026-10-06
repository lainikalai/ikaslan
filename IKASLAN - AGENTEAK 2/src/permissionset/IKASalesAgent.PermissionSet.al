permissionset 99001 "IKA Sales Agent"
{
    Caption = 'Agente de ventas (Claude)';
    Assignable = true;

    Permissions =
        tabledata "IKA Sales Agent Setup" = RIMD,
        tabledata "IKA Sales Agent Mail Filter" = RIMD,
        tabledata "IKA Sales Request Header" = RIMD,
        tabledata "IKA Sales Request Line" = RIMD,
        tabledata "IKA Sales Request Attachment" = RIMD,
        tabledata "IKA Sales Agent Log" = RIMD,
        tabledata "IKA Sales Mail Account" = RIMD,
        table "IKA Sales Mail Account" = X,
        table "IKA Sales Agent Setup" = X,
        table "IKA Sales Agent Mail Filter" = X,
        table "IKA Sales Request Header" = X,
        table "IKA Sales Request Line" = X,
        table "IKA Sales Request Attachment" = X,
        table "IKA Sales Agent Log" = X,
        codeunit "IKA Claude API Client" = X,
        codeunit "IKA Graph Mail Client" = X,
        codeunit "IKA Sales Req. Extraction" = X,
        codeunit "IKA Sales Req. Resolver" = X,
        codeunit "IKA Sales Order Creator" = X,
        codeunit "IKA Sales Agent Json Helper" = X,
        codeunit "IKA Sales Agent Log Mgt." = X,
        codeunit "IKA Attachment To Text" = X,
        codeunit "IKA Sales Req. Process" = X,
        codeunit "IKA Move Request Mail" = X,
        codeunit "IKA Sales Agent Job" = X,
        page "IKA Sales Agent Setup" = X,
        page "IKA Sales Agent Mail Filters" = X,
        page "IKA Sales Requests" = X,
        page "IKA Sales Request" = X,
        page "IKA Sales Request Subform" = X,
        page "IKA Sales Req. Attachments" = X,
        page "IKA Sales Agent Log" = X,
        page "IKA Sales Mail Accounts" = X,
        page "IKA Secret Input" = X;
}
