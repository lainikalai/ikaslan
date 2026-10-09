page 99436 "IKA CRM Opportunities Part"
{
    Caption = 'Oportunidades abiertas';
    PageType = ListPart;
    SourceTable = "IKA CRM Opportunity Buffer";
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
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Tema de la oportunidad.';
                }
                field("Estimated Value"; Rec."Estimated Value")
                {
                    ApplicationArea = All;
                    ToolTip = 'Ingresos estimados.';
                }
                field("Est. Close Date"; Rec."Est. Close Date")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha de cierre estimada.';
                }
                field("Probability %"; Rec."Probability %")
                {
                    ApplicationArea = All;
                    ToolTip = 'Probabilidad de ganarla.';
                }
                field("Sales Stage"; Rec."Sales Stage")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fase del proceso de ventas.';
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
                ToolTip = 'Abre la oportunidad en el CRM.';

                trigger OnAction()
                var
                    DataMgt: Codeunit "IKA CRM Data Mgt.";
                begin
                    DataMgt.OpenInCrm('opportunity', Rec."Opportunity Id");
                end;
            }
        }
    }

    procedure SetData(var TempOpportunity: Record "IKA CRM Opportunity Buffer" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();
        if TempOpportunity.FindSet() then
            repeat
                Rec := TempOpportunity;
                Rec.Insert();
            until TempOpportunity.Next() = 0;
        if Rec.FindFirst() then;
    end;
}
