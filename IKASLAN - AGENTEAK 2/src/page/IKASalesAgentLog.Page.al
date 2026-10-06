page 99031 "IKA Sales Agent Log"
{
    Caption = 'Registro agente de ventas';
    PageType = List;
    SourceTable = "IKA Sales Agent Log";
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
                field("Created At"; Rec."Created At")
                {
                    ApplicationArea = All;
                }
                field("Log Type"; Rec."Log Type")
                {
                    ApplicationArea = All;
                }
                field("Request Entry No."; Rec."Request Entry No.")
                {
                    ApplicationArea = All;
                }
                field(Message; Rec.Message)
                {
                    ApplicationArea = All;
                }
                field("HTTP Status"; Rec."HTTP Status")
                {
                    ApplicationArea = All;
                }
                field(Model; Rec.Model)
                {
                    ApplicationArea = All;
                }
                field("Input Tokens"; Rec."Input Tokens")
                {
                    ApplicationArea = All;
                }
                field("Output Tokens"; Rec."Output Tokens")
                {
                    ApplicationArea = All;
                }
                field(Duration; Rec.Duration)
                {
                    ApplicationArea = All;
                }
                field("User ID"; Rec."User ID")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DownloadRequest)
            {
                ApplicationArea = All;
                Caption = 'Descargar petición';
                Image = Download;
                ToolTip = 'Descarga el JSON enviado (los ficheros en base64 se omiten).';

                trigger OnAction()
                begin
                    Rec.DownloadPayload(0);
                end;
            }
            action(DownloadResponse)
            {
                ApplicationArea = All;
                Caption = 'Descargar respuesta';
                Image = Download;
                ToolTip = 'Descarga el JSON recibido.';

                trigger OnAction()
                begin
                    Rec.DownloadPayload(1);
                end;
            }
            action(DeleteOld)
            {
                ApplicationArea = All;
                Caption = 'Borrar registros de más de 90 días';
                Image = Delete;
                ToolTip = 'Elimina las entradas antiguas del registro.';

                trigger OnAction()
                var
                    AgentLog: Record "IKA Sales Agent Log";
                begin
                    AgentLog.SetFilter("Created At", '<%1', CreateDateTime(Today() - 90, 0T));
                    AgentLog.DeleteAll();
                end;
            }
        }
    }
}
