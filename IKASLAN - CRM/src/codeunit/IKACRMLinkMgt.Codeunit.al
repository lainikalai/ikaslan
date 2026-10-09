codeunit 99416 "IKA CRM Link Mgt."
{
    // Vínculos entre clientes, proveedores y contactos de BC y su registro del CRM:
    // cliente y proveedor -> cuenta; contacto de tipo empresa -> cuenta; contacto de tipo persona -> contacto.

    var
        DataMgt: Codeunit "IKA CRM Data Mgt.";
        NotSupportedErr: Label 'Solo se pueden vincular clientes, proveedores y contactos.';
        LinkedMsg: Label 'Vinculado con %1 "%2" del CRM.', Comment = '%1 = entity, %2 = name';
        SuggestionQst: Label 'En el CRM hay %1 "%2" con el mismo email o nombre.\¿Vincular %3 %4 con ese registro?', Comment = '%1 = entity, %2 = name, %3 = BC type, %4 = BC no.';
        NoSuggestionMsg: Label 'No se ha encontrado en el CRM ningún registro activo con el mismo email o nombre. Búsquelo en la lista que se abre a continuación.';

    procedure GetLink(TableId: Integer; No: Code[20]; var CrmLink: Record "IKA CRM Link"): Boolean
    begin
        exit(CrmLink.Get(TableId, No));
    end;

    /// <summary>
    /// Entidad del CRM que corresponde al registro de BC.
    /// </summary>
    procedure GetCrmEntity(TableId: Integer; No: Code[20]): Enum "IKA CRM Entity"
    var
        Contact: Record Contact;
    begin
        case TableId of
            Database::Customer, Database::Vendor:
                exit(Enum::"IKA CRM Entity"::Account);
            Database::Contact:
                if Contact.Get(No) then
                    if Contact.Type = Contact.Type::Person then
                        exit(Enum::"IKA CRM Entity"::Contact)
                    else
                        exit(Enum::"IKA CRM Entity"::Account);
        end;
        Error(NotSupportedErr);
    end;

    /// <summary>
    /// Vincula el registro de BC con el CRM: si hay un registro activo con el mismo email (o nombre) lo propone;
    /// si no, abre la lista del CRM para buscarlo. Devuelve true si queda vinculado.
    /// </summary>
    procedure LinkInteractive(TableId: Integer; No: Code[20]): Boolean
    var
        TempAccount: Record "IKA CRM Account Buffer" temporary;
        TempContact: Record "IKA CRM Contact Buffer" temporary;
        CrmEntity: Enum "IKA CRM Entity";
        Name: Text;
        Email: Text;
    begin
        CrmEntity := GetCrmEntity(TableId, No);
        GetSourceData(TableId, No, Name, Email);
        case CrmEntity of
            CrmEntity::Account:
                begin
                    DataMgt.FindAccounts(TempAccount, Email, Name);
                    if TempAccount.Count() = 1 then
                        if Confirm(SuggestionQst, true, CrmEntity, TempAccount.Name, GetBCTypeText(TableId), No) then
                            exit(CreateLink(TableId, No, CrmEntity, TempAccount."Account Id", TempAccount.Name));
                    if TempAccount.IsEmpty() then
                        Message(NoSuggestionMsg);
                    if SelectAccount(Name, TempAccount) then
                        exit(CreateLink(TableId, No, CrmEntity, TempAccount."Account Id", TempAccount.Name));
                end;
            CrmEntity::Contact:
                begin
                    DataMgt.FindContacts(TempContact, Email, Name);
                    if TempContact.Count() = 1 then
                        if Confirm(SuggestionQst, true, CrmEntity, TempContact."Full Name", GetBCTypeText(TableId), No) then
                            exit(CreateLink(TableId, No, CrmEntity, TempContact."Contact Id", TempContact."Full Name"));
                    if TempContact.IsEmpty() then
                        Message(NoSuggestionMsg);
                    if SelectContact(Name, TempContact) then
                        exit(CreateLink(TableId, No, CrmEntity, TempContact."Contact Id", TempContact."Full Name"));
                end;
        end;
        exit(false);
    end;

    local procedure SelectAccount(SearchText: Text; var TempAccount: Record "IKA CRM Account Buffer" temporary): Boolean
    var
        CrmAccounts: Page "IKA CRM Accounts";
    begin
        CrmAccounts.SetSearchText(SearchText);
        CrmAccounts.LookupMode(true);
        if CrmAccounts.RunModal() <> Action::LookupOK then
            exit(false);
        exit(CrmAccounts.GetSelectedAccount(TempAccount));
    end;

    local procedure SelectContact(SearchText: Text; var TempContact: Record "IKA CRM Contact Buffer" temporary): Boolean
    var
        CrmContacts: Page "IKA CRM Contacts";
    begin
        CrmContacts.SetSearchText(SearchText);
        CrmContacts.LookupMode(true);
        if CrmContacts.RunModal() <> Action::LookupOK then
            exit(false);
        exit(CrmContacts.GetSelectedContact(TempContact));
    end;

    procedure CreateLink(TableId: Integer; No: Code[20]; CrmEntity: Enum "IKA CRM Entity"; CrmId: Guid; CrmName: Text): Boolean
    var
        CrmLink: Record "IKA CRM Link";
    begin
        if not CrmLink.Get(TableId, No) then begin
            CrmLink.Init();
            CrmLink."Table ID" := TableId;
            CrmLink."No." := No;
            CrmLink.Insert();
        end;
        CrmLink."CRM Entity" := CrmEntity;
        CrmLink."CRM Id" := CrmId;
        CrmLink."CRM Name" := CopyStr(CrmName, 1, MaxStrLen(CrmLink."CRM Name"));
        CrmLink."Linked At" := CurrentDateTime();
        CrmLink."Linked By" := CopyStr(UserId(), 1, MaxStrLen(CrmLink."Linked By"));
        CrmLink.Modify();
        Message(LinkedMsg, CrmEntity, CrmName);
        exit(true);
    end;

    procedure RemoveLink(TableId: Integer; No: Code[20])
    var
        CrmLink: Record "IKA CRM Link";
    begin
        if CrmLink.Get(TableId, No) then
            CrmLink.Delete();
    end;

    procedure OpenLinkedInCrm(CrmLink: Record "IKA CRM Link")
    begin
        DataMgt.OpenInCrm(GetLogicalName(CrmLink."CRM Entity"), CrmLink."CRM Id");
    end;

    /// <summary>
    /// Abre en BC la ficha de la cuenta del CRM (con sus contactos, oportunidades y actividades) o, para un contacto
    /// del CRM, la lista de contactos filtrada por él.
    /// </summary>
    procedure ShowLinkedInBC(CrmLink: Record "IKA CRM Link")
    var
        TempAccount: Record "IKA CRM Account Buffer" temporary;
        CrmAccount: Page "IKA CRM Account";
        CrmContacts: Page "IKA CRM Contacts";
    begin
        case CrmLink."CRM Entity" of
            CrmLink."CRM Entity"::Account:
                if DataMgt.GetAccount(CrmLink."CRM Id", TempAccount) then begin
                    CrmAccount.SetAccount(TempAccount);
                    CrmAccount.Run();
                end;
            CrmLink."CRM Entity"::Contact:
                begin
                    CrmContacts.SetSearchText(CrmLink."CRM Name");
                    CrmContacts.Run();
                end;
        end;
    end;

    procedure GetLogicalName(CrmEntity: Enum "IKA CRM Entity"): Text
    begin
        case CrmEntity of
            CrmEntity::Account:
                exit('account');
            CrmEntity::Contact:
                exit('contact');
            CrmEntity::Lead:
                exit('lead');
            CrmEntity::Opportunity:
                exit('opportunity');
        end;
        exit('');
    end;

    local procedure GetSourceData(TableId: Integer; No: Code[20]; var Name: Text; var Email: Text)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
    begin
        case TableId of
            Database::Customer:
                if Customer.Get(No) then begin
                    Name := Customer.Name;
                    Email := Customer."E-Mail";
                end;
            Database::Vendor:
                if Vendor.Get(No) then begin
                    Name := Vendor.Name;
                    Email := Vendor."E-Mail";
                end;
            Database::Contact:
                if Contact.Get(No) then begin
                    Name := Contact.Name;
                    Email := Contact."E-Mail";
                end;
        end;
    end;

    local procedure GetBCTypeText(TableId: Integer): Text
    var
        CrmLink: Record "IKA CRM Link";
    begin
        CrmLink."Table ID" := TableId;
        exit(LowerCase(CrmLink.GetBCTypeText()));
    end;
}
