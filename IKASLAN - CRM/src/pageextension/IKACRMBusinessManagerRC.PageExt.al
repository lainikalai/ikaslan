pageextension 99416 "IKA CRM Business Manager RC" extends "Business Manager Role Center"
{
    actions
    {
        addlast(Sections)
        {
            group("IKA CRM")
            {
                Caption = 'CRM';
                ToolTip = 'Cuentas, contactos, clientes potenciales y oportunidades de Microsoft Dynamics 365 Customer Engagement.';

                action("IKA CRM Setup")
                {
                    ApplicationArea = All;
                    Caption = 'Configuración';
                    RunObject = page "IKA CRM Setup";
                    ToolTip = 'Conexión con el CRM (URL, registro de aplicación y secreto).';
                }
                action("IKA CRM Accounts")
                {
                    ApplicationArea = All;
                    Caption = 'Cuentas';
                    RunObject = page "IKA CRM Accounts";
                    ToolTip = 'Cuentas (empresas) del CRM.';
                }
                action("IKA CRM Contacts")
                {
                    ApplicationArea = All;
                    Caption = 'Contactos';
                    RunObject = page "IKA CRM Contacts";
                    ToolTip = 'Contactos (personas) del CRM.';
                }
                action("IKA CRM Leads")
                {
                    ApplicationArea = All;
                    Caption = 'Clientes potenciales';
                    RunObject = page "IKA CRM Leads";
                    ToolTip = 'Clientes potenciales (prospectos) del CRM.';
                }
                action("IKA CRM Opportunities")
                {
                    ApplicationArea = All;
                    Caption = 'Oportunidades';
                    RunObject = page "IKA CRM Opportunities";
                    ToolTip = 'Oportunidades del CRM.';
                }
                action("IKA CRM Links")
                {
                    ApplicationArea = All;
                    Caption = 'Vínculos con BC';
                    RunObject = page "IKA CRM Links";
                    ToolTip = 'Clientes, proveedores y contactos de BC vinculados con el CRM.';
                }
            }
        }
    }
}
