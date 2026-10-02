page 50215 "IKA DN Vendor Template"
{
    Caption = 'Plantilla de albarán de proveedor';
    PageType = Card;
    SourceTable = "IKA DN Vendor Template";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = All;
                }
                field("Vendor Name"; Rec."Vendor Name")
                {
                    ApplicationArea = All;
                }
                field(Active; Rec.Active)
                {
                    ApplicationArea = All;
                }
                field(Priority; Rec.Priority)
                {
                    ApplicationArea = All;
                    ToolTip = 'Si varias plantillas coinciden con un email o fichero, gana la de menor prioridad.';
                }
            }
            group(Identification)
            {
                Caption = 'Cómo reconocer sus documentos';

                field("Sender Filter"; Rec."Sender Filter")
                {
                    ApplicationArea = All;
                }
                field("Subject Filter"; Rec."Subject Filter")
                {
                    ApplicationArea = All;
                }
                field("File Name Filter"; Rec."File Name Filter")
                {
                    ApplicationArea = All;
                }
            }
            group(Knowledge)
            {
                Caption = 'Conocimiento para Claude';

                field("Item Code Type"; Rec."Item Code Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Qué representa el código de artículo que imprime este proveedor en sus albaranes.';
                }
                field("Prices Included"; Rec."Prices Included")
                {
                    ApplicationArea = All;
                }
                field(Instructions; Rec.Instructions)
                {
                    ApplicationArea = All;
                    MultiLine = true;
                }
                field(ExampleStatus; ExampleStatus)
                {
                    ApplicationArea = All;
                    Caption = 'Ejemplo validado';
                    Editable = false;
                    ToolTip = 'Albarán validado que se envía a Claude como ejemplo. Se establece desde la ficha del albarán con "Usar como ejemplo de la plantilla".';

                    trigger OnDrillDown()
                    begin
                        if Rec.GetExampleJson() <> '' then
                            Message('%1', Rec.GetExampleJson());
                    end;
                }
                field("No. of Documents"; Rec."No. of Documents")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Navigation)
        {
            action(Aliases)
            {
                ApplicationArea = All;
                Caption = 'Alias de campos del proveedor';
                Image = SetupList;
                RunObject = page "IKA DN Field Aliases";
                RunPageLink = "Vendor No." = field("Vendor No.");
                ToolTip = 'Cómo llama este proveedor a cada campo en sus albaranes.';
            }
            action(Documents)
            {
                ApplicationArea = All;
                Caption = 'Albaranes';
                Image = Documents;
                RunObject = page "IKA DN Documents";
                RunPageLink = "Vendor No." = field("Vendor No.");
                ToolTip = 'Albaranes procesados de este proveedor.';
            }
        }
        area(Processing)
        {
            action(ClearExample)
            {
                ApplicationArea = All;
                Caption = 'Quitar ejemplo';
                Image = Delete;
                ToolTip = 'Deja de enviar el albarán de ejemplo a Claude.';

                trigger OnAction()
                begin
                    Clear(Rec."Example JSON");
                    Rec."Example Document Entry No." := 0;
                    Rec.Modify();
                    UpdateExampleStatus();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Navigate)
            {
                Caption = 'Navegar';

                actionref(Aliases_Promoted; Aliases) { }
                actionref(Documents_Promoted; Documents) { }
            }
        }
    }

    var
        ExampleStatus: Text;
        WithExampleTxt: Label 'Sí (albarán %1)', Comment = '%1 = entry no.';
        WithoutExampleTxt: Label 'No';

    trigger OnAfterGetRecord()
    begin
        UpdateExampleStatus();
    end;

    local procedure UpdateExampleStatus()
    begin
        Rec.CalcFields("Example JSON");
        if Rec."Example JSON".HasValue() then
            ExampleStatus := StrSubstNo(WithExampleTxt, Rec."Example Document Entry No.")
        else
            ExampleStatus := WithoutExampleTxt;
    end;
}
