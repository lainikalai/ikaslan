page 99006 "IKA Sales Agent Mail Filters"
{
    Caption = 'Filtros de correo agentes (Claude)';
    PageType = List;
    SourceTable = "IKA Sales Agent Mail Filter";
    SourceTableView = sorting(Priority, "Line No.");
    UsageCategory = Lists;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Document Type"; Rec."Document Type")
                {
                    ApplicationArea = All;
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                    ToolTip = 'Indica si el filtro está en uso.';
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = All;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Descripción libre del filtro. Aparece en el registro y en las instrucciones que recibe Claude.';
                }
                field("Sender Filter"; Rec."Sender Filter")
                {
                    ApplicationArea = All;
                }
                field("Subject Filter"; Rec."Subject Filter")
                {
                    ApplicationArea = All;
                }
                field("Body Filter"; Rec."Body Filter")
                {
                    ApplicationArea = All;
                }
                field("File Name Filter"; Rec."File Name Filter")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Customer No."; Rec."Customer No.")
                {
                    ApplicationArea = All;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Extraction Instructions"; Rec."Extraction Instructions")
                {
                    ApplicationArea = All;

                    trigger OnAssistEdit()
                    var
                        InstructionsDialog: Page "IKA Extraction Instructions";
                    begin
                        InstructionsDialog.SetInstructions(Rec."Extraction Instructions", Rec.Description);
                        if InstructionsDialog.RunModal() = Action::OK then begin
                            Rec."Extraction Instructions" := CopyStr(InstructionsDialog.GetInstructions(), 1, MaxStrLen(Rec."Extraction Instructions"));
                            Rec.Modify(true);
                        end;
                    end;
                }
                field("Item Code Type"; Rec."Item Code Type")
                {
                    ApplicationArea = All;
                }
                field("Prices Included"; Rec."Prices Included")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Solo albaranes: si los albaranes de este origen vienen valorados.';
                }
                field(ExampleStatus; ExampleStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Ejemplo validado';
                    Editable = false;
                    ToolTip = 'Documento revisado que se envía a Claude como guía. Se establece desde la solicitud o el albarán con "Usar como ejemplo del filtro". Pulse para verlo.';

                    trigger OnDrillDown()
                    begin
                        if Rec.HasExample() then
                            Message('%1', Rec.GetExampleJson());
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ClearExample)
            {
                ApplicationArea = All;
                Caption = 'Quitar ejemplo';
                Image = Delete;
                ToolTip = 'Deja de enviar a Claude el documento de ejemplo de este filtro.';

                trigger OnAction()
                begin
                    Rec.ClearExample();
                    Rec.Modify(true);
                    UpdateExampleStatus();
                end;
            }
        }
        area(Navigation)
        {
            action(PartnerAliases)
            {
                ApplicationArea = All;
                Caption = 'Alias de campos';
                Image = SetupList;
                ToolTip = 'Cómo llama este cliente o proveedor a cada campo en sus documentos.';

                trigger OnAction()
                var
                    FieldAlias: Record "IKA Field Alias";
                begin
                    FieldAlias.SetRange("Document Type", Rec."Document Type");
                    FieldAlias.SetRange("Partner No.", Rec.GetPartnerNo());
                    Page.Run(Page::"IKA Field Aliases", FieldAlias);
                end;
            }
            action(Documents)
            {
                ApplicationArea = All;
                Caption = 'Documentos';
                Image = Documents;
                ToolTip = 'Solicitudes de venta o albaranes que han entrado por este filtro.';

                trigger OnAction()
                var
                    RequestHeader: Record "IKA Sales Request Header";
                    DNDocument: Record "IKA DN Document";
                begin
                    if Rec."Document Type" = Rec."Document Type"::"Delivery Note" then begin
                        DNDocument.SetRange("Mail Filter Line No.", Rec."Line No.");
                        Page.Run(Page::"IKA DN Documents", DNDocument);
                    end else begin
                        RequestHeader.SetRange("Mail Filter Line No.", Rec."Line No.");
                        Page.Run(Page::"IKA Sales Requests", RequestHeader);
                    end;
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(ClearExample_Promoted; ClearExample) { }
            }
            group(Category_Navigate)
            {
                Caption = 'Navegar';

                actionref(PartnerAliases_Promoted; PartnerAliases) { }
                actionref(Documents_Promoted; Documents) { }
            }
        }
    }

    views
    {
        view(SalesOrders)
        {
            Caption = 'Pedidos de clientes';
            Filters = where("Document Type" = const("Sales Order"));
        }
        view(DeliveryNotes)
        {
            Caption = 'Albaranes de proveedores';
            Filters = where("Document Type" = const("Delivery Note"));
        }
    }

    var
        ExampleStatus: Text;
        WithExampleTxt: Label 'Sí (nº mov. %1)', Comment = '%1 = entry no.';
        WithoutExampleTxt: Label 'No';

    trigger OnAfterGetRecord()
    begin
        UpdateExampleStatus();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    var
        TypeFilter: Text;
    begin
        // En la vista de albaranes, los filtros nuevos son de albaranes
        TypeFilter := Rec.GetFilter("Document Type");
        if TypeFilter <> '' then
            if Evaluate(Rec."Document Type", TypeFilter) then;
        ExampleStatus := WithoutExampleTxt;
    end;

    local procedure UpdateExampleStatus()
    begin
        if Rec.HasExample() then
            ExampleStatus := StrSubstNo(WithExampleTxt, Rec."Example Entry No.")
        else
            ExampleStatus := WithoutExampleTxt;
    end;
}
