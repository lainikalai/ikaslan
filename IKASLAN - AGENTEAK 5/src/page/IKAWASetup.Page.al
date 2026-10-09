page 99301 "IKA WA Setup"
{
    Caption = 'Configuración WhatsApp';
    PageType = Card;
    SourceTable = "IKA WA Setup";
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

                field("Default Account Code"; Rec."Default Account Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cuenta que se propone al enviar.';
                }
                field("Default Country Code"; Rec."Default Country Code")
                {
                    ApplicationArea = All;
                }
                field("Auto Link by Phone"; Rec."Auto Link by Phone")
                {
                    ApplicationArea = All;
                    ToolTip = 'Vincula las conversaciones nuevas al cliente, proveedor o contacto con ese teléfono.';
                }
                field("Open My Conversations"; Rec."Open My Conversations")
                {
                    ApplicationArea = All;
                }
                field("Send Read Receipts"; Rec."Send Read Receipts")
                {
                    ApplicationArea = All;
                }
                field("Download Inbound Media"; Rec."Download Inbound Media")
                {
                    ApplicationArea = All;
                }
                field("Max Media Size (MB)"; Rec."Max Media Size (MB)")
                {
                    ApplicationArea = All;
                    ToolTip = 'Límite para enviar y descargar ficheros (WhatsApp admite hasta 100 MB en documentos y 5 MB en imágenes).';
                }
            }
            group(Api)
            {
                Caption = 'API de Meta';

                field("Graph API Base URL"; Rec."Graph API Base URL")
                {
                    ApplicationArea = All;
                }
                field("Graph API Version"; Rec."Graph API Version")
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
            action(ProcessInbound)
            {
                ApplicationArea = All;
                Caption = 'Procesar mensajes recibidos';
                Image = Refresh;
                ToolTip = 'Procesa ahora los eventos que ha dejado la Azure Function.';

                trigger OnAction()
                var
                    InboundProcessor: Codeunit "IKA WA Inbound Processor";
                    ProcessedMsg: Label '%1 evento(s) procesado(s).', Comment = '%1 = count';
                begin
                    Message(ProcessedMsg, InboundProcessor.ProcessPending());
                end;
            }
            action(FillSalespersons)
            {
                ApplicationArea = All;
                Caption = 'Asignar comerciales a las conversaciones';
                Image = SalesPurchaseTeam;
                ToolTip = 'Rellena el comercial de las conversaciones vinculadas que no lo tienen, con el vendedor del cliente o contacto o el comprador del proveedor.';

                trigger OnAction()
                var
                    ChatMgt: Codeunit "IKA WA Chat Mgt.";
                    UpdatedMsg: Label '%1 conversación(es) actualizada(s).', Comment = '%1 = count';
                begin
                    Message(UpdatedMsg, ChatMgt.FillMissingSalespersons());
                end;
            }
            action(CreateJobQueue)
            {
                ApplicationArea = All;
                Caption = 'Crear entrada de cola de proyectos';
                Image = Job;
                ToolTip = 'Procesa automáticamente los mensajes recibidos cada 2 minutos.';

                trigger OnAction()
                var
                    WAJob: Codeunit "IKA WA Job";
                begin
                    WAJob.CreateJobQueueEntry();
                end;
            }
        }
        area(Navigation)
        {
            action(Accounts)
            {
                ApplicationArea = All;
                Caption = 'Cuentas de WhatsApp';
                Image = Setup;
                RunObject = page "IKA WA Accounts";
                ToolTip = 'Números de WhatsApp Business.';
            }
            action(Templates)
            {
                ApplicationArea = All;
                Caption = 'Plantillas';
                Image = Template;
                RunObject = page "IKA WA Templates";
                ToolTip = 'Plantillas aprobadas por Meta y sus variables.';
            }
            action(Conversations)
            {
                ApplicationArea = All;
                Caption = 'Conversaciones';
                Image = Documents;
                RunObject = page "IKA WA Conversations";
                ToolTip = 'Bandeja de WhatsApp.';
            }
            action(QuickReplies)
            {
                ApplicationArea = All;
                Caption = 'Respuestas rápidas';
                Image = Text;
                RunObject = page "IKA WA Quick Replies";
                ToolTip = 'Textos predefinidos que se insertan con un clic en el chat.';
            }
            action(InboundEvents)
            {
                ApplicationArea = All;
                Caption = 'Eventos recibidos';
                Image = Log;
                RunObject = page "IKA WA Inbound Events";
                ToolTip = 'Lo que ha llegado desde la Azure Function, procesado o con error.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(Accounts_Promoted; Accounts) { }
                actionref(Templates_Promoted; Templates) { }
                actionref(Conversations_Promoted; Conversations) { }
                actionref(QuickReplies_Promoted; QuickReplies) { }
                actionref(ProcessInbound_Promoted; ProcessInbound) { }
                actionref(CreateJobQueue_Promoted; CreateJobQueue) { }
                actionref(InboundEvents_Promoted; InboundEvents) { }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.GetSetup();
    end;
}
