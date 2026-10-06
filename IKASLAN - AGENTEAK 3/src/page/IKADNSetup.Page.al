page 50200 "IKA DN Setup"
{
    Caption = 'Configuración agente de albaranes (Claude)';
    PageType = Card;
    SourceTable = "IKA DN Setup";
    UsageCategory = Administration;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Activa la ejecución desde la cola de proyectos.';
                }
                field("Job Interval (min)"; Rec."Job Interval (min)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cada cuántos minutos se ejecuta la cola de proyectos.';
                }
                field("Max Documents per Run"; Rec."Max Documents per Run")
                {
                    ApplicationArea = All;
                    ToolTip = 'Máximo de emails/ficheros a importar por ejecución.';
                }
                field("Max Attachment Size (KB)"; Rec."Max Attachment Size (KB)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Los ficheros mayores no se procesan.';
                }
            }
            group(Matching)
            {
                Caption = 'Conciliación';

                field("Price Tolerance %"; Rec."Price Tolerance %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Diferencia máxima admitida entre el precio neto del albarán y el del pedido.';
                }
                field("Allow Over-Receipt"; Rec."Allow Over-Receipt")
                {
                    ApplicationArea = All;
                    ToolTip = 'No marcar como discrepancia recibir más que lo pendiente (BC debe permitirlo con códigos de exceso de recepción).';
                }
                field("Search Other Open Orders"; Rec."Search Other Open Orders")
                {
                    ApplicationArea = All;
                }
                field("Allow Description Match"; Rec."Allow Description Match")
                {
                    ApplicationArea = All;
                    ToolTip = 'Permite identificar productos por descripción (primero en los pedidos abiertos del proveedor).';
                }
                field("Min. Confidence"; Rec."Min. Confidence")
                {
                    ApplicationArea = All;
                    ToolTip = 'Confianza mínima declarada por Claude para dar el albarán por conciliado.';
                }
                field("Auto Apply to Orders"; Rec."Auto Apply to Orders")
                {
                    ApplicationArea = All;
                }
                field("Reset Qty. to Receive"; Rec."Reset Qty. to Receive")
                {
                    ApplicationArea = All;
                    ToolTip = 'Al aplicar, deja a 0 la cantidad a recibir de las líneas del pedido que no vienen en el albarán.';
                }
                field("Auto Post Receipt"; Rec."Auto Post Receipt")
                {
                    ApplicationArea = All;
                }
            }
            group(Claude)
            {
                Caption = 'Claude (Anthropic)';

                field(ClaudeApiKeyStatus; ClaudeApiKeyStatus)
                {
                    ApplicationArea = All;
                    Caption = 'API key';
                    Editable = false;
                    ToolTip = 'La API key se guarda cifrada en Isolated Storage.';
                }
                field("Claude Model"; Rec."Claude Model")
                {
                    ApplicationArea = All;
                    ToolTip = 'Por defecto claude-opus-5-5. Alternativa más económica: claude-sonnet-5-5.';
                }
                field("Claude Effort"; Rec."Claude Effort")
                {
                    ApplicationArea = All;
                }
                field("Claude Max Tokens"; Rec."Claude Max Tokens")
                {
                    ApplicationArea = All;
                    ToolTip = 'Auméntelo si los albaranes tienen muchas líneas y la respuesta se corta.';
                }
                field("Claude Timeout (sec)"; Rec."Claude Timeout (sec)")
                {
                    ApplicationArea = All;
                }
                field("Use Refusal Fallback"; Rec."Use Refusal Fallback")
                {
                    ApplicationArea = All;
                }
                field("Claude Endpoint"; Rec."Claude Endpoint")
                {
                    ApplicationArea = All;
                }
                field("Extra Instructions"; Rec."Extra Instructions")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Reglas que se aplican a todos los proveedores. Las propias de cada proveedor van en su plantilla.';
                }
            }
            group(Graph)
            {
                Caption = 'Microsoft Graph';

                field("Graph Tenant Id"; Rec."Graph Tenant Id")
                {
                    ApplicationArea = All;
                }
                field("Graph Client Id"; Rec."Graph Client Id")
                {
                    ApplicationArea = All;
                }
                field(GraphSecretStatus; GraphSecretStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Secreto de cliente';
                    Editable = false;
                }
            }
            group(Mail)
            {
                Caption = 'Origen: buzón de correo';

                field("Mail Enabled"; Rec."Mail Enabled")
                {
                    ApplicationArea = All;
                }
                field("Mail Account Code"; Rec."Mail Account Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cuenta de Outlook 365 de la que se leen los albaranes.';
                }
                field("Mail Processed Folder"; Rec."Mail Processed Folder")
                {
                    ApplicationArea = All;
                }
                field("Mail Error Folder"; Rec."Mail Error Folder")
                {
                    ApplicationArea = All;
                }
                field("Only Unread"; Rec."Only Unread")
                {
                    ApplicationArea = All;
                }
                field("Mark as Read"; Rec."Mark as Read")
                {
                    ApplicationArea = All;
                }
                field("Accept Unknown Senders"; Rec."Accept Unknown Senders")
                {
                    ApplicationArea = All;
                }
                field("Generic Subject Filter"; Rec."Generic Subject Filter")
                {
                    ApplicationArea = All;
                    ToolTip = 'Para remitentes sin plantilla: patrón de asunto con comodines, p.ej. *albar*.';
                }
            }
            group(Folder)
            {
                Caption = 'Origen: carpeta SharePoint / OneDrive';

                field("Folder Enabled"; Rec."Folder Enabled")
                {
                    ApplicationArea = All;
                }
                field("Drive Site"; Rec."Drive Site")
                {
                    ApplicationArea = All;
                }
                field("Drive Id"; Rec."Drive Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Se puede obtener automáticamente con la acción "Obtener Drive Id".';
                }
                field("Folder Inbox Path"; Rec."Folder Inbox Path")
                {
                    ApplicationArea = All;
                }
                field("Folder Processed Path"; Rec."Folder Processed Path")
                {
                    ApplicationArea = All;
                }
                field("Folder Error Path"; Rec."Folder Error Path")
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
            action(SetClaudeApiKey)
            {
                ApplicationArea = All;
                Caption = 'Establecer API key de Claude';
                Image = EncryptionKeys;
                ToolTip = 'Introduce la API key de Anthropic.';

                trigger OnAction()
                var
                    SecretInput: Page "IKA DN Secret Input";
                begin
                    if SecretInput.RunModal() = Action::OK then begin
                        Rec.SetClaudeApiKey(SecretInput.GetSecret());
                        UpdateStatusTexts();
                    end;
                end;
            }
            action(SetGraphSecret)
            {
                ApplicationArea = All;
                Caption = 'Establecer secreto de Graph';
                Image = EncryptionKeys;
                ToolTip = 'Introduce el secreto de cliente del registro de aplicación.';

                trigger OnAction()
                var
                    SecretInput: Page "IKA DN Secret Input";
                begin
                    if SecretInput.RunModal() = Action::OK then begin
                        Rec.SetGraphClientSecret(SecretInput.GetSecret());
                        UpdateStatusTexts();
                    end;
                end;
            }
            action(GetDriveId)
            {
                ApplicationArea = All;
                Caption = 'Obtener Drive Id';
                Image = LinkWeb;
                ToolTip = 'Obtiene el Drive Id de la biblioteca de documentos del sitio SharePoint indicado.';

                trigger OnAction()
                var
                    GraphClient: Codeunit "IKA DN Graph Client";
                begin
                    CurrPage.SaveRecord();
                    Rec.TestField("Drive Site");
                    Rec."Drive Id" := CopyStr(GraphClient.ResolveDriveId(), 1, MaxStrLen(Rec."Drive Id"));
                    Rec.Modify();
                end;
            }
            action(TestClaude)
            {
                ApplicationArea = All;
                Caption = 'Probar conexión con Claude';
                Image = TestDatabase;
                ToolTip = 'Llamada mínima a la API para comprobar la API key y el modelo.';

                trigger OnAction()
                var
                    ClaudeClient: Codeunit "IKA DN Claude Client";
                begin
                    CurrPage.SaveRecord();
                    Message('%1', ClaudeClient.TestConnection());
                end;
            }
            action(TestGraph)
            {
                ApplicationArea = All;
                Caption = 'Probar conexión con Graph';
                Image = TestDatabase;
                ToolTip = 'Comprueba el acceso al buzón y/o a la carpeta.';

                trigger OnAction()
                var
                    GraphClient: Codeunit "IKA DN Graph Client";
                begin
                    CurrPage.SaveRecord();
                    Message('%1', GraphClient.TestConnection());
                end;
            }
            action(RunNow)
            {
                ApplicationArea = All;
                Caption = 'Ejecutar ahora';
                Image = ExecuteBatch;
                ToolTip = 'Importa y procesa ahora mismo, como lo haría la cola de proyectos.';

                trigger OnAction()
                var
                    DNJob: Codeunit "IKA DN Job";
                begin
                    CurrPage.SaveRecord();
                    Commit();
                    DNJob.RunAgent();
                    Message(RunDoneMsg);
                end;
            }
            action(CreateJobQueue)
            {
                ApplicationArea = All;
                Caption = 'Crear entrada de cola de proyectos';
                Image = Job;
                ToolTip = 'Crea la tarea recurrente.';

                trigger OnAction()
                var
                    DNJob: Codeunit "IKA DN Job";
                begin
                    CurrPage.SaveRecord();
                    DNJob.CreateJobQueueEntry();
                end;
            }
        }
        area(Navigation)
        {
            action(MailAccounts)
            {
                ApplicationArea = All;
                Caption = 'Cuentas de Outlook 365';
                Image = Email;
                RunObject = page "IKA DN Mail Accounts";
                ToolTip = 'Cuentas de correo (la suya u otras) que puede usar el agente.';
            }
            action(Templates)
            {
                ApplicationArea = All;
                Caption = 'Plantillas de proveedor';
                Image = Template;
                RunObject = page "IKA DN Vendor Templates";
                ToolTip = 'Conocimiento por proveedor: identificación, alias, instrucciones y ejemplo.';
            }
            action(GlobalAliases)
            {
                ApplicationArea = All;
                Caption = 'Alias de campos (globales)';
                Image = SetupList;
                RunObject = page "IKA DN Field Aliases";
                RunPageView = where("Vendor No." = const(''));
                ToolTip = 'Nombres habituales de los campos válidos para todos los proveedores.';
            }
            action(Documents)
            {
                ApplicationArea = All;
                Caption = 'Bandeja de albaranes';
                Image = Documents;
                RunObject = page "IKA DN Documents";
                ToolTip = 'Albaranes recibidos.';
            }
            action(Log)
            {
                ApplicationArea = All;
                Caption = 'Registro';
                Image = Log;
                RunObject = page "IKA DN Log";
                ToolTip = 'Registro de llamadas y eventos.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(SetClaudeApiKey_Promoted; SetClaudeApiKey) { }
                actionref(SetGraphSecret_Promoted; SetGraphSecret) { }
                actionref(TestClaude_Promoted; TestClaude) { }
                actionref(TestGraph_Promoted; TestGraph) { }
                actionref(RunNow_Promoted; RunNow) { }
                actionref(CreateJobQueue_Promoted; CreateJobQueue) { }
            }
            group(Category_Navigate)
            {
                Caption = 'Navegar';

                actionref(MailAccounts_Promoted; MailAccounts) { }
                actionref(Templates_Promoted; Templates) { }
                actionref(GlobalAliases_Promoted; GlobalAliases) { }
                actionref(Documents_Promoted; Documents) { }
                actionref(Log_Promoted; Log) { }
            }
        }
    }

    var
        ClaudeApiKeyStatus: Text;
        GraphSecretStatus: Text;
        ConfiguredTxt: Label 'Configurada ✔';
        NotConfiguredTxt: Label 'No configurada';
        RunDoneMsg: Label 'Ejecución terminada. Revise la bandeja de albaranes y el registro.';

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
        UpdateStatusTexts();
    end;

    local procedure UpdateStatusTexts()
    begin
        if Rec.HasClaudeApiKey() then
            ClaudeApiKeyStatus := ConfiguredTxt
        else
            ClaudeApiKeyStatus := NotConfiguredTxt;
        if Rec.HasGraphClientSecret() then
            GraphSecretStatus := ConfiguredTxt
        else
            GraphSecretStatus := NotConfiguredTxt;
    end;
}
