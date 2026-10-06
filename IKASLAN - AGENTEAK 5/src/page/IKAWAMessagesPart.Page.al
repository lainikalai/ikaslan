page 99336 "IKA WA Messages Part"
{
    Caption = 'Mensajes';
    PageType = ListPart;
    SourceTable = "IKA WA Message";
    SourceTableView = sorting("Conversation Entry No.", "Sent At") order(descending);
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Sent At"; Rec."Sent At")
                {
                    ApplicationArea = All;
                    StyleExpr = RowStyle;
                }
                field(DirectionIcon; DirectionIcon)
                {
                    ApplicationArea = All;
                    Caption = ' ';
                    StyleExpr = RowStyle;
                }
                field(DisplayText; Rec.GetDisplayText())
                {
                    ApplicationArea = All;
                    Caption = 'Mensaje';
                    StyleExpr = RowStyle;

                    trigger OnDrillDown()
                    begin
                        Message('%1', Rec.GetFullText());
                    end;
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    StyleExpr = StatusStyle;
                }
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    begin
                        DownloadMedia();
                    end;
                }
                field("Attached to Entity"; Rec."Attached to Entity")
                {
                    ApplicationArea = All;
                }
                field("Error Text"; Rec."Error Text")
                {
                    ApplicationArea = All;
                    Style = Unfavorable;
                }
                field("Sent By"; Rec."Sent By")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Source Document No."; Rec."Source Document No.")
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
            action(Download)
            {
                ApplicationArea = All;
                Caption = 'Descargar fichero';
                Image = Download;
                Enabled = Rec."Media ID" <> '';
                ToolTip = 'Descarga la foto, PDF o audio del mensaje.';

                trigger OnAction()
                begin
                    DownloadMedia();
                end;
            }
            action(AttachToEntity)
            {
                ApplicationArea = All;
                Caption = 'Adjuntar a la entidad';
                Image = Attach;
                Enabled = Rec."Media ID" <> '';
                ToolTip = 'Guarda el fichero en los documentos adjuntos del cliente, proveedor o contacto de la conversación.';

                trigger OnAction()
                var
                    Conversation: Record "IKA WA Conversation";
                    CloudApi: Codeunit "IKA WA Cloud API";
                    PhoneMgt: Codeunit "IKA WA Phone Mgt.";
                    NotLinkedErr: Label 'Vincule primero la conversación a un cliente, proveedor o contacto.';
                    AttachedMsg: Label '%1 adjuntado a %2 %3.', Comment = '%1 = file, %2 = entity type, %3 = no.';
                begin
                    Conversation.Get(Rec."Conversation Entry No.");
                    if Conversation."Entity No." = '' then
                        Error(NotLinkedErr);
                    CloudApi.DownloadMedia(Rec);
                    PhoneMgt.AttachMediaToEntity(Rec, Conversation."Entity Type", Conversation."Entity No.");
                    Message(AttachedMsg, Rec."File Name", Conversation."Entity Type", Conversation."Entity No.");
                end;
            }
        }
    }

    var
        DirectionIcon: Text;
        RowStyle: Text;
        StatusStyle: Text;

    trigger OnAfterGetRecord()
    begin
        if Rec.Direction = Rec.Direction::Inbound then begin
            DirectionIcon := '◀';
            RowStyle := 'Strong';
        end else begin
            DirectionIcon := '▶';
            RowStyle := 'Standard';
        end;
        case Rec.Status of
            Rec.Status::Failed:
                StatusStyle := 'Unfavorable';
            Rec.Status::Read:
                StatusStyle := 'Favorable';
            else
                StatusStyle := 'Standard';
        end;
    end;

    local procedure DownloadMedia()
    var
        CloudApi: Codeunit "IKA WA Cloud API";
        InStr: InStream;
        FileName: Text;
    begin
        if Rec."Media ID" = '' then
            exit;
        CloudApi.DownloadMedia(Rec);
        Rec.CalcFields("Media Content");
        Rec."Media Content".CreateInStream(InStr);
        FileName := Rec."File Name";
        if FileName = '' then
            FileName := CloudApi.GetDefaultFileName(Rec);
        DownloadFromStream(InStr, '', '', '', FileName);
    end;
}
