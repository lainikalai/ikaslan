page 99321 "IKA WA Conversations"
{
    // Bandeja de WhatsApp a dos paneles: conversaciones a la izquierda y el chat de la seleccionada
    // en el panel de FactBox. "Mis conversaciones" filtra por el comercial del usuario (Configuración usuarios).
    Caption = 'WhatsApp';
    PageType = List;
    SourceTable = "IKA WA Conversation";
    SourceTableView = sorting("Last Message At") order(descending);
    CardPageId = "IKA WA Conversation";
    UsageCategory = Lists;
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Last Message At"; Rec."Last Message At")
                {
                    ApplicationArea = All;
                    StyleExpr = RowStyle;
                }
                field("Entity Name"; Rec."Entity Name")
                {
                    ApplicationArea = All;
                    StyleExpr = RowStyle;
                }
                field("Profile Name"; Rec."Profile Name")
                {
                    ApplicationArea = All;
                }
                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = All;
                }
                field("Last Message Preview"; Rec."Last Message Preview")
                {
                    ApplicationArea = All;
                    StyleExpr = RowStyle;
                }
                field("No. of Unread"; Rec."No. of Unread")
                {
                    ApplicationArea = All;
                    BlankZero = true;
                    Style = Strong;
                }
                field(WindowText; Rec.GetWindowText())
                {
                    ApplicationArea = All;
                    Caption = 'Ventana 24 h';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
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
                field("Account Code"; Rec."Account Code")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
            }
        }
        area(FactBoxes)
        {
            part(Chat; "IKA WA Chat Part")
            {
                ApplicationArea = All;
                Caption = 'Chat';
                SubPageLink = "Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
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
            action(MyConversations)
            {
                ApplicationArea = All;
                Caption = 'Mis conversaciones';
                Image = FilterLines;
                Visible = not OnlyMine;
                ToolTip = 'Muestra solo las conversaciones asignadas a su vendedor/comprador (Configuración usuarios).';

                trigger OnAction()
                begin
                    SetOnlyMine(true);
                end;
            }
            action(AllConversations)
            {
                ApplicationArea = All;
                Caption = 'Todas las conversaciones';
                Image = ClearFilter;
                Visible = OnlyMine;
                ToolTip = 'Quita el filtro de comercial.';

                trigger OnAction()
                begin
                    SetOnlyMine(false);
                end;
            }
            action(NotifySalesperson)
            {
                ApplicationArea = All;
                Caption = 'Avisar al comercial';
                Image = SalesPerson;
                Enabled = Rec."Salesperson Code" <> '';
                ToolTip = 'Envía por WhatsApp al comercial asignado el último mensaje de la conversación.';

                trigger OnAction()
                var
                    ChatMgt: Codeunit "IKA WA Chat Mgt.";
                begin
                    ChatMgt.NotifySalesperson(Rec."Entry No.");
                end;
            }
        }
        area(Navigation)
        {
            action(QuickReplies)
            {
                ApplicationArea = All;
                Caption = 'Respuestas rápidas';
                Image = Text;
                RunObject = page "IKA WA Quick Replies";
                ToolTip = 'Textos predefinidos que se insertan con un clic en el chat.';
            }
            action(Setup)
            {
                ApplicationArea = All;
                Caption = 'Configuración';
                Image = Setup;
                RunObject = page "IKA WA Setup";
                ToolTip = 'Configuración de WhatsApp.';
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(Refresh_Promoted; Refresh) { }
                actionref(MyConversations_Promoted; MyConversations) { }
                actionref(AllConversations_Promoted; AllConversations) { }
                actionref(NotifySalesperson_Promoted; NotifySalesperson) { }
                actionref(QuickReplies_Promoted; QuickReplies) { }
                actionref(Setup_Promoted; Setup) { }
            }
        }
    }

    views
    {
        view(Unread)
        {
            Caption = 'No leídas';
            Filters = where("No. of Unread" = filter(> 0));
        }
        view(NotLinked)
        {
            Caption = 'Sin vincular';
            Filters = where("Entity No." = const(''));
        }
    }

    var
        PhoneMgt: Codeunit "IKA WA Phone Mgt.";
        RowStyle: Text;
        OnlyMine: Boolean;
        NoSalespersonErr: Label 'Su usuario no tiene vendedor/comprador en Configuración usuarios.';

    trigger OnOpenPage()
    var
        Account: Record "IKA WA Account";
        WASetup: Record "IKA WA Setup";
        InboundProcessor: Codeunit "IKA WA Inbound Processor";
        AllowedFilter: Text;
    begin
        AllowedFilter := Account.GetAllowedFilter();
        Rec.FilterGroup(2);
        if AllowedFilter = '' then
            Rec.SetRange("Account Code", '')
        else
            Rec.SetFilter("Account Code", AllowedFilter);
        Rec.FilterGroup(0);
        WASetup.GetSetup();
        if WASetup."Open My Conversations" and (Rec.GetFilter("Salesperson Code") = '') and (PhoneMgt.GetUserSalespersonCode() <> '') then
            ApplyOnlyMine(true);
        // Al abrir la bandeja se procesa lo que haya llegado (además de la cola de proyectos)
        InboundProcessor.ProcessPending();
    end;

    local procedure SetOnlyMine(NewOnlyMine: Boolean)
    begin
        ApplyOnlyMine(NewOnlyMine);
        CurrPage.Update(false);
    end;

    local procedure ApplyOnlyMine(NewOnlyMine: Boolean)
    var
        SalespersonCode: Code[20];
    begin
        if NewOnlyMine then begin
            SalespersonCode := PhoneMgt.GetUserSalespersonCode();
            if SalespersonCode = '' then
                Error(NoSalespersonErr);
            Rec.SetRange("Salesperson Code", SalespersonCode);
        end else
            Rec.SetRange("Salesperson Code");
        OnlyMine := NewOnlyMine;
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec."No. of Unread" > 0 then
            RowStyle := 'Strong'
        else
            RowStyle := 'Standard';
    end;
}
