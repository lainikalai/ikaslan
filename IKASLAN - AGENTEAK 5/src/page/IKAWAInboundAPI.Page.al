page 99356 "IKA WA Inbound API"
{
    // Endpoint donde la Azure Function inserta cada mensaje o cambio de estado recibido de WhatsApp:
    // POST https://api.businesscentral.dynamics.com/v2.0/{tenant}/{entorno}/api/ikaslan/whatsapp/v1.0/companies({id})/inboundEvents
    // Autenticación: registro de aplicación de Entra ID dado de alta en BC ("Aplicaciones de Microsoft Entra")
    // con el conjunto de permisos "IKA WA Inbound" (solo puede insertar en esta tabla).
    PageType = API;
    APIPublisher = 'ikaslan';
    APIGroup = 'whatsapp';
    APIVersion = 'v1.0';
    EntityName = 'inboundEvent';
    EntitySetName = 'inboundEvents';
    EntityCaption = 'WhatsApp Inbound Event';
    EntitySetCaption = 'WhatsApp Inbound Events';
    SourceTable = "IKA WA Inbound Event";
    ODataKeyFields = SystemId;
    DelayedInsert = true;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;

    layout
    {
        area(Content)
        {
            repeater(Records)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(eventKind; Rec."Event Kind")
                {
                    Caption = 'Event Kind';
                }
                field(phoneNumberId; Rec."Phone Number ID")
                {
                    Caption = 'Phone Number Id';
                }
                field(fromPhone; Rec."From Phone")
                {
                    Caption = 'From Phone';
                }
                field(profileName; Rec."Profile Name")
                {
                    Caption = 'Profile Name';
                }
                field(waMessageId; Rec."WA Message ID")
                {
                    Caption = 'WA Message Id';
                }
                field(contextMessageId; Rec."Context Message ID")
                {
                    Caption = 'Context Message Id';
                }
                field(unixTimestamp; Rec."Unix Timestamp")
                {
                    Caption = 'Unix Timestamp';
                }
                field(messageType; Rec."Message Type")
                {
                    Caption = 'Message Type';
                }
                field(textPart1; Rec."Text Part 1")
                {
                    Caption = 'Text Part 1';
                }
                field(textPart2; Rec."Text Part 2")
                {
                    Caption = 'Text Part 2';
                }
                field(mediaId; Rec."Media ID")
                {
                    Caption = 'Media Id';
                }
                field(mimeType; Rec."MIME Type")
                {
                    Caption = 'MIME Type';
                }
                field(fileName; Rec."File Name")
                {
                    Caption = 'File Name';
                }
                field(statusValue; Rec."Status Value")
                {
                    Caption = 'Status Value';
                }
                field(errorText; Rec."Error Text")
                {
                    Caption = 'Error Text';
                }
                field(processed; Rec.Processed)
                {
                    Caption = 'Processed';
                    Editable = false;
                }
                field(receivedAt; Rec."Received At")
                {
                    Caption = 'Received At';
                    Editable = false;
                }
            }
        }
    }
}
