page 99131 "IKA DN Document Subform"
{
    Caption = 'Líneas';
    PageType = ListPart;
    SourceTable = "IKA DN Document Line";
    AutoSplitKey = true;
    DelayedInsert = true;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Ext. Position"; Rec."Ext. Position")
                {
                    ApplicationArea = All;
                }
                field("Ext. Vendor Item Code"; Rec."Ext. Vendor Item Code")
                {
                    ApplicationArea = All;
                }
                field("Ext. Description"; Rec."Ext. Description")
                {
                    ApplicationArea = All;
                }
                field(Quantity; Rec.Quantity)
                {
                    ApplicationArea = All;
                    StyleExpr = QtyStyle;
                    ToolTip = 'Cantidad entregada. Las líneas a 0 vienen en el documento sin cantidad: sirven para situar los artículos en el pedido y no se reciben.';
                }
                field("Ext. Unit of Measure"; Rec."Ext. Unit of Measure")
                {
                    ApplicationArea = All;
                }
                field("Delivery Date"; Rec."Delivery Date")
                {
                    ApplicationArea = All;
                }
                field("Ext. Delivery Date"; Rec."Ext. Delivery Date")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = All;
                }
                field("Discount %"; Rec."Discount %")
                {
                    ApplicationArea = All;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = All;
                    StyleExpr = ItemStyle;
                }
                field("Item Description"; Rec."Item Description")
                {
                    ApplicationArea = All;
                }
                field("Item Match Method"; Rec."Item Match Method")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Purchase Order No."; Rec."Purchase Order No.")
                {
                    ApplicationArea = All;
                    StyleExpr = OrderStyle;
                }
                field("Purchase Order Line No."; Rec."Purchase Order Line No.")
                {
                    ApplicationArea = All;
                }
                field("Order Match Method"; Rec."Order Match Method")
                {
                    ApplicationArea = All;
                }
                field("Order Outstanding Qty."; Rec."Order Outstanding Qty.")
                {
                    ApplicationArea = All;
                }
                field("Qty. to Receive (Order UoM)"; Rec."Qty. to Receive (Order UoM)")
                {
                    ApplicationArea = All;
                }
                field("Order Unit of Measure"; Rec."Order Unit of Measure")
                {
                    ApplicationArea = All;
                }
                field("Order Unit Cost"; Rec."Order Unit Cost")
                {
                    ApplicationArea = All;
                }
                field("Has Discrepancy"; Rec."Has Discrepancy")
                {
                    ApplicationArea = All;
                    StyleExpr = DiscrepancyStyle;
                }
                field("Discrepancy Text"; Rec."Discrepancy Text")
                {
                    ApplicationArea = All;
                    StyleExpr = DiscrepancyStyle;
                }
                field("Accept Discrepancy"; Rec."Accept Discrepancy")
                {
                    ApplicationArea = All;
                }
                field("Lot No."; Rec."Lot No.")
                {
                    ApplicationArea = All;
                }
                field("Expiration Date"; Rec."Expiration Date")
                {
                    ApplicationArea = All;
                }
                field("Ext. Order Reference"; Rec."Ext. Order Reference")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Ext. EAN"; Rec."Ext. EAN")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Ext. Our Item Code"; Rec."Ext. Our Item Code")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Line Amount"; Rec."Line Amount")
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
            action(SelectOrderLine)
            {
                ApplicationArea = All;
                Caption = 'Elegir línea de pedido';
                Image = Line;
                ToolTip = 'Muestra las líneas de pedido abiertas del proveedor para asignar manualmente esta línea del albarán.';

                trigger OnAction()
                var
                    DNDocument: Record "IKA DN Document";
                    PurchaseLine: Record "Purchase Line";
                    Resolver: Codeunit "IKA DN Vendor Item Resolver";
                    POMatcher: Codeunit "IKA DN PO Matcher";
                begin
                    DNDocument.Get(Rec."Document Entry No.");
                    DNDocument.TestField("Vendor No.");
                    Resolver.FilterOpenOrderLines(PurchaseLine, DNDocument."Vendor No.");
                    if Rec."Item No." <> '' then
                        PurchaseLine.SetRange("No.", Rec."Item No.");
                    if Page.RunModal(Page::"Purchase Lines", PurchaseLine) <> Action::LookupOK then
                        exit;
                    Rec."Purchase Order No." := PurchaseLine."Document No.";
                    Rec."Purchase Order Line No." := PurchaseLine."Line No.";
                    Rec."Order Match Status" := Rec."Order Match Status"::Manual;
                    if Rec."Item No." = '' then begin
                        Rec."Item No." := PurchaseLine."No.";
                        Rec."Item Match Status" := Rec."Item Match Status"::Manual;
                    end;
                    Rec.Modify();
                    POMatcher.MatchDocument(DNDocument);
                    CurrPage.Update(false);
                end;
            }
            action(CreateVendorReference)
            {
                ApplicationArea = All;
                Caption = 'Guardar como referencia de proveedor';
                Image = Item;
                ToolTip = 'Crea una referencia de producto de tipo Proveedor con su código y el producto asignado, para que la próxima vez se identifique automáticamente.';

                trigger OnAction()
                var
                    DNDocument: Record "IKA DN Document";
                    ItemReference: Record "Item Reference";
                    CreatedMsg: Label 'Referencia %1 del proveedor %2 asociada al producto %3.', Comment = '%1 = reference, %2 = vendor, %3 = item';
                begin
                    Rec.TestField("Item No.");
                    Rec.TestField("Ext. Vendor Item Code");
                    DNDocument.Get(Rec."Document Entry No.");
                    DNDocument.TestField("Vendor No.");

                    ItemReference.Init();
                    ItemReference."Item No." := Rec."Item No.";
                    ItemReference."Variant Code" := Rec."Variant Code";
                    ItemReference."Unit of Measure" := Rec."Unit of Measure Code";
                    ItemReference."Reference Type" := ItemReference."Reference Type"::Vendor;
                    ItemReference."Reference Type No." := DNDocument."Vendor No.";
                    ItemReference."Reference No." := CopyStr(UpperCase(Rec."Ext. Vendor Item Code"), 1, MaxStrLen(ItemReference."Reference No."));
                    ItemReference.Description := CopyStr(Rec."Ext. Description", 1, MaxStrLen(ItemReference.Description));
                    ItemReference.Insert(true);
                    Message(CreatedMsg, ItemReference."Reference No.", DNDocument."Vendor No.", Rec."Item No.");
                end;
            }
        }
    }

    var
        ItemStyle: Text;
        QtyStyle: Text;
        OrderStyle: Text;
        DiscrepancyStyle: Text;

    trigger OnAfterGetRecord()
    begin
        ItemStyle := GetMatchStyle(Rec."Item Match Status");
        if Rec.Quantity = 0 then
            QtyStyle := 'Subordinate'
        else
            QtyStyle := 'Standard';
        OrderStyle := GetMatchStyle(Rec."Order Match Status");
        if Rec."Has Discrepancy" and not Rec."Accept Discrepancy" then
            DiscrepancyStyle := 'Unfavorable'
        else
            DiscrepancyStyle := 'Standard';
    end;

    local procedure GetMatchStyle(MatchStatus: Enum "IKA DN Match Status"): Text
    begin
        case MatchStatus of
            MatchStatus::Matched, MatchStatus::Manual:
                exit('Favorable');
            MatchStatus::Ambiguous, MatchStatus::"Not Found":
                exit('Unfavorable');
        end;
        exit('Standard');
    end;
}
