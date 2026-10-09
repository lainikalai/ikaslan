page 99406 "IKA CRM Accounts"
{
    // Cuentas del CRM leídas en directo (no se guardan en BC). Se usa también para elegir la cuenta al vincular
    // un cliente o proveedor (modo búsqueda).
    Caption = 'Cuentas del CRM';
    PageType = Worksheet;
    SourceTable = "IKA CRM Account Buffer";
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
                    Editable = true;
                    ToolTip = 'Texto que contiene el nombre, el nº de cuenta, el email o la ciudad. Pulse Intro para buscar en el CRM.';

                    trigger OnValidate()
                    begin
                        LoadData(true);
                    end;
                }
                field(IncludeInactive; IncludeInactive)
                {
                    ApplicationArea = All;
                    Caption = 'Incluir inactivas';
                    Editable = true;
                    ToolTip = 'Muestra también las cuentas desactivadas en el CRM.';

                    trigger OnValidate()
                    begin
                        LoadData(true);
                    end;
                }
            }
            repeater(Lines)
            {
                Editable = false;

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre de la cuenta.';

                    trigger OnDrillDown()
                    begin
                        ShowCard();
                    end;
                }
                field("Account Number"; Rec."Account Number")
                {
                    ApplicationArea = All;
                    ToolTip = 'Nº de cuenta en el CRM.';
                }
                field("Relationship Type"; Rec."Relationship Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Tipo de relación (cliente, proveedor, socio...).';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                    ToolTip = 'Ciudad.';
                }
                field(Phone; Rec.Phone)
                {
                    ApplicationArea = All;
                    ToolTip = 'Teléfono principal.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = All;
                    ToolTip = 'Correo electrónico.';
                }
                field("Primary Contact"; Rec."Primary Contact")
                {
                    ApplicationArea = All;
                    ToolTip = 'Contacto principal de la cuenta.';
                }
                field(Owner; Rec.Owner)
                {
                    ApplicationArea = All;
                    ToolTip = 'Propietario en el CRM.';
                }
                field(Industry; Rec.Industry)
                {
                    ApplicationArea = All;
                    Visible = false;
                    ToolTip = 'Sector.';
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
                ToolTip = 'Vuelve a leer las cuentas del CRM.';

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
                ToolTip = 'Abre la cuenta en el CRM.';

                trigger OnAction()
                begin
                    DataMgt.OpenInCrm('account', Rec."Account Id");
                end;
            }
        }
        area(Navigation)
        {
            action(Card)
            {
                ApplicationArea = All;
                Caption = 'Ficha';
                Image = Card;
                ShortcutKey = 'Shift+F7';
                ToolTip = 'Datos de la cuenta con sus contactos, oportunidades y actividades.';

                trigger OnAction()
                begin
                    ShowCard();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(Card_Promoted; Card) { }
                actionref(OpenInCrm_Promoted; OpenInCrm) { }
                actionref(Refresh_Promoted; Refresh) { }
            }
        }
    }

    var
        DataMgt: Codeunit "IKA CRM Data Mgt.";
        SearchText: Text;
        IncludeInactive: Boolean;

    trigger OnOpenPage()
    begin
        LoadData(false);
    end;

    procedure SetSearchText(NewSearchText: Text)
    begin
        SearchText := NewSearchText;
    end;

    procedure GetSelectedAccount(var TempAccount: Record "IKA CRM Account Buffer" temporary): Boolean
    begin
        if IsNullGuid(Rec."Account Id") then
            exit(false);
        TempAccount := Rec;
        exit(true);
    end;

    local procedure LoadData(UpdatePage: Boolean)
    begin
        DataMgt.LoadAccounts(Rec, SearchText, IncludeInactive);
        if UpdatePage then
            CurrPage.Update(false);
    end;

    local procedure ShowCard()
    var
        CrmAccount: Page "IKA CRM Account";
    begin
        if IsNullGuid(Rec."Account Id") then
            exit;
        CrmAccount.SetAccount(Rec);
        CrmAccount.Run();
    end;
}
