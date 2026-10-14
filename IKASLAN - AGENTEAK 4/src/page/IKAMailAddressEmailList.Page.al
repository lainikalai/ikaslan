page 99246 "IKA Mail Address Email List"
{
    // Lista completa de emails enviados y recibidos con una dirección: se abre desde el FactBox
    // ("Ver en lista") o desde la búsqueda de BC para buscar cualquier dirección o asunto.
    Caption = 'Emails enviados y recibidos';
    PageType = List;
    SourceTable = "IKA Mail Message";
    SourceTableTemporary = true;
    SourceTableView = sorting("Received At") order(descending);
    UsageCategory = Lists;
    ApplicationArea = All;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            group(Filters)
            {
                Caption = 'Buscar en Outlook 365';

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
                field(DirectionFilter; Direction)
                {
                    ApplicationArea = All;
                    Caption = 'Mostrar';
                    ToolTip = 'Todos, solo los recibidos o solo los enviados.';

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
                field("From Name"; Rec."From Name")
                {
                    ApplicationArea = All;
                    StyleExpr = RowStyle;
                }
                field("To Recipients"; Rec."To Recipients")
                {
                    ApplicationArea = All;
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
                field("Has Attachments"; Rec."Has Attachments")
                {
                    ApplicationArea = All;
                    Caption = '📎';
                }
                field("Body Preview"; Rec."Body Preview")
                {
                    ApplicationArea = All;
                }
                field("From Address"; Rec."From Address")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Cc Recipients"; Rec."Cc Recipients")
                {
                    ApplicationArea = All;
                    Visible = false;
                }
                field("Mailbox Code"; Rec."Mailbox Code")
                {
                    ApplicationArea = All;
                    Caption = 'Cuenta';
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
                Caption = 'Buscar';
                Image = Find;
                ShortcutKey = 'F5';
                ToolTip = 'Busca en Outlook con los filtros actuales.';

                trigger OnAction()
                begin
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
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(Refresh_Promoted; Refresh) { }
                actionref(OpenEmail_Promoted; OpenEmail) { }
                actionref(OpenInOutlook_Promoted; OpenInOutlook) { }
            }
        }
    }

    var
        AddressSearch: Codeunit "IKA Mail Address Search";
        Direction: Enum "IKA Mail Address Direction";
        AddressFilterText: Text;
        SubjectFilterText: Text;
        StatusText: Text;
        DirectionText: Text;
        DirectionStyle: Text;
        RowStyle: Text;
        SentLbl: Label 'Enviado';
        ReceivedLbl: Label 'Recibido';

    trigger OnOpenPage()
    begin
        SearchEmails();
    end;

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
    end;

    procedure SetFilters(NewAddressFilter: Text; NewSubjectFilter: Text; NewDirection: Enum "IKA Mail Address Direction")
    begin
        Direction := NewDirection;
        SetFilters(NewAddressFilter, NewSubjectFilter);
    end;

    procedure SetFilters(NewAddressFilter: Text; NewSubjectFilter: Text)
    begin
        AddressFilterText := NewAddressFilter;
        SubjectFilterText := NewSubjectFilter;
    end;

    local procedure LoadEmails()
    begin
        SearchEmails();
        CurrPage.Update(false);
    end;

    local procedure SearchEmails()
    begin
        StatusText := AddressSearch.RunSearch(AddressFilterText, SubjectFilterText, Direction, Rec);
        Rec.Reset();
        Rec.SetCurrentKey("Received At");
        Rec.Ascending(false);
        if Rec.FindFirst() then;
    end;
}
