permissionset 99401 "IKA CRM"
{
    Caption = 'Conector CRM (Dynamics 365 CE)';
    Assignable = true;

    Permissions =
        tabledata "IKA CRM Setup" = RIMD,
        tabledata "IKA CRM Link" = RIMD,
        table "IKA CRM Setup" = X,
        table "IKA CRM Link" = X,
        table "IKA CRM Account Buffer" = X,
        table "IKA CRM Contact Buffer" = X,
        table "IKA CRM Lead Buffer" = X,
        table "IKA CRM Opportunity Buffer" = X,
        table "IKA CRM Activity Buffer" = X,
        codeunit "IKA CRM Web API" = X,
        codeunit "IKA CRM Json Helper" = X,
        codeunit "IKA CRM Data Mgt." = X,
        codeunit "IKA CRM Link Mgt." = X,
        page "IKA CRM Setup" = X,
        page "IKA CRM Accounts" = X,
        page "IKA CRM Account" = X,
        page "IKA CRM Contacts" = X,
        page "IKA CRM Leads" = X,
        page "IKA CRM Opportunities" = X,
        page "IKA CRM Contacts Part" = X,
        page "IKA CRM Opportunities Part" = X,
        page "IKA CRM Activities Part" = X,
        page "IKA CRM FactBox" = X,
        page "IKA CRM Links" = X,
        page "IKA CRM Secret Input" = X;
}
