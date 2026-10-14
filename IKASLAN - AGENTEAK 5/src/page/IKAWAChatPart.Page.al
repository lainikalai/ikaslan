page 99371 "IKA WA Chat Part"
{
    // Chat de una conversación con el control add-in "IKA WA Chat". Se usa en la ficha de la
    // conversación y como FactBox de la bandeja (vista a dos paneles). No modifica su Rec:
    // todo pasa por "IKA WA Chat Mgt." con registros leídos de nuevo.
    Caption = 'Chat';
    PageType = CardPart;
    SourceTable = "IKA WA Conversation";
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;
    ModifyAllowed = false;

    layout
    {
        area(Content)
        {
            usercontrol(Chat; "IKA WA Chat")
            {
                ApplicationArea = All;

                trigger ControlReady()
                begin
                    ControlIsReady := true;
                    RefreshChat(true);
                end;

                trigger SendText(MessageText: Text)
                begin
                    ChatMgt.SendText(Rec."Entry No.", MessageText);
                    CurrPage.Chat.ClearComposer();
                    RefreshChat(false);
                end;

                trigger AttachFile(Caption: Text)
                begin
                    if ChatMgt.SendFile(Rec."Entry No.", Caption) then
                        CurrPage.Chat.ClearComposer();
                    RefreshChat(false);
                end;

                trigger SendTemplate()
                begin
                    ChatMgt.SendTemplate(Rec."Entry No.");
                    RefreshChat(false);
                end;

                trigger RequestImage(EntryNo: Integer)
                begin
                    CurrPage.Chat.ShowImage(EntryNo, ChatMgt.GetImageDataUrl(EntryNo));
                end;

                trigger DownloadFile(EntryNo: Integer)
                begin
                    ChatMgt.DownloadFile(EntryNo);
                end;

                trigger AttachToEntity(EntryNo: Integer)
                begin
                    ChatMgt.AttachToEntity(EntryNo);
                    RefreshChat(false);
                end;

                trigger Poll()
                begin
                    ChatMgt.ProcessPendingInbound();
                    RefreshChat(false);
                end;
            }
        }
    }

    var
        ChatMgt: Codeunit "IKA WA Chat Mgt.";
        ControlIsReady: Boolean;
        ShownEntryNo: Integer;
        LastDataText: Text;

    trigger OnAfterGetCurrRecord()
    begin
        if ControlIsReady then
            RefreshChat(false);
    end;

    /// <summary>
    /// Vuelve a pintar el chat solo si algo ha cambiado (mensajes nuevos, estados, ventana...).
    /// Al abrir otra conversación se marcan como leídos sus mensajes.
    /// </summary>
    local procedure RefreshChat(Force: Boolean)
    var
        Data: JsonObject;
        DataText: Text;
    begin
        if Rec."Entry No." <> ShownEntryNo then begin
            ShownEntryNo := Rec."Entry No.";
            if ShownEntryNo <> 0 then
                ChatMgt.MarkAsRead(ShownEntryNo);
            Force := true;
        end else
            if ShownEntryNo <> 0 then
                ChatMgt.MarkAsRead(ShownEntryNo); // lo que llega con el chat abierto ya está visto

        Data := ChatMgt.BuildChatData(ShownEntryNo);
        Data.WriteTo(DataText);
        if (not Force) and (DataText = LastDataText) then
            exit;
        LastDataText := DataText;
        CurrPage.Chat.Render(Data);
    end;
}
