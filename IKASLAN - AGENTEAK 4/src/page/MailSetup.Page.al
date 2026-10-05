page 50400 "IKA Mail Setup"
{
    Caption = 'Configuración correo Outlook 365';
    PageType = Card;
    SourceTable = "IKA Mail Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Graph)
            {
                Caption = 'Microsoft Graph (registro de aplicación por defecto)';

                field("Graph Tenant Id"; Rec."Graph Tenant Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Id de directorio (tenant) de Entra ID. Lo usan todas las cuentas que no tengan credenciales propias.';
                }
                field("Graph Client Id"; Rec."Graph Client Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Id de aplicación (cliente) con permisos de aplicación Mail.ReadWrite y Mail.Send.';
                }
                field(GraphSecretStatus; GraphSecretStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Secreto de cliente';
                    Editable = false;
                    ToolTip = 'Se guarda cifrado en Isolated Storage. Use la acción "Establecer secreto".';
                }
                field("Default Mailbox Code"; Rec."Default Mailbox Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cuenta que se abre por defecto en la bandeja de correo.';
                }
            }
            group(Viewer)
            {
                Caption = 'Bandeja y visor';

                field("Messages per Sync"; Rec."Messages per Sync")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cuántos emails se descargan en cada sincronización.';
                }
                field("Mark as Read on Open"; Rec."Mark as Read on Open")
                {
                    ApplicationArea = All;
                    ToolTip = 'Marca el email como leído en Outlook al abrirlo en BC.';
                }
                field("Load Inline Images"; Rec."Load Inline Images")
                {
                    ApplicationArea = All;
                    ToolTip = 'Muestra las imágenes incrustadas en el cuerpo (logos, capturas...).';
                }
                field("Max Inline Image (KB)"; Rec."Max Inline Image (KB)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Las imágenes incrustadas mayores no se descargan para el visor.';
                }
                field("Block Remote Images"; Rec."Block Remote Images")
                {
                    ApplicationArea = All;
                }
                field("Max Attach Size (MB)"; Rec."Max Attach Size (MB)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Tamaño máximo de un fichero para adjuntarlo a una entidad de BC.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SetGraphSecret)
            {
                ApplicationArea = All;
                Caption = 'Establecer secreto';
                Image = EncryptionKeys;
                ToolTip = 'Introduce el secreto de cliente del registro de aplicación.';

                trigger OnAction()
                var
                    SecretInput: Page "IKA Mail Secret Input";
                begin
                    if SecretInput.RunModal() = Action::OK then begin
                        Rec.SetGraphClientSecret(SecretInput.GetSecret());
                        UpdateStatusTexts();
                    end;
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
                ToolTip = 'Cuentas (la suya u otras) cuyos emails se muestran en BC.';
            }
            action(Messages)
            {
                ApplicationArea = All;
                Caption = 'Bandeja de correo';
                Image = Documents;
                RunObject = page "IKA Mail Messages";
                ToolTip = 'Abre la bandeja de correo.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(SetGraphSecret_Promoted; SetGraphSecret) { }
                actionref(Accounts_Promoted; Accounts) { }
                actionref(Messages_Promoted; Messages) { }
            }
        }
    }

    var
        GraphSecretStatus: Text;
        ConfiguredTxt: Label 'Configurado ✔';
        NotConfiguredTxt: Label 'No configurado';

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
        UpdateStatusTexts();
    end;

    local procedure UpdateStatusTexts()
    begin
        if Rec.HasGraphClientSecret() then
            GraphSecretStatus := ConfiguredTxt
        else
            GraphSecretStatus := NotConfiguredTxt;
    end;
}
