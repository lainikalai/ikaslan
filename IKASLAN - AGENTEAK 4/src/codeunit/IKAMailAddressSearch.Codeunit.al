codeunit 99221 "IKA Mail Address Search"
{
    // Emails enviados y recibidos con una o varias direcciones (y, opcionalmente, un texto en el asunto),
    // buscados en Outlook 365 en todas las cuentas a las que tiene acceso el usuario.
    // La usan el FactBox "IKA Mail Address Emails" y la lista "IKA Mail Address Email List".
    //
    // Uso desde una página:
    //     StatusText := AddressSearch.RunSearch(Addresses, SubjectFilter, TempMailMessage);
    // RunSearch no da error: si Graph falla (sin configurar, sin permisos...) devuelve el motivo en el
    // texto de estado, para que el FactBox no bloquee la ficha. Se usa una TryFunction y no Codeunit.Run
    // porque la búsqueda puede lanzarse con una transacción de escritura abierta (p.ej. al cambiar el
    // email de la ficha); dentro solo se escribe en tablas temporales.

    var
        TempResult: Record "IKA Mail Message" temporary;
        AddressFilter: Text;
        SubjectFilter: Text;
        MailboxCount: Integer;
        NoMailboxErr: Label 'No tiene acceso a ninguna cuenta de Outlook 365 activa.';
        NoFilterLbl: Label 'Indique un email o un texto del asunto.';
        NotConfiguredLbl: Label 'Falta la configuración de correo Outlook 365.';
        SearchErrLbl: Label 'No se pudo buscar en Outlook: %1', Comment = '%1 = error';
        ResultLbl: Label '%1 emails en %2 cuentas', Comment = '%1 = count, %2 = mailboxes';
        ResultMaxLbl: Label 'Últimos %1 emails en %2 cuentas', Comment = '%1 = count, %2 = mailboxes';
        NoAccessErr: Label 'No tiene acceso a la cuenta %1.', Comment = '%1 = mailbox';

    /// <summary>
    /// Busca y deja los resultados en TempMailMessage (borra lo que tuviera). Devuelve el texto de estado.
    /// </summary>
    procedure RunSearch(NewAddressFilter: Text; NewSubjectFilter: Text; var TempMailMessage: Record "IKA Mail Message" temporary): Text
    var
        Setup: Record "IKA Mail Setup";
    begin
        TempMailMessage.Reset();
        TempMailMessage.DeleteAll();
        AddressFilter := NewAddressFilter;
        SubjectFilter := NewSubjectFilter;
        if BuildQuery(AddressFilter, SubjectFilter) = '' then
            exit(NoFilterLbl);
        // Sin registro de configuración, el cliente de Graph lo insertaría (escritura dentro de la TryFunction)
        if not Setup.Get() then
            exit(NotConfiguredLbl);

        ClearLastError();
        if not TrySearch() then
            exit(StrSubstNo(SearchErrLbl, GetLastErrorText()));

        TempResult.Reset();
        if TempResult.FindSet() then
            repeat
                TempMailMessage := TempResult;
                TempMailMessage.Insert();
            until TempResult.Next() = 0;
        exit(GetStatusText());
    end;

    local procedure GetStatusText(): Text
    begin
        TempResult.Reset();
        if TempResult.Count() >= GetMaxResults() then
            exit(StrSubstNo(ResultMaxLbl, TempResult.Count(), MailboxCount));
        exit(StrSubstNo(ResultLbl, TempResult.Count(), MailboxCount));
    end;

    [TryFunction]
    local procedure TrySearch()
    begin
        Search();
    end;

    local procedure Search()
    var
        Mailbox: Record "IKA Mail Mailbox";
        GraphClient: Codeunit "IKA Mail Graph Client";
        AllowedFilter: Text;
        KqlQuery: Text;
        MaxResults: Integer;
    begin
        TempResult.Reset();
        TempResult.DeleteAll();
        MailboxCount := 0;
        KqlQuery := BuildQuery(AddressFilter, SubjectFilter);
        if KqlQuery = '' then
            exit;
        AllowedFilter := Mailbox.GetAllowedFilter();
        if AllowedFilter = '' then
            Error(NoMailboxErr);

        MaxResults := GetMaxResults();
        Mailbox.SetFilter(Code, AllowedFilter);
        if Mailbox.FindSet() then
            repeat
                GraphClient.SearchMessages(Mailbox, KqlQuery, MaxResults, TempResult);
                MailboxCount += 1;
            until Mailbox.Next() = 0;
        KeepNewest(MaxResults);
    end;

    local procedure KeepNewest(MaxResults: Integer)
    var
        Counter: Integer;
    begin
        // Con varias cuentas puede haber más de MaxResults: se dejan los más recientes
        TempResult.Reset();
        TempResult.SetCurrentKey("Received At");
        TempResult.Ascending(false);
        if TempResult.FindSet() then
            repeat
                Counter += 1;
                if Counter > MaxResults then
                    TempResult.Delete();
            until TempResult.Next() = 0;
        TempResult.Reset();
    end;

    local procedure GetMaxResults(): Integer
    var
        Setup: Record "IKA Mail Setup";
    begin
        if Setup.Get() then
            if Setup."Address Emails to Show" > 0 then
                exit(Setup."Address Emails to Show");
        exit(25);
    end;

    /// <summary>
    /// Consulta KQL para $search de Graph:
    ///   "ana@cliente.com; pedidos@cliente.com" + "pedido 2026" ->
    ///   (participants:ana@cliente.com OR participants:pedidos@cliente.com) AND subject:pedido AND subject:2026
    /// participants = De, Para, CC y CCO. En el asunto se puede usar * al final de una palabra (pedi*).
    /// '' si no hay ni dirección ni asunto.
    /// </summary>
    procedure BuildQuery(AddressText: Text; SubjectText: Text): Text
    var
        AddressPart: Text;
        SubjectPart: Text;
        Term: Text;
        AddressCount: Integer;
    begin
        foreach Term in AddressText.Replace(',', ';').Replace(' ', ';').Split(';') do begin
            Term := CleanTerm(Term);
            // "@cliente.com" -> todo el dominio
            Term := DelChr(Term, '<', '@');
            if Term <> '' then begin
                if AddressPart <> '' then
                    AddressPart += ' OR ';
                AddressPart += 'participants:' + Term;
                AddressCount += 1;
            end;
        end;
        if AddressCount > 1 then
            AddressPart := '(' + AddressPart + ')';

        foreach Term in SubjectText.Split(' ') do begin
            Term := CleanTerm(Term);
            if Term <> '' then begin
                if SubjectPart <> '' then
                    SubjectPart += ' AND ';
                SubjectPart += 'subject:' + Term;
            end;
        end;

        if (AddressPart <> '') and (SubjectPart <> '') then
            exit(AddressPart + ' AND ' + SubjectPart);
        exit(AddressPart + SubjectPart);
    end;

    local procedure CleanTerm(Term: Text): Text
    begin
        // Fuera lo que rompería la consulta ($search va entre comillas dobles)
        Term := DelChr(Term, '=', '"''()\:<>');
        exit(DelChr(Term, '<>', ' '));
    end;

    /// <summary>
    /// Une las direcciones de una entidad (vacías fuera) en un filtro "a@x.com; b@x.com".
    /// </summary>
    procedure JoinAddresses(Address1: Text; Address2: Text): Text
    begin
        Address1 := DelChr(Address1, '<>', ' ');
        Address2 := DelChr(Address2, '<>', ' ');
        if (Address1 = '') or (LowerCase(Address1) = LowerCase(Address2)) then
            exit(Address2);
        if Address2 = '' then
            exit(Address1);
        exit(Address1 + '; ' + Address2);
    end;

    procedure IsAutoLoadEnabled(): Boolean
    var
        Setup: Record "IKA Mail Setup";
    begin
        if not Setup.Get() then
            exit(true);
        exit(Setup."Address Emails Auto Load");
    end;

    /// <summary>
    /// Abre en la ficha del email un resultado de la búsqueda. Si no estaba en la caché local se guarda
    /// marcado como "Solo de búsqueda", para que no aparezca en la bandeja.
    /// </summary>
    procedure OpenMessage(TempMailMessage: Record "IKA Mail Message" temporary)
    var
        MailMessage: Record "IKA Mail Message";
        Mailbox: Record "IKA Mail Mailbox";
    begin
        if TempMailMessage."Graph Id" = '' then
            exit;
        Mailbox.Get(TempMailMessage."Mailbox Code");
        if not Mailbox.HasAccess() then
            Error(NoAccessErr, Mailbox.Code);

        MailMessage.SetCurrentKey("Mailbox Code", "Graph Id");
        MailMessage.SetRange("Mailbox Code", TempMailMessage."Mailbox Code");
        MailMessage.SetRange("Graph Id", TempMailMessage."Graph Id");
        if not MailMessage.FindFirst() then begin
            MailMessage.Init();
            MailMessage.TransferFields(TempMailMessage, false);
            MailMessage."Search Only" := true;
            MailMessage.Insert(true);
        end;
        Page.Run(Page::"IKA Mail Message", MailMessage);
    end;

    procedure OpenInOutlook(TempMailMessage: Record "IKA Mail Message" temporary)
    begin
        if TempMailMessage."Web Link" <> '' then
            Hyperlink(TempMailMessage."Web Link");
    end;

    /// <summary>
    /// Texto para la columna "Con": destinatarios si es un email enviado, remitente si es recibido.
    /// </summary>
    procedure GetCounterpart(TempMailMessage: Record "IKA Mail Message" temporary): Text
    begin
        if TempMailMessage."Is Sent" then
            exit(TempMailMessage."To Recipients");
        if TempMailMessage."From Name" <> '' then
            exit(TempMailMessage."From Name");
        exit(TempMailMessage."From Address");
    end;
}
