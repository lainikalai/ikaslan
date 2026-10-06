page 99016 "IKA Sales Request"
{
    Caption = 'Solicitud de venta (Claude)';
    PageType = Document;
    SourceTable = "IKA Sales Request Header";
    UsageCategory = None;
    DataCaptionFields = "Entry No.", Subject;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Editable = false;
                    StyleExpr = StatusStyle;
                }
                field(Source; Rec.Source)
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Error Message"; Rec."Error Message")
                {
                    ApplicationArea = All;
                    Caption = 'Pendiente de revisar';
                    MultiLine = true;
                    Editable = false;
                    Style = Attention;
                }
                field("Sales Order No."; Rec."Sales Order No.")
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    begin
                        OpenSalesOrder();
                    end;
                }
            }
            group(OrderGroup)
            {
                Caption = 'Pedido (resuelto en BC)';
                Editable = IsEditable;

                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                    StyleExpr = CustomerStyle;
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                }
                field("Customer Match Status"; Rec."Customer Match Status")
                {
                    ApplicationArea = All;
                    StyleExpr = CustomerStyle;
                }
                field("Customer Match Method"; Rec."Customer Match Method")
                {
                    ApplicationArea = All;
                }
                field("Ship-to Code"; Rec."Ship-to Code")
                {
                    ApplicationArea = All;
                }
                field("External Document No."; Rec."External Document No.")
                {
                    ApplicationArea = All;
                }
                field("Requested Delivery Date"; Rec."Requested Delivery Date")
                {
                    ApplicationArea = All;
                }
                field(Comments; Rec.Comments)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                }
                field("Possible Duplicate"; Rec."Possible Duplicate")
                {
                    ApplicationArea = All;
                }
            }
            part(Lines; "IKA Sales Request Subform")
            {
                ApplicationArea = All;
                Caption = 'Líneas';
                SubPageLink = "Request Entry No." = field("Entry No.");
                Editable = IsEditable;
                UpdatePropagation = Both;
            }
            group(Extracted)
            {
                Caption = 'Datos extraídos por Claude';
                Editable = false;

                field("Ext. Customer Code"; Rec."Ext. Customer Code")
                {
                    ApplicationArea = All;
                }
                field("Ext. Customer Name"; Rec."Ext. Customer Name")
                {
                    ApplicationArea = All;
                }
                field("Ext. VAT Registration No."; Rec."Ext. VAT Registration No.")
                {
                    ApplicationArea = All;
                }
                field("Ext. Customer E-Mail"; Rec."Ext. Customer E-Mail")
                {
                    ApplicationArea = All;
                }
                field("Ext. Customer Order No."; Rec."Ext. Customer Order No.")
                {
                    ApplicationArea = All;
                }
                field("Ext. Requested Delivery Date"; Rec."Ext. Requested Delivery Date")
                {
                    ApplicationArea = All;
                }
                field("Ext. Ship-to Name"; Rec."Ext. Ship-to Name")
                {
                    ApplicationArea = All;
                }
                field("Ext. Ship-to Address"; Rec."Ext. Ship-to Address")
                {
                    ApplicationArea = All;
                }
                field("Ext. Ship-to Post Code"; Rec."Ext. Ship-to Post Code")
                {
                    ApplicationArea = All;
                }
                field("Ext. Ship-to City"; Rec."Ext. Ship-to City")
                {
                    ApplicationArea = All;
                }
                field(Confidence; Rec.Confidence)
                {
                    ApplicationArea = All;
                }
                field("Claude Warnings"; Rec."Claude Warnings")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                }
                field("Claude Model"; Rec."Claude Model")
                {
                    ApplicationArea = All;
                }
                field("Input Tokens"; Rec."Input Tokens")
                {
                    ApplicationArea = All;
                }
                field("Output Tokens"; Rec."Output Tokens")
                {
                    ApplicationArea = All;
                }
            }
            group(Email)
            {
                Caption = 'Email';

                field("Sender Name"; Rec."Sender Name")
                {
                    ApplicationArea = All;
                    Editable = IsManual;
                }
                field("Sender Address"; Rec."Sender Address")
                {
                    ApplicationArea = All;
                    Editable = IsManual;
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = All;
                    Editable = IsManual;
                }
                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(BodyText; BodyText)
                {
                    ApplicationArea = All;
                    Caption = 'Cuerpo del email / texto del pedido';
                    MultiLine = true;
                    Editable = IsManual;
                    ToolTip = 'En solicitudes manuales puede pegar aquí el texto de un email o pedido.';

                    trigger OnValidate()
                    begin
                        Rec.SetBodyText(BodyText);
                        Rec.Modify();
                    end;
                }
            }
        }
        area(FactBoxes)
        {
            part(Attachments; "IKA Sales Req. Attachments")
            {
                ApplicationArea = All;
                Caption = 'Adjuntos';
                SubPageLink = "Request Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ProcessWithClaude)
            {
                ApplicationArea = All;
                Caption = 'Procesar con Claude';
                Image = Sparkle;
                Enabled = Rec."Sales Order No." = '';
                ToolTip = 'Envía el email y los adjuntos a Claude, extrae el pedido y lo resuelve en BC. Sustituye las líneas actuales.';

                trigger OnAction()
                var
                    SalesReqProcess: Codeunit "IKA Sales Req. Process";
                begin
                    if Rec."No. of Lines" > 0 then
                        if not Confirm(ReprocessQst, false) then
                            exit;
                    CurrPage.SaveRecord();
                    Commit();
                    SalesReqProcess.SetForceExtraction(true);
                    SalesReqProcess.SetAutoCreate(false);
                    SalesReqProcess.Run(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Resolve)
            {
                ApplicationArea = All;
                Caption = 'Volver a resolver';
                Image = Refresh;
                Enabled = Rec."Sales Order No." = '';
                ToolTip = 'Vuelve a buscar cliente y productos en BC (por ejemplo, tras crear una referencia de producto de cliente). No llama a Claude.';

                trigger OnAction()
                var
                    Resolver: Codeunit "IKA Sales Req. Resolver";
                begin
                    CurrPage.SaveRecord();
                    if Rec.Status = Rec.Status::Error then
                        Rec.Status := Rec.Status::Extracted;
                    Resolver.ResolveRequest(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(CreateOrder)
            {
                ApplicationArea = All;
                Caption = 'Crear pedido de venta';
                Image = MakeOrder;
                Enabled = Rec."Sales Order No." = '';
                ToolTip = 'Crea el pedido de venta en BC. Precios y descuentos los calcula BC al validar los campos.';

                trigger OnAction()
                var
                    SalesOrderCreator: Codeunit "IKA Sales Order Creator";
                begin
                    CurrPage.SaveRecord();
                    SalesOrderCreator.CreateSalesOrder(Rec);
                    CurrPage.Update(false);
                    OpenSalesOrder();
                end;
            }
            action(Ignore)
            {
                ApplicationArea = All;
                Caption = 'Marcar como ignorada';
                Image = Cancel;
                Enabled = Rec."Sales Order No." = '';
                ToolTip = 'La solicitud no es un pedido o no se va a tramitar.';

                trigger OnAction()
                begin
                    Rec.Status := Rec.Status::Ignored;
                    Rec.Modify();
                end;
            }
            action(AddAttachment)
            {
                ApplicationArea = All;
                Caption = 'Añadir adjunto';
                Image = Attach;
                ToolTip = 'Añade un fichero (PDF, imagen, Excel, CSV...) a la solicitud.';

                trigger OnAction()
                var
                    RequestAttachment: Record "IKA Sales Request Attachment";
                begin
                    CurrPage.SaveRecord();
                    RequestAttachment.ImportFromClient(Rec.GetAttachmentOwnerEntryNo());
                    CurrPage.Update(false);
                end;
            }
            action(ShowJson)
            {
                ApplicationArea = All;
                Caption = 'Ver JSON de Claude';
                Image = XMLFile;
                ToolTip = 'Muestra el JSON tal como lo devolvió Claude.';

                trigger OnAction()
                begin
                    Message('%1', Rec.GetExtractionJson());
                end;
            }
        }
        area(Navigation)
        {
            action(SalesOrder)
            {
                ApplicationArea = All;
                Caption = 'Pedido de venta';
                Image = Document;
                Enabled = Rec."Sales Order No." <> '';
                ToolTip = 'Abre el pedido de venta creado.';

                trigger OnAction()
                begin
                    OpenSalesOrder();
                end;
            }
            action(Log)
            {
                ApplicationArea = All;
                Caption = 'Registro';
                Image = Log;
                RunObject = page "IKA Sales Agent Log";
                RunPageLink = "Request Entry No." = field("Entry No.");
                ToolTip = 'Llamadas a Claude y eventos de esta solicitud.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(ProcessWithClaude_Promoted; ProcessWithClaude) { }
                actionref(Resolve_Promoted; Resolve) { }
                actionref(CreateOrder_Promoted; CreateOrder) { }
                actionref(AddAttachment_Promoted; AddAttachment) { }
                actionref(Ignore_Promoted; Ignore) { }
            }
            group(Category_Navigate)
            {
                Caption = 'Navegar';

                actionref(SalesOrder_Promoted; SalesOrder) { }
                actionref(Log_Promoted; Log) { }
                actionref(ShowJson_Promoted; ShowJson) { }
            }
        }
    }

    var
        BodyText: Text;
        StatusStyle: Text;
        CustomerStyle: Text;
        IsEditable: Boolean;
        IsManual: Boolean;
        ReprocessQst: Label 'Se volverá a llamar a Claude y se sustituirán las líneas actuales (se conservan los datos asignados manualmente en cabecera). ¿Continuar?';

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.Source := Rec.Source::Manual;
        IsManual := true;
        IsEditable := true;
        BodyText := '';
    end;

    trigger OnAfterGetRecord()
    begin
        BodyText := Rec.GetBodyText();
        IsManual := Rec.Source = Rec.Source::Manual;
        IsEditable := Rec."Sales Order No." = '';
        Rec.CalcFields("No. of Lines");

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
        case Rec."Customer Match Status" of
            Rec."Customer Match Status"::Matched, Rec."Customer Match Status"::Manual:
                CustomerStyle := 'Favorable';
            Rec."Customer Match Status"::Ambiguous, Rec."Customer Match Status"::"Not Found":
                CustomerStyle := 'Unfavorable';
            else
                CustomerStyle := 'Standard';
        end;
    end;

    local procedure OpenSalesOrder()
    var
        SalesHeader: Record "Sales Header";
    begin
        if Rec."Sales Order No." = '' then
            exit;
        if SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."Sales Order No.") then
            Page.Run(Page::"Sales Order", SalesHeader);
    end;
}
