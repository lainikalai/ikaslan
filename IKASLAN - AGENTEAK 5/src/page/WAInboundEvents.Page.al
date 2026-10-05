page 50660 "IKA WA Inbound Events"
{
    Caption = 'Eventos recibidos de WhatsApp';
    PageType = List;
    SourceTable = "IKA WA Inbound Event";
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
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = All;
                }
                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = All;
                }
                field("Event Kind"; Rec."Event Kind")
                {
                    ApplicationArea = All;
                }
                field("From Phone"; Rec."From Phone")
                {
                    ApplicationArea = All;
                }
                field("Profile Name"; Rec."Profile Name")
                {
                    ApplicationArea = All;
                }
                field("Message Type"; Rec."Message Type")
                {
                    ApplicationArea = All;
                }
                field("Text Part 1"; Rec."Text Part 1")
                {
                    ApplicationArea = All;
                }
                field("Status Value"; Rec."Status Value")
                {
                    ApplicationArea = All;
                }
                field(Processed; Rec.Processed)
                {
                    ApplicationArea = All;
                }
                field("Processing Error"; Rec."Processing Error")
                {
                    ApplicationArea = All;
                    Style = Unfavorable;
                }
                field("Error Text"; Rec."Error Text")
                {
                    ApplicationArea = All;
                }
                field("Phone Number ID"; Rec."Phone Number ID")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("WA Message ID"; Rec."WA Message ID")
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
            action(ProcessPending)
            {
                ApplicationArea = All;
                Caption = 'Procesar pendientes';
                Image = Refresh;
                ToolTip = 'Vuelve a intentar los eventos no procesados.';

                trigger OnAction()
                var
                    InboundProcessor: Codeunit "IKA WA Inbound Processor";
                begin
                    InboundProcessor.ProcessPending();
                    CurrPage.Update(false);
                end;
            }
            action(DeleteOld)
            {
                ApplicationArea = All;
                Caption = 'Borrar procesados de más de 30 días';
                Image = Delete;
                ToolTip = 'Limpia la cola de entrada (los mensajes se conservan).';

                trigger OnAction()
                var
                    InboundEvent: Record "IKA WA Inbound Event";
                begin
                    InboundEvent.SetRange(Processed, true);
                    InboundEvent.SetFilter("Received At", '<%1', CreateDateTime(Today() - 30, 0T));
                    InboundEvent.DeleteAll();
                end;
            }
        }
    }

    views
    {
        view(WithErrors)
        {
            Caption = 'Con error';
            Filters = where(Processed = const(false));
        }
    }
}
