codeunit 99311 "IKA WA Media Downloader"
{
    // Descarga el fichero de un mensaje recibido. Se ejecuta con Codeunit.Run para que un fallo
    // (fichero caducado en Meta, red...) no impida registrar el mensaje.
    TableNo = "IKA WA Message";

    trigger OnRun()
    var
        CloudApi: Codeunit "IKA WA Cloud API";
    begin
        CloudApi.DownloadMedia(Rec);
    end;
}
