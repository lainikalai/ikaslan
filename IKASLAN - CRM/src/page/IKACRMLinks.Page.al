page 99451 "IKA CRM Links"
{
    Caption = 'Vínculos con el CRM';
    PageType = List;
    SourceTable = "IKA CRM Link";
    UsageCategory = Lists;
    ApplicationArea = All;
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(BCType; Rec.GetBCTypeText())
                {
                    ApplicationArea = All;
                    Caption = 'Tipo en BC';
                    ToolTip = 'Cliente, proveedor o contacto.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nº del cliente, proveedor o contacto en BC.';

                    trigger OnDrillDown()
                    begin
                        OpenBCCard();
                    end;
                }
                field("CRM Entity"; Rec."CRM Entity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cuenta o contacto del CRM.';
                }
                field("CRM Name"; Rec."CRM Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre en el CRM (al vincular).';

                    trigger OnDrillDown()
                    begin
                        LinkMgt.ShowLinkedInBC(Rec);
                    end;
                }
                field("Linked At"; Rec."Linked At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cuándo se vinculó.';
                }
                field("Linked By"; Rec."Linked By")
                {
                    ApplicationArea = All;
                    ToolTip = 'Quién lo vinculó.';
                }
                field("CRM Id"; Rec."CRM Id")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Id del registro en el CRM.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenInCrm)
            {
                ApplicationArea = All;
                Caption = 'Abrir en el CRM';
                Image = Web;
                ToolTip = 'Abre en el CRM el registro vinculado.';

                trigger OnAction()
                begin
                    LinkMgt.OpenLinkedInCrm(Rec);
                end;
            }
            action(ShowInBC)
            {
                ApplicationArea = All;
                Caption = 'Ver datos del CRM';
                Image = View;
                ToolTip = 'Ficha del registro del CRM con sus contactos, oportunidades y actividades.';

                trigger OnAction()
                begin
                    LinkMgt.ShowLinkedInBC(Rec);
                end;
            }
            action(BCCard)
            {
                ApplicationArea = All;
                Caption = 'Ficha en BC';
                Image = Card;
                ToolTip = 'Abre la ficha del cliente, proveedor o contacto en BC.';

                trigger OnAction()
                begin
                    OpenBCCard();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(OpenInCrm_Promoted; OpenInCrm) { }
                actionref(ShowInBC_Promoted; ShowInBC) { }
                actionref(BCCard_Promoted; BCCard) { }
            }
        }
    }

    var
        LinkMgt: Codeunit "IKA CRM Link Mgt.";

    local procedure OpenBCCard()
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
    begin
        case Rec."Table ID" of
            Database::Customer:
                if Customer.Get(Rec."No.") then
                    Page.Run(Page::"Customer Card", Customer);
            Database::Vendor:
                if Vendor.Get(Rec."No.") then
                    Page.Run(Page::"Vendor Card", Vendor);
            Database::Contact:
                if Contact.Get(Rec."No.") then
                    Page.Run(Page::"Contact Card", Contact);
        end;
    end;
}
