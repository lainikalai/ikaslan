codeunit 99316 "IKA WA Phone Mgt."
{
    // Teléfonos (normalización a formato internacional de WhatsApp) y todo lo que depende del tipo
    // de entidad: nombre, teléfono, ficha, enlace wa.me y adjuntos.

    var
        Setup: Record "IKA WA Setup";
        NoPhoneErr: Label '%1 %2 no tiene teléfono móvil ni fijo.', Comment = '%1 = entity type, %2 = no.';
        EntityNotFoundErr: Label 'No existe %1 %2.', Comment = '%1 = entity type, %2 = no.';
        WaMeUrlTok: Label 'https://wa.me/%1', Locked = true;

    /// <summary>
    /// "+34 600 12 34 56", "0034600123456" o "600123456" -> "34600123456".
    /// </summary>
    procedure NormalizePhone(Phone: Text): Text
    var
        Digits: Text;
        i: Integer;
    begin
        Setup.GetSetup();
        for i := 1 to StrLen(Phone) do
            if CopyStr(Phone, i, 1) in ['0' .. '9'] then
                Digits += CopyStr(Phone, i, 1);
        if Digits = '' then
            exit('');
        if CopyStr(Digits, 1, 2) = '00' then
            exit(CopyStr(Digits, 3));
        // Sin prefijo internacional (ni "+" ni "00"): se añade el de la configuración
        if (StrPos(DelChr(Phone, '<', ' '), '+') <> 1) and (StrLen(Digits) <= 9) and (Setup."Default Country Code" <> '') then
            exit(Setup."Default Country Code" + Digits);
        exit(Digits);
    end;

    procedure SamePhone(Phone1: Text; Phone2: Text): Boolean
    var
        Normalized1: Text;
        Normalized2: Text;
    begin
        Normalized1 := NormalizePhone(Phone1);
        Normalized2 := NormalizePhone(Phone2);
        exit((Normalized1 <> '') and (Normalized1 = Normalized2));
    end;

    /// <summary>
    /// Busca el cliente, proveedor o contacto con ese teléfono (móvil o fijo). Recorre los registros
    /// con teléfono porque en BC los números se guardan con formatos variados (espacios, guiones...).
    /// </summary>
    procedure FindEntityByPhone(Phone: Text; var EntityType: Enum "IKA WA Entity Type"; var EntityNo: Code[20]): Boolean
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
    begin
        if NormalizePhone(Phone) = '' then
            exit(false);

        Customer.SetLoadFields("No.", "Phone No.", "Mobile Phone No.");
        Customer.SetFilter("Mobile Phone No.", '<>%1', '');
        if Customer.FindSet() then
            repeat
                if SamePhone(Customer."Mobile Phone No.", Phone) then
                    exit(SetEntity(EntityType, EntityNo, EntityType::Customer, Customer."No."));
            until Customer.Next() = 0;
        Customer.SetRange("Mobile Phone No.");
        Customer.SetFilter("Phone No.", '<>%1', '');
        if Customer.FindSet() then
            repeat
                if SamePhone(Customer."Phone No.", Phone) then
                    exit(SetEntity(EntityType, EntityNo, EntityType::Customer, Customer."No."));
            until Customer.Next() = 0;

        Vendor.SetLoadFields("No.", "Phone No.", "Mobile Phone No.");
        Vendor.SetFilter("Mobile Phone No.", '<>%1', '');
        if Vendor.FindSet() then
            repeat
                if SamePhone(Vendor."Mobile Phone No.", Phone) then
                    exit(SetEntity(EntityType, EntityNo, EntityType::Vendor, Vendor."No."));
            until Vendor.Next() = 0;
        Vendor.SetRange("Mobile Phone No.");
        Vendor.SetFilter("Phone No.", '<>%1', '');
        if Vendor.FindSet() then
            repeat
                if SamePhone(Vendor."Phone No.", Phone) then
                    exit(SetEntity(EntityType, EntityNo, EntityType::Vendor, Vendor."No."));
            until Vendor.Next() = 0;

        Contact.SetLoadFields("No.", "Phone No.", "Mobile Phone No.");
        Contact.SetFilter("Mobile Phone No.", '<>%1', '');
        if Contact.FindSet() then
            repeat
                if SamePhone(Contact."Mobile Phone No.", Phone) then
                    exit(SetEntity(EntityType, EntityNo, EntityType::Contact, Contact."No."));
            until Contact.Next() = 0;
        Contact.SetRange("Mobile Phone No.");
        Contact.SetFilter("Phone No.", '<>%1', '');
        if Contact.FindSet() then
            repeat
                if SamePhone(Contact."Phone No.", Phone) then
                    exit(SetEntity(EntityType, EntityNo, EntityType::Contact, Contact."No."));
            until Contact.Next() = 0;
        exit(false);
    end;

    local procedure SetEntity(var EntityType: Enum "IKA WA Entity Type"; var EntityNo: Code[20]; FoundType: Enum "IKA WA Entity Type"; FoundNo: Code[20]): Boolean
    begin
        EntityType := FoundType;
        EntityNo := FoundNo;
        exit(true);
    end;

    /// <summary>
    /// Teléfono de WhatsApp de la entidad: el móvil y, si no hay, el fijo. Ya normalizado.
    /// </summary>
    procedure GetEntityPhone(EntityType: Enum "IKA WA Entity Type"; EntityNo: Code[20]): Text
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        Phone: Text;
    begin
        case EntityType of
            EntityType::Customer:
                if Customer.Get(EntityNo) then
                    Phone := FirstNotBlank(Customer."Mobile Phone No.", Customer."Phone No.");
            EntityType::Vendor:
                if Vendor.Get(EntityNo) then
                    Phone := FirstNotBlank(Vendor."Mobile Phone No.", Vendor."Phone No.");
            EntityType::Contact:
                if Contact.Get(EntityNo) then
                    Phone := FirstNotBlank(Contact."Mobile Phone No.", Contact."Phone No.");
        end;
        if Phone = '' then
            Error(NoPhoneErr, EntityType, EntityNo);
        exit(NormalizePhone(Phone));
    end;

    local procedure FirstNotBlank(Value1: Text; Value2: Text): Text
    begin
        if DelChr(Value1, '=', ' ') <> '' then
            exit(Value1);
        exit(Value2);
    end;

    procedure GetEntityName(EntityType: Enum "IKA WA Entity Type"; EntityNo: Code[20]): Text[100]
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
    begin
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
        end;
        exit('');
    end;

    procedure OpenEntityCard(EntityType: Enum "IKA WA Entity Type"; EntityNo: Code[20])
    var
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
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
        end;
    end;

    /// <summary>
    /// Enlace "click to chat": abre WhatsApp (web o escritorio) con el mensaje ya escrito.
    /// No necesita la API de Meta; el usuario envía el mensaje desde su propio WhatsApp.
    /// </summary>
    procedure OpenWaMe(Phone: Text; MessageText: Text)
    var
        UriHelper: Codeunit Uri;
        Url: Text;
    begin
        Url := StrSubstNo(WaMeUrlTok, NormalizePhone(Phone));
        if MessageText <> '' then
            Url += '?text=' + UriHelper.EscapeDataString(MessageText);
        Hyperlink(Url);
    end;

    /// <summary>
    /// Guarda el fichero recibido en los adjuntos estándar (Document Attachment) de la entidad.
    /// </summary>
    procedure AttachMediaToEntity(var WAMessage: Record "IKA WA Message"; EntityType: Enum "IKA WA Entity Type"; EntityNo: Code[20])
    var
        DocumentAttachment: Record "Document Attachment";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        InStr: InStream;
    begin
        case EntityType of
            EntityType::Customer:
                RecRef.Open(Database::Customer);
            EntityType::Vendor:
                RecRef.Open(Database::Vendor);
            EntityType::Contact:
                RecRef.Open(Database::Contact);
            else
                Error(EntityNotFoundErr, EntityType, EntityNo);
        end;
        FieldRef := RecRef.Field(1);
        FieldRef.SetRange(EntityNo);
        if not RecRef.FindFirst() then
            Error(EntityNotFoundErr, EntityType, EntityNo);

        WAMessage.CalcFields("Media Content");
        WAMessage."Media Content".CreateInStream(InStr);
        DocumentAttachment.SaveAttachmentFromStream(InStr, RecRef, WAMessage."File Name");
        WAMessage."Attached to Entity" := true;
        WAMessage.Modify();
    end;

    /// <summary>
    /// "Document Attachment" no rellena el Nº para Contacto; se completa aquí.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Document Attachment", 'OnAfterInitFieldsFromRecRef', '', false, false)]
    local procedure DocumentAttachmentOnAfterInitFieldsFromRecRef(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
    begin
        if (DocumentAttachment."No." <> '') or (RecRef.Number <> Database::Contact) then
            exit;
        FieldRef := RecRef.Field(1);
        DocumentAttachment."No." := FieldRef.Value;
    end;
}
