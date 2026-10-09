page 99446 "IKA CRM FactBox"
{
    // FactBox de las fichas de cliente, proveedor y contacto: registro del CRM vinculado, oportunidades abiertas
    // y última actividad. Lee del CRM solo si el registro está vinculado; un error de conexión se muestra en el
    // FactBox sin impedir trabajar con la ficha.
    Caption = 'CRM';
    PageType = CardPart;
    Editable = false;

    layout
    {
        area(Content)
        {
            field(StatusText; StatusText)
            {
                ApplicationArea = All;
                Caption = 'Estado';
                Visible = not Linked;
                StyleExpr = StatusStyle;
                ToolTip = 'Si el registro está vinculado con el CRM. Use "Vincular con el CRM".';
            }
            group(LinkedGroup)
            {
                ShowCaption = false;
                Visible = Linked;

                field(CrmName; CrmName)
                {
                    ApplicationArea = All;
                    CaptionClass = '3,' + CrmEntityText;
                    ToolTip = 'Cuenta o contacto del CRM vinculado. Pulse para ver su ficha con contactos, oportunidades y actividades.';

                    trigger OnDrillDown()
                    begin
                        ShowInBC();
                    end;
                }
                field(Phone; Phone)
                {
                    ApplicationArea = All;
                    Caption = 'Teléfono (CRM)';
                    ToolTip = 'Teléfono en el CRM.';
                }
                field(Email; Email)
                {
                    ApplicationArea = All;
                    Caption = 'Email (CRM)';
                    ToolTip = 'Correo electrónico en el CRM.';
                }
                field(Owner; Owner)
                {
                    ApplicationArea = All;
                    Caption = 'Propietario';
                    ToolTip = 'Propietario del registro en el CRM.';
                }
                field(OpenOpportunities; OpenOpportunities)
                {
                    ApplicationArea = All;
                    Caption = 'Oportunidades abiertas';
                    BlankZero = true;
                    ToolTip = 'Número de oportunidades abiertas en el CRM.';

                    trigger OnDrillDown()
                    begin
                        ShowInBC();
                    end;
                }
                field(OpenOpportunitiesValue; OpenOpportunitiesValue)
                {
                    ApplicationArea = All;
                    Caption = 'Ingresos estimados';
                    BlankZero = true;
                    AutoFormatType = 1;
                    ToolTip = 'Suma de los ingresos estimados de las oportunidades abiertas.';
                }
                field(LastActivity; LastActivity)
                {
                    ApplicationArea = All;
                    Caption = 'Última actividad';
                    ToolTip = 'Última actividad (llamada, cita, correo, tarea...) registrada en el CRM.';
                }
                field(ErrorText; ErrorText)
                {
                    ApplicationArea = All;
                    Caption = 'Error';
                    Style = Unfavorable;
                    Visible = ErrorText <> '';
                    ToolTip = 'No se han podido leer los datos del CRM.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Link)
            {
                ApplicationArea = All;
                Caption = 'Vincular con el CRM';
                Image = Link;
                ToolTip = 'Busca la cuenta o el contacto del CRM (propone el que tiene el mismo email o nombre) y lo vincula.';

                trigger OnAction()
                begin
                    if LinkMgt.LinkInteractive(SourceTableId, SourceNo) then
                        Reload();
                end;
            }
            action(OpenInCrm)
            {
                ApplicationArea = All;
                Caption = 'Abrir en el CRM';
                Image = Web;
                Enabled = Linked;
                ToolTip = 'Abre en el CRM el registro vinculado.';

                trigger OnAction()
                var
                    CrmLink: Record "IKA CRM Link";
                begin
                    if LinkMgt.GetLink(SourceTableId, SourceNo, CrmLink) then
                        LinkMgt.OpenLinkedInCrm(CrmLink);
                end;
            }
            action(ShowDetails)
            {
                ApplicationArea = All;
                Caption = 'Ver en BC';
                Image = View;
                Enabled = Linked;
                ToolTip = 'Ficha del registro del CRM con sus contactos, oportunidades y actividades.';

                trigger OnAction()
                begin
                    ShowInBC();
                end;
            }
            action(Unlink)
            {
                ApplicationArea = All;
                Caption = 'Quitar vínculo';
                Image = UnLinkAccount;
                Enabled = Linked;
                ToolTip = 'Deja de relacionar este registro de BC con el CRM (no borra nada en el CRM).';

                trigger OnAction()
                begin
                    LinkMgt.RemoveLink(SourceTableId, SourceNo);
                    Reload();
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Actualizar';
                Image = Refresh;
                Enabled = Linked;
                ToolTip = 'Vuelve a leer los datos del CRM.';

                trigger OnAction()
                begin
                    Reload();
                end;
            }
        }
    }

    var
        LinkMgt: Codeunit "IKA CRM Link Mgt.";
        SourceTableId: Integer;
        SourceNo: Code[20];
        LoadedKey: Text;
        Linked: Boolean;
        CrmEntityText: Text;
        CrmName: Text;
        Phone: Text;
        Email: Text;
        Owner: Text;
        OpenOpportunities: Integer;
        OpenOpportunitiesValue: Decimal;
        LastActivity: Text;
        ErrorText: Text;
        StatusText: Text;
        StatusStyle: Text;
        NotLinkedTxt: Label 'Sin vincular con el CRM';

    /// <summary>
    /// Registro de BC (cliente, proveedor o contacto) del que se muestran los datos del CRM.
    /// Se llama desde OnAfterGetCurrRecord de la ficha; solo lee del CRM si cambia el registro.
    /// </summary>
    procedure SetSource(TableId: Integer; No: Code[20])
    begin
        SourceTableId := TableId;
        SourceNo := No;
        if LoadedKey = Format(TableId) + '|' + No then
            exit;
        Reload();
    end;

    local procedure Reload()
    var
        CrmLink: Record "IKA CRM Link";
    begin
        LoadedKey := Format(SourceTableId) + '|' + SourceNo;
        ClearData();
        Linked := LinkMgt.GetLink(SourceTableId, SourceNo, CrmLink);
        if not Linked then begin
            StatusText := NotLinkedTxt;
            StatusStyle := 'Subordinate';
            exit;
        end;
        CrmEntityText := Format(CrmLink."CRM Entity");
        CrmName := CrmLink."CRM Name";
        ClearLastError();
        if not TryLoadCrmData(CrmLink) then
            ErrorText := GetLastErrorText();
    end;

    local procedure ClearData()
    begin
        CrmEntityText := '';
        CrmName := '';
        Phone := '';
        Email := '';
        Owner := '';
        OpenOpportunities := 0;
        OpenOpportunitiesValue := 0;
        LastActivity := '';
        ErrorText := '';
        StatusText := '';
    end;

    [TryFunction]
    local procedure TryLoadCrmData(CrmLink: Record "IKA CRM Link")
    var
        TempAccount: Record "IKA CRM Account Buffer" temporary;
        TempContact: Record "IKA CRM Contact Buffer" temporary;
        TempOpportunity: Record "IKA CRM Opportunity Buffer" temporary;
        TempActivity: Record "IKA CRM Activity Buffer" temporary;
        DataMgt: Codeunit "IKA CRM Data Mgt.";
    begin
        case CrmLink."CRM Entity" of
            CrmLink."CRM Entity"::Account:
                if DataMgt.GetAccount(CrmLink."CRM Id", TempAccount) then begin
                    CrmName := TempAccount.Name;
                    Phone := TempAccount.Phone;
                    Email := TempAccount."E-Mail";
                    Owner := TempAccount.Owner;
                end;
            CrmLink."CRM Entity"::Contact:
                if DataMgt.GetContact(CrmLink."CRM Id", TempContact) then begin
                    CrmName := TempContact."Full Name";
                    Phone := TempContact.Phone;
                    if Phone = '' then
                        Phone := TempContact."Mobile Phone";
                    Email := TempContact."E-Mail";
                    Owner := TempContact.Owner;
                end;
        end;

        DataMgt.LoadOpportunities(TempOpportunity, '', CrmLink."CRM Id", true);
        if TempOpportunity.FindSet() then
            repeat
                OpenOpportunities += 1;
                OpenOpportunitiesValue += TempOpportunity."Estimated Value";
            until TempOpportunity.Next() = 0;

        DataMgt.LoadActivities(TempActivity, CrmLink."CRM Id", 1);
        if TempActivity.FindFirst() then
            LastActivity := Format(DT2Date(TempActivity."Created On")) + ' · ' + TempActivity."Activity Type" + ': ' + TempActivity.Subject;
    end;

    local procedure ShowInBC()
    var
        CrmLink: Record "IKA CRM Link";
    begin
        if LinkMgt.GetLink(SourceTableId, SourceNo, CrmLink) then
            LinkMgt.ShowLinkedInBC(CrmLink);
    end;
}
