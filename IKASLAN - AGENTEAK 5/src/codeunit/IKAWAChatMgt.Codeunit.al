codeunit 99336 "IKA WA Chat Mgt."
{
    // Lógica del chat ("IKA WA Chat Part" + control add-in "IKA WA Chat"): datos que se pintan,
    // acciones del usuario (enviar, ficheros, imágenes, plantillas), vinculación de la conversación
    // y aviso al comercial. Las páginas no modifican su Rec: todo se hace sobre un registro leído
    // de nuevo, para no chocar con los cambios que hace el chat (no leídos, último mensaje...).

    var
        PhoneMgt: Codeunit "IKA WA Phone Mgt.";
        CloudApi: Codeunit "IKA WA Cloud API";
        NotLinkedErr: Label 'Vincule primero la conversación a un cliente, proveedor, contacto o vendedor/comprador.';
        NoSalespersonErr: Label 'La conversación no tiene comercial asignado.';
        ImageTooBigErr: Label 'La imagen ocupa más de %1 MB: descárguela para verla.', Comment = '%1 = MB';
        NoMediaErr: Label 'El mensaje no tiene fichero.';
        NotifyTextLbl: Label 'WhatsApp de %1 (+%2): %3', Comment = '%1 = name, %2 = phone, %3 = last message';
        NotifyConfirmQst: Label '¿Enviar a %1 por WhatsApp?\\%2', Comment = '%1 = salesperson, %2 = text';
        NotifySentMsg: Label 'Aviso enviado a %1.', Comment = '%1 = salesperson';
        LinkedMsg: Label 'Conversación vinculada a %1 %2.', Comment = '%1 = entity type, %2 = name';
        NotFoundByPhoneMsg: Label 'No hay ningún cliente, proveedor, contacto ni vendedor/comprador con el teléfono %1.', Comment = '%1 = phone';

    // =====================================================================
    // Datos del chat
    // =====================================================================

    /// <summary>
    /// JSON que pinta el control add-in: { conversationId, title, windowOpen, windowText, canAttach,
    /// truncated, messages: [...], quickReplies: [...] }. Con EntryNo 0 o inexistente, chat vacío.
    /// </summary>
    procedure BuildChatData(ConversationEntryNo: Integer) Data: JsonObject
    var
        Conversation: Record "IKA WA Conversation";
        WAMessage: Record "IKA WA Message";
        Messages: JsonArray;
        MaxMessages: Integer;
        Total: Integer;
    begin
        if (ConversationEntryNo = 0) or not Conversation.Get(ConversationEntryNo) then begin
            Data.Add('conversationId', 0);
            Data.Add('messages', Messages);
            exit;
        end;

        Data.Add('conversationId', Conversation."Entry No.");
        Data.Add('title', GetTitle(Conversation));
        Data.Add('windowOpen', Conversation.IsWindowOpen());
        Data.Add('windowText', Conversation.GetWindowText());
        Data.Add('canAttach', Conversation."Entity No." <> '');

        MaxMessages := 200;
        WAMessage.SetCurrentKey("Conversation Entry No.", "Sent At");
        WAMessage.SetRange("Conversation Entry No.", Conversation."Entry No.");
        WAMessage.SetLoadFields("Entry No.", Direction, "Message Type", Status, "Sent At", "Message Text", "Message Text (Cont.)",
            "Template Name", "Media ID", "File Name", "Media Downloaded", "Attached to Entity", "Error Text", "Sent By");
        Total := WAMessage.Count();
        if WAMessage.FindSet() then begin
            if Total > MaxMessages then
                WAMessage.Next(Total - MaxMessages);
            repeat
                Messages.Add(MessageToJson(WAMessage));
            until WAMessage.Next() = 0;
        end;
        Data.Add('truncated', Total > MaxMessages);
        Data.Add('messages', Messages);
        Data.Add('quickReplies', GetQuickReplies(Conversation));
    end;

    local procedure GetTitle(Conversation: Record "IKA WA Conversation"): Text
    var
        Name: Text;
    begin
        Name := Conversation."Entity Name";
        if Name = '' then
            Name := Conversation."Profile Name";
        if Name = '' then
            exit('+' + Conversation."Phone No.");
        exit(Name + ' · +' + Conversation."Phone No.");
    end;

    local procedure MessageToJson(WAMessage: Record "IKA WA Message") Msg: JsonObject
    var
        Text: Text;
    begin
        Msg.Add('id', WAMessage."Entry No.");
        if WAMessage.Direction = WAMessage.Direction::Inbound then
            Msg.Add('dir', 'in')
        else
            Msg.Add('dir', 'out');
        Msg.Add('kind', GetKind(WAMessage));
        Msg.Add('status', GetStatusCode(WAMessage));
        Msg.Add('day', Format(DT2Date(WAMessage."Sent At"), 0, '<Day,2>/<Month,2>/<Year4>'));
        Msg.Add('time', Format(DT2Time(WAMessage."Sent At"), 0, '<Hours24,2>:<Minutes,2>'));

        // Texto: el propio mensaje o el pie del fichero; para el resto de tipos, la descripción
        if WAMessage.HasMedia() or WAMessage."Media Downloaded" or (WAMessage."Message Type" = WAMessage."Message Type"::Template) then
            Text := WAMessage.GetFullText()
        else
            Text := WAMessage.GetDisplayText();
        Msg.Add('text', Text);
        if WAMessage."Message Type" = WAMessage."Message Type"::Template then
            Msg.Add('template', WAMessage."Template Name");

        Msg.Add('hasMedia', WAMessage.HasMedia() or WAMessage."Media Downloaded");
        Msg.Add('isImage', WAMessage."Message Type" in [WAMessage."Message Type"::Image, WAMessage."Message Type"::Sticker]);
        Msg.Add('fileName', WAMessage."File Name");
        Msg.Add('attached', WAMessage."Attached to Entity");
        Msg.Add('error', WAMessage."Error Text");
        if WAMessage.Direction = WAMessage.Direction::Outbound then
            Msg.Add('sentBy', WAMessage."Sent By");
    end;

    local procedure GetKind(WAMessage: Record "IKA WA Message"): Text
    begin
        case WAMessage."Message Type" of
            WAMessage."Message Type"::Image, WAMessage."Message Type"::Sticker:
                exit('image');
            WAMessage."Message Type"::Audio:
                exit('audio');
            WAMessage."Message Type"::Video:
                exit('video');
            WAMessage."Message Type"::Document:
                exit('document');
            WAMessage."Message Type"::Template:
                exit('template');
        end;
        exit('text');
    end;

    local procedure GetStatusCode(WAMessage: Record "IKA WA Message"): Text
    begin
        case WAMessage.Status of
            WAMessage.Status::Sent:
                exit('sent');
            WAMessage.Status::Delivered:
                exit('delivered');
            WAMessage.Status::Read:
                exit('read');
            WAMessage.Status::Failed:
                exit('failed');
        end;
        exit('received');
    end;

    local procedure GetQuickReplies(Conversation: Record "IKA WA Conversation") Replies: JsonArray
    var
        QuickReply: Record "IKA WA Quick Reply";
        Reply: JsonObject;
        Label: Text;
    begin
        QuickReply.SetCurrentKey("Sorting Order", "Code");
        QuickReply.SetRange(Enabled, true);
        if QuickReply.FindSet() then
            repeat
                Clear(Reply);
                Label := QuickReply.Description;
                if Label = '' then
                    Label := QuickReply."Code";
                Reply.Add('label', Label);
                Reply.Add('text', ResolveQuickReplyText(QuickReply."Message Text", Conversation));
                Replies.Add(Reply);
            until QuickReply.Next() = 0;
    end;

    local procedure ResolveQuickReplyText(Template: Text; Conversation: Record "IKA WA Conversation"): Text
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        User: Record User;
        Name: Text;
        SalespersonName: Text;
        UserName: Text;
    begin
        Name := Conversation."Entity Name";
        if Name = '' then
            Name := Conversation."Profile Name";
        if Conversation."Salesperson Code" <> '' then
            if SalespersonPurchaser.Get(Conversation."Salesperson Code") then
                SalespersonName := SalespersonPurchaser.Name;
        UserName := UserId();
        User.SetRange("User Name", UserId());
        if User.FindFirst() then
            if User."Full Name" <> '' then
                UserName := User."Full Name";
        exit(Template.Replace('{nombre}', Name).Replace('{comercial}', SalespersonName).Replace('{usuario}', UserName));
    end;

    // =====================================================================
    // Acciones del chat
    // =====================================================================

    procedure SendText(ConversationEntryNo: Integer; MessageText: Text)
    var
        Conversation: Record "IKA WA Conversation";
    begin
        Conversation.Get(ConversationEntryNo);
        CloudApi.SendText(Conversation, MessageText);
    end;

    /// <summary>
    /// Pide un fichero al usuario y lo envía (PDF, imagen...) con el texto escrito como pie.
    /// Devuelve false si el usuario cancela.
    /// </summary>
    procedure SendFile(ConversationEntryNo: Integer; Caption: Text): Boolean
    var
        Conversation: Record "IKA WA Conversation";
        TempBlob: Codeunit "Temp Blob";
        InStr: InStream;
        OutStr: OutStream;
        FileName: Text;
    begin
        Conversation.Get(ConversationEntryNo);
        if not UploadIntoStream('', '', '', FileName, InStr) then
            exit(false);
        TempBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, InStr);
        CloudApi.SendFile(Conversation, TempBlob, GetFileNameOnly(FileName), Caption, 0, '');
        exit(true);
    end;

    procedure SendTemplate(ConversationEntryNo: Integer)
    var
        Conversation: Record "IKA WA Conversation";
        TempBlob: Codeunit "Temp Blob";
        WASend: Page "IKA WA Send";
        EmptyRecordId: RecordId;
    begin
        Conversation.Get(ConversationEntryNo);
        WASend.SetContext(Conversation."Entity Type", Conversation."Entity No.", Conversation."Phone No.", TempBlob, '', EmptyRecordId, '');
        WASend.RunModal();
    end;

    /// <summary>
    /// Imagen del mensaje como data URL (base64) para verla dentro del chat. La descarga de Meta si hace falta.
    /// </summary>
    procedure GetImageDataUrl(MessageEntryNo: Integer): Text
    var
        WAMessage: Record "IKA WA Message";
        Base64Convert: Codeunit "Base64 Convert";
        InStr: InStream;
        MimeType: Text;
        MaxImageMB: Integer;
    begin
        WAMessage.Get(MessageEntryNo);
        if not (WAMessage.HasMedia() or WAMessage."Media Downloaded") then
            Error(NoMediaErr);
        CloudApi.DownloadMedia(WAMessage);
        WAMessage.CalcFields("Media Content");
        MaxImageMB := 5;
        if WAMessage."Media Content".Length() > MaxImageMB * 1024 * 1024 then
            Error(ImageTooBigErr, MaxImageMB);
        MimeType := WAMessage."MIME Type";
        if MimeType = '' then
            MimeType := 'image/jpeg';
        WAMessage."Media Content".CreateInStream(InStr);
        exit('data:' + MimeType + ';base64,' + Base64Convert.ToBase64(InStr));
    end;

    procedure DownloadFile(MessageEntryNo: Integer)
    var
        WAMessage: Record "IKA WA Message";
        InStr: InStream;
        FileName: Text;
    begin
        WAMessage.Get(MessageEntryNo);
        if not (WAMessage.HasMedia() or WAMessage."Media Downloaded") then
            Error(NoMediaErr);
        CloudApi.DownloadMedia(WAMessage);
        WAMessage.CalcFields("Media Content");
        WAMessage."Media Content".CreateInStream(InStr);
        FileName := WAMessage."File Name";
        if FileName = '' then
            FileName := CloudApi.GetDefaultFileName(WAMessage);
        DownloadFromStream(InStr, '', '', '', FileName);
    end;

    procedure AttachToEntity(MessageEntryNo: Integer)
    var
        WAMessage: Record "IKA WA Message";
        Conversation: Record "IKA WA Conversation";
    begin
        WAMessage.Get(MessageEntryNo);
        Conversation.Get(WAMessage."Conversation Entry No.");
        if Conversation."Entity No." = '' then
            Error(NotLinkedErr);
        CloudApi.DownloadMedia(WAMessage);
        PhoneMgt.AttachMediaToEntity(WAMessage, Conversation."Entity Type", Conversation."Entity No.");
    end;

    /// <summary>
    /// Procesa los mensajes que haya dejado la Azure Function (sin reintentar los que dieron error,
    /// eso lo hace la cola de proyectos). Se llama cada pocos segundos desde el chat abierto.
    /// </summary>
    procedure ProcessPendingInbound()
    var
        InboundEvent: Record "IKA WA Inbound Event";
        InboundProcessor: Codeunit "IKA WA Inbound Processor";
    begin
        InboundEvent.SetRange(Processed, false);
        InboundEvent.SetRange("Processing Error", '');
        if not InboundEvent.IsEmpty() then
            InboundProcessor.ProcessPending();
    end;

    procedure MarkAsRead(ConversationEntryNo: Integer)
    var
        Conversation: Record "IKA WA Conversation";
    begin
        if Conversation.Get(ConversationEntryNo) then
            Conversation.MarkAsRead();
    end;

    // =====================================================================
    // Vinculación y comercial
    // =====================================================================

    /// <summary>
    /// Elige en la lista correspondiente el cliente, proveedor, contacto o vendedor/comprador y vincula la conversación.
    /// </summary>
    procedure LinkToEntity(ConversationEntryNo: Integer; EntityType: Enum "IKA WA Entity Type"): Boolean
    var
        Conversation: Record "IKA WA Conversation";
        Customer: Record Customer;
        Vendor: Record Vendor;
        Contact: Record Contact;
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        EntityNo: Code[20];
    begin
        Conversation.Get(ConversationEntryNo);
        case EntityType of
            EntityType::Customer:
                if Page.RunModal(0, Customer) = Action::LookupOK then
                    EntityNo := Customer."No.";
            EntityType::Vendor:
                if Page.RunModal(0, Vendor) = Action::LookupOK then
                    EntityNo := Vendor."No.";
            EntityType::Contact:
                if Page.RunModal(0, Contact) = Action::LookupOK then
                    EntityNo := Contact."No.";
            EntityType::SalespersonPurchaser:
                if Page.RunModal(0, SalespersonPurchaser) = Action::LookupOK then
                    EntityNo := SalespersonPurchaser.Code;
        end;
        if EntityNo = '' then
            exit(false);
        Conversation.SetEntity(EntityType, EntityNo);
        Conversation.Modify(true);
        exit(true);
    end;

    procedure LinkByPhone(ConversationEntryNo: Integer)
    var
        Conversation: Record "IKA WA Conversation";
        EntityType: Enum "IKA WA Entity Type";
        EntityNo: Code[20];
    begin
        Conversation.Get(ConversationEntryNo);
        if not PhoneMgt.FindEntityByPhone(Conversation."Phone No.", EntityType, EntityNo) then begin
            Message(NotFoundByPhoneMsg, Conversation."Phone No.");
            exit;
        end;
        Conversation.SetEntity(EntityType, EntityNo);
        Conversation.Modify(true);
        Message(LinkedMsg, EntityType, Conversation."Entity Name");
    end;

    procedure Unlink(ConversationEntryNo: Integer)
    var
        Conversation: Record "IKA WA Conversation";
    begin
        Conversation.Get(ConversationEntryNo);
        Conversation.SetEntity(Conversation."Entity Type"::" ", '');
        Conversation.Modify(true);
    end;

    /// <summary>
    /// Rellena el comercial de las conversaciones vinculadas que no lo tienen (p.ej. las creadas antes
    /// de esta versión) con el de la ficha del cliente, proveedor o contacto.
    /// </summary>
    procedure FillMissingSalespersons(): Integer
    var
        Conversation: Record "IKA WA Conversation";
        SalespersonCode: Code[20];
        UpdatedCount: Integer;
    begin
        Conversation.SetFilter("Entity No.", '<>%1', '');
        Conversation.SetRange("Salesperson Code", '');
        if Conversation.FindSet(true) then
            repeat
                SalespersonCode := PhoneMgt.GetEntitySalespersonCode(Conversation."Entity Type", Conversation."Entity No.");
                if SalespersonCode <> '' then begin
                    Conversation."Salesperson Code" := SalespersonCode;
                    Conversation.Modify(true);
                    UpdatedCount += 1;
                end;
            until Conversation.Next() = 0;
        exit(UpdatedCount);
    end;

    procedure AssignSalesperson(ConversationEntryNo: Integer): Boolean
    var
        Conversation: Record "IKA WA Conversation";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        Conversation.Get(ConversationEntryNo);
        if Conversation."Salesperson Code" <> '' then
            if SalespersonPurchaser.Get(Conversation."Salesperson Code") then;
        if Page.RunModal(0, SalespersonPurchaser) <> Action::LookupOK then
            exit(false);
        Conversation."Salesperson Code" := SalespersonPurchaser.Code;
        Conversation.Modify(true);
        exit(true);
    end;

    /// <summary>
    /// Avisa por WhatsApp al comercial asignado de que el cliente ha escrito, con el último mensaje recibido.
    /// Si el comercial no ha escrito a la empresa en las últimas 24 h, WhatsApp obliga a usar una plantilla:
    /// se abre el diálogo de envío.
    /// </summary>
    procedure NotifySalesperson(ConversationEntryNo: Integer)
    var
        Conversation: Record "IKA WA Conversation";
        SalespersonConversation: Record "IKA WA Conversation";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        TempBlob: Codeunit "Temp Blob";
        WASend: Page "IKA WA Send";
        EmptyRecordId: RecordId;
        Phone: Text;
        NotifyText: Text;
    begin
        Conversation.Get(ConversationEntryNo);
        if Conversation."Salesperson Code" = '' then
            Error(NoSalespersonErr);
        SalespersonPurchaser.Get(Conversation."Salesperson Code");
        Phone := PhoneMgt.GetEntityPhone(Enum::"IKA WA Entity Type"::SalespersonPurchaser, SalespersonPurchaser.Code);
        NotifyText := StrSubstNo(NotifyTextLbl, GetContactName(Conversation), Conversation."Phone No.", GetLastInboundText(Conversation));

        if SalespersonConversation.FindOrCreate(Conversation."Account Code", Phone) or (SalespersonConversation."Entity No." = '') then begin
            SalespersonConversation.SetEntity(Enum::"IKA WA Entity Type"::SalespersonPurchaser, SalespersonPurchaser.Code);
            SalespersonConversation.Modify(true);
        end;

        if SalespersonConversation.IsWindowOpen() then begin
            if not Confirm(NotifyConfirmQst, true, SalespersonPurchaser.Name, NotifyText) then
                exit;
            CloudApi.SendText(SalespersonConversation, NotifyText);
            Message(NotifySentMsg, SalespersonPurchaser.Name);
            exit;
        end;

        WASend.SetContext(Enum::"IKA WA Entity Type"::SalespersonPurchaser, SalespersonPurchaser.Code, Phone, TempBlob, '', EmptyRecordId, '');
        WASend.SetFreeText(NotifyText);
        WASend.RunModal();
    end;

    local procedure GetContactName(Conversation: Record "IKA WA Conversation"): Text
    begin
        if Conversation."Entity Name" <> '' then
            exit(Conversation."Entity Name");
        exit(Conversation."Profile Name");
    end;

    local procedure GetLastInboundText(Conversation: Record "IKA WA Conversation"): Text
    var
        WAMessage: Record "IKA WA Message";
    begin
        WAMessage.SetCurrentKey("Conversation Entry No.", "Sent At");
        WAMessage.SetRange("Conversation Entry No.", Conversation."Entry No.");
        WAMessage.SetRange(Direction, WAMessage.Direction::Inbound);
        if WAMessage.FindLast() then
            exit(CopyStr(WAMessage.GetDisplayText(), 1, 500));
        exit('');
    end;

    procedure GetFileNameOnly(FullPath: Text): Text
    var
        Pos: Integer;
    begin
        Pos := StrLen(FullPath);
        while (Pos > 0) and not (CopyStr(FullPath, Pos, 1) in ['\', '/']) do
            Pos -= 1;
        exit(CopyStr(FullPath, Pos + 1));
    end;
}
