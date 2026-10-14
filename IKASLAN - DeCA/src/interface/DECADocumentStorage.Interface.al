/// <summary>
/// Repositorio externo donde se publican los PDF del DeCA.
/// La URL debe conocerse ANTES de generar el PDF, porque va dentro del código QR.
/// </summary>
interface "DECA Document Storage"
{
    /// <summary>Devuelve la URL https de descarga directa para un nombre de fichero.</summary>
    procedure GetDocumentUrl(BlobName: Text): Text;

    /// <summary>Publica el PDF en el repositorio.</summary>
    procedure Upload(BlobName: Text; DocumentInStream: InStream);

    /// <summary>Retira el PDF del repositorio (desactiva la descarga).</summary>
    procedure Remove(BlobName: Text);
}
