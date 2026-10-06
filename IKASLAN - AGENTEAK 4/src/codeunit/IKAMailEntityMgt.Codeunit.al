codeunit 50410 "IKA Mail Entity Mgt."
{
    // Todo lo que depende del tipo de entidad (cliente, proveedor, banco...) está aquí.
    // Para añadir un tipo nuevo: valor en el enum "IKA Mail Entity Type" + un caso en cada procedimiento.

    procedure GetTableId(EntityType: Enum "IKA Mail Entity Type"): Integer
    begin
        case EntityType of
            EntityType::Customer:
                exit(Database::Customer);
            EntityType::Vendor:
                exit(Database::Vendor);
            EntityType::Contact:
                exit(Database::Contact);
            EntityType::"Bank Account":
                exit(Database::"Bank Account");
            EntityType::Resource:
                exit(Database::Resource);
            EntityType::Item:
                exit(Database::Item);
            EntityType::Employee:
                exit(Database::Employee);
            EntityType::"Fixed Asset":
                exit(Database::"Fixed Asset");
            EntityType::Job:
                exit(Database::Job);
        end;
    end;

    procedure GetRecRef(EntityType: Enum "IKA Mail Entity Type"; EntityNo: Code[20]; var RecRef: RecordRef): Boolean
    var
        FieldRef: FieldRef;
    begin
        Clear(RecRef);
        RecRef.Open(GetTableId(EntityType));
        // En todas estas tablas la clave primaria es el campo 1 "No."
        FieldRef := RecRef.Field(1);
        FieldRef.SetRange(EntityNo);
        exit(RecRef.FindFirst());
    end;

    procedure GetName(EntityType: Enum "IKA Mail Entity Type"; EntityNo: Code[20]): Text[100]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        BankAccount: Record "Bank Account";
        Resource: Record Resource;
        Item: Record Item;
        Employee: Record Employee;
        FixedAsset: Record "Fixed Asset";
        Job: Record Job;
    begin
        if EntityNo = '' then
            exit('');
        case EntityType of
            EntityType::Customer:
                if Customer.Get(EntityNo) then
                    exit(Customer.Name);
            EntityType::Vendor:
                if Vendor.Get(EntityNo) then
                    exit(Vendor.Name);
            EntityType::Contact:
                if Contact.Get(EntityNo) then
                    exit(Contact.Name);
            EntityType::"Bank Account":
                if BankAccount.Get(EntityNo) then
                    exit(BankAccount.Name);
            EntityType::Resource:
                if Resource.Get(EntityNo) then
                    exit(Resource.Name);
            EntityType::Item:
                if Item.Get(EntityNo) then
                    exit(Item.Description);
            EntityType::Employee:
                if Employee.Get(EntityNo) then
                    exit(CopyStr(Employee.FullName(), 1, 100));
            EntityType::"Fixed Asset":
                if FixedAsset.Get(EntityNo) then
                    exit(FixedAsset.Description);
            EntityType::Job:
                if Job.Get(EntityNo) then
                    exit(Job.Description);
        end;
        exit('');
    end;

    procedure Lookup(EntityType: Enum "IKA Mail Entity Type"; var EntityNo: Code[20]): Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        BankAccount: Record "Bank Account";
        Resource: Record Resource;
        Item: Record Item;
        Employee: Record Employee;
        FixedAsset: Record "Fixed Asset";
        Job: Record Job;
    begin
        case EntityType of
            EntityType::Customer:
                begin
                    if Customer.Get(EntityNo) then;
                    if Page.RunModal(0, Customer) <> Action::LookupOK then
                        exit(false);
                    EntityNo := Customer."No.";
                end;
            EntityType::Vendor:
                begin
                    if Vendor.Get(EntityNo) then;
                    if Page.RunModal(0, Vendor) <> Action::LookupOK then
                        exit(false);
                    EntityNo := Vendor."No.";
                end;
            EntityType::Contact:
                begin
                    if Contact.Get(EntityNo) then;
                    if Page.RunModal(0, Contact) <> Action::LookupOK then
                        exit(false);
                    EntityNo := Contact."No.";
                end;
            EntityType::"Bank Account":
                begin
                    if BankAccount.Get(EntityNo) then;
                    if Page.RunModal(0, BankAccount) <> Action::LookupOK then
                        exit(false);
                    EntityNo := BankAccount."No.";
                end;
            EntityType::Resource:
                begin
                    if Resource.Get(EntityNo) then;
                    if Page.RunModal(0, Resource) <> Action::LookupOK then
                        exit(false);
                    EntityNo := Resource."No.";
                end;
            EntityType::Item:
                begin
                    if Item.Get(EntityNo) then;
                    if Page.RunModal(0, Item) <> Action::LookupOK then
                        exit(false);
                    EntityNo := Item."No.";
                end;
            EntityType::Employee:
                begin
                    if Employee.Get(EntityNo) then;
                    if Page.RunModal(0, Employee) <> Action::LookupOK then
                        exit(false);
                    EntityNo := Employee."No.";
                end;
            EntityType::"Fixed Asset":
                begin
                    if FixedAsset.Get(EntityNo) then;
                    if Page.RunModal(0, FixedAsset) <> Action::LookupOK then
                        exit(false);
                    EntityNo := FixedAsset."No.";
                end;
            EntityType::Job:
                begin
                    if Job.Get(EntityNo) then;
                    if Page.RunModal(0, Job) <> Action::LookupOK then
                        exit(false);
                    EntityNo := Job."No.";
                end;
        end;
        exit(true);
    end;

    procedure OpenCard(EntityType: Enum "IKA Mail Entity Type"; EntityNo: Code[20])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        BankAccount: Record "Bank Account";
        Resource: Record Resource;
        Item: Record Item;
        Employee: Record Employee;
        FixedAsset: Record "Fixed Asset";
        Job: Record Job;
    begin
        case EntityType of
            EntityType::Customer:
                if Customer.Get(EntityNo) then
                    Page.Run(Page::"Customer Card", Customer);
            EntityType::Vendor:
                if Vendor.Get(EntityNo) then
                    Page.Run(Page::"Vendor Card", Vendor);
            EntityType::Contact:
                if Contact.Get(EntityNo) then
                    Page.Run(Page::"Contact Card", Contact);
            EntityType::"Bank Account":
                if BankAccount.Get(EntityNo) then
                    Page.Run(Page::"Bank Account Card", BankAccount);
            EntityType::Resource:
                if Resource.Get(EntityNo) then
                    Page.Run(Page::"Resource Card", Resource);
            EntityType::Item:
                if Item.Get(EntityNo) then
                    Page.Run(Page::"Item Card", Item);
            EntityType::Employee:
                if Employee.Get(EntityNo) then
                    Page.Run(Page::"Employee Card", Employee);
            EntityType::"Fixed Asset":
                if FixedAsset.Get(EntityNo) then
                    Page.Run(Page::"Fixed Asset Card", FixedAsset);
            EntityType::Job:
                if Job.Get(EntityNo) then
                    Page.Run(Page::"Job Card", Job);
        end;
    end;

    /// <summary>
    /// Destinos sugeridos a partir del remitente: clientes, proveedores y contactos con ese email
    /// y, si no hay coincidencia exacta, clientes y proveedores cuyo email es del mismo dominio.
    /// </summary>
    procedure AddSuggestions(FromAddress: Text; var TempDropTarget: Record "IKA Mail Drop Target" temporary; var SortOrder: Integer)
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        Address: Text;
        Domain: Text;
        Found: Boolean;
    begin
        Address := LowerCase(DelChr(FromAddress, '<>', ' '));
        if (Address = '') or (StrPos(Address, '@') = 0) or (StrLen(Address) > 80) then
            exit;

        Customer.SetRange("E-Mail", Address);
        if Customer.FindSet() then
            repeat
                Found := AddTarget(TempDropTarget, "IKA Mail Entity Type"::Customer, Customer."No.", Customer.Name, SortOrder) or Found;
            until Customer.Next() = 0;
        Vendor.SetRange("E-Mail", Address);
        if Vendor.FindSet() then
            repeat
                Found := AddTarget(TempDropTarget, "IKA Mail Entity Type"::Vendor, Vendor."No.", Vendor.Name, SortOrder) or Found;
            until Vendor.Next() = 0;
        Contact.SetRange("E-Mail", Address);
        if Contact.FindSet() then
            repeat
                Found := AddTarget(TempDropTarget, "IKA Mail Entity Type"::Contact, Contact."No.", Contact.Name, SortOrder) or Found;
            until Contact.Next() = 0;
        if Found then
            exit;

        // Mismo dominio (solo dominios corporativos)
        Domain := CopyStr(Address, StrPos(Address, '@') + 1);
        if IsGenericDomain(Domain) or (DelChr(Domain, '=', 'abcdefghijklmnopqrstuvwxyz0123456789.-') <> '') then
            exit;
        Customer.Reset();
        Customer.SetFilter("E-Mail", '@*' + Domain + '*');
        if Customer.FindSet() then
            repeat
                if LowerCase(Customer."E-Mail").EndsWith('@' + Domain) then
                    AddTarget(TempDropTarget, "IKA Mail Entity Type"::Customer, Customer."No.", Customer.Name, SortOrder);
            until (Customer.Next() = 0) or (SortOrder > 20);
        Vendor.Reset();
        Vendor.SetFilter("E-Mail", '@*' + Domain + '*');
        if Vendor.FindSet() then
            repeat
                if LowerCase(Vendor."E-Mail").EndsWith('@' + Domain) then
                    AddTarget(TempDropTarget, "IKA Mail Entity Type"::Vendor, Vendor."No.", Vendor.Name, SortOrder);
            until (Vendor.Next() = 0) or (SortOrder > 20);
    end;

    local procedure AddTarget(var TempDropTarget: Record "IKA Mail Drop Target" temporary; EntityType: Enum "IKA Mail Entity Type"; EntityNo: Code[20]; Name: Text; var SortOrder: Integer): Boolean
    begin
        if TempDropTarget.Get(EntityType, EntityNo) then
            exit(true);
        SortOrder += 1;
        TempDropTarget.Init();
        TempDropTarget."Entity Type" := EntityType;
        TempDropTarget."Entity No." := EntityNo;
        TempDropTarget.Name := CopyStr(Name, 1, MaxStrLen(TempDropTarget.Name));
        TempDropTarget.Kind := TempDropTarget.Kind::Suggested;
        TempDropTarget."Sort Order" := SortOrder;
        TempDropTarget.Insert();
        exit(true);
    end;

    local procedure IsGenericDomain(Domain: Text): Boolean
    begin
        exit(Domain in ['gmail.com', 'hotmail.com', 'hotmail.es', 'outlook.com', 'outlook.es', 'live.com', 'yahoo.com', 'yahoo.es', 'icloud.com', 'telefonica.net', 'movistar.es', 'euskaltel.net', '']);
    end;
}
