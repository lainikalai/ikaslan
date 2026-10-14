page 99241 "IKA Mail Address Emails"
{
    // FactBox con los emails enviados y recibidos con una dirección, buscados en Outlook 365 (todas las
    // carpetas de las cuentas a las que tiene acceso el usuario). La página que lo contiene le pasa la
    // dirección (y, si quiere, un texto del asunto) con SetContext, p.ej. en OnAfterGetCurrRecord:
    //     CurrPage."IKA Mail Address Emails".Page.SetContext(Rec."E-Mail", '');
    // Para un documento (pedido, albarán, factura) se puede pasar el email del cliente/proveedor y el nº
    // del documento como asunto. El usuario puede cambiar los dos filtros en el propio FactBox.
    Caption = 'Emails enviados y recibidos';
    PageType = ListPart;
    SourceTable = "IKA Mail Message";
    SourceTableTemporary = true;
    SourceTableView = sorting("Received At") order(descending);
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                ShowCaption = false;

                field(AddressFilterText; AddressFilterText)
                {
                    ApplicationArea = All;
                    Caption = 'Email';
                    ExtendedDatatype = EMail;
                    ToolTip = 'Dirección (o varias separadas por ;) con la que se han enviado o recibido los emails. Con @dominio.com se busca todo el dominio.';

                    trigger OnValidate()
                    begin
                        LoadEmails();
                    end;
                }
                field(SubjectFilterText; SubjectFilterText)
                {
                    ApplicationArea = All;
                    Caption = 'Asunto';
                    ToolTip = 'Palabras que debe contener el asunto (todas). Admite * al final de una palabra, p.ej. pedi*.';

                    trigger OnValidate()
                    begin
                        LoadEmails();
                    end;
                }
                field(StatusText; StatusText)
                {
                    ApplicationArea = All;
                    Caption = 'Resultado';
                    Editable = false;
                    Style = Subordinate;
                    ToolTip = 'Cuántos emails se han encontrado, o por qué no se ha podido buscar.';
                }
            }
            repeater(Lines)
            {
                Editable = false;

                field("Received At"; Rec."Received At")
                {
                    ApplicationArea = All;
                    Caption = 'Fecha';
                    StyleExpr = RowStyle;
                    ToolTip = 'Fecha de recepción (o de envío, en los enviados).';
                }
                field(DirectionText; DirectionText)
                {
                    ApplicationArea = All;
                    Caption = 'Tipo';
                    StyleExpr = DirectionStyle;
                    ToolTip = 'Enviado desde una cuenta de la empresa o recibido en ella.';
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = All;
                    StyleExpr = RowStyle;
                    ToolTip = 'Pulse para abrir el email.';

                    trigger OnDrillDown()
                    begin
                        AddressSearch.OpenMessage(Rec);
                    end;
                }
                field(CounterpartText; CounterpartText)
                {
                    ApplicationArea = All;
                    Caption = 'De / Para';
                    ToolTip = 'Remitente de los recibidos y destinatarios de los enviados.';
                }
                field("Has Attachments"; Rec."Has Attachments")
                {
                    ApplicationArea = All;
                    Caption = '📎';
                    Visible = false;
                }
                field("Mailbox Code"; Rec."Mailbox Code")
                {
                    ApplicationArea = All;
                    Caption = 'Cuenta';
                    Visible = false;
                    ToolTip = 'Cuenta de Outlook 365 en la que está el email.';
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
                ToolTip = 'Vuelve a buscar en Outlook con los filtros actuales.';

                trigger OnAction()
                begin
                    LoadEmails();
                end;
            }
            action(ChangeFilters)
            {
                ApplicationArea = All;
                Caption = 'Cambiar filtros';
                Image = EditFilter;
                ToolTip = 'Cambia el email y el texto del asunto que se buscan.';

                trigger OnAction()
                var
                    AddressFilterDialog: Page "IKA Mail Address Filter";
                begin
                    AddressFilterDialog.SetFilters(AddressFilterText, SubjectFilterText);
                    if AddressFilterDialog.RunModal() <> Action::OK then
                        exit;
                    AddressFilterDialog.GetFilters(AddressFilterText, SubjectFilterText);
                    LoadEmails();
                end;
            }
            action(ResetFilters)
            {
                ApplicationArea = All;
                Caption = 'Restablecer filtros';
                Image = ClearFilter;
                ToolTip = 'Vuelve al email y asunto de la ficha.';

                trigger OnAction()
                begin
                    AddressFilterText := ContextAddresses;
                    SubjectFilterText := ContextSubject;
                    LoadEmails();
                end;
            }
            action(OpenEmail)
            {
                ApplicationArea = All;
                Caption = 'Abrir email';
                Image = Email;
                ToolTip = 'Abre el email en BC (cuerpo, adjuntos, responder y adjuntar a entidades).';

                trigger OnAction()
                begin
                    AddressSearch.OpenMessage(Rec);
                end;
            }
            action(OpenInOutlook)
            {
                ApplicationArea = All;
                Caption = 'Abrir en Outlook';
                Image = Web;
                ToolTip = 'Abre el email en Outlook en la web.';

                trigger OnAction()
                begin
                    AddressSearch.OpenInOutlook(Rec);
                end;
            }
            action(SearchDetails)
            {
                ApplicationArea = All;
                Caption = 'Detalle de la búsqueda';
                Image = ViewDetails;
                ToolTip = 'Muestra qué consultas se han hecho en cada cuenta de Outlook, cuántos emails ha devuelto cada una y los errores. Útil si no aparece un email que debería.';

                trigger OnAction()
                begin
                    Message(AddressSearch.GetSearchLog());
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = All;
                Caption = 'Ver en lista';
                Image = List;
                ToolTip = 'Abre la lista completa con los mismos filtros (más columnas y más espacio).';

                trigger OnAction()
                var
                    AddressEmailList: Page "IKA Mail Address Email List";
                begin
                    AddressEmailList.SetFilters(AddressFilterText, SubjectFilterText);
                    AddressEmailList.Run();
                end;
            }
        }
    }

    var
        AddressSearch: Codeunit "IKA Mail Address Search";
        AddressFilterText: Text;
        SubjectFilterText: Text;
        ContextAddresses: Text;
        ContextSubject: Text;
        StatusText: Text;
        DirectionText: Text;
        DirectionStyle: Text;
        CounterpartText: Text;
        RowStyle: Text;
        ContextSet: Boolean;
        SentLbl: Label 'Enviado';
        ReceivedLbl: Label 'Recibido';
        PressRefreshLbl: Label 'Pulse "Actualizar" para buscar en Outlook.';

    trigger OnAfterGetRecord()
    begin
        if Rec."Is Sent" then begin
            DirectionText := SentLbl;
            DirectionStyle := 'Ambiguous';
        end else begin
            DirectionText := ReceivedLbl;
            DirectionStyle := 'Favorable';
        end;
        if Rec."Is Read" or Rec."Is Sent" then
            RowStyle := 'Standard'
        else
            RowStyle := 'Strong';
        CounterpartText := AddressSearch.GetCounterpart(Rec);
    end;

    /// <summary>
    /// La llama la página que contiene el FactBox cada vez que cambia el registro actual. Solo busca si
    /// la dirección o el asunto han cambiado (y, si está desactivada la carga automática, al pulsar Actualizar).
    /// </summary>
    procedure SetContext(NewAddresses: Text; NewSubject: Text)
    begin
        if ContextSet and (NewAddresses = ContextAddresses) and (NewSubject = ContextSubject) then
            exit;
        ContextSet := true;
        ContextAddresses := NewAddresses;
        ContextSubject := NewSubject;
        AddressFilterText := NewAddresses;
        SubjectFilterText := NewSubject;
        if AddressSearch.IsAutoLoadEnabled() then
            LoadEmails()
        else begin
            Rec.Reset();
            Rec.DeleteAll();
            StatusText := PressRefreshLbl;
            CurrPage.Update(false);
        end;
    end;

    local procedure LoadEmails()
    begin
        StatusText := AddressSearch.RunSearch(AddressFilterText, SubjectFilterText, Rec);
        Rec.Reset();
        Rec.SetCurrentKey("Received At");
        Rec.Ascending(false);
        if Rec.FindFirst() then;
        CurrPage.Update(false);
    end;
}
