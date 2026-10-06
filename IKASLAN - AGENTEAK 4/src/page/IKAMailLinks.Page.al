page 99226 "IKA Mail Links"
{
    Caption = 'Emails vinculados a entidades';
    PageType = List;
    SourceTable = "IKA Mail Link";
    SourceTableView = sorting("Entry No.") order(descending);
    UsageCategory = History;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Linked At"; Rec."Linked At")
                {
                    ApplicationArea = All;
                }
                field("Entity Type"; Rec."Entity Type")
                {
                    ApplicationArea = All;
                }
                field("Entity No."; Rec."Entity No.")
                {
                    ApplicationArea = All;
                }
                field(EntityName; EntityMgt.GetName(Rec."Entity Type", Rec."Entity No."))
                {
                    ApplicationArea = All;
                    Caption = 'Nombre';
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = All;
                }
                field("From Address"; Rec."From Address")
                {
                    ApplicationArea = All;
                }
                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = All;
                }
                field("Linked By"; Rec."Linked By")
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
            action(OpenEmail)
            {
                ApplicationArea = All;
                Caption = 'Abrir email';
                Image = Email;
                ToolTip = 'Abre el email de origen.';

                trigger OnAction()
                begin
                    OpenEmailOfLink(Rec);
                end;
            }
            action(OpenEntity)
            {
                ApplicationArea = All;
                Caption = 'Abrir entidad';
                Image = Card;
                ToolTip = 'Abre la ficha de la entidad.';

                trigger OnAction()
                begin
                    EntityMgt.OpenCard(Rec."Entity Type", Rec."Entity No.");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Navigate)
            {
                Caption = 'Navegar';

                actionref(OpenEmail_Promoted; OpenEmail) { }
                actionref(OpenEntity_Promoted; OpenEntity) { }
            }
        }
    }

    var
        EntityMgt: Codeunit "IKA Mail Entity Mgt.";

    procedure OpenEmailOfLink(MailLink: Record "IKA Mail Link")
    var
        MailMessage: Record "IKA Mail Message";
        Mailbox: Record "IKA Mail Mailbox";
        NotAvailableMsg: Label 'El email ya no está en la bandeja de BC. El fichero sigue disponible en los documentos adjuntos de la entidad.';
    begin
        if not MailMessage.Get(MailLink."Message Entry No.") then begin
            Message(NotAvailableMsg);
            exit;
        end;
        Mailbox.Get(MailMessage."Mailbox Code");
        Mailbox.CheckAccess();
        Page.Run(Page::"IKA Mail Message", MailMessage);
    end;
}
