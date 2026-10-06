page 99121 "IKA DN Documents"
{
    Caption = 'Bandeja de albaranes de proveedor (Claude)';
    PageType = List;
    SourceTable = "IKA DN Document";
    SourceTableView = sorting("Entry No.") order(descending);
    CardPageId = "IKA DN Document";
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
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = All;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Vendor Name"; Rec."Vendor Name")
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
                }
                field("No. of Orders"; Rec."No. of Orders")
                {
                    ApplicationArea = All;
                }
                field("No. of Lines"; Rec."No. of Lines")
                {
                    ApplicationArea = All;
                }
                field("No. of Unmatched Lines"; Rec."No. of Unmatched Lines")
                {
                    ApplicationArea = All;
                }
                field("No. of Discrepancies"; Rec."No. of Discrepancies")
                {
                    ApplicationArea = All;
                }
                field(Confidence; Rec.Confidence)
                {
                    ApplicationArea = All;
                }
                field("Review Notes"; Rec."Review Notes")
                {
                    ApplicationArea = All;
                }
                field("Posted Receipt Nos."; Rec."Posted Receipt Nos.")
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
            action(NewFromFile)
            {
                ApplicationArea = All;
                Caption = 'Nuevo desde fichero';
                Image = Import;
                ToolTip = 'Crea un albarán a partir de un fichero (PDF, foto, Excel...) y lo abre para procesarlo con Claude.';

                trigger OnAction()
                var
                    DNDocument: Record "IKA DN Document";
                    DNFile: Record "IKA DN File";
                begin
                    DNDocument.Init();
                    DNDocument.Source := DNDocument.Source::Manual;
                    DNDocument.Insert(true);
                    DNFile.ImportFromClient(DNDocument."Entry No.");
                    DNFile.SetRange("Document Entry No.", DNDocument."Entry No.");
                    if DNFile.IsEmpty() then begin
                        DNDocument.Delete(true);
                        exit;
                    end;
                    DNDocument.Subject := CopyStr(DNFile."File Name", 1, MaxStrLen(DNDocument.Subject));
                    DNDocument."Source File Name" := DNFile."File Name";
                    DNDocument.Modify();
                    Commit();
                    Page.Run(Page::"IKA DN Document", DNDocument);
                end;
            }
            action(RunAgent)
            {
                ApplicationArea = All;
                Caption = 'Leer origen y procesar';
                Image = ExecuteBatch;
                ToolTip = 'Importa emails/ficheros nuevos y procesa los albaranes pendientes.';

                trigger OnAction()
                var
                    DNJob: Codeunit "IKA DN Job";
                begin
                    DNJob.RunAgent();
                    CurrPage.Update(false);
                end;
            }
            action(ProcessSelected)
            {
                ApplicationArea = All;
                Caption = 'Procesar seleccionados';
                Image = Process;
                ToolTip = 'Procesa con Claude los albaranes seleccionados que estén nuevos o con error.';

                trigger OnAction()
                var
                    DNDocument: Record "IKA DN Document";
                    DNJob: Codeunit "IKA DN Job";
                begin
                    CurrPage.SetSelectionFilter(DNDocument);
                    DNDocument.SetFilter(Status, '%1|%2', DNDocument.Status::New, DNDocument.Status::Error);
                    if DNDocument.FindSet() then
                        repeat
                            DNJob.ProcessOne(DNDocument, false);
                        until DNDocument.Next() = 0;
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
                RunObject = page "IKA DN Setup";
                ToolTip = 'Configuración del agente de albaranes.';
            }
            action(Templates)
            {
                ApplicationArea = All;
                Caption = 'Plantillas de proveedor';
                Image = Template;
                RunObject = page "IKA DN Vendor Templates";
                ToolTip = 'Plantillas de albarán por proveedor.';
            }
            action(Log)
            {
                ApplicationArea = All;
                Caption = 'Registro';
                Image = Log;
                RunObject = page "IKA DN Log";
                RunPageLink = "Document Entry No." = field("Entry No.");
                ToolTip = 'Registro del albarán seleccionado.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(NewFromFile_Promoted; NewFromFile) { }
                actionref(RunAgent_Promoted; RunAgent) { }
                actionref(ProcessSelected_Promoted; ProcessSelected) { }
            }
            group(Category_Navigate)
            {
                Caption = 'Navegar';

                actionref(Templates_Promoted; Templates) { }
                actionref(Log_Promoted; Log) { }
                actionref(Setup_Promoted; Setup) { }
            }
        }
    }

    views
    {
        view(Pending)
        {
            Caption = 'Pendientes';
            Filters = where(Status = filter("Needs Review" | Matched | Error));
        }
        view(Applied)
        {
            Caption = 'Aplicados / recibidos';
            Filters = where(Status = filter(Applied | Received));
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
            Rec.Status::Matched, Rec.Status::Applied, Rec.Status::Received:
                StatusStyle := 'Favorable';
            else
                StatusStyle := 'Standard';
        end;
    end;
}
