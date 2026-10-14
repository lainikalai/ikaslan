codeunit 99221 "IKA Mail Address Search"
{
    // Emails enviados y recibidos con una o varias direcciones (y, opcionalmente, un texto en el asunto),
    // buscados en Outlook 365 en todas las cuentas a las que tiene acceso el usuario.
    // La usan el FactBox "IKA Mail Address Emails" y la lista "IKA Mail Address Email List".
    //
    // En cada cuenta se lanzan tres consultas y se juntan los resultados (sin repetir):
    //   1. Recibidos: $filter from = dirección, en todas las carpetas. No depende del índice de búsqueda.
    //   2. Enviados:  $filter toRecipients = dirección, en "Elementos enviados".
    //   3. Búsqueda:  $search participants:dirección (De, Para, CC, CCO; todas las carpetas). Cubre los
    //      dominios (@cliente.com) y los emails en copia, pero depende del índice de Outlook, que puede
    //      tardar unos minutos en incluir los emails nuevos.
    // Si una consulta falla, las demás siguen; el detalle queda en GetSearchLog() (acción "Detalle de la búsqueda").
    //
    // Uso desde una página:
    //     StatusText := AddressSearch.RunSearch(Addresses, SubjectFilter, TempMailMessage);
    // RunSearch no da error: si Graph falla (sin configurar, sin permisos...) devuelve el motivo en el
    // texto de estado, para que el FactBox no bloquee la ficha. Se usa una TryFunction y no Codeunit.Run
    // porque la búsqueda puede lanzarse con una transacción de escritura abierta (p.ej. al cambiar el
    // email de la ficha); dentro solo se escribe en tablas temporales.

    var
        TempResult: Record "IKA Mail Message" temporary;
        UriHelper: Codeunit Uri;
        AddressFilter: Text;
        SubjectFilter: Text;
        Direction: Enum "IKA Mail Address Direction";
        SearchLog: Text;
        FirstError: Text;
        MailboxCount: Integer;
        QueryOkCount: Integer;
        QueryErrorCount: Integer;
        NoMailboxErr: Label 'No tiene acceso a ninguna cuenta de Outlook 365 activa.';
        NoFilterLbl: Label 'Indique un email o un texto del asunto.';
        NotConfiguredLbl: Label 'Falta la configuración de correo Outlook 365.';
        SearchErrLbl: Label 'No se pudo buscar en Outlook: %1', Comment = '%1 = error';
        ResultLbl: Label 'Recibidos: %1 · Enviados: %2 (%3 cuentas)', Comment = '%1 = received, %2 = sent, %3 = mailboxes';
        ResultOneLbl: Label '%1 emails', Comment = '%1 = count';
        ResultOneMaxLbl: Label 'Últimos %1 emails', Comment = '%1 = count';
        ResultMaxLbl: Label 'Últimos %1 emails. Recibidos: %2 · Enviados: %3 (%4 cuentas)', Comment = '%1 = total, %2 = received, %3 = sent, %4 = mailboxes';
        QueryErrorsLbl: Label ' · %1 consultas con error (ver "Detalle de la búsqueda")', Comment = '%1 = count';
        NoAccessErr: Label 'No tiene acceso a la cuenta %1.', Comment = '%1 = mailbox';
        NoSearchYetLbl: Label 'Todavía no se ha buscado.';
        LogHeaderLbl: Label 'Email: %1 · Asunto: %2 · %3', Comment = '%1 = address filter, %2 = subject filter, %3 = Todos/Recibidos/Enviados';
        LogQueryOkLbl: Label '%1 (%2) - %3: %4 emails nuevos', Comment = '%1 = mailbox, %2 = address, %3 = query, %4 = count';
        LogQueryErrLbl: Label '%1 (%2) - %3: ERROR %4', Comment = '%1 = mailbox, %2 = address, %3 = query, %4 = error';
        LogSubjectLbl: Label 'Descartados por el asunto: %1', Comment = '%1 = count';
        QueryReceivedLbl: Label 'recibidos';
        QuerySentLbl: Label 'enviados';
        QuerySearchLbl: Label 'búsqueda';

    /// <summary>
    /// Busca enviados y recibidos y deja los resultados en TempMailMessage (borra lo que tuviera).
    /// Devuelve el texto de estado.
    /// </summary>
    procedure RunSearch(NewAddressFilter: Text; NewSubjectFilter: Text; var TempMailMessage: Record "IKA Mail Message" temporary): Text
    begin
        exit(RunSearch(NewAddressFilter, NewSubjectFilter, Direction::All, TempMailMessage));
    end;

    /// <summary>
    /// Igual, pero solo los recibidos o solo los enviados (NewDirection); así no se lanza la consulta que no hace falta.
    /// </summary>
    procedure RunSearch(NewAddressFilter: Text; NewSubjectFilter: Text; NewDirection: Enum "IKA Mail Address Direction"; var TempMailMessage: Record "IKA Mail Message" temporary): Text
    var
        Setup: Record "IKA Mail Setup";
    begin
        TempMailMessage.Reset();
        TempMailMessage.DeleteAll();
        AddressFilter := NewAddressFilter;
        SubjectFilter := NewSubjectFilter;
        Direction := NewDirection;
        SearchLog := '';
        if BuildQuery(AddressFilter, SubjectFilter) = '' then
            exit(NoFilterLbl);
        // Sin registro de configuración, el cliente de Graph lo insertaría (escritura dentro de la TryFunction)
        if not Setup.Get() then
            exit(NotConfiguredLbl);

        ClearLastError();
        if not TrySearch() then begin
            AddLog(GetLastErrorText());
            exit(StrSubstNo(SearchErrLbl, GetLastErrorText()));
        end;

        TempResult.Reset();
        if TempResult.FindSet() then
            repeat
                TempMailMessage := TempResult;
                TempMailMessage.Insert();
            until TempResult.Next() = 0;
        exit(GetStatusText());
    end;

    /// <summary>
    /// Qué consultas se han lanzado en la última búsqueda, cuántos emails ha devuelto cada una y los errores.
    /// </summary>
    procedure GetSearchLog(): Text
    begin
        if SearchLog = '' then
            exit(NoSearchYetLbl);
        exit(SearchLog);
    end;

    local procedure GetStatusText(): Text
    var
        StatusText: Text;
        TotalCount: Integer;
        SentCount: Integer;
    begin
        TempResult.Reset();
        TotalCount := TempResult.Count();
        TempResult.SetRange("Is Sent", true);
        SentCount := TempResult.Count();
        TempResult.Reset();
        if Direction <> Direction::All then begin
            if TotalCount >= GetMaxResults() then
                StatusText := StrSubstNo(ResultOneMaxLbl, TotalCount)
            else
                StatusText := StrSubstNo(ResultOneLbl, TotalCount);
        end else
            if TotalCount >= GetMaxResults() then
                StatusText := StrSubstNo(ResultMaxLbl, TotalCount, TotalCount - SentCount, SentCount, MailboxCount)
            else
                StatusText := StrSubstNo(ResultLbl, TotalCount - SentCount, SentCount, MailboxCount);
        if QueryErrorCount > 0 then
            StatusText += StrSubstNo(QueryErrorsLbl, QueryErrorCount);
        exit(StatusText);
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
        ExactAddresses: List of [Text];
        AllowedFilter: Text;
        KqlQuery: Text;
        FromFilter: Text;
        ToFilter: Text;
        TopText: Text;
        MaxResults: Integer;
    begin
        TempResult.Reset();
        TempResult.DeleteAll();
        MailboxCount := 0;
        QueryOkCount := 0;
        QueryErrorCount := 0;
        FirstError := '';
        KqlQuery := BuildQuery(AddressFilter, SubjectFilter);
        if KqlQuery = '' then
            exit;
        AllowedFilter := Mailbox.GetAllowedFilter();
        if AllowedFilter = '' then
            Error(NoMailboxErr);

        AddLog(StrSubstNo(LogHeaderLbl, AddressFilter, SubjectFilter, Format(Direction)));
        MaxResults := GetMaxResults();
        TopText := '&$top=' + Format(MaxResults);
        ExactAddresses := GetExactAddresses(AddressFilter);
        BuildAddressFilters(ExactAddresses, FromFilter, ToFilter);

        Mailbox.SetFilter(Code, AllowedFilter);
        if Mailbox.FindSet() then
            repeat
                MailboxCount += 1;
                // $orderby solo se admite si su campo va primero en el $filter
                if (FromFilter <> '') and (Direction <> Direction::Sent) then
                    RunQuery(GraphClient, Mailbox, QueryReceivedLbl, '/messages',
                        '$filter=' + UriHelper.EscapeDataString('receivedDateTime ge 1900-01-01T00:00:00Z and (' + FromFilter + ')') +
                        '&$orderby=receivedDateTime%20desc' + TopText);
                if (ToFilter <> '') and (Direction <> Direction::Received) then
                    RunQuery(GraphClient, Mailbox, QuerySentLbl, '/mailFolders/sentitems/messages',
                        '$filter=' + UriHelper.EscapeDataString(ToFilter) + TopText);
                RunQuery(GraphClient, Mailbox, QuerySearchLbl, '/messages',
                    '$search=' + UriHelper.EscapeDataString('"' + KqlQuery + '"') + TopText);
            until Mailbox.Next() = 0;

        // Si no ha funcionado ninguna consulta, el error se muestra en el estado
        if (QueryOkCount = 0) and (FirstError <> '') then
            Error(FirstError);
        ApplyDirectionFilter();
        ApplySubjectFilter();
        KeepNewest(MaxResults);
    end;

    local procedure ApplyDirectionFilter()
    begin
        // $search devuelve enviados y recibidos: se quitan los que no tocan
        if Direction = Direction::All then
            exit;
        TempResult.Reset();
        TempResult.SetRange("Is Sent", Direction = Direction::Received);
        TempResult.DeleteAll();
        TempResult.Reset();
    end;

    local procedure RunQuery(var GraphClient: Codeunit "IKA Mail Graph Client"; var Mailbox: Record "IKA Mail Mailbox"; QueryName: Text; RelativePath: Text; QueryText: Text)
    var
        FoundCount: Integer;
    begin
        ClearLastError();
        if TryListMessages(GraphClient, Mailbox, RelativePath, QueryText, FoundCount) then begin
            QueryOkCount += 1;
            AddLog(StrSubstNo(LogQueryOkLbl, Mailbox.Code, Mailbox.Address, QueryName, FoundCount));
        end else begin
            QueryErrorCount += 1;
            if FirstError = '' then
                FirstError := GetLastErrorText();
            AddLog(StrSubstNo(LogQueryErrLbl, Mailbox.Code, Mailbox.Address, QueryName, CopyStr(GetLastErrorText(), 1, 400)));
        end;
    end;

    [TryFunction]
    local procedure TryListMessages(var GraphClient: Codeunit "IKA Mail Graph Client"; var Mailbox: Record "IKA Mail Mailbox"; RelativePath: Text; QueryText: Text; var FoundCount: Integer)
    begin
        FoundCount := GraphClient.ListMessages(Mailbox, RelativePath, QueryText, TempResult);
    end;

    local procedure AddLog(LineText: Text)
    begin
        // En Message(), \ es un salto de línea
        if SearchLog <> '' then
            SearchLog += '\';
        SearchLog += LineText.Replace('\', '/');
    end;

    /// <summary>
    /// Direcciones completas (nombre@dominio) del filtro; los dominios (@cliente.com) solo los cubre $search.
    /// </summary>
    local procedure GetExactAddresses(AddressText: Text) Result: List of [Text]
    var
        Term: Text;
    begin
        foreach Term in AddressText.Replace(',', ';').Replace(' ', ';').Split(';') do begin
            Term := LowerCase(CleanTerm(Term));
            if (StrPos(Term, '@') > 1) and (StrPos(Term, '@') < StrLen(Term)) and not Result.Contains(Term) then
                Result.Add(Term);
        end;
    end;

    local procedure BuildAddressFilters(ExactAddresses: List of [Text]; var FromFilter: Text; var ToFilter: Text)
    var
        Address: Text;
    begin
        FromFilter := '';
        ToFilter := '';
        foreach Address in ExactAddresses do begin
            if FromFilter <> '' then begin
                FromFilter += ' or ';
                ToFilter += ' or ';
            end;
            FromFilter += 'from/emailAddress/address eq ''' + Address + '''';
            ToFilter += 'toRecipients/any(r:r/emailAddress/address eq ''' + Address + ''')';
        end;
    end;

    /// <summary>
    /// Las consultas $filter no filtran por asunto: se quitan aquí los emails cuyo asunto no cumple el filtro.
    /// Filtro: alternativas separadas por | y, en cada una, palabras que deben estar todas.
    ///   "pedido 2026|PV-1001" = (contiene "pedido" y "2026") o contiene "PV-1001".
    /// </summary>
    local procedure ApplySubjectFilter()
    var
        Alternatives: List of [Text];
        Alternative: Text;
        LowerSubject: Text;
        RemovedCount: Integer;
        Keep: Boolean;
    begin
        foreach Alternative in SubjectFilter.Split('|') do begin
            Alternative := LowerCase(DelChr(CleanTerm(Alternative.Replace('*', '')), '<>', ' '));
            if Alternative <> '' then
                Alternatives.Add(Alternative);
        end;
        if Alternatives.Count() = 0 then
            exit;

        TempResult.Reset();
        if TempResult.FindSet() then
            repeat
                LowerSubject := LowerCase(TempResult.Subject);
                Keep := false;
                foreach Alternative in Alternatives do
                    if not Keep then
                        Keep := ContainsAllWords(LowerSubject, Alternative);
                if not Keep then begin
                    TempResult.Delete();
                    RemovedCount += 1;
                end;
            until TempResult.Next() = 0;
        if RemovedCount > 0 then
            AddLog(StrSubstNo(LogSubjectLbl, RemovedCount));
    end;

    local procedure ContainsAllWords(LowerSubject: Text; Alternative: Text): Boolean
    var
        Word: Text;
    begin
        foreach Word in Alternative.Split(' ') do
            if (Word <> '') and (StrPos(LowerSubject, Word) = 0) then
                exit(false);
        exit(true);
    end;

    local procedure KeepNewest(MaxResults: Integer)
    var
        Counter: Integer;
    begin
        // Con varias consultas y cuentas puede haber más de MaxResults: se dejan los más recientes
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

        SubjectPart := BuildSubjectQuery(SubjectText);

        if (AddressPart <> '') and (SubjectPart <> '') then
            exit(AddressPart + ' AND ' + SubjectPart);
        exit(AddressPart + SubjectPart);
    end;

    local procedure BuildSubjectQuery(SubjectText: Text): Text
    var
        Alternative: Text;
        Word: Text;
        GroupPart: Text;
        Result: Text;
        GroupCount: Integer;
    begin
        // "pedido 2026|PV-1001" -> ((subject:pedido AND subject:2026) OR (subject:PV AND subject:1001))
        // Los separadores de los nº de documento (PV-1001) se pasan como palabras sueltas, que es como
        // Outlook indexa el asunto; el filtro local (ApplySubjectFilter) sí exige "pv-1001" entero.
        foreach Alternative in SubjectText.Split('|') do begin
            GroupPart := '';
            foreach Word in ConvertStr(CleanTerm(Alternative), '-/_.,;#+', '        ').Split(' ') do
                if Word <> '' then begin
                    if GroupPart <> '' then
                        GroupPart += ' AND ';
                    GroupPart += 'subject:' + Word;
                end;
            if GroupPart <> '' then begin
                if StrPos(GroupPart, ' AND ') > 0 then
                    GroupPart := '(' + GroupPart + ')';
                if Result <> '' then
                    Result += ' OR ';
                Result += GroupPart;
                GroupCount += 1;
            end;
        end;
        if GroupCount > 1 then
            Result := '(' + Result + ')';
        exit(Result);
    end;

    local procedure CleanTerm(Term: Text): Text
    begin
        // Fuera lo que rompería las consultas ($search va entre comillas dobles, $filter entre simples)
        Term := DelChr(Term, '=', '"''()\:<>|');
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

    /// <summary>
    /// Email del cliente y del contacto del documento ("a@x.com; b@x.com").
    /// </summary>
    procedure GetCustomerAddresses(CustomerNo: Code[20]; ContactNo: Code[20]): Text
    var
        Customer: Record Customer;
    begin
        if CustomerNo <> '' then
            if Customer.Get(CustomerNo) then;
        exit(JoinAddresses(Customer."E-Mail", GetContactAddress(ContactNo)));
    end;

    /// <summary>
    /// Email del proveedor y del contacto del documento.
    /// </summary>
    procedure GetVendorAddresses(VendorNo: Code[20]; ContactNo: Code[20]): Text
    var
        Vendor: Record Vendor;
    begin
        if VendorNo <> '' then
            if Vendor.Get(VendorNo) then;
        exit(JoinAddresses(Vendor."E-Mail", GetContactAddress(ContactNo)));
    end;

    local procedure GetContactAddress(ContactNo: Code[20]): Text
    var
        Contact: Record Contact;
    begin
        if ContactNo = '' then
            exit('');
        if not Contact.Get(ContactNo) then
            exit('');
        exit(Contact."E-Mail");
    end;

    /// <summary>
    /// Filtro de asunto de un documento: sus números como alternativas ("PV-1001|PED-555"), sin vacíos ni
    /// repetidos. '' si en la configuración se ha desactivado el filtro por nº de documento.
    /// </summary>
    procedure GetDocumentSubjectFilter(DocumentNo1: Text; DocumentNo2: Text; DocumentNo3: Text): Text
    var
        Setup: Record "IKA Mail Setup";
        Result: Text;
    begin
        if Setup.Get() then
            if not Setup."Doc. Emails by Doc. No." then
                exit('');
        AddSubjectAlternative(Result, DocumentNo1);
        AddSubjectAlternative(Result, DocumentNo2);
        AddSubjectAlternative(Result, DocumentNo3);
        exit(Result);
    end;

    local procedure AddSubjectAlternative(var SubjectFilterText: Text; DocumentNo: Text)
    begin
        DocumentNo := DelChr(CleanTerm(DocumentNo), '<>', ' ');
        if DocumentNo = '' then
            exit;
        if ('|' + UpperCase(SubjectFilterText) + '|').Contains('|' + UpperCase(DocumentNo) + '|') then
            exit;
        if SubjectFilterText <> '' then
            SubjectFilterText += '|';
        SubjectFilterText += DocumentNo;
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
