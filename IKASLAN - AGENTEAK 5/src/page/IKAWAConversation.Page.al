page 99331 "IKA WA Conversation"
{
    // Ficha de la conversación: datos de la entidad vinculada y el chat (control add-in).
    // La página no es editable para no chocar con los cambios que hace el chat sobre la conversación
    // (no leídos, último mensaje); la vinculación y el comercial se cambian con acciones.
    Caption = 'Conversación de WhatsApp';
    PageType = Document;
    SourceTable = "IKA WA Conversation";
    UsageCategory = None;
    InsertAllowed = false;
    Editable = false;
    DataCaptionFields = "Entity Name", "Phone No.";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Conversación';

                field("Entity Name"; Rec."Entity Name")
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    begin
                        PhoneMgt.OpenEntityCard(Rec."Entity Type", Rec."Entity No.");
                    end;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = All;
                }
                field(WindowText; Rec.GetWindowText())
                {
                    ApplicationArea = All;
                    Caption = 'Ventana de 24 h';
                    StyleExpr = WindowStyle;
                    ToolTip = 'Con la ventana cerrada WhatsApp solo permite enviar plantillas aprobadas.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = All;
                }
                field("Profile Name"; Rec."Profile Name")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                }
                field("Entity Type"; Rec."Entity Type")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                }
                field("Entity No."; Rec."Entity No.")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                }
                field("Account Code"; Rec."Account Code")
                {
                    ApplicationArea = All;
                    Importance = Additional;
                }
            }
            part(Chat; "IKA WA Chat Part")
            {
                ApplicationArea = All;
                Caption = 'Chat';
                SubPageLink = "Entry No." = field("Entry No.");
            }
            part(Messages; "IKA WA Messages Part")
            {
                // Vista clásica en lista (estado, errores, documento de origen). Oculta por defecto:
                // se puede mostrar personalizando la página.
                ApplicationArea = All;
                Caption = 'Detalle de mensajes';
                Visible = false;
                SubPageLink = "Conversation Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SendTemplate)
            {
                ApplicationArea = All;
                Caption = 'Enviar plantilla';
                Image = Template;
                ToolTip = 'Envía una plantilla aprobada (siempre permitido, también con la ventana cerrada).';

                trigger OnAction()
                begin
                    ChatMgt.SendTemplate(Rec."Entry No.");
                    CurrPage.Update(false);
                end;
            }
            action(NotifySalesperson)
            {
                ApplicationArea = All;
                Caption = 'Avisar al comercial';
                Image = SalesPerson;
                Enabled = Rec."Salesperson Code" <> '';
                ToolTip = 'Envía por WhatsApp al comercial asignado el último mensaje de esta conversación.';

                trigger OnAction()
                begin
                    ChatMgt.NotifySalesperson(Rec."Entry No.");
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Actualizar';
                Image = Refresh;
                ShortcutKey = 'F5';
                ToolTip = 'Procesa los mensajes recibidos pendientes.';

                trigger OnAction()
                var
                    InboundProcessor: Codeunit "IKA WA Inbound Processor";
                begin
                    InboundProcessor.ProcessPending();
                    CurrPage.Update(false);
                end;
            }
            group(Link)
            {
                Caption = 'Vincular';
                Image = Link;

                action(LinkByPhone)
                {
                    ApplicationArea = All;
                    Caption = 'Buscar por teléfono';
                    Image = Find;
                    ToolTip = 'Busca el cliente, proveedor, contacto o vendedor/comprador con este teléfono.';

                    trigger OnAction()
                    begin
                        ChatMgt.LinkByPhone(Rec."Entry No.");
                        CurrPage.Update(false);
                    end;
                }
                action(LinkCustomer)
                {
                    ApplicationArea = All;
                    Caption = 'Cliente...';
                    Image = Customer;
                    ToolTip = 'Vincula la conversación a un cliente.';

                    trigger OnAction()
                    begin
                        LinkTo(Enum::"IKA WA Entity Type"::Customer);
                    end;
                }
                action(LinkVendor)
                {
                    ApplicationArea = All;
                    Caption = 'Proveedor...';
                    Image = Vendor;
                    ToolTip = 'Vincula la conversación a un proveedor.';

                    trigger OnAction()
                    begin
                        LinkTo(Enum::"IKA WA Entity Type"::Vendor);
                    end;
                }
                action(LinkContact)
                {
                    ApplicationArea = All;
                    Caption = 'Contacto...';
                    Image = ContactPerson;
                    ToolTip = 'Vincula la conversación a un contacto.';

                    trigger OnAction()
                    begin
                        LinkTo(Enum::"IKA WA Entity Type"::Contact);
                    end;
                }
                action(LinkSalesperson)
                {
                    ApplicationArea = All;
                    Caption = 'Vendedor/comprador...';
                    Image = SalesPerson;
                    ToolTip = 'Vincula la conversación a un vendedor o comprador de la empresa.';

                    trigger OnAction()
                    begin
                        LinkTo(Enum::"IKA WA Entity Type"::SalespersonPurchaser);
                    end;
                }
                action(Unlink)
                {
                    ApplicationArea = All;
                    Caption = 'Desvincular';
                    Image = Cancel;
                    Enabled = Rec."Entity No." <> '';
                    ToolTip = 'Quita la vinculación con el cliente, proveedor, contacto o vendedor/comprador.';

                    trigger OnAction()
                    begin
                        ChatMgt.Unlink(Rec."Entry No.");
                        CurrPage.Update(false);
                    end;
                }
            }
            action(AssignSalesperson)
            {
                ApplicationArea = All;
                Caption = 'Asignar comercial';
                Image = SalesPurchaseTeam;
                ToolTip = 'Cambia el comercial responsable de la conversación (por defecto, el de la ficha del cliente, proveedor o contacto).';

                trigger OnAction()
                begin
                    if ChatMgt.AssignSalesperson(Rec."Entry No.") then
                        CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(OpenEntity)
            {
                ApplicationArea = All;
                Caption = 'Abrir ficha';
                Image = Card;
                Enabled = Rec."Entity No." <> '';
                ToolTip = 'Abre la ficha del cliente, proveedor, contacto o vendedor/comprador.';

                trigger OnAction()
                begin
                    PhoneMgt.OpenEntityCard(Rec."Entity Type", Rec."Entity No.");
                end;
            }
            action(OpenWaMe)
            {
                ApplicationArea = All;
                Caption = 'Abrir en mi WhatsApp';
                Image = Web;
                ToolTip = 'Abre este chat en WhatsApp web o de escritorio (lo que se envíe desde allí no queda en BC).';

                trigger OnAction()
                begin
                    PhoneMgt.OpenWaMe(Rec."Phone No.", '');
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(SendTemplate_Promoted; SendTemplate) { }
                actionref(NotifySalesperson_Promoted; NotifySalesperson) { }
                actionref(Refresh_Promoted; Refresh) { }
            }
            group(Category_Link)
            {
                Caption = 'Vincular';

                actionref(LinkByPhone_Promoted; LinkByPhone) { }
                actionref(LinkCustomer_Promoted; LinkCustomer) { }
                actionref(LinkVendor_Promoted; LinkVendor) { }
                actionref(LinkContact_Promoted; LinkContact) { }
                actionref(LinkSalesperson_Promoted; LinkSalesperson) { }
                actionref(AssignSalesperson_Promoted; AssignSalesperson) { }
            }
            group(Category_Navigate)
            {
                Caption = 'Navegar';

                actionref(OpenEntity_Promoted; OpenEntity) { }
                actionref(OpenWaMe_Promoted; OpenWaMe) { }
            }
        }
    }

    var
        ChatMgt: Codeunit "IKA WA Chat Mgt.";
        PhoneMgt: Codeunit "IKA WA Phone Mgt.";
        WindowStyle: Text;

    trigger OnAfterGetCurrRecord()
    begin
        if Rec.IsWindowOpen() then
            WindowStyle := 'Favorable'
        else
            WindowStyle := 'Attention';
    end;

    local procedure LinkTo(EntityType: Enum "IKA WA Entity Type")
    begin
        if ChatMgt.LinkToEntity(Rec."Entry No.", EntityType) then
            CurrPage.Update(false);
    end;
}
