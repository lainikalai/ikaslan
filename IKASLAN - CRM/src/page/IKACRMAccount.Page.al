page 99411 "IKA CRM Account"
{
    // Ficha de una cuenta del CRM (en directo, solo lectura) con sus contactos, oportunidades abiertas y
    // últimas actividades.
    Caption = 'Cuenta del CRM';
    PageType = Card;
    SourceTable = "IKA CRM Account Buffer";
    UsageCategory = None;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;
    DataCaptionFields = Name;

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'General';

                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    ToolTip = 'Nombre de la cuenta.';
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
                field(Industry; Rec.Industry)
                {
                    ApplicationArea = All;
                    ToolTip = 'Sector.';
                }
                field("Primary Contact"; Rec."Primary Contact")
                {
                    ApplicationArea = All;
                    ToolTip = 'Contacto principal.';
                }
                field(Owner; Rec.Owner)
                {
                    ApplicationArea = All;
                    ToolTip = 'Propietario en el CRM.';
                }
                field(Status; Rec.Status)
                {
                    ApplicationArea = All;
                    ToolTip = 'Estado en el CRM.';
                }
            }
            group(Communication)
            {
                Caption = 'Dirección y contacto';

                field(Address; Rec.Address)
                {
                    ApplicationArea = All;
                    ToolTip = 'Dirección.';
                }
                field("Post Code"; Rec."Post Code")
                {
                    ApplicationArea = All;
                    ToolTip = 'Código postal.';
                }
                field(City; Rec.City)
                {
                    ApplicationArea = All;
                    ToolTip = 'Ciudad.';
                }
                field(County; Rec.County)
                {
                    ApplicationArea = All;
                    ToolTip = 'Provincia.';
                }
                field(Country; Rec.Country)
                {
                    ApplicationArea = All;
                    ToolTip = 'País.';
                }
                field(Phone; Rec.Phone)
                {
                    ApplicationArea = All;
                    ToolTip = 'Teléfono principal.';
                }
                field("E-Mail"; Rec."E-Mail")
                {
                    ApplicationArea = All;
                    ExtendedDatatype = EMail;
                    ToolTip = 'Correo electrónico.';
                }
                field(Website; Rec.Website)
                {
                    ApplicationArea = All;
                    ExtendedDatatype = URL;
                    ToolTip = 'Sitio web.';
                }
            }
            part(Contacts; "IKA CRM Contacts Part")
            {
                ApplicationArea = All;
            }
            part(Opportunities; "IKA CRM Opportunities Part")
            {
                ApplicationArea = All;
            }
            part(Activities; "IKA CRM Activities Part")
            {
                ApplicationArea = All;
                Caption = 'Últimas actividades';
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
                ToolTip = 'Abre la cuenta en el CRM.';

                trigger OnAction()
                begin
                    DataMgt.OpenInCrm('account', Rec."Account Id");
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Actualizar';
                Image = Refresh;
                ShortcutKey = 'F5';
                ToolTip = 'Vuelve a leer del CRM los contactos, oportunidades y actividades de la cuenta.';

                trigger OnAction()
                begin
                    LoadRelated();
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
        LoadedAccountId: Guid;

    /// <summary>
    /// Cuenta a mostrar (antes de Run).
    /// </summary>
    procedure SetAccount(var TempAccount: Record "IKA CRM Account Buffer" temporary)
    begin
        Rec.Reset();
        Rec.DeleteAll();
        Rec := TempAccount;
        Rec.Insert();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        if IsNullGuid(Rec."Account Id") or (Rec."Account Id" = LoadedAccountId) then
            exit;
        LoadRelated();
    end;

    local procedure LoadRelated()
    var
        TempContact: Record "IKA CRM Contact Buffer" temporary;
        TempOpportunity: Record "IKA CRM Opportunity Buffer" temporary;
        TempActivity: Record "IKA CRM Activity Buffer" temporary;
    begin
        LoadedAccountId := Rec."Account Id";
        DataMgt.LoadContacts(TempContact, '', Rec."Account Id", false);
        CurrPage.Contacts.Page.SetData(TempContact);
        CurrPage.Contacts.Page.Update(false);
        DataMgt.LoadOpportunities(TempOpportunity, '', Rec."Account Id", true);
        CurrPage.Opportunities.Page.SetData(TempOpportunity);
        CurrPage.Opportunities.Page.Update(false);
        DataMgt.LoadActivities(TempActivity, Rec."Account Id", 20);
        CurrPage.Activities.Page.SetData(TempActivity);
        CurrPage.Activities.Page.Update(false);
    end;
}
