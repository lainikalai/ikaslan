controladdin "IKA Mail Workspace"
{
    // Visor del email + zonas de destino en un mismo iframe, para que el drag & drop sea nativo
    // del navegador (BC no permite arrastrar entre páginas distintas).
    RequestedHeight = 650;
    MinimumHeight = 400;
    RequestedWidth = 900;
    MinimumWidth = 300;
    VerticalStretch = true;
    VerticalShrink = true;
    HorizontalStretch = true;
    HorizontalShrink = true;

    Scripts = 'src/controladdin/MailWorkspace/js/MailWorkspace.js';
    StartupScript = 'src/controladdin/MailWorkspace/js/Startup.js';
    StyleSheets = 'src/controladdin/MailWorkspace/css/MailWorkspace.css';

    /// <summary>El add-in está listo para recibir datos.</summary>
    event ControlReady();
    /// <summary>Se ha soltado (o asignado con clic) un elemento del email sobre un destino.</summary>
    event ItemDropped(ItemId: Text; TargetId: Text);
    /// <summary>Se ha soltado un fichero del escritorio/Outlook sobre un destino.</summary>
    event FileDropped(TargetId: Text; FileName: Text; Base64Content: Text);
    /// <summary>El usuario quiere descargar un elemento.</summary>
    event DownloadRequested(ItemId: Text);
    /// <summary>El usuario fija o quita un destino.</summary>
    event PinToggled(TargetId: Text);
    /// <summary>El usuario quiere abrir la ficha del destino.</summary>
    event OpenTargetRequested(TargetId: Text);

    procedure SetBody(Html: Text);
    procedure SetItems(ItemsJson: Text);
    procedure SetTargets(TargetsJson: Text);
    procedure ShowStatus(MessageText: Text; IsError: Boolean);
    procedure SetBusy(IsBusy: Boolean);
}
