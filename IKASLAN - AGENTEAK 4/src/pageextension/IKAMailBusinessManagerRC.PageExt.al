pageextension 99246 "IKA Mail Business Manager RC" extends "Business Manager Role Center"
{
    actions
    {
        addlast(Sections)
        {
            group("IKA Mail Workspace")
            {
                Caption = 'Correo Outlook 365';
                ToolTip = 'Configuración, cuentas y bandeja de correo de Outlook 365, y emails vinculados a entidades.';

                action("IKA Mail Setup")
                {
                    ApplicationArea = All;
                    Caption = 'Configuración';
                    RunObject = page "IKA Mail Setup";
                    ToolTip = 'Credenciales de Microsoft Graph (registro de aplicación), cuenta por defecto y opciones del visor de correo.';
                }
                action("IKA Mail Messages")
                {
                    ApplicationArea = All;
                    Caption = 'Bandeja de correo';
                    RunObject = page "IKA Mail Messages";
                    ToolTip = 'Emails de sus cuentas de Outlook 365, con selector de carpetas.';
                }
                action("IKA Mail Messages Unread")
                {
                    ApplicationArea = All;
                    Caption = 'No leídos';
                    RunObject = page "IKA Mail Messages";
                    RunPageView = where("Is Read" = const(false));
                    ToolTip = 'Emails sin leer.';
                }
                action("IKA Mail Messages Not Linked")
                {
                    ApplicationArea = All;
                    Caption = 'Con adjuntos sin vincular';
                    RunObject = page "IKA Mail Messages";
                    RunPageView = where("Has Attachments" = const(true), "No. of Links" = const(0));
                    ToolTip = 'Emails con adjuntos que todavía no se han adjuntado a ninguna entidad de BC.';
                }
                action("IKA Mail Links")
                {
                    ApplicationArea = All;
                    Caption = 'Emails vinculados a entidades';
                    RunObject = page "IKA Mail Links";
                    ToolTip = 'Emails y adjuntos que se han adjuntado a clientes, proveedores, contactos y otras entidades.';
                }
                action("IKA Mail Mailboxes")
                {
                    ApplicationArea = All;
                    Caption = 'Cuentas de Outlook 365';
                    RunObject = page "IKA Mail Mailboxes";
                    ToolTip = 'Cuentas y buzones compartidos que se muestran en BC.';
                }
            }
        }
    }
}
