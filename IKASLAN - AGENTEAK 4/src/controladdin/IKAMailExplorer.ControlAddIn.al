controladdin "IKA Mail Explorer"
{
    // Vista tipo Outlook en tres paneles: árbol de carpetas, emails de la carpeta y panel de lectura
    // (que se puede ocultar). Todo el texto se pinta como texto (nunca como HTML) y el cuerpo del email
    // se muestra en un iframe aislado sin scripts, igual que en "IKA Mail Workspace".
    RequestedHeight = 700;
    MinimumHeight = 420;
    RequestedWidth = 1100;
    MinimumWidth = 320;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts = 'src/controladdin/MailExplorer/js/MailExplorer.js';
    StartupScript = 'src/controladdin/MailExplorer/js/Startup.js';
    StyleSheets = 'src/controladdin/MailExplorer/css/MailExplorer.css';

    /// <summary>El add-in está listo para recibir datos.</summary>
    event ControlReady();
    /// <summary>El usuario elige otra cuenta.</summary>
    event MailboxSelected(MailboxCode: Text);
    /// <summary>El usuario elige una carpeta del árbol.</summary>
    event FolderSelected(FolderId: Text);
    /// <summary>El usuario selecciona un email de la lista (clic o flechas).</summary>
    event MessageSelected(EntryNo: Integer);
    /// <summary>El usuario abre un email (doble clic o Intro): se abre su ficha.</summary>
    event MessageOpened(EntryNo: Integer);
    /// <summary>Descargar los últimos emails de la carpeta.</summary>
    event SyncRequested();
    /// <summary>Descargar emails más antiguos de la carpeta.</summary>
    event LoadOlderRequested();
    /// <summary>Volver a leer el árbol de carpetas.</summary>
    event RefreshFoldersRequested();
    /// <summary>Responder ("reply"), responder a todos ("replyAll") o reenviar ("forward").</summary>
    event ComposeRequested(EntryNo: Integer; Mode: Text);
    event MoveRequested(EntryNo: Integer);
    event ToggleReadRequested(EntryNo: Integer);
    event OpenInOutlookRequested(EntryNo: Integer);
    event DownloadAttachmentRequested(EntryNo: Integer; LineNo: Integer);
    event DownloadEmlRequested(EntryNo: Integer);
    /// <summary>El usuario muestra u oculta el panel de lectura.</summary>
    event ReadingPaneToggled(Visible: Boolean);

    /// <summary>{ current, items: [{ code, label }] }</summary>
    procedure SetMailboxes(DataJson: Text);
    /// <summary>{ selected, items: [{ id, name, path, level, unread, total, children, wellKnown }] }</summary>
    procedure SetFolders(DataJson: Text);
    /// <summary>{ folderId, title, selected, truncated, items: [{ id, from, subject, preview, date, read, ... }] }</summary>
    procedure SetMessages(DataJson: Text);
    /// <summary>Actualiza una fila de la lista (p.ej. al marcarlo como leído).</summary>
    procedure UpdateMessage(ItemJson: Text);
    /// <summary>Cabecera y adjuntos del email del panel de lectura ('' lo vacía).</summary>
    procedure SetMessage(DetailJson: Text);
    /// <summary>Cuerpo HTML del email del panel de lectura.</summary>
    procedure SetBody(Html: Text);
    procedure SetReadingPane(Visible: Boolean);
    procedure ShowStatus(MessageText: Text; IsError: Boolean);
    procedure SetBusy(IsBusy: Boolean);
}
