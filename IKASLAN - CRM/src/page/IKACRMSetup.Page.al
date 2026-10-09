page 99401 "IKA CRM Setup"
{
    Caption = 'Configuración CRM';
    PageType = Card;
    SourceTable = "IKA CRM Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Connection)
            {
                Caption = 'Conexión con Dynamics 365 Customer Engagement';

                field("Environment URL"; Rec."Environment URL")
                {
                    ApplicationArea = All;
                }
                field("Tenant Id"; Rec."Tenant Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Id del inquilino (tenant) de Microsoft Entra ID.';
                }
                field("Client Id"; Rec."Client Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Id de aplicación (cliente) del registro de aplicación de Entra ID dado de alta como usuario de aplicación en el CRM.';
                }
                field(SecretStatus; SecretStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Secreto de cliente';
                    Editable = false;
                    ToolTip = 'El secreto se guarda cifrado. Use la acción "Establecer secreto".';
                }
                field("API Version"; Rec."API Version")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    ToolTip = 'Versión de la API web de Dataverse (normalmente v9.2).';
                }
            }
            group(Options)
            {
                Caption = 'Opciones';

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                }
                field("Max. Records"; Rec."Max. Records")
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
            action(SetSecret)
            {
                ApplicationArea = All;
                Caption = 'Establecer secreto';
                Image = EncryptionKeys;
                ToolTip = 'Introduce el secreto de cliente (el "Valor" del secreto, no su Id) del registro de aplicación.';

                trigger OnAction()
                var
                    SecretInput: Page "IKA CRM Secret Input";
                begin
                    if SecretInput.RunModal() = Action::OK then begin
                        Rec.SetClientSecret(SecretInput.GetSecret());
                        UpdateSecretStatus();
                    end;
                end;
            }
            action(TestConnection)
            {
                ApplicationArea = All;
                Caption = 'Probar conexión';
                Image = TestDatabase;
                ToolTip = 'Comprueba que BC puede leer del CRM con estas credenciales.';

                trigger OnAction()
                var
                    WebApi: Codeunit "IKA CRM Web API";
                begin
                    CurrPage.SaveRecord();
                    Commit();
                    Message(WebApi.TestConnection());
                end;
            }
            action(OpenCrm)
            {
                ApplicationArea = All;
                Caption = 'Abrir el CRM';
                Image = Web;
                ToolTip = 'Abre el CRM en el navegador.';

                trigger OnAction()
                begin
                    Rec.TestField("Environment URL");
                    Hyperlink(Rec."Environment URL");
                end;
            }
        }
        area(Navigation)
        {
            action(Accounts)
            {
                ApplicationArea = All;
                Caption = 'Cuentas';
                Image = Customer;
                RunObject = page "IKA CRM Accounts";
                ToolTip = 'Cuentas del CRM.';
            }
            action(Links)
            {
                ApplicationArea = All;
                Caption = 'Vínculos con BC';
                Image = Links;
                RunObject = page "IKA CRM Links";
                ToolTip = 'Clientes, proveedores y contactos de BC vinculados con el CRM.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(SetSecret_Promoted; SetSecret) { }
                actionref(TestConnection_Promoted; TestConnection) { }
                actionref(OpenCrm_Promoted; OpenCrm) { }
            }
            group(Category_Navigate)
            {
                Caption = 'Navegar';

                actionref(Accounts_Promoted; Accounts) { }
                actionref(Links_Promoted; Links) { }
            }
        }
    }

    var
        SecretStatus: Text;
        ConfiguredTxt: Label 'Configurado ✔';
        NotConfiguredTxt: Label 'No configurado';

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
        UpdateSecretStatus();
    end;

    local procedure UpdateSecretStatus()
    begin
        if Rec.HasClientSecret() then
            SecretStatus := ConfiguredTxt
        else
            SecretStatus := NotConfiguredTxt;
    end;
}
