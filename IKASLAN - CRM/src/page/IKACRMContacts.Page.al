page 99416 "IKA CRM Contacts"
{
    // Contactos (personas) del CRM leídos en directo. Se usa también para elegir el contacto al vincular un
    // contacto de BC de tipo persona (modo búsqueda).
    Caption = 'Contactos del CRM';
    PageType = Worksheet;
    SourceTable = "IKA CRM Contact Buffer";
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
                    ToolTip = 'Texto que contiene el nombre, el email o los teléfonos. Pulse Intro para buscar en el CRM.';

                    trigger OnValidate()
                    begin
                        LoadData(true);
                    end;
                }
                field(IncludeInactive; IncludeInactive)
                {
                    ApplicationArea = All;
                    Caption = 'Incluir inactivos';
                    ToolTip = 'Muestra también los contactos desactivados en el CRM.';

                    trigger OnValidate()
                    begin
                        LoadData(true);
                    end;
                }
            }
            repeater(Lines)
            {
                Editable = false;

                field("Full Name"; Rec."Full Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre completo.';
                }
                field("Job Title"; Rec."Job Title")
                {
                    ApplicationArea = All;
                    ToolTip = 'Puesto.';
                }
                field("Company Name"; Rec."Company Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Cuenta (empresa) del contacto.';

                    trigger OnDrillDown()
                    begin
                        ShowCompany();
                    end;
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
                    ToolTip = 'Teléfono móvil.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Ciudad.';
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
                    ToolTip = 'Estado en el CRM.';
                }
                field("Modified On"; Rec."Modified On")
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Última modificación en el CRM.';
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
                ToolTip = 'Vuelve a leer los contactos del CRM.';

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
                ToolTip = 'Abre el contacto en el CRM.';

                trigger OnAction()
                begin
                    DataMgt.OpenInCrm('contact', Rec."Contact Id");
                end;
            }
        }
        area(Navigation)
        {
            action(Company)
            {
                ApplicationArea = All;
                Caption = 'Cuenta';
                Image = Company;
                ToolTip = 'Ficha de la cuenta (empresa) del contacto.';

                trigger OnAction()
                begin
                    ShowCompany();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(OpenInCrm_Promoted; OpenInCrm) { }
                actionref(Company_Promoted; Company) { }
                actionref(Refresh_Promoted; Refresh) { }
            }
        }
    }

    var
        DataMgt: Codeunit "IKA CRM Data Mgt.";
        SearchText: Text;
        IncludeInactive: Boolean;
        NullGuid: Guid;

    trigger OnOpenPage()
    begin
        LoadData(false);
    end;

    procedure SetSearchText(NewSearchText: Text)
    begin
        SearchText := NewSearchText;
    end;

    procedure GetSelectedContact(var TempContact: Record "IKA CRM Contact Buffer" temporary): Boolean
    begin
        if IsNullGuid(Rec."Contact Id") then
            exit(false);
        TempContact := Rec;
        exit(true);
    end;

    local procedure LoadData(UpdatePage: Boolean)
    begin
        DataMgt.LoadContacts(Rec, SearchText, NullGuid, IncludeInactive);
        if UpdatePage then
            CurrPage.Update(false);
    end;

    local procedure ShowCompany()
    var
        TempAccount: Record "IKA CRM Account Buffer" temporary;
        CrmAccount: Page "IKA CRM Account";
    begin
        if IsNullGuid(Rec."Company Id") then
            exit;
        if not DataMgt.GetAccount(Rec."Company Id", TempAccount) then
            exit;
        CrmAccount.SetAccount(TempAccount);
        CrmAccount.Run();
    end;
}
