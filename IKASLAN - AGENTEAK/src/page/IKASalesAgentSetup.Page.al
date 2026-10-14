page 99001 "IKA Sales Agent Setup"
{
    Caption = 'Configuración agentes (Claude)';
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
            group(Claude)
            {
                Caption = 'Claude (Anthropic)';

                field(ClaudeApiKeyStatus; ClaudeApiKeyStatus)
                {
                    ApplicationArea = All;
                    Caption = 'API key';
                    Editable = false;
                    ToolTip = 'La API key se guarda cifrada en Isolated Storage. Use la acción "Establecer API key de Claude". Debe estar creada dentro de un workspace de console.anthropic.com.';
                }
                field("Claude Model"; Rec."Claude Model")
                {
                    ApplicationArea = All;
                    ToolTip = 'Id del modelo. Por defecto claude-opus-5-5. Alternativa más económica: claude-sonnet-5-5.';
                }
                field("Claude Effort"; Rec."Claude Effort")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cuánto razona el modelo. Medio es un buen equilibrio; súbalo si hay errores en documentos complejos.';
                }
                field("Claude Max Tokens"; Rec."Claude Max Tokens")
                {
                    ApplicationArea = All;
                    ToolTip = 'Máximo de tokens de la respuesta. Auméntelo si los documentos tienen muchas líneas y la respuesta se corta.';
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
                field("Anthropic Workspace Id"; Rec."Anthropic Workspace Id")
                {
                    ApplicationArea = All;
                }
                field(AdminKeyStatus; AdminKeyStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Admin API key (costes reales)';
                    Editable = false;
                    ToolTip = 'Opcional. Solo para descargar de Anthropic el coste real facturado y compararlo con el calculado en BC. Se crea en Claude Console > Settings > Admin keys (requiere una organización y el rol admin). Use la acción "Establecer Admin API key".';
                }
            }
            group(Graph)
            {
                Caption = 'Microsoft Graph (credenciales generales)';
                InstructionalText = 'Solo se usan para las cuentas de Outlook que no tienen credenciales propias y para la carpeta de SharePoint. Si todas las cuentas tienen credenciales propias y no se usa la carpeta, pueden quedar vacías.';

                field("Graph Tenant Id"; Rec."Graph Tenant Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Id de directorio (tenant) de Entra ID de las credenciales generales.';
                }
                field("Graph Client Id"; Rec."Graph Client Id")
                {
                    ApplicationArea = All;
                    ToolTip = 'Id de aplicación (cliente) del registro de aplicación con permiso Mail.ReadWrite (y Sites.Selected si se usa la carpeta).';
                }
                field(GraphSecretStatus; GraphSecretStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Secreto de cliente';
                    Editable = false;
                    ToolTip = 'Secreto de las credenciales generales, cifrado en Isolated Storage. Use la acción "Establecer secreto de Graph".';
                }
            }
            group(SalesOrders)
            {
                Caption = 'Pedidos de venta (emails de clientes)';

                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    Caption = 'Agente de pedidos activado';
                    ToolTip = 'Activa la ejecución del agente de pedidos de venta (cola de proyectos y "Ejecutar ahora").';
                }
                field("Mail Account Code"; Rec."Mail Account Code")
                {
                    ApplicationArea = All;
                    Caption = 'Cuenta de Outlook 365 (pedidos)';
                    ToolTip = 'Cuenta (buzón) de la que se leen los pedidos (la carpeta origen es la de la cuenta).';
                }
                field("Processed Folder"; Rec."Processed Folder")
                {
                    ApplicationArea = All;
                    Caption = 'Carpeta procesados (pedidos)';
                    ToolTip = 'Carpeta a la que se mueven los emails procesados. Vacío = no se mueven.';
                }
                field("Error Folder"; Rec."Error Folder")
                {
                    ApplicationArea = All;
                    Caption = 'Carpeta errores (pedidos)';
                    ToolTip = 'Carpeta a la que se mueven los emails con error. Vacío = no se mueven.';
                }
                field("Only Unread"; Rec."Only Unread")
                {
                    ApplicationArea = All;
                    Caption = 'Solo no leídos (pedidos)';
                    ToolTip = 'Leer solo emails no leídos.';
                }
                field("Mark as Read"; Rec."Mark as Read")
                {
                    ApplicationArea = All;
                    Caption = 'Marcar como leído (pedidos)';
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
                    Caption = 'Intervalo cola de proyectos (min) (pedidos)';
                    ToolTip = 'Cada cuántos minutos se ejecuta la cola de proyectos de pedidos.';
                }
                field("Extra Instructions"; Rec."Extra Instructions")
                {
                    ApplicationArea = All;
                    Caption = 'Instrucciones adicionales para Claude (pedidos)';
                    MultiLine = true;
                    ToolTip = 'Reglas propias que se añaden al prompt de todos los pedidos. Las de cada cliente van en su filtro de correo o en su ficha.';
                }
            }
            group(DeliveryNotes)
            {
                Caption = 'Albaranes de compra (emails de proveedores)';

                field("DN Enabled"; Rec."DN Enabled")
                {
                    ApplicationArea = All;
                    ToolTip = 'Activa la ejecución del agente de albaranes (cola de proyectos y "Ejecutar ahora").';
                }
                field("DN Mail Enabled"; Rec."DN Mail Enabled")
                {
                    ApplicationArea = All;
                }
                field("DN Mail Account Code"; Rec."DN Mail Account Code")
                {
                    ApplicationArea = All;
                }
                field("DN Processed Folder"; Rec."DN Processed Folder")
                {
                    ApplicationArea = All;
                    ToolTip = 'Carpeta del buzón a la que se mueven los emails procesados. Vacío = no se mueven.';
                }
                field("DN Error Folder"; Rec."DN Error Folder")
                {
                    ApplicationArea = All;
                    ToolTip = 'Carpeta del buzón a la que se mueven los emails con error. Vacío = no se mueven.';
                }
                field("DN Only Unread"; Rec."DN Only Unread")
                {
                    ApplicationArea = All;
                }
                field("DN Mark as Read"; Rec."DN Mark as Read")
                {
                    ApplicationArea = All;
                }
                field("DN Max Documents per Run"; Rec."DN Max Documents per Run")
                {
                    ApplicationArea = All;
                    ToolTip = 'Máximo de emails / ficheros a importar en cada ejecución.';
                }
                field("DN Max File Size (KB)"; Rec."DN Max File Size (KB)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Los ficheros mayores no se procesan.';
                }
                field("DN Min. Confidence"; Rec."DN Min. Confidence")
                {
                    ApplicationArea = All;
                    ToolTip = 'Confianza mínima (0-1) declarada por Claude para dar el albarán por conciliado.';
                }
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
                field("DN Allow Description Match"; Rec."DN Allow Description Match")
                {
                    ApplicationArea = All;
                    ToolTip = 'Permite identificar productos por descripción (primero en los pedidos abiertos del proveedor).';
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
                field("DN Job Interval (min)"; Rec."DN Job Interval (min)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cada cuántos minutos se ejecuta la cola de proyectos de albaranes.';
                }
                field("DN Extra Instructions"; Rec."DN Extra Instructions")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    ToolTip = 'Reglas que se aplican a todos los albaranes. Las de cada proveedor van en las instrucciones de su filtro de correo.';
                }
            }
            group(Folder)
            {
                Caption = 'Carpeta SharePoint / OneDrive (albaranes)';

                field("DN Folder Enabled"; Rec."DN Folder Enabled")
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
                ToolTip = 'Introduce la API key de Anthropic (console.anthropic.com), creada dentro de un workspace.';

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
                ToolTip = 'Introduce el secreto de cliente de las credenciales generales de Entra ID.';

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
            action(SetAdminKey)
            {
                ApplicationArea = All;
                Caption = 'Establecer Admin API key';
                Image = EncryptionKeys;
                ToolTip = 'Introduce la Admin API key de Anthropic (sk-ant-admin01-...), solo para consultar los costes reales. Déjela vacía para borrarla.';

                trigger OnAction()
                var
                    SecretInput: Page "IKA Secret Input";
                begin
                    if SecretInput.RunModal() = Action::OK then begin
                        Rec.SetAdminApiKey(SecretInput.GetSecret());
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
            group(SalesActions)
            {
                Caption = 'Pedidos de venta';
                Image = Sales;

                action(TestGraph)
                {
                    ApplicationArea = All;
                    Caption = 'Probar conexión con Outlook (pedidos)';
                    Image = TestDatabase;
                    ToolTip = 'Comprueba el acceso al buzón de pedidos y a su carpeta origen.';

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
                    Caption = 'Ejecutar ahora (pedidos)';
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
                    Caption = 'Crear entrada de cola de proyectos (pedidos)';
                    Image = Job;
                    ToolTip = 'Crea la tarea recurrente que lee el buzón y procesa los pedidos (codeunit 99051).';

                    trigger OnAction()
                    var
                        SalesAgentJob: Codeunit "IKA Sales Agent Job";
                    begin
                        CurrPage.SaveRecord();
                        SalesAgentJob.CreateJobQueueEntry();
                    end;
                }
            }
            group(DeliveryNoteActions)
            {
                Caption = 'Albaranes';
                Image = Purchasing;

                action(TestGraphDN)
                {
                    ApplicationArea = All;
                    Caption = 'Probar conexión con Outlook (albaranes)';
                    Image = TestDatabase;
                    ToolTip = 'Comprueba el acceso al buzón de albaranes y, si está activada, a la carpeta.';

                    trigger OnAction()
                    var
                        DNGraphClient: Codeunit "IKA DN Graph Client";
                    begin
                        CurrPage.SaveRecord();
                        Message('%1', DNGraphClient.TestConnection());
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
                        DNGraphClient: Codeunit "IKA DN Graph Client";
                    begin
                        CurrPage.SaveRecord();
                        Rec.TestField("Drive Site");
                        Rec."Drive Id" := CopyStr(DNGraphClient.ResolveDriveId(), 1, MaxStrLen(Rec."Drive Id"));
                        Rec.Modify();
                    end;
                }
                action(RunNowDN)
                {
                    ApplicationArea = All;
                    Caption = 'Ejecutar ahora (albaranes)';
                    Image = ExecuteBatch;
                    ToolTip = 'Lee el buzón y la carpeta y concilia los albaranes nuevos ahora mismo (como lo haría la cola de proyectos).';

                    trigger OnAction()
                    var
                        DNJob: Codeunit "IKA DN Job";
                    begin
                        CurrPage.SaveRecord();
                        Commit();
                        DNJob.RunAgent();
                        Message(RunDoneDNMsg);
                    end;
                }
                action(CreateJobQueueDN)
                {
                    ApplicationArea = All;
                    Caption = 'Crear entrada de cola de proyectos (albaranes)';
                    Image = Job;
                    ToolTip = 'Crea la tarea recurrente que lee el buzón y concilia los albaranes (codeunit 99156).';

                    trigger OnAction()
                    var
                        DNJob: Codeunit "IKA DN Job";
                    begin
                        CurrPage.SaveRecord();
                        DNJob.CreateJobQueueEntry();
                    end;
                }
            }
        }
        area(Navigation)
        {
            action(MailAccounts)
            {
                ApplicationArea = All;
                Caption = 'Cuentas de Outlook 365';
                Image = Email;
                RunObject = page "IKA Sales Mail Accounts";
                ToolTip = 'Cuentas de correo (la suya u otras) que pueden usar los agentes.';
            }
            action(MailFilters)
            {
                ApplicationArea = All;
                Caption = 'Filtros de correo';
                Image = FilterLines;
                RunObject = page "IKA Sales Agent Mail Filters";
                ToolTip = 'Remitentes, asuntos y ficheros que se procesan como pedidos o albaranes, con su cliente o proveedor, instrucciones y ejemplo.';
            }
            action(FieldAliases)
            {
                ApplicationArea = All;
                Caption = 'Alias de campos';
                Image = SetupList;
                RunObject = page "IKA Field Aliases";
                ToolTip = 'Cómo aparecen los campos en los documentos (globales o por cliente / proveedor).';
            }
            action(RealCosts)
            {
                ApplicationArea = All;
                Caption = 'Costes reales (Anthropic)';
                Image = Statistics;
                RunObject = page "IKA Claude Cost Comparison";
                ToolTip = 'Coste facturado por Anthropic frente al calculado en BC, por día y modelo, y tarifa real.';
            }
            action(ModelPrices)
            {
                ApplicationArea = All;
                Caption = 'Precios de Claude';
                Image = Price;
                RunObject = page "IKA Claude Model Prices";
                ToolTip = 'Precio por millón de tokens de cada modelo, para calcular el coste de cada llamada.';
            }
            action(Requests)
            {
                ApplicationArea = All;
                Caption = 'Bandeja de solicitudes de venta';
                Image = Documents;
                RunObject = page "IKA Sales Requests";
                ToolTip = 'Solicitudes de venta recibidas.';
            }
            action(DNDocuments)
            {
                ApplicationArea = All;
                Caption = 'Bandeja de albaranes';
                Image = Documents;
                RunObject = page "IKA DN Documents";
                ToolTip = 'Albaranes de proveedor recibidos.';
            }
            action(Log)
            {
                ApplicationArea = All;
                Caption = 'Registro (pedidos)';
                Image = Log;
                RunObject = page "IKA Sales Agent Log";
                ToolTip = 'Registro de llamadas y eventos del agente de pedidos.';
            }
            action(DNLog)
            {
                ApplicationArea = All;
                Caption = 'Registro (albaranes)';
                Image = Log;
                RunObject = page "IKA DN Log";
                ToolTip = 'Registro de llamadas y eventos del agente de albaranes.';
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
                actionref(TestGraph_Home; TestGraph) { }
                actionref(TestGraphDN_Home; TestGraphDN) { }
            }
            group(Category_Sales)
            {
                Caption = 'Pedidos de venta';

                actionref(TestGraph_Promoted; TestGraph) { }
                actionref(RunNow_Promoted; RunNow) { }
                actionref(CreateJobQueue_Promoted; CreateJobQueue) { }
            }
            group(Category_DeliveryNotes)
            {
                Caption = 'Albaranes';

                actionref(TestGraphDN_Promoted; TestGraphDN) { }
                actionref(GetDriveId_Promoted; GetDriveId) { }
                actionref(RunNowDN_Promoted; RunNowDN) { }
                actionref(CreateJobQueueDN_Promoted; CreateJobQueueDN) { }
            }
            group(Category_Navigate)
            {
                Caption = 'Navegar';

                actionref(MailAccounts_Promoted; MailAccounts) { }
                actionref(MailFilters_Promoted; MailFilters) { }
                actionref(FieldAliases_Promoted; FieldAliases) { }
                actionref(ModelPrices_Promoted; ModelPrices) { }
                actionref(RealCosts_Promoted; RealCosts) { }
                actionref(Requests_Promoted; Requests) { }
                actionref(DNDocuments_Promoted; DNDocuments) { }
                actionref(Log_Promoted; Log) { }
                actionref(DNLog_Promoted; DNLog) { }
            }
        }
    }

    var
        ClaudeApiKeyStatus: Text;
        GraphSecretStatus: Text;
        AdminKeyStatus: Text;
        ConfiguredTxt: Label 'Configurada ✔';
        NotConfiguredTxt: Label 'No configurada';
        RunDoneMsg: Label 'Ejecución terminada. Revise la bandeja de solicitudes y el registro.';
        RunDoneDNMsg: Label 'Ejecución terminada. Revise la bandeja de albaranes y el registro.';

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
        if Rec.HasAdminApiKey() then
            AdminKeyStatus := ConfiguredTxt
        else
            AdminKeyStatus := NotConfiguredTxt;
    end;
}
