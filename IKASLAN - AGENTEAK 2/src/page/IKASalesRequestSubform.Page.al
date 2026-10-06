page 50040 "IKA Sales Request Subform"
{
    Caption = 'Líneas';
    PageType = ListPart;
    SourceTable = "IKA Sales Request Line";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Ext. Customer Item Code"; Rec."Ext. Customer Item Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Código del artículo según el cliente, tal como lo extrajo Claude.';
                }
                field("Ext. Item No."; Rec."Ext. Item No.")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Ext. Description"; Rec."Ext. Description")
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                }
                field("Ext. Unit of Measure"; Rec."Ext. Unit of Measure")
                {
                    ApplicationArea = All;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    StyleExpr = MatchStyle;
                    ToolTip = 'Producto de BC. Puede asignarlo manualmente si no se ha encontrado.';
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = All;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = All;
                }
                field("Unit of Measure Code"; Rec."Unit of Measure Code")
                {
                    ApplicationArea = All;
                }
                field("Match Status"; Rec."Match Status")
                {
                    ApplicationArea = All;
                    StyleExpr = MatchStyle;
                }
                field("Match Method"; Rec."Match Method")
                {
                    ApplicationArea = All;
                }
                field("Resolution Note"; Rec."Resolution Note")
                {
                    ApplicationArea = All;
                }
                field("Ext. Notes"; Rec."Ext. Notes")
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
            action(CreateItemReference)
            {
                ApplicationArea = All;
                Caption = 'Guardar como referencia de cliente';
                Image = Item;
                ToolTip = 'Crea una referencia de producto de tipo Cliente con el código del cliente y el producto asignado, para que la próxima vez se identifique automáticamente.';

                trigger OnAction()
                var
                    RequestHeader: Record "IKA Sales Request Header";
                    ItemReference: Record "Item Reference";
                    CreatedMsg: Label 'Referencia %1 del cliente %2 asociada al producto %3.', Comment = '%1 = reference, %2 = customer, %3 = item';
                begin
                    Rec.TestField("Item No.");
                    Rec.TestField("Ext. Customer Item Code");
                    RequestHeader.Get(Rec."Request Entry No.");
                    RequestHeader.TestField("Customer No.");

                    ItemReference.Init();
                    ItemReference."Item No." := Rec."Item No.";
                    ItemReference."Variant Code" := Rec."Variant Code";
                    ItemReference."Unit of Measure" := Rec."Unit of Measure Code";
                    ItemReference."Reference Type" := ItemReference."Reference Type"::Customer;
                    ItemReference."Reference Type No." := RequestHeader."Customer No.";
                    ItemReference."Reference No." := CopyStr(UpperCase(Rec."Ext. Customer Item Code"), 1, MaxStrLen(ItemReference."Reference No."));
                    ItemReference.Description := CopyStr(Rec."Ext. Description", 1, MaxStrLen(ItemReference.Description));
                    ItemReference.Insert(true);
                    Message(CreatedMsg, ItemReference."Reference No.", RequestHeader."Customer No.", Rec."Item No.");
                end;
            }
        }
    }

    var
        MatchStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec."Match Status" of
            Rec."Match Status"::Matched, Rec."Match Status"::Manual:
                MatchStyle := 'Favorable';
            Rec."Match Status"::Ambiguous, Rec."Match Status"::"Not Found":
                MatchStyle := 'Unfavorable';
            else
                MatchStyle := 'Standard';
        end;
    end;
}
