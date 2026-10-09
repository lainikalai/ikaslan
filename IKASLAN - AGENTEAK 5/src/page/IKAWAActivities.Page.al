page 99366 "IKA WA Activities"
{
    // Pila de WhatsApp para las Áreas de trabajo: cada cifra abre la bandeja ya filtrada.
    Caption = 'WhatsApp';
    PageType = CardPart;
    SourceTable = "IKA WA Cue";
    RefreshOnActivate = true;
    ShowFilter = false;

    layout
    {
        area(Content)
        {
            cuegroup(Conversations)
            {
                Caption = 'Conversaciones';

                field("My Unread Conversations"; Rec."My Unread Conversations")
                {
                    ApplicationArea = All;
                    Visible = HasSalesperson;
                    ToolTip = 'Conversaciones con mensajes sin leer asignadas a su vendedor/comprador.';

                    trigger OnDrillDown()
                    begin
                        OpenConversations(1);
                    end;
                }
                field("Unread Conversations"; Rec."Unread Conversations")
                {
                    ApplicationArea = All;
                    ToolTip = 'Conversaciones con mensajes sin leer.';

                    trigger OnDrillDown()
                    begin
                        OpenConversations(0);
                    end;
                }
                field("Windows Closing Soon"; Rec."Windows Closing Soon")
                {
                    ApplicationArea = All;
                    ToolTip = 'Conversaciones en las que quedan menos de 4 horas para poder responder con texto libre; después solo se podrán usar plantillas.';

                    trigger OnDrillDown()
                    begin
                        OpenConversations(2);
                    end;
                }
                field("Not Linked Conversations"; Rec."Not Linked Conversations")
                {
                    ApplicationArea = All;
                    ToolTip = 'Conversaciones sin cliente, proveedor, contacto ni vendedor/comprador vinculado.';

                    trigger OnDrillDown()
                    begin
                        OpenConversations(3);
                    end;
                }
            }
            cuegroup(Shortcuts)
            {
                Caption = 'Acciones';

                actions
                {
                    action(OpenInbox)
                    {
                        ApplicationArea = All;
                        Caption = 'Abrir WhatsApp';
                        RunObject = page "IKA WA Conversations";
                        ToolTip = 'Abre la bandeja de WhatsApp.';
                    }
                }
            }
        }
    }

    var
        PhoneMgt: Codeunit "IKA WA Phone Mgt.";
        HasSalesperson: Boolean;
        WindowFrom: DateTime;
        WindowTo: DateTime;

    trigger OnOpenPage()
    var
        Account: Record "IKA WA Account";
        AllowedFilter: Text;
        SalespersonCode: Code[20];
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;

        AllowedFilter := Account.GetAllowedFilter();
        if AllowedFilter = '' then
            Rec.SetRange("Account Filter", '')
        else
            Rec.SetFilter("Account Filter", AllowedFilter);

        SalespersonCode := PhoneMgt.GetUserSalespersonCode();
        HasSalesperson := SalespersonCode <> '';
        if HasSalesperson then
            Rec.SetRange("Salesperson Filter", SalespersonCode);

        // Ventana abierta (último mensaje del cliente hace menos de 24 h) con menos de 4 h por delante
        WindowFrom := CurrentDateTime() - 24 * 60 * 60 * 1000;
        WindowTo := CurrentDateTime() - 20 * 60 * 60 * 1000;
        Rec.SetRange("Window Closing Filter", WindowFrom, WindowTo);
    end;

    local procedure OpenConversations(CueType: Integer)
    var
        Conversation: Record "IKA WA Conversation";
    begin
        case CueType of
            0:
                Conversation.SetFilter("No. of Unread", '>0');
            1:
                begin
                    Conversation.SetFilter("No. of Unread", '>0');
                    Conversation.SetRange("Salesperson Code", Rec.GetFilter("Salesperson Filter"));
                end;
            2:
                Conversation.SetRange("Last Inbound At", WindowFrom, WindowTo);
            3:
                Conversation.SetRange("Entity No.", '');
        end;
        Page.Run(Page::"IKA WA Conversations", Conversation);
    end;
}
