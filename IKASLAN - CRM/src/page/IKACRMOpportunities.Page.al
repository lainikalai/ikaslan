page 99426 "IKA CRM Opportunities"
{
    // Oportunidades del CRM leídas en directo, por fecha de cierre estimada.
    Caption = 'Oportunidades del CRM';
    PageType = Worksheet;
    SourceTable = "IKA CRM Opportunity Buffer";
    SourceTableView = sorting("Sorting No.");
    UsageCategory = Lists;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Search)
            {
                Caption = 'Buscar';

                field(SearchText; SearchText)
                {
                    ApplicationArea = All;
                    Caption = 'Buscar';
                    ToolTip = 'Texto que contiene el tema de la oportunidad. Pulse Intro para buscar en el CRM.';

                    trigger OnValidate()
                    begin
                        LoadData(true);
                    end;
                }
                field(OnlyOpen; OnlyOpen)
                {
                    ApplicationArea = All;
                    Caption = 'Solo abiertas';
                    ToolTip = 'Oculta las oportunidades ganadas o perdidas.';

                    trigger OnValidate()
                    begin
                        LoadData(true);
                    end;
                }
                field(TotalValue; TotalValue)
                {
                    ApplicationArea = All;
                    Caption = 'Total ingresos estimados';
                    Editable = false;
                    AutoFormatType = 1;
                    ToolTip = 'Suma de los ingresos estimados de las oportunidades de la lista.';
                }
            }
            repeater(Lines)
            {
                Editable = false;

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Tema de la oportunidad.';
                }
                field("Customer Name"; Rec."Customer Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cuenta o contacto de la oportunidad.';

                    trigger OnDrillDown()
                    begin
                        ShowCustomer();
                    end;
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
                field("Status Reason"; Rec."Status Reason")
                {
                    ApplicationArea = All;
                    ToolTip = 'Razón para el estado.';
                }
                field(Owner; Rec.Owner)
                {
                    ApplicationArea = All;
                    ToolTip = 'Propietario en el CRM.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Estado (abierta, ganada, perdida).';
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
                ToolTip = 'Vuelve a leer las oportunidades del CRM.';

                trigger OnAction()
                begin
                    LoadData(true);
                end;
            }
            action(OpenInCrm)
            {
                ApplicationArea = All;
                Caption = 'Abrir en el CRM';
                Image = Web;
                ToolTip = 'Abre la oportunidad en el CRM.';

                trigger OnAction()
                begin
                    DataMgt.OpenInCrm('opportunity', Rec."Opportunity Id");
                end;
            }
        }
        area(Navigation)
        {
            action(Customer)
            {
                ApplicationArea = All;
                Caption = 'Cuenta';
                Image = Company;
                ToolTip = 'Ficha de la cuenta de la oportunidad.';

                trigger OnAction()
                begin
                    ShowCustomer();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(OpenInCrm_Promoted; OpenInCrm) { }
                actionref(Customer_Promoted; Customer) { }
                actionref(Refresh_Promoted; Refresh) { }
            }
        }
    }

    var
        DataMgt: Codeunit "IKA CRM Data Mgt.";
        SearchText: Text;
        OnlyOpen: Boolean;
        TotalValue: Decimal;
        NullGuid: Guid;

    trigger OnOpenPage()
    begin
        OnlyOpen := true;
        LoadData(false);
    end;

    local procedure LoadData(UpdatePage: Boolean)
    begin
        DataMgt.LoadOpportunities(Rec, SearchText, NullGuid, OnlyOpen);
        TotalValue := 0;
        if Rec.FindSet() then
            repeat
                TotalValue += Rec."Estimated Value";
            until Rec.Next() = 0;
        if Rec.FindFirst() then;
        if UpdatePage then
            CurrPage.Update(false);
    end;

    local procedure ShowCustomer()
    var
        TempAccount: Record "IKA CRM Account Buffer" temporary;
        CrmAccount: Page "IKA CRM Account";
    begin
        // El cliente de una oportunidad puede ser una cuenta o un contacto; solo las cuentas tienen ficha aquí
        if IsNullGuid(Rec."Customer Id") then
            exit;
        if not DataMgt.GetAccount(Rec."Customer Id", TempAccount) then begin
            DataMgt.OpenInCrm('contact', Rec."Customer Id");
            exit;
        end;
        CrmAccount.SetAccount(TempAccount);
        CrmAccount.Run();
    end;
}
