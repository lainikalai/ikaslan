codeunit 99306 "IKA WA Inbound Processor"
{
    // Convierte los eventos de la cola de entrada (insertados por la Azure Function a través de la
    // página API) en mensajes y conversaciones, y actualiza el estado de los mensajes enviados.
    // OnRun procesa UN evento; ProcessPending los recorre aislando errores con Codeunit.Run.
    TableNo = "IKA WA Inbound Event";

    trigger OnRun()
    begin
        ProcessEvent(Rec);
    end;

    var
        Setup: Record "IKA WA Setup";
        PhoneMgt: Codeunit "IKA WA Phone Mgt.";
        UnknownAccountErr: Label 'No hay ninguna cuenta de WhatsApp con Phone Number ID %1.', Comment = '%1 = phone number id';

    procedure ProcessPending(): Integer
    var
        InboundEvent: Record "IKA WA Inbound Event";
        TempInboundEvent: Record "IKA WA Inbound Event" temporary;
        ProcessedCount: Integer;
    begin
        InboundEvent.SetCurrentKey(Processed, "Entry No.");
        InboundEvent.SetRange(Processed, false);
        if InboundEvent.FindSet() then
            repeat
                TempInboundEvent := InboundEvent;
                TempInboundEvent.Insert();
            until InboundEvent.Next() = 0;

        if TempInboundEvent.FindSet() then
            repeat
                InboundEvent.Get(TempInboundEvent."Entry No.");
                Commit();
                ClearLastError();
                if Codeunit.Run(Codeunit::"IKA WA Inbound Processor", InboundEvent) then begin
                    ProcessedCount += 1;
                    InboundEvent.Get(TempInboundEvent."Entry No.");
                    DownloadMedia(InboundEvent."Message Entry No.");
                end else begin
                    InboundEvent.Get(TempInboundEvent."Entry No.");
                    InboundEvent."Processing Error" := CopyStr(GetLastErrorText(), 1, MaxStrLen(InboundEvent."Processing Error"));
                    InboundEvent.Modify();
                end;
                Commit();
            until TempInboundEvent.Next() = 0;
        exit(ProcessedCount);
    end;

    local procedure ProcessEvent(var InboundEvent: Record "IKA WA Inbound Event")
    begin
        if InboundEvent.Processed then
            exit;
        Setup.GetSetup();
        case InboundEvent."Event Kind" of
            InboundEvent."Event Kind"::Message:
                ProcessMessage(InboundEvent);
            InboundEvent."Event Kind"::Status:
                ProcessStatus(InboundEvent);
        end;
        InboundEvent.Processed := true;
        InboundEvent."Processing Error" := '';
        InboundEvent.Modify();
    end;

    local procedure ProcessMessage(var InboundEvent: Record "IKA WA Inbound Event")
    var
        Account: Record "IKA WA Account";
        Conversation: Record "IKA WA Conversation";
        WAMessage: Record "IKA WA Message";
        EntityType: Enum "IKA WA Entity Type";
        EntityNo: Code[20];
        Phone: Text;
    begin
        FindAccount(InboundEvent."Phone Number ID", Account);

        // Duplicados: Meta puede reenviar el mismo webhook
        if InboundEvent."WA Message ID" <> '' then begin
            WAMessage.SetCurrentKey("WA Message ID");
            WAMessage.SetRange("WA Message ID", InboundEvent."WA Message ID");
            if WAMessage.FindFirst() then begin
                InboundEvent."Message Entry No." := WAMessage."Entry No.";
                exit;
            end;
        end;

        Phone := PhoneMgt.NormalizePhone(InboundEvent."From Phone");
        Conversation.FindOrCreate(Account.Code, Phone);
        if InboundEvent."Profile Name" <> '' then
            Conversation."Profile Name" := InboundEvent."Profile Name";
        if (Conversation."Entity No." = '') and Setup."Auto Link by Phone" then
            if PhoneMgt.FindEntityByPhone(Phone, EntityType, EntityNo) then
                Conversation.SetEntity(EntityType, EntityNo);

        WAMessage.Init();
        WAMessage."Entry No." := 0;
        WAMessage."Conversation Entry No." := Conversation."Entry No.";
        WAMessage."Account Code" := Account.Code;
        WAMessage.Direction := WAMessage.Direction::Inbound;
        WAMessage.Status := WAMessage.Status::Received;
        WAMessage."Message Type" := ParseMessageType(InboundEvent."Message Type");
        WAMessage."WA Message ID" := InboundEvent."WA Message ID";
        WAMessage."Context Message ID" := InboundEvent."Context Message ID";
        WAMessage."Sent At" := InboundEvent.GetEventDateTime();
        WAMessage.SetFullText(InboundEvent."Text Part 1" + InboundEvent."Text Part 2");
        WAMessage."Media ID" := InboundEvent."Media ID";
        WAMessage."MIME Type" := InboundEvent."MIME Type";
        WAMessage."File Name" := InboundEvent."File Name";
        WAMessage.Insert(true);

        if WAMessage."Sent At" > Conversation."Last Inbound At" then
            Conversation."Last Inbound At" := WAMessage."Sent At";
        if WAMessage."Sent At" > Conversation."Last Message At" then begin
            Conversation."Last Message At" := WAMessage."Sent At";
            Conversation."Last Message Preview" := CopyStr(WAMessage.GetDisplayText(), 1, MaxStrLen(Conversation."Last Message Preview"));
        end;
        Conversation."No. of Unread" += 1;
        Conversation.Modify();

        InboundEvent."Message Entry No." := WAMessage."Entry No.";
        OnAfterInboundMessage(WAMessage, Conversation);
    end;

    /// <summary>
    /// sent -> delivered -> read (o failed). Nunca se retrocede de estado.
    /// </summary>
    local procedure ProcessStatus(var InboundEvent: Record "IKA WA Inbound Event")
    var
        WAMessage: Record "IKA WA Message";
        NewStatus: Enum "IKA WA Message Status";
    begin
        if InboundEvent."WA Message ID" = '' then
            exit;
        WAMessage.SetCurrentKey("WA Message ID");
        WAMessage.SetRange("WA Message ID", InboundEvent."WA Message ID");
        if not WAMessage.FindFirst() then
            exit; // mensaje enviado desde otra aplicación

        case LowerCase(InboundEvent."Status Value") of
            'sent':
                NewStatus := NewStatus::Sent;
            'delivered':
                NewStatus := NewStatus::Delivered;
            'read':
                NewStatus := NewStatus::Read;
            'failed':
                NewStatus := NewStatus::Failed;
            else
                exit;
        end;
        if (NewStatus = NewStatus::Failed) or (NewStatus.AsInteger() > WAMessage.Status.AsInteger()) then
            WAMessage.Status := NewStatus;
        if InboundEvent."Error Text" <> '' then
            WAMessage."Error Text" := InboundEvent."Error Text";
        WAMessage.Modify();
        InboundEvent."Message Entry No." := WAMessage."Entry No.";
    end;

    local procedure DownloadMedia(MessageEntryNo: Integer)
    var
        WAMessage: Record "IKA WA Message";
    begin
        Setup.GetSetup();
        if not Setup."Download Inbound Media" then
            exit;
        if not WAMessage.Get(MessageEntryNo) then
            exit;
        if (WAMessage."Media ID" = '') or WAMessage."Media Downloaded" or (WAMessage.Direction <> WAMessage.Direction::Inbound) then
            exit;
        Commit();
        ClearLastError();
        if not Codeunit.Run(Codeunit::"IKA WA Media Downloader", WAMessage) then begin
            WAMessage.Get(MessageEntryNo);
            WAMessage."Error Text" := CopyStr(GetLastErrorText(), 1, MaxStrLen(WAMessage."Error Text"));
            WAMessage.Modify();
        end;
    end;

    local procedure FindAccount(PhoneNumberId: Text; var Account: Record "IKA WA Account")
    begin
        Account.SetRange("Phone Number ID", CopyStr(PhoneNumberId, 1, MaxStrLen(Account."Phone Number ID")));
        if not Account.FindFirst() then
            Error(UnknownAccountErr, PhoneNumberId);
    end;

    local procedure ParseMessageType(TypeText: Text): Enum "IKA WA Message Type"
    var
        WAMessage: Record "IKA WA Message";
    begin
        case LowerCase(TypeText) of
            'text':
                exit(WAMessage."Message Type"::"Plain Text");
            'document':
                exit(WAMessage."Message Type"::Document);
            'image':
                exit(WAMessage."Message Type"::Image);
            'audio':
                exit(WAMessage."Message Type"::Audio);
            'video':
                exit(WAMessage."Message Type"::Video);
            'sticker':
                exit(WAMessage."Message Type"::Sticker);
            'location':
                exit(WAMessage."Message Type"::Location);
            'contacts':
                exit(WAMessage."Message Type"::Contacts);
            'interactive':
                exit(WAMessage."Message Type"::Interactive);
            'button':
                exit(WAMessage."Message Type"::Button);
            'reaction':
                exit(WAMessage."Message Type"::Reaction);
        end;
        exit(WAMessage."Message Type"::Other);
    end;

    /// <summary>
    /// Punto de extensión: p.ej. pasar el mensaje al agente de pedidos (AGENTEAK 2) para que Claude
    /// extraiga un pedido de venta.
    /// </summary>
    [IntegrationEvent(false, false)]
    local procedure OnAfterInboundMessage(WAMessage: Record "IKA WA Message"; Conversation: Record "IKA WA Conversation")
    begin
    end;
}
