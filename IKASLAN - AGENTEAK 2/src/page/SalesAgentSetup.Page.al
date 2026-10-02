page 50000 "IKA Sales Agent Setup"
{
    Caption = 'Configuración agente de ventas (Claude)';
    PageType = Card;
    SourceTable = "IKA Sales Agent Setup";
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
                    ToolTip = 'Activa la ejecución automática del agente desde la cola de proyectos.';
                }
                field("Auto Create Orders"; Rec."Auto Create Orders")
                {
                    ApplicationArea = All;
                    ToolTip = 'Si está activo, las solicitudes en estado "Lista para crear" generan el pedido sin intervención. Si no, todas quedan en la bandeja para revisión.';
                }
                field("Min. Confidence Auto Create"; Rec."Min. Confidence Auto Create")
                {
                    ApplicationArea = All;
                    ToolTip = 'Confianza mínima (0-1) declarada por Claude para considerar una solicitud lista.';
                }
                field("Allow Description Match"; Rec."Allow Description Match")
                {
                    ApplicationArea = All;
                    ToolTip = 'Permite identificar productos por su descripción cuando no hay código.';
                }
                field("Unmatched Lines as Comments"; Rec."Unmatched Lines as Comments")
                {
                    ApplicationArea = All;
                    ToolTip = 'Las líneas sin producto identificado se añaden al pedido como comentario para no perderlas.';
                }
                field("Job Interval (min)"; Rec."Job Interval (min)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cada cuántos minutos se ejecuta la cola de proyectos.';
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
                    ToolTip = 'La API key se guarda cifrada en Isolated Storage. Use la acción "Establecer API key de Claude".';
                }
                field("Claude Model"; Rec."Claude Model")
                {
                    ApplicationArea = All;
                    ToolTip = 'Id del modelo. Por defecto claude-opus-5-5. Alternativa más económica: claude-sonnet-5-5.';
                }
                field("Claude Effort"; Rec."Claude Effort")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cuánto razona el modelo. Medio es un buen equilibrio para extracción de pedidos; súbalo si hay errores en documentos complejos.';
                }
                field("Claude Max Tokens"; Rec."Claude Max Tokens")
                {
                    ApplicationArea = All;
                    ToolTip = 'Máximo de tokens de la respuesta. Auméntelo si los pedidos tienen muchas líneas y la respuesta se corta.';
                }
                field("Claude Timeout (sec)"; Rec."Claude Timeout (sec)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Tiempo máximo de espera de la llamada a Claude.';
                }
                field("Use Refusal Fallback"; Rec."Use Refusal Fallback")
                {
                    ApplicationArea = All;
                    ToolTip = 'Si el modelo rechaza una petición por sus filtros de seguridad (falso positivo), la API la reintenta con otro modelo automáticamente.';
                }
                field("Claude Endpoint"; Rec."Claude Endpoint")
                {
                    ApplicationArea = All;
                    ToolTip = 'URL de la Messages API.';
                }
                field("Extra Instructions"; Rec."Extra Instructions")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Reglas propias que se añaden al prompt. Ej.: "Los pedidos del cliente X vienen siempre en cajas de 12 unidades".';
                }
            }
            group(Outlook)
            {
                Caption = 'Outlook (Microsoft Graph)';

                field("Graph Tenant Id"; Rec."Graph Tenant Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Id de directorio (tenant) de Entra ID.';
                }
                field("Graph Client Id"; Rec."Graph Client Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Id de aplicación (cliente) del registro de aplicación con permiso Mail.ReadWrite.';
                }
                field(GraphSecretStatus; GraphSecretStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Secreto de cliente';
                    Editable = false;
                    ToolTip = 'El secreto se guarda cifrado en Isolated Storage. Use la acción "Establecer secreto de Graph".';
                }
                field("Mailbox Address"; Rec."Mailbox Address")
                {
                    ApplicationArea = All;
                    ToolTip = 'Buzón del que se leen los pedidos (p.ej. pedidos@empresa.com).';
                }
                field("Source Folder"; Rec."Source Folder")
                {
                    ApplicationArea = All;
                    ToolTip = 'Carpeta a leer: inbox, el nombre de una subcarpeta de la bandeja de entrada o de primer nivel, o su id.';
                }
                field("Processed Folder"; Rec."Processed Folder")
                {
                    ApplicationArea = All;
                    ToolTip = 'Carpeta a la que se mueven los emails procesados. Vacío = no se mueven.';
                }
                field("Error Folder"; Rec."Error Folder")
                {
                    ApplicationArea = All;
                    ToolTip = 'Carpeta a la que se mueven los emails con error. Vacío = no se mueven.';
                }
                field("Only Unread"; Rec."Only Unread")
                {
                    ApplicationArea = All;
                    ToolTip = 'Leer solo emails no leídos.';
                }
                field("Mark as Read"; Rec."Mark as Read")
                {
                    ApplicationArea = All;
                    ToolTip = 'Marcar como leídos los emails importados.';
                }
                field("Max Emails per Run"; Rec."Max Emails per Run")
                {
                    ApplicationArea = All;
                    ToolTip = 'Máximo de emails a importar en cada ejecución.';
                }
                field("Max Attachment Size (KB)"; Rec."Max Attachment Size (KB)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Los adjuntos mayores no se envían a Claude.';
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
                ToolTip = 'Introduce la API key de Anthropic (console.anthropic.com).';

                trigger OnAction()
                var
                    SecretInput: Page "IKA Secret Input";
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
                ToolTip = 'Introduce el secreto de cliente del registro de aplicación de Entra ID.';

                trigger OnAction()
                var
                    SecretInput: Page "IKA Secret Input";
                begin
                    if SecretInput.RunModal() = Action::OK then begin
                        Rec.SetGraphClientSecret(SecretInput.GetSecret());
                        UpdateStatusTexts();
                    end;
                end;
            }
            action(TestClaude)
            {
                ApplicationArea = All;
                Caption = 'Probar conexión con Claude';
                Image = TestDatabase;
                ToolTip = 'Hace una llamada mínima a la API para comprobar la API key y el modelo.';

                trigger OnAction()
                var
                    ClaudeApiClient: Codeunit "IKA Claude API Client";
                begin
                    CurrPage.SaveRecord();
                    Message('%1', ClaudeApiClient.TestConnection());
                end;
            }
            action(TestGraph)
            {
                ApplicationArea = All;
                Caption = 'Probar conexión con Outlook';
                Image = TestDatabase;
                ToolTip = 'Comprueba el acceso al buzón y a la carpeta origen.';

                trigger OnAction()
                var
                    GraphMailClient: Codeunit "IKA Graph Mail Client";
                begin
                    CurrPage.SaveRecord();
                    Message('%1', GraphMailClient.TestConnection());
                end;
            }
            action(RunNow)
            {
                ApplicationArea = All;
                Caption = 'Ejecutar ahora';
                Image = ExecuteBatch;
                ToolTip = 'Lee el buzón y procesa las solicitudes nuevas ahora mismo (como lo haría la cola de proyectos).';

                trigger OnAction()
                var
                    SalesAgentJob: Codeunit "IKA Sales Agent Job";
                begin
                    CurrPage.SaveRecord();
                    Commit();
                    SalesAgentJob.RunAgent();
                    Message(RunDoneMsg);
                end;
            }
            action(CreateJobQueue)
            {
                ApplicationArea = All;
                Caption = 'Crear entrada de cola de proyectos';
                Image = Job;
                ToolTip = 'Crea la tarea recurrente que lee el buzón y procesa los pedidos.';

                trigger OnAction()
                var
                    SalesAgentJob: Codeunit "IKA Sales Agent Job";
                begin
                    CurrPage.SaveRecord();
                    SalesAgentJob.CreateJobQueueEntry();
                end;
            }
        }
        area(Navigation)
        {
            action(MailFilters)
            {
                ApplicationArea = All;
                Caption = 'Filtros de correo';
                Image = FilterLines;
                RunObject = page "IKA Sales Agent Mail Filters";
                ToolTip = 'Remitentes y asuntos que se procesan.';
            }
            action(Requests)
            {
                ApplicationArea = All;
                Caption = 'Bandeja de solicitudes';
                Image = Documents;
                RunObject = page "IKA Sales Requests";
                ToolTip = 'Solicitudes de venta recibidas.';
            }
            action(Log)
            {
                ApplicationArea = All;
                Caption = 'Registro';
                Image = Log;
                RunObject = page "IKA Sales Agent Log";
                ToolTip = 'Registro de llamadas y eventos del agente.';
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

                actionref(MailFilters_Promoted; MailFilters) { }
                actionref(Requests_Promoted; Requests) { }
                actionref(Log_Promoted; Log) { }
            }
        }
    }

    var
        ClaudeApiKeyStatus: Text;
        GraphSecretStatus: Text;
        ConfiguredTxt: Label 'Configurada ✔';
        NotConfiguredTxt: Label 'No configurada';
        RunDoneMsg: Label 'Ejecución terminada. Revise la bandeja de solicitudes y el registro.';

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
