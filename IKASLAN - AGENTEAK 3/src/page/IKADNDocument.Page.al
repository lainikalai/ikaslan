page 99126 "IKA DN Document"
{
    Caption = 'Albarán de proveedor (Claude)';
    PageType = Document;
    SourceTable = "IKA DN Document";
    UsageCategory = None;
    DataCaptionFields = "Entry No.", "Vendor Shipment No.";

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
                field("Review Notes"; Rec."Review Notes")
                {
                    ApplicationArea = All;
                    MultiLine = true;
                    Editable = false;
                    Style = Attention;
                }
                field("Posted Receipt Nos."; Rec."Posted Receipt Nos.")
                {
                    ApplicationArea = All;
                }
            }
            group(Resolved)
            {
                Caption = 'Albarán (resuelto en BC)';
                Editable = IsEditable;

                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                    StyleExpr = VendorStyle;
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                }
                field("Vendor Match Status"; Rec."Vendor Match Status")
                {
                    ApplicationArea = All;
                    StyleExpr = VendorStyle;
                }
                field("Vendor Match Method"; Rec."Vendor Match Method")
                {
                    ApplicationArea = All;
                }
                field("Vendor Shipment No."; Rec."Vendor Shipment No.")
                {
                    ApplicationArea = All;
                }
                field("Delivery Note Date"; Rec."Delivery Note Date")
                {
                    ApplicationArea = All;
                }
                field("Purchase Order No."; Rec."Purchase Order No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Pedido principal. Si lo asigna a mano, se usará como primer candidato al volver a conciliar.';

                    trigger OnDrillDown()
                    begin
                        OpenPurchaseOrder(Rec."Purchase Order No.");
                    end;
                }
                field("No. of Orders"; Rec."No. of Orders")
                {
                    ApplicationArea = All;
                }
                field("Possible Duplicate"; Rec."Possible Duplicate")
                {
                    ApplicationArea = All;
                }
                field("Template Vendor No."; Rec."Template Vendor No.")
                {
                    ApplicationArea = All;
                }
            }
            part(Lines; "IKA DN Document Subform")
            {
                ApplicationArea = All;
                Caption = 'Líneas';
                SubPageLink = "Document Entry No." = field("Entry No.");
                Editable = IsEditable;
                UpdatePropagation = Both;
            }
            group(Extracted)
            {
                Caption = 'Datos extraídos por Claude';
                Editable = false;

                field("Ext. Vendor Name"; Rec."Ext. Vendor Name")
                {
                    ApplicationArea = All;
                }
                field("Ext. Vendor VAT No."; Rec."Ext. Vendor VAT No.")
                {
                    ApplicationArea = All;
                }
                field("Ext. Vendor E-Mail"; Rec."Ext. Vendor E-Mail")
                {
                    ApplicationArea = All;
                }
                field("Ext. Our Customer Code"; Rec."Ext. Our Customer Code")
                {
                    ApplicationArea = All;
                }
                field("Ext. Delivery Note No."; Rec."Ext. Delivery Note No.")
                {
                    ApplicationArea = All;
                }
                field("Ext. Delivery Note Date"; Rec."Ext. Delivery Note Date")
                {
                    ApplicationArea = All;
                }
                field("Ext. Order References"; Rec."Ext. Order References")
                {
                    ApplicationArea = All;
                }
                field("Prices Included"; Rec."Prices Included")
                {
                    ApplicationArea = All;
                }
                field("Ext. Total Amount"; Rec."Ext. Total Amount")
                {
                    ApplicationArea = All;
                }
                field("Ext. Currency"; Rec."Ext. Currency")
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
            group(Origin)
            {
                Caption = 'Origen';

                field("Sender Name"; Rec."Sender Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Sender Address"; Rec."Sender Address")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = All;
                    Editable = IsManual;
                }
                field("Source File Name"; Rec."Source File Name")
                {
                    ApplicationArea = All;
                }
                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field(BodyText; BodyText)
                {
                    ApplicationArea = All;
                    Caption = 'Cuerpo del email / texto';
                    MultiLine = true;
                    Editable = IsManual;
                    ToolTip = 'En albaranes manuales puede pegar aquí el texto del albarán.';

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
            part(Files; "IKA DN Files")
            {
                ApplicationArea = All;
                Caption = 'Ficheros';
                SubPageLink = "Document Entry No." = field("Entry No.");
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
                Enabled = IsEditable;
                ToolTip = 'Envía los ficheros a Claude, extrae el albarán y lo concilia con los pedidos. Sustituye las líneas actuales.';

                trigger OnAction()
                var
                    DNProcess: Codeunit "IKA DN Process";
                begin
                    if Rec."No. of Lines" > 0 then
                        if not Confirm(ReprocessQst, false) then
                            exit;
                    CurrPage.SaveRecord();
                    Commit();
                    DNProcess.SetForceExtraction(true);
                    DNProcess.SetAutoApply(false);
                    DNProcess.Run(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(Rematch)
            {
                ApplicationArea = All;
                Caption = 'Volver a conciliar';
                Image = Refresh;
                Enabled = IsEditable;
                ToolTip = 'Vuelve a buscar proveedor, productos y líneas de pedido sin llamar a Claude (p.ej. tras crear una referencia o corregir datos).';

                trigger OnAction()
                var
                    POMatcher: Codeunit "IKA DN PO Matcher";
                begin
                    CurrPage.SaveRecord();
                    if Rec.Status in [Rec.Status::Error, Rec.Status::New] then
                        Rec.Status := Rec.Status::Extracted;
                    POMatcher.MatchDocument(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(ApplyToOrders)
            {
                ApplicationArea = All;
                Caption = 'Aplicar a pedidos';
                Image = ReceiptLines;
                Enabled = IsEditable;
                ToolTip = 'Rellena "Nº albarán proveedor" y "Cant. a recibir" en los pedidos de compra conciliados.';

                trigger OnAction()
                var
                    ReceiptApplier: Codeunit "IKA DN Receipt Applier";
                begin
                    CurrPage.SaveRecord();
                    ReceiptApplier.ApplyToOrders(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(PostReceipt)
            {
                ApplicationArea = All;
                Caption = 'Registrar recepción';
                Image = PostedReceipt;
                Enabled = Rec.Status = Rec.Status::Applied;
                ToolTip = 'Registra la recepción (sin factura) de los pedidos a los que se aplicó el albarán.';

                trigger OnAction()
                var
                    ReceiptApplier: Codeunit "IKA DN Receipt Applier";
                begin
                    if not Confirm(PostQst, false) then
                        exit;
                    ReceiptApplier.PostReceipts(Rec);
                    CurrPage.Update(false);
                end;
            }
            action(UseAsExample)
            {
                ApplicationArea = All;
                Caption = 'Usar como ejemplo de la plantilla';
                Image = Template;
                ToolTip = 'Guarda la extracción de este albarán (ya revisado) como ejemplo para los próximos albaranes del mismo proveedor. Si el proveedor no tiene plantilla, la crea.';

                trigger OnAction()
                begin
                    SaveAsTemplateExample();
                end;
            }
            action(AddFile)
            {
                ApplicationArea = All;
                Caption = 'Añadir fichero';
                Image = Attach;
                Enabled = IsEditable;
                ToolTip = 'Añade un fichero al albarán.';

                trigger OnAction()
                var
                    DNFile: Record "IKA DN File";
                begin
                    CurrPage.SaveRecord();
                    DNFile.ImportFromClient(Rec.GetFileOwnerEntryNo());
                    CurrPage.Update(false);
                end;
            }
            action(Ignore)
            {
                ApplicationArea = All;
                Caption = 'Marcar como ignorado';
                Image = Cancel;
                Enabled = IsEditable;
                ToolTip = 'El documento no es un albarán o no se va a tramitar.';

                trigger OnAction()
                begin
                    Rec.Status := Rec.Status::Ignored;
                    Rec.Modify();
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
            action(PurchaseOrder)
            {
                ApplicationArea = All;
                Caption = 'Pedido de compra';
                Image = Document;
                Enabled = Rec."Purchase Order No." <> '';
                ToolTip = 'Abre el pedido de compra principal.';

                trigger OnAction()
                begin
                    OpenPurchaseOrder(Rec."Purchase Order No.");
                end;
            }
            action(Template)
            {
                ApplicationArea = All;
                Caption = 'Plantilla del proveedor';
                Image = Template;
                Enabled = Rec."Vendor No." <> '';
                RunObject = page "IKA DN Vendor Template";
                RunPageLink = "Vendor No." = field("Vendor No.");
                ToolTip = 'Abre la plantilla de albarán del proveedor.';
            }
            action(Log)
            {
                ApplicationArea = All;
                Caption = 'Registro';
                Image = Log;
                RunObject = page "IKA DN Log";
                RunPageLink = "Document Entry No." = field("Entry No.");
                ToolTip = 'Llamadas a Claude y eventos de este albarán.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(ProcessWithClaude_Promoted; ProcessWithClaude) { }
                actionref(Rematch_Promoted; Rematch) { }
                actionref(ApplyToOrders_Promoted; ApplyToOrders) { }
                actionref(PostReceipt_Promoted; PostReceipt) { }
                actionref(UseAsExample_Promoted; UseAsExample) { }
                actionref(AddFile_Promoted; AddFile) { }
            }
            group(Category_Navigate)
            {
                Caption = 'Navegar';

                actionref(PurchaseOrder_Promoted; PurchaseOrder) { }
                actionref(Template_Promoted; Template) { }
                actionref(Log_Promoted; Log) { }
                actionref(ShowJson_Promoted; ShowJson) { }
            }
        }
    }

    var
        BodyText: Text;
        StatusStyle: Text;
        VendorStyle: Text;
        IsEditable: Boolean;
        IsManual: Boolean;
        ReprocessQst: Label 'Se volverá a llamar a Claude y se sustituirán las líneas actuales. ¿Continuar?';
        PostQst: Label 'Se registrará la recepción de los pedidos afectados. ¿Continuar?';
        ExampleSavedMsg: Label 'Ejemplo guardado en la plantilla del proveedor %1. Los próximos albaranes de este proveedor se extraerán usando este ejemplo como guía.', Comment = '%1 = vendor';
        NoJsonErr: Label 'El albarán no tiene una extracción de Claude que guardar.';

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
        IsEditable := not (Rec.Status in [Rec.Status::Applied, Rec.Status::Received]);
        Rec.CalcFields("No. of Lines");

        case Rec.Status of
            Rec.Status::Error:
                StatusStyle := 'Unfavorable';
            Rec.Status::"Needs Review":
                StatusStyle := 'Ambiguous';
            Rec.Status::Matched, Rec.Status::Applied, Rec.Status::Received:
                StatusStyle := 'Favorable';
            else
                StatusStyle := 'Standard';
        end;
        case Rec."Vendor Match Status" of
            Rec."Vendor Match Status"::Matched, Rec."Vendor Match Status"::Manual:
                VendorStyle := 'Favorable';
            Rec."Vendor Match Status"::Ambiguous, Rec."Vendor Match Status"::"Not Found":
                VendorStyle := 'Unfavorable';
            else
                VendorStyle := 'Standard';
        end;
    end;

    local procedure OpenPurchaseOrder(OrderNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        if OrderNo = '' then
            exit;
        if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, OrderNo) then
            Page.Run(Page::"Purchase Order", PurchaseHeader);
    end;

    local procedure SaveAsTemplateExample()
    var
        VendorTemplate: Record "IKA DN Vendor Template";
        ParentDocument: Record "IKA DN Document";
        JsonText: Text;
        Domain: Text;
    begin
        Rec.TestField("Vendor No.");
        JsonText := Rec.GetExtractionJson();
        if (JsonText = '') and (Rec."Parent Entry No." <> 0) then
            if ParentDocument.Get(Rec."Parent Entry No.") then
                JsonText := ParentDocument.GetExtractionJson();
        if JsonText = '' then
            Error(NoJsonErr);

        if not VendorTemplate.Get(Rec."Vendor No.") then begin
            VendorTemplate.Init();
            VendorTemplate."Vendor No." := Rec."Vendor No.";
            if StrPos(Rec."Sender Address", '@') > 0 then begin
                Domain := CopyStr(Rec."Sender Address", StrPos(Rec."Sender Address", '@') + 1);
                VendorTemplate."Sender Filter" := CopyStr('*@' + Domain, 1, MaxStrLen(VendorTemplate."Sender Filter"));
            end;
            VendorTemplate.Insert(true);
        end;
        VendorTemplate.SetExampleJson(JsonText, Rec."Entry No.");
        VendorTemplate.Modify(true);

        Rec."Template Vendor No." := VendorTemplate."Vendor No.";
        Rec.Modify();
        Message(ExampleSavedMsg, Rec."Vendor No.");
    end;
}
