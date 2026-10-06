page 50260 "IKA DN Files"
{
    Caption = 'Ficheros';
    PageType = ListPart;
    SourceTable = "IKA DN File";
    InsertAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("File Name"; Rec."File Name")
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    begin
                        Rec.ExportToClient();
                    end;
                }
                field("Sent to Claude"; Rec."Sent to Claude")
                {
                    ApplicationArea = All;
                }
                field("Skip Reason"; Rec."Skip Reason")
                {
                    ApplicationArea = All;
                }
                field("Size (Bytes)"; Rec."Size (Bytes)")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Content Type"; Rec."Content Type")
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
                Caption = 'Descargar';
                Image = Download;
                ToolTip = 'Descarga el fichero adjunto.';

                trigger OnAction()
                begin
                    Rec.ExportToClient();
                end;
            }
        }
    }
}
