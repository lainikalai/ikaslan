page 50020 "IKA Sales Requests"
{
    Caption = 'Bandeja de solicitudes de venta (Claude)';
    PageType = List;
    SourceTable = "IKA Sales Request Header";
    SourceTableView = sorting("Entry No.") order(descending);
    CardPageId = "IKA Sales Request";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }
                field(Source; Rec.Source)
                {
                    ApplicationArea = All;
                }
                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = All;
                }
                field("Sender Address"; Rec."Sender Address")
                {
                    ApplicationArea = All;
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = All;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                }
                field("Customer Match Status"; Rec."Customer Match Status")
                {
                    ApplicationArea = All;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = All;
                }
                field("No. of Lines"; Rec."No. of Lines")
                {
                    ApplicationArea = All;
                }
                field("No. of Unresolved Lines"; Rec."No. of Unresolved Lines")
                {
                    ApplicationArea = All;
                }
                field(Confidence; Rec.Confidence)
                {
                    ApplicationArea = All;
                }
                field("Sales Order No."; Rec."Sales Order No.")
                {
                    ApplicationArea = All;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                }
                field("Input Tokens"; Rec."Input Tokens")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Output Tokens"; Rec."Output Tokens")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(NewManual)
            {
                ApplicationArea = All;
                Caption = 'Nueva desde fichero';
                Image = Import;
                ToolTip = 'Crea una solicitud manual a partir de un fichero (PDF, imagen, Excel...) y la procesa con Claude.';

                trigger OnAction()
                var
                    RequestHeader: Record "IKA Sales Request Header";
                    RequestAttachment: Record "IKA Sales Request Attachment";
                begin
                    RequestHeader.Init();
                    RequestHeader.Source := RequestHeader.Source::Manual;
                    RequestHeader.Insert(true);
                    RequestAttachment.ImportFromClient(RequestHeader."Entry No.");
                    RequestAttachment.SetRange("Request Entry No.", RequestHeader."Entry No.");
                    if RequestAttachment.IsEmpty() then begin
                        RequestHeader.Delete(true);
                        exit;
                    end;
                    RequestHeader.Subject := CopyStr(RequestAttachment."File Name", 1, MaxStrLen(RequestHeader.Subject));
                    RequestHeader.Modify();
                    Commit();
                    Page.Run(Page::"IKA Sales Request", RequestHeader);
                end;
            }
            action(RunAgent)
            {
                ApplicationArea = All;
                Caption = 'Leer buzón y procesar';
                Image = ExecuteBatch;
                ToolTip = 'Ejecuta el agente ahora: importa emails nuevos y procesa las solicitudes pendientes.';

                trigger OnAction()
                var
                    SalesAgentJob: Codeunit "IKA Sales Agent Job";
                begin
                    SalesAgentJob.RunAgent();
                    CurrPage.Update(false);
                end;
            }
            action(ProcessSelected)
            {
                ApplicationArea = All;
                Caption = 'Procesar seleccionadas';
                Image = Process;
                ToolTip = 'Procesa con Claude las solicitudes seleccionadas que estén nuevas o con error.';

                trigger OnAction()
                var
                    RequestHeader: Record "IKA Sales Request Header";
                    SalesAgentJob: Codeunit "IKA Sales Agent Job";
                begin
                    CurrPage.SetSelectionFilter(RequestHeader);
                    RequestHeader.SetFilter(Status, '%1|%2', RequestHeader.Status::New, RequestHeader.Status::Error);
                    if RequestHeader.FindSet() then
                        repeat
                            SalesAgentJob.ProcessOne(RequestHeader);
                        until RequestHeader.Next() = 0;
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(Setup)
            {
                ApplicationArea = All;
                Caption = 'Configuración';
                Image = Setup;
                RunObject = page "IKA Sales Agent Setup";
                ToolTip = 'Configuración del agente de ventas.';
            }
            action(Log)
            {
                ApplicationArea = All;
                Caption = 'Registro';
                Image = Log;
                RunObject = page "IKA Sales Agent Log";
                RunPageLink = "Request Entry No." = field("Entry No.");
                ToolTip = 'Registro de la solicitud seleccionada.';
            }
            action(SalesOrder)
            {
                ApplicationArea = All;
                Caption = 'Pedido de venta';
                Image = Document;
                Enabled = Rec."Sales Order No." <> '';
                ToolTip = 'Abre el pedido de venta creado.';

                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."Sales Order No.");
                    Page.Run(Page::"Sales Order", SalesHeader);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(NewManual_Promoted; NewManual) { }
                actionref(RunAgent_Promoted; RunAgent) { }
                actionref(ProcessSelected_Promoted; ProcessSelected) { }
            }
            group(Category_Navigate)
            {
                Caption = 'Navegar';

                actionref(SalesOrder_Promoted; SalesOrder) { }
                actionref(Log_Promoted; Log) { }
                actionref(Setup_Promoted; Setup) { }
            }
        }
    }

    views
    {
        view(Pending)
        {
            Caption = 'Pendientes de revisión';
            Filters = where(Status = filter("Needs Review" | Ready | Error));
        }
        view(Created)
        {
            Caption = 'Pedido creado';
            Filters = where(Status = const("Order Created"));
        }
    }

    var
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec.Status of
            Rec.Status::Error:
                StatusStyle := 'Unfavorable';
            Rec.Status::"Needs Review":
                StatusStyle := 'Ambiguous';
            Rec.Status::Ready, Rec.Status::"Order Created":
                StatusStyle := 'Favorable';
            else
                StatusStyle := 'Standard';
        end;
    end;
}
