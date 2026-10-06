page 99331 "IKA WA Conversation"
{
    Caption = 'Conversación de WhatsApp';
    PageType = Document;
    SourceTable = "IKA WA Conversation";
    UsageCategory = None;
    InsertAllowed = false;
    DataCaptionFields = "Entity Name", "Phone No.";

    layout
    {
        area(Content)
        {
            group(General)
            {
                Caption = 'Conversación';

                field("Phone No."; Rec."Phone No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Profile Name"; Rec."Profile Name")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                field("Entity Type"; Rec."Entity Type")
                {
                    ApplicationArea = All;
                }
                field("Entity No."; Rec."Entity No.")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec."Entity Name" := PhoneMgt.GetEntityName(Rec."Entity Type", Rec."Entity No.");
                    end;
                }
                field("Entity Name"; Rec."Entity Name")
                {
                    ApplicationArea = All;
                }
                field(WindowText; Rec.GetWindowText())
                {
                    ApplicationArea = All;
                    Caption = 'Ventana de 24 h';
                    StyleExpr = WindowStyle;
                }
                field("Account Code"; Rec."Account Code")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
            }
            group(Reply)
            {
                Caption = 'Responder';

                field(NewMessageText; NewMessageText)
                {
                    ApplicationArea = All;
                    Caption = 'Mensaje';
                    MultiLine = true;
                    ToolTip = 'Texto libre: solo con la ventana de 24 h abierta. Si está cerrada, use "Enviar plantilla".';
                }
            }
            part(Messages; "IKA WA Messages Part")
            {
                ApplicationArea = All;
                SubPageLink = "Conversation Entry No." = field("Entry No.");
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SendText)
            {
                ApplicationArea = All;
                Caption = 'Enviar';
                Image = SendTo;
                ShortcutKey = 'Ctrl+Enter';
                ToolTip = 'Envía el texto escrito.';

                trigger OnAction()
                var
                    CloudApi: Codeunit "IKA WA Cloud API";
                begin
                    CurrPage.SaveRecord();
                    CloudApi.SendText(Rec, NewMessageText);
                    NewMessageText := '';
                    CurrPage.Update(false);
                end;
            }
            action(SendFile)
            {
                ApplicationArea = All;
                Caption = 'Enviar fichero';
                Image = Attach;
                ToolTip = 'Envía un PDF o una imagen (ventana de 24 h abierta). El texto escrito va como pie.';

                trigger OnAction()
                var
                    CloudApi: Codeunit "IKA WA Cloud API";
                    TempBlob: Codeunit "Temp Blob";
                    InStr: InStream;
                    OutStr: OutStream;
                    FileName: Text;
                begin
                    if not UploadIntoStream('', '', '', FileName, InStr) then
                        exit;
                    TempBlob.CreateOutStream(OutStr);
                    CopyStream(OutStr, InStr);
                    CloudApi.SendFile(Rec, TempBlob, GetFileNameOnly(FileName), NewMessageText, 0, '');
                    NewMessageText := '';
                    CurrPage.Update(false);
                end;
            }
            action(SendTemplate)
            {
                ApplicationArea = All;
                Caption = 'Enviar plantilla';
                Image = Template;
                ToolTip = 'Envía una plantilla aprobada (siempre permitido, también con la ventana cerrada).';

                trigger OnAction()
                var
                    WASend: Page "IKA WA Send";
                    TempBlob: Codeunit "Temp Blob";
                    EmptyRecordId: RecordId;
                begin
                    WASend.SetContext(Rec."Entity Type", Rec."Entity No.", Rec."Phone No.", TempBlob, '', EmptyRecordId, '');
                    WASend.RunModal();
                    CurrPage.Update(false);
                end;
            }
            action(LinkByPhone)
            {
                ApplicationArea = All;
                Caption = 'Buscar entidad por teléfono';
                Image = Find;
                ToolTip = 'Busca el cliente, proveedor o contacto con este teléfono.';

                trigger OnAction()
                var
                    EntityType: Enum "IKA WA Entity Type";
                    EntityNo: Code[20];
                    NotFoundMsg: Label 'No hay ningún cliente, proveedor ni contacto con el teléfono %1.', Comment = '%1 = phone';
                begin
                    if not PhoneMgt.FindEntityByPhone(Rec."Phone No.", EntityType, EntityNo) then begin
                        Message(NotFoundMsg, Rec."Phone No.");
                        exit;
                    end;
                    Rec."Entity Type" := EntityType;
                    Rec."Entity No." := EntityNo;
                    Rec."Entity Name" := PhoneMgt.GetEntityName(EntityType, EntityNo);
                    Rec.Modify();
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Actualizar';
                Image = Refresh;
                ShortcutKey = 'F5';
                ToolTip = 'Procesa los mensajes recibidos pendientes.';

                trigger OnAction()
                var
                    InboundProcessor: Codeunit "IKA WA Inbound Processor";
                begin
                    InboundProcessor.ProcessPending();
                    Rec.Get(Rec."Entry No.");
                    MarkConversationRead();
                    CurrPage.Update(false);
                end;
            }
        }
        area(Navigation)
        {
            action(OpenEntity)
            {
                ApplicationArea = All;
                Caption = 'Abrir ficha';
                Image = Card;
                Enabled = Rec."Entity No." <> '';
                ToolTip = 'Abre la ficha del cliente, proveedor o contacto.';

                trigger OnAction()
                begin
                    PhoneMgt.OpenEntityCard(Rec."Entity Type", Rec."Entity No.");
                end;
            }
            action(OpenWaMe)
            {
                ApplicationArea = All;
                Caption = 'Abrir en mi WhatsApp';
                Image = Web;
                ToolTip = 'Abre este chat en WhatsApp web o de escritorio.';

                trigger OnAction()
                begin
                    PhoneMgt.OpenWaMe(Rec."Phone No.", NewMessageText);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Proceso';

                actionref(SendText_Promoted; SendText) { }
                actionref(SendFile_Promoted; SendFile) { }
                actionref(SendTemplate_Promoted; SendTemplate) { }
                actionref(Refresh_Promoted; Refresh) { }
            }
            group(Category_Navigate)
            {
                Caption = 'Navegar';

                actionref(OpenEntity_Promoted; OpenEntity) { }
                actionref(LinkByPhone_Promoted; LinkByPhone) { }
                actionref(OpenWaMe_Promoted; OpenWaMe) { }
            }
        }
    }

    var
        PhoneMgt: Codeunit "IKA WA Phone Mgt.";
        NewMessageText: Text;
        WindowStyle: Text;
        MarkedEntryNo: Integer;

    trigger OnAfterGetCurrRecord()
    begin
        if Rec.IsWindowOpen() then
            WindowStyle := 'Favorable'
        else
            WindowStyle := 'Attention';
        if Rec."Entry No." <> MarkedEntryNo then begin
            MarkedEntryNo := Rec."Entry No.";
            MarkConversationRead();
        end;
    end;

    /// <summary>
    /// Pone a cero los no leídos y, si está configurado, envía el "leído" a WhatsApp del último mensaje recibido.
    /// </summary>
    local procedure MarkConversationRead()
    var
        Setup: Record "IKA WA Setup";
        WAMessage: Record "IKA WA Message";
        CloudApi: Codeunit "IKA WA Cloud API";
    begin
        if Rec."No. of Unread" = 0 then
            exit;
        Setup.GetSetup();
        if Setup."Send Read Receipts" then begin
            WAMessage.SetCurrentKey("Conversation Entry No.", "Sent At");
            WAMessage.SetRange("Conversation Entry No.", Rec."Entry No.");
            WAMessage.SetRange(Direction, WAMessage.Direction::Inbound);
            if WAMessage.FindLast() then
                if not TryMarkAsRead(CloudApi, WAMessage) then; // no es crítico
        end;
        Rec."No. of Unread" := 0;
        Rec.Modify();
    end;

    [TryFunction]
    local procedure TryMarkAsRead(var CloudApi: Codeunit "IKA WA Cloud API"; WAMessage: Record "IKA WA Message")
    begin
        CloudApi.MarkAsRead(WAMessage."Account Code", WAMessage."WA Message ID");
    end;

    local procedure GetFileNameOnly(FullPath: Text): Text
    var
        Pos: Integer;
    begin
        Pos := StrLen(FullPath);
        while (Pos > 0) and not (CopyStr(FullPath, Pos, 1) in ['\', '/']) do
            Pos -= 1;
        exit(CopyStr(FullPath, Pos + 1));
    end;
}
