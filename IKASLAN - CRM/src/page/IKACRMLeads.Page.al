page 99421 "IKA CRM Leads"
{
    // Clientes potenciales (prospectos) del CRM leídos en directo, los más recientes primero.
    Caption = 'Clientes potenciales del CRM';
    PageType = Worksheet;
    SourceTable = "IKA CRM Lead Buffer";
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
                    ToolTip = 'Texto que contiene el nombre, la empresa, el tema o el email. Pulse Intro para buscar en el CRM.';

                    trigger OnValidate()
                    begin
                        LoadData(true);
                    end;
                }
                field(OnlyOpen; OnlyOpen)
                {
                    ApplicationArea = All;
                    Caption = 'Solo abiertos';
                    ToolTip = 'Oculta los clientes potenciales ya cualificados o descalificados.';

                    trigger OnValidate()
                    begin
                        LoadData(true);
                    end;
                }
            }
            repeater(Lines)
            {
                Editable = false;

                field(Topic; Rec.Topic)
                {
                    ApplicationArea = All;
                    ToolTip = 'Tema del cliente potencial.';
                }
                field("Full Name"; Rec."Full Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre de la persona.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Empresa.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = All;
                    ToolTip = 'Correo electrónico.';
                }
                field(Phone; Rec.Phone)
                {
                    ApplicationArea = All;
                    ToolTip = 'Teléfono del trabajo.';
                }
                field("Mobile Phone"; Rec."Mobile Phone")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Teléfono móvil.';
                }
                field("Lead Source"; Rec."Lead Source")
                {
                    ApplicationArea = All;
                    ToolTip = 'Origen del cliente potencial.';
                }
                field(Rating; Rec.Rating)
                {
                    ApplicationArea = All;
                    ToolTip = 'Calificación (caliente, templado, frío).';
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
                field("Created On"; Rec."Created On")
                {
                    ApplicationArea = All;
                    ToolTip = 'Fecha de creación en el CRM.';
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
                ToolTip = 'Vuelve a leer los clientes potenciales del CRM.';

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
                ToolTip = 'Abre el cliente potencial en el CRM (para cualificarlo, descalificarlo o editarlo).';

                trigger OnAction()
                begin
                    DataMgt.OpenInCrm('lead', Rec."Lead Id");
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(OpenInCrm_Promoted; OpenInCrm) { }
                actionref(Refresh_Promoted; Refresh) { }
            }
        }
    }

    var
        DataMgt: Codeunit "IKA CRM Data Mgt.";
        SearchText: Text;
        OnlyOpen: Boolean;

    trigger OnOpenPage()
    begin
        OnlyOpen := true;
        LoadData(false);
    end;

    local procedure LoadData(UpdatePage: Boolean)
    begin
        DataMgt.LoadLeads(Rec, SearchText, OnlyOpen);
        if UpdatePage then
            CurrPage.Update(false);
    end;
}
