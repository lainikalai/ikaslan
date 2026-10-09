codeunit 99411 "IKA CRM Data Mgt."
{
    // Lee del CRM (Dataverse Web API) cuentas, contactos, clientes potenciales, oportunidades y actividades
    // y los deja en las tablas temporales "IKA CRM ... Buffer" para mostrarlos en BC. No escribe en el CRM.
    // Nombres de las entidades y columnas: los estándar de Dynamics 365 Customer Engagement.

    var
        Setup: Record "IKA CRM Setup";
        WebApi: Codeunit "IKA CRM Web API";
        JsonHelper: Codeunit "IKA CRM Json Helper";
        AccountSelectTok: Label 'accountid,name,accountnumber,customertypecode,telephone1,emailaddress1,websiteurl,address1_line1,address1_city,address1_postalcode,address1_stateorprovince,address1_country,_primarycontactid_value,industrycode,_ownerid_value,statecode,modifiedon', Locked = true;
        ContactSelectTok: Label 'contactid,fullname,jobtitle,_parentcustomerid_value,telephone1,mobilephone,emailaddress1,address1_city,_ownerid_value,statecode,modifiedon', Locked = true;
        LeadSelectTok: Label 'leadid,subject,fullname,companyname,telephone1,mobilephone,emailaddress1,leadsourcecode,leadqualitycode,statuscode,statecode,_ownerid_value,createdon', Locked = true;
        OpportunitySelectTok: Label 'opportunityid,name,_customerid_value,estimatedvalue,estimatedclosedate,closeprobability,stepname,statuscode,statecode,_ownerid_value,modifiedon', Locked = true;
        ActivitySelectTok: Label 'activityid,activitytypecode,subject,_regardingobjectid_value,scheduledstart,scheduledend,actualend,statecode,_ownerid_value,createdon', Locked = true;
        FormattedValueTok: Label '@OData.Community.Display.V1.FormattedValue', Locked = true;

    // =====================================================================
    // Cuentas
    // =====================================================================

    /// <summary>
    /// Cuentas que contienen SearchText en el nombre, nº de cuenta, email o ciudad (todas si va vacío).
    /// </summary>
    procedure LoadAccounts(var TempAccount: Record "IKA CRM Account Buffer" temporary; SearchText: Text; IncludeInactive: Boolean)
    var
        FilterText: Text;
    begin
        if not IncludeInactive then
            FilterText := 'statecode eq 0';
        AddSearch(FilterText, SearchText, 'name,accountnumber,emailaddress1,address1_city');
        LoadAccountsWithFilter(TempAccount, FilterText);
    end;

    procedure GetAccount(AccountId: Guid; var TempAccount: Record "IKA CRM Account Buffer" temporary): Boolean
    begin
        LoadAccountsWithFilter(TempAccount, 'accountid eq ' + GuidText(AccountId));
        exit(TempAccount.FindFirst());
    end;

    /// <summary>
    /// Cuentas activas cuyo email o nombre coincide exactamente (para proponer el vínculo con un cliente o proveedor).
    /// </summary>
    procedure FindAccounts(var TempAccount: Record "IKA CRM Account Buffer" temporary; Email: Text; Name: Text)
    begin
        TempAccount.Reset();
        TempAccount.DeleteAll();
        if Email <> '' then
            LoadAccountsWithFilter(TempAccount, 'statecode eq 0 and emailaddress1 eq ' + Quote(Email));
        if TempAccount.IsEmpty() and (Name <> '') then
            LoadAccountsWithFilter(TempAccount, 'statecode eq 0 and name eq ' + Quote(Name));
    end;

    local procedure LoadAccountsWithFilter(var TempAccount: Record "IKA CRM Account Buffer" temporary; FilterText: Text)
    var
        ResultArray: JsonArray;
        RecordToken: JsonToken;
        RecordJson: JsonObject;
        SortingNo: Integer;
    begin
        TempAccount.Reset();
        TempAccount.DeleteAll();
        ResultArray := Query('accounts', AccountSelectTok, FilterText, 'name asc');
        foreach RecordToken in ResultArray do begin
            RecordJson := RecordToken.AsObject();
            SortingNo += 1;
            TempAccount.Init();
            TempAccount."Account Id" := GetGuid(RecordJson, 'accountid');
            TempAccount.Name := CopyStr(GetText(RecordJson, 'name'), 1, MaxStrLen(TempAccount.Name));
            TempAccount."Account Number" := CopyStr(GetText(RecordJson, 'accountnumber'), 1, MaxStrLen(TempAccount."Account Number"));
            TempAccount."Relationship Type" := CopyStr(GetFormatted(RecordJson, 'customertypecode'), 1, MaxStrLen(TempAccount."Relationship Type"));
            TempAccount.Phone := CopyStr(GetText(RecordJson, 'telephone1'), 1, MaxStrLen(TempAccount.Phone));
            TempAccount."E-Mail" := CopyStr(GetText(RecordJson, 'emailaddress1'), 1, MaxStrLen(TempAccount."E-Mail"));
            TempAccount.Website := CopyStr(GetText(RecordJson, 'websiteurl'), 1, MaxStrLen(TempAccount.Website));
            TempAccount.Address := CopyStr(GetText(RecordJson, 'address1_line1'), 1, MaxStrLen(TempAccount.Address));
            TempAccount.City := CopyStr(GetText(RecordJson, 'address1_city'), 1, MaxStrLen(TempAccount.City));
            TempAccount."Post Code" := CopyStr(GetText(RecordJson, 'address1_postalcode'), 1, MaxStrLen(TempAccount."Post Code"));
            TempAccount.County := CopyStr(GetText(RecordJson, 'address1_stateorprovince'), 1, MaxStrLen(TempAccount.County));
            TempAccount.Country := CopyStr(GetText(RecordJson, 'address1_country'), 1, MaxStrLen(TempAccount.Country));
            TempAccount."Primary Contact" := CopyStr(GetFormatted(RecordJson, '_primarycontactid_value'), 1, MaxStrLen(TempAccount."Primary Contact"));
            TempAccount.Industry := CopyStr(GetFormatted(RecordJson, 'industrycode'), 1, MaxStrLen(TempAccount.Industry));
            TempAccount.Owner := CopyStr(GetFormatted(RecordJson, '_ownerid_value'), 1, MaxStrLen(TempAccount.Owner));
            TempAccount.Status := CopyStr(GetFormatted(RecordJson, 'statecode'), 1, MaxStrLen(TempAccount.Status));
            TempAccount."Modified On" := GetDateTime(RecordJson, 'modifiedon');
            TempAccount."Sorting No." := SortingNo;
            if TempAccount.Insert() then;
        end;
        TempAccount.SetCurrentKey("Sorting No.");
        if TempAccount.FindFirst() then;
    end;

    // =====================================================================
    // Contactos
    // =====================================================================

    /// <summary>
    /// Contactos que contienen SearchText en el nombre, email o teléfonos. Con AccountId, solo los de esa cuenta.
    /// </summary>
    procedure LoadContacts(var TempContact: Record "IKA CRM Contact Buffer" temporary; SearchText: Text; AccountId: Guid; IncludeInactive: Boolean)
    var
        FilterText: Text;
    begin
        if not IncludeInactive then
            FilterText := 'statecode eq 0';
        if not IsNullGuid(AccountId) then
            AddCondition(FilterText, '_parentcustomerid_value eq ' + GuidText(AccountId));
        AddSearch(FilterText, SearchText, 'fullname,emailaddress1,telephone1,mobilephone');
        LoadContactsWithFilter(TempContact, FilterText);
    end;

    procedure GetContact(ContactId: Guid; var TempContact: Record "IKA CRM Contact Buffer" temporary): Boolean
    begin
        LoadContactsWithFilter(TempContact, 'contactid eq ' + GuidText(ContactId));
        exit(TempContact.FindFirst());
    end;

    /// <summary>
    /// Contactos activos cuyo email o nombre completo coincide exactamente (para proponer el vínculo con un contacto de BC).
    /// </summary>
    procedure FindContacts(var TempContact: Record "IKA CRM Contact Buffer" temporary; Email: Text; Name: Text)
    begin
        TempContact.Reset();
        TempContact.DeleteAll();
        if Email <> '' then
            LoadContactsWithFilter(TempContact, 'statecode eq 0 and emailaddress1 eq ' + Quote(Email));
        if TempContact.IsEmpty() and (Name <> '') then
            LoadContactsWithFilter(TempContact, 'statecode eq 0 and fullname eq ' + Quote(Name));
    end;

    local procedure LoadContactsWithFilter(var TempContact: Record "IKA CRM Contact Buffer" temporary; FilterText: Text)
    var
        ResultArray: JsonArray;
        RecordToken: JsonToken;
        RecordJson: JsonObject;
        SortingNo: Integer;
    begin
        TempContact.Reset();
        TempContact.DeleteAll();
        ResultArray := Query('contacts', ContactSelectTok, FilterText, 'fullname asc');
        foreach RecordToken in ResultArray do begin
            RecordJson := RecordToken.AsObject();
            SortingNo += 1;
            TempContact.Init();
            TempContact."Contact Id" := GetGuid(RecordJson, 'contactid');
            TempContact."Full Name" := CopyStr(GetText(RecordJson, 'fullname'), 1, MaxStrLen(TempContact."Full Name"));
            TempContact."Job Title" := CopyStr(GetText(RecordJson, 'jobtitle'), 1, MaxStrLen(TempContact."Job Title"));
            TempContact."Company Name" := CopyStr(GetFormatted(RecordJson, '_parentcustomerid_value'), 1, MaxStrLen(TempContact."Company Name"));
            TempContact."Company Id" := GetGuid(RecordJson, '_parentcustomerid_value');
            TempContact.Phone := CopyStr(GetText(RecordJson, 'telephone1'), 1, MaxStrLen(TempContact.Phone));
            TempContact."Mobile Phone" := CopyStr(GetText(RecordJson, 'mobilephone'), 1, MaxStrLen(TempContact."Mobile Phone"));
            TempContact."E-Mail" := CopyStr(GetText(RecordJson, 'emailaddress1'), 1, MaxStrLen(TempContact."E-Mail"));
            TempContact.City := CopyStr(GetText(RecordJson, 'address1_city'), 1, MaxStrLen(TempContact.City));
            TempContact.Owner := CopyStr(GetFormatted(RecordJson, '_ownerid_value'), 1, MaxStrLen(TempContact.Owner));
            TempContact.Status := CopyStr(GetFormatted(RecordJson, 'statecode'), 1, MaxStrLen(TempContact.Status));
            TempContact."Modified On" := GetDateTime(RecordJson, 'modifiedon');
            TempContact."Sorting No." := SortingNo;
            if TempContact.Insert() then;
        end;
        TempContact.SetCurrentKey("Sorting No.");
        if TempContact.FindFirst() then;
    end;

    // =====================================================================
    // Clientes potenciales
    // =====================================================================

    /// <summary>
    /// Clientes potenciales (los más recientes primero) que contienen SearchText en el nombre, empresa, tema o email.
    /// </summary>
    procedure LoadLeads(var TempLead: Record "IKA CRM Lead Buffer" temporary; SearchText: Text; OnlyOpen: Boolean)
    var
        ResultArray: JsonArray;
        RecordToken: JsonToken;
        RecordJson: JsonObject;
        FilterText: Text;
        SortingNo: Integer;
    begin
        TempLead.Reset();
        TempLead.DeleteAll();
        if OnlyOpen then
            FilterText := 'statecode eq 0';
        AddSearch(FilterText, SearchText, 'fullname,companyname,subject,emailaddress1');
        ResultArray := Query('leads', LeadSelectTok, FilterText, 'createdon desc');
        foreach RecordToken in ResultArray do begin
            RecordJson := RecordToken.AsObject();
            SortingNo += 1;
            TempLead.Init();
            TempLead."Lead Id" := GetGuid(RecordJson, 'leadid');
            TempLead.Topic := CopyStr(GetText(RecordJson, 'subject'), 1, MaxStrLen(TempLead.Topic));
            TempLead."Full Name" := CopyStr(GetText(RecordJson, 'fullname'), 1, MaxStrLen(TempLead."Full Name"));
            TempLead."Company Name" := CopyStr(GetText(RecordJson, 'companyname'), 1, MaxStrLen(TempLead."Company Name"));
            TempLead.Phone := CopyStr(GetText(RecordJson, 'telephone1'), 1, MaxStrLen(TempLead.Phone));
            TempLead."Mobile Phone" := CopyStr(GetText(RecordJson, 'mobilephone'), 1, MaxStrLen(TempLead."Mobile Phone"));
            TempLead."E-Mail" := CopyStr(GetText(RecordJson, 'emailaddress1'), 1, MaxStrLen(TempLead."E-Mail"));
            TempLead."Lead Source" := CopyStr(GetFormatted(RecordJson, 'leadsourcecode'), 1, MaxStrLen(TempLead."Lead Source"));
            TempLead.Rating := CopyStr(GetFormatted(RecordJson, 'leadqualitycode'), 1, MaxStrLen(TempLead.Rating));
            TempLead."Status Reason" := CopyStr(GetFormatted(RecordJson, 'statuscode'), 1, MaxStrLen(TempLead."Status Reason"));
            TempLead.Status := CopyStr(GetFormatted(RecordJson, 'statecode'), 1, MaxStrLen(TempLead.Status));
            TempLead.Owner := CopyStr(GetFormatted(RecordJson, '_ownerid_value'), 1, MaxStrLen(TempLead.Owner));
            TempLead."Created On" := GetDateTime(RecordJson, 'createdon');
            TempLead."Sorting No." := SortingNo;
            if TempLead.Insert() then;
        end;
        TempLead.SetCurrentKey("Sorting No.");
        if TempLead.FindFirst() then;
    end;

    // =====================================================================
    // Oportunidades
    // =====================================================================

    /// <summary>
    /// Oportunidades (por fecha de cierre estimada) que contienen SearchText en el tema. Con CustomerId, solo las
    /// de esa cuenta o contacto.
    /// </summary>
    procedure LoadOpportunities(var TempOpportunity: Record "IKA CRM Opportunity Buffer" temporary; SearchText: Text; CustomerId: Guid; OnlyOpen: Boolean)
    var
        ResultArray: JsonArray;
        RecordToken: JsonToken;
        RecordJson: JsonObject;
        FilterText: Text;
        SortingNo: Integer;
    begin
        TempOpportunity.Reset();
        TempOpportunity.DeleteAll();
        if OnlyOpen then
            FilterText := 'statecode eq 0';
        if not IsNullGuid(CustomerId) then
            AddCondition(FilterText, '_customerid_value eq ' + GuidText(CustomerId));
        AddSearch(FilterText, SearchText, 'name');
        ResultArray := Query('opportunities', OpportunitySelectTok, FilterText, 'estimatedclosedate asc');
        foreach RecordToken in ResultArray do begin
            RecordJson := RecordToken.AsObject();
            SortingNo += 1;
            TempOpportunity.Init();
            TempOpportunity."Opportunity Id" := GetGuid(RecordJson, 'opportunityid');
            TempOpportunity.Name := CopyStr(GetText(RecordJson, 'name'), 1, MaxStrLen(TempOpportunity.Name));
            TempOpportunity."Customer Name" := CopyStr(GetFormatted(RecordJson, '_customerid_value'), 1, MaxStrLen(TempOpportunity."Customer Name"));
            TempOpportunity."Customer Id" := GetGuid(RecordJson, '_customerid_value');
            TempOpportunity."Estimated Value" := JsonHelper.GetDecimal(RecordJson, 'estimatedvalue');
            TempOpportunity."Est. Close Date" := GetDate(RecordJson, 'estimatedclosedate');
            TempOpportunity."Probability %" := JsonHelper.GetInteger(RecordJson, 'closeprobability');
            TempOpportunity."Sales Stage" := CopyStr(GetText(RecordJson, 'stepname'), 1, MaxStrLen(TempOpportunity."Sales Stage"));
            TempOpportunity."Status Reason" := CopyStr(GetFormatted(RecordJson, 'statuscode'), 1, MaxStrLen(TempOpportunity."Status Reason"));
            TempOpportunity.Status := CopyStr(GetFormatted(RecordJson, 'statecode'), 1, MaxStrLen(TempOpportunity.Status));
            TempOpportunity.Owner := CopyStr(GetFormatted(RecordJson, '_ownerid_value'), 1, MaxStrLen(TempOpportunity.Owner));
            TempOpportunity."Modified On" := GetDateTime(RecordJson, 'modifiedon');
            TempOpportunity."Sorting No." := SortingNo;
            if TempOpportunity.Insert() then;
        end;
        TempOpportunity.SetCurrentKey("Sorting No.");
        if TempOpportunity.FindFirst() then;
    end;

    // =====================================================================
    // Actividades
    // =====================================================================

    /// <summary>
    /// Actividades (llamadas, citas, emails, tareas...) referentes a la cuenta o contacto, las más recientes primero.
    /// MaxRecords = 0: el máximo de la configuración.
    /// </summary>
    procedure LoadActivities(var TempActivity: Record "IKA CRM Activity Buffer" temporary; RegardingId: Guid; MaxRecords: Integer)
    var
        ResultArray: JsonArray;
        RecordToken: JsonToken;
        RecordJson: JsonObject;
        SortingNo: Integer;
    begin
        TempActivity.Reset();
        TempActivity.DeleteAll();
        if IsNullGuid(RegardingId) then
            exit;
        ResultArray := QueryTop('activitypointers', ActivitySelectTok, '_regardingobjectid_value eq ' + GuidText(RegardingId), 'createdon desc', MaxRecords);
        foreach RecordToken in ResultArray do begin
            RecordJson := RecordToken.AsObject();
            SortingNo += 1;
            TempActivity.Init();
            TempActivity."Activity Id" := GetGuid(RecordJson, 'activityid');
            TempActivity."Activity Type" := CopyStr(GetFormatted(RecordJson, 'activitytypecode'), 1, MaxStrLen(TempActivity."Activity Type"));
            TempActivity."Activity Type Code" := CopyStr(GetText(RecordJson, 'activitytypecode'), 1, MaxStrLen(TempActivity."Activity Type Code"));
            TempActivity.Subject := CopyStr(GetText(RecordJson, 'subject'), 1, MaxStrLen(TempActivity.Subject));
            TempActivity.Regarding := CopyStr(GetFormatted(RecordJson, '_regardingobjectid_value'), 1, MaxStrLen(TempActivity.Regarding));
            TempActivity."Scheduled Start" := GetDateTime(RecordJson, 'scheduledstart');
            TempActivity."Scheduled End" := GetDateTime(RecordJson, 'scheduledend');
            TempActivity."Actual End" := GetDateTime(RecordJson, 'actualend');
            TempActivity.Status := CopyStr(GetFormatted(RecordJson, 'statecode'), 1, MaxStrLen(TempActivity.Status));
            TempActivity.Owner := CopyStr(GetFormatted(RecordJson, '_ownerid_value'), 1, MaxStrLen(TempActivity.Owner));
            TempActivity."Created On" := GetDateTime(RecordJson, 'createdon');
            TempActivity."Sorting No." := SortingNo;
            if TempActivity.Insert() then;
        end;
        TempActivity.SetCurrentKey("Sorting No.");
        if TempActivity.FindFirst() then;
    end;

    // =====================================================================
    // Abrir en el CRM
    // =====================================================================

    procedure OpenInCrm(EntityLogicalName: Text; RecordId: Guid)
    begin
        if IsNullGuid(RecordId) then
            exit;
        Setup.GetSetup();
        Setup.TestConfigured();
        Hyperlink(Setup.GetRecordUrl(EntityLogicalName, RecordId));
    end;

    // =====================================================================
    // Consultas OData
    // =====================================================================

    local procedure Query(EntitySetName: Text; SelectList: Text; FilterText: Text; OrderBy: Text): JsonArray
    begin
        exit(QueryTop(EntitySetName, SelectList, FilterText, OrderBy, 0));
    end;

    local procedure QueryTop(EntitySetName: Text; SelectList: Text; FilterText: Text; OrderBy: Text; MaxRecords: Integer) Result: JsonArray
    var
        ResponseJson: JsonObject;
        Url: Text;
    begin
        Setup.GetSetup();
        if MaxRecords <= 0 then
            MaxRecords := Setup."Max. Records";
        if MaxRecords <= 0 then
            MaxRecords := 200;
        Url := EntitySetName + '?$select=' + SelectList + '&$top=' + Format(MaxRecords);
        if FilterText <> '' then
            Url += '&$filter=' + WebApi.EncodeQueryValue(FilterText);
        if OrderBy <> '' then
            Url += '&$orderby=' + WebApi.EncodeQueryValue(OrderBy);
        ResponseJson := WebApi.Get(Url);
        if not JsonHelper.GetArray(ResponseJson, 'value', Result) then
            Clear(Result);
    end;

    local procedure AddCondition(var FilterText: Text; Condition: Text)
    begin
        if FilterText <> '' then
            FilterText += ' and ';
        FilterText += Condition;
    end;

    /// <summary>
    /// (contains(col1,'texto') or contains(col2,'texto') ...) para las columnas indicadas, separadas por comas.
    /// </summary>
    local procedure AddSearch(var FilterText: Text; SearchText: Text; Columns: Text)
    var
        Column: Text;
        Condition: Text;
    begin
        SearchText := DelChr(SearchText, '<>', ' ');
        if SearchText = '' then
            exit;
        foreach Column in Columns.Split(',') do begin
            if Condition <> '' then
                Condition += ' or ';
            Condition += 'contains(' + Column + ',' + Quote(SearchText) + ')';
        end;
        AddCondition(FilterText, '(' + Condition + ')');
    end;

    /// <summary>
    /// Literal de texto OData: entre comillas simples y con las comillas simples duplicadas.
    /// </summary>
    local procedure Quote(Value: Text): Text
    begin
        exit('''' + Value.Replace('''', '''''') + '''');
    end;

    local procedure GuidText(Value: Guid): Text
    begin
        exit(LowerCase(DelChr(Format(Value), '=', '{}')));
    end;

    // =====================================================================
    // Lectura de valores JSON
    // =====================================================================

    local procedure GetText(RecordJson: JsonObject; Name: Text): Text
    begin
        exit(JsonHelper.GetText(RecordJson, Name));
    end;

    /// <summary>
    /// Valor con formato (nombre de la búsqueda, etiqueta del conjunto de opciones) o, si no lo hay, el valor.
    /// </summary>
    local procedure GetFormatted(RecordJson: JsonObject; Name: Text): Text
    var
        Value: Text;
    begin
        Value := JsonHelper.GetText(RecordJson, Name + FormattedValueTok);
        if Value = '' then
            Value := JsonHelper.GetText(RecordJson, Name);
        exit(Value);
    end;

    local procedure GetGuid(RecordJson: JsonObject; Name: Text) Result: Guid
    begin
        if Evaluate(Result, JsonHelper.GetText(RecordJson, Name)) then;
    end;

    local procedure GetDateTime(RecordJson: JsonObject; Name: Text) Result: DateTime
    begin
        if Evaluate(Result, JsonHelper.GetText(RecordJson, Name), 9) then;
    end;

    local procedure GetDate(RecordJson: JsonObject; Name: Text) Result: Date
    var
        Value: Text;
    begin
        Value := JsonHelper.GetText(RecordJson, Name);
        if StrLen(Value) > 10 then
            Value := CopyStr(Value, 1, 10);
        if Evaluate(Result, Value, 9) then;
    end;
}
