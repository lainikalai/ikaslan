page 50630 "IKA WA Conversations"
{
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
        }
        area(Navigation)
        {
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
        RowStyle: Text;

    trigger OnOpenPage()
    var
        Account: Record "IKA WA Account";
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
        // Al abrir la bandeja se procesa lo que haya llegado (además de la cola de proyectos)
        InboundProcessor.ProcessPending();
    end;

    trigger OnAfterGetRecord()
    begin
        if Rec."No. of Unread" > 0 then
            RowStyle := 'Strong'
        else
            RowStyle := 'Standard';
    end;
}
