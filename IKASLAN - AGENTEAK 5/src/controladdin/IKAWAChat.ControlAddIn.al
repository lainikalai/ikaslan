controladdin "IKA WA Chat"
{
    // Vista de chat de una conversación de WhatsApp: burbujas, estados (✓ ✓✓), imágenes, respuestas
    // rápidas y caja de texto (Intro envía, Mayús+Intro salto de línea). Toda la lógica está en AL
    // ("IKA WA Chat Mgt."); el JavaScript solo pinta y avisa de lo que hace el usuario.
    RequestedHeight = 560;
    MinimumHeight = 320;
    RequestedWidth = 400;
    MinimumWidth = 260;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;
    Scripts = 'src/controladdin/WhatsAppChat/js/WhatsAppChat.js';
    StartupScript = 'src/controladdin/WhatsAppChat/js/Startup.js';
    StyleSheets = 'src/controladdin/WhatsAppChat/css/WhatsAppChat.css';

    /// <summary>
    /// Pinta la conversación completa (cabecera, mensajes, respuestas rápidas). Ver "IKA WA Chat Mgt.".BuildChatData.
    /// </summary>
    procedure Render(Data: JsonObject);
    /// <summary>
    /// Muestra la imagen pedida con RequestImage (data URL en base64).
    /// </summary>
    procedure ShowImage(EntryNo: Integer; DataUrl: Text);
    /// <summary>
    /// Vacía la caja de texto tras un envío correcto (si el envío falla, el texto se conserva).
    /// </summary>
    procedure ClearComposer();

    event ControlReady();
    event SendText(MessageText: Text);
    event AttachFile(Caption: Text);
    event SendTemplate();
    event RequestImage(EntryNo: Integer);
    event DownloadFile(EntryNo: Integer);
    event AttachToEntity(EntryNo: Integer);
    event Poll();
}
