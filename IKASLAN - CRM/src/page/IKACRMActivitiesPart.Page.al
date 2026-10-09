page 99441 "IKA CRM Activities Part"
{
    Caption = 'Actividades';
    PageType = ListPart;
    SourceTable = "IKA CRM Activity Buffer";
    SourceTableView = sorting("Sorting No.");
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Created On"; Rec."Created On")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha de creación.';
                }
                field("Activity Type"; Rec."Activity Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Tipo de actividad (llamada, cita, correo, tarea...).';
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = All;
                    ToolTip = 'Asunto.';
                }
                field("Scheduled End"; Rec."Scheduled End")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha de vencimiento.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Estado (abierta, completada, cancelada).';
                }
                field(Owner; Rec.Owner)
                {
                    ApplicationArea = All;
                    ToolTip = 'Propietario en el CRM.';
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
                ToolTip = 'Abre la actividad en el CRM.';

                trigger OnAction()
                var
                    DataMgt: Codeunit "IKA CRM Data Mgt.";
                begin
                    DataMgt.OpenInCrm(Rec."Activity Type Code", Rec."Activity Id");
                end;
            }
        }
    }

    procedure SetData(var TempActivity: Record "IKA CRM Activity Buffer" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();
        if TempActivity.FindSet() then
            repeat
                Rec := TempActivity;
                Rec.Insert();
            until TempActivity.Next() = 0;
        if Rec.FindFirst() then;
    end;
}
