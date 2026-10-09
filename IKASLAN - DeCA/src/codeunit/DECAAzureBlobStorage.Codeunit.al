/// <summary>
/// Repositorio en Azure Blob Storage.
/// Subida y borrado: clave compartida de la cuenta (guardada en IsolatedStorage).
/// Descarga: anónima, bien por acceso público "Blob" del contenedor, bien añadiendo a la URL
/// un token SAS de solo lectura. En ambos casos la URL descarga el PDF sin credenciales ni
/// interacción, como exige el apartado tercero de la Resolución de 5/6/2026.
/// </summary>
codeunit 50010 "DECA Azure Blob Storage" implements "DECA Document Storage"
{
    Access = Internal;

    var
        BlobUrlTok: Label 'https://%1.blob.core.windows.net/%2/%3', Locked = true;
        UploadErr: Label 'No se ha podido publicar el DeCA en Azure Blob Storage: %1', Comment = '%1 = error';
        RemoveErr: Label 'No se ha podido retirar el DeCA de Azure Blob Storage: %1', Comment = '%1 = error';

    procedure GetDocumentUrl(BlobName: Text): Text
    var
        DECASetup: Record "DECA Setup";
        Url: Text;
        SasToken: Text;
    begin
        GetCheckedSetup(DECASetup);
        Url := StrSubstNo(BlobUrlTok, DECASetup."Storage Account Name", DECASetup."Container Name", BlobName);
        SasToken := DECASetup."Read SAS Token";
        if SasToken <> '' then begin
            if SasToken.StartsWith('?') then
                SasToken := SasToken.Substring(2);
            Url += '?' + SasToken;
        end;
        exit(Url);
    end;

    procedure Upload(BlobName: Text; DocumentInStream: InStream)
    var
        ABSBlobClient: Codeunit "ABS Blob Client";
        ABSOperationResponse: Codeunit "ABS Operation Response";
        ABSOptionalParameters: Codeunit "ABS Optional Parameters";
    begin
        InitializeClient(ABSBlobClient);
        // Si su versión no tiene esta sobrecarga, use PutBlobBlockBlobStream(BlobName, DocumentInStream)
        ABSOperationResponse := ABSBlobClient.PutBlobBlockBlobStream(BlobName, DocumentInStream, 'application/pdf', ABSOptionalParameters);
        if not ABSOperationResponse.IsSuccessful() then
            Error(UploadErr, ABSOperationResponse.GetError());
    end;

    procedure Remove(BlobName: Text)
    var
        ABSBlobClient: Codeunit "ABS Blob Client";
        ABSOperationResponse: Codeunit "ABS Operation Response";
    begin
        InitializeClient(ABSBlobClient);
        ABSOperationResponse := ABSBlobClient.DeleteBlob(BlobName);
        if not ABSOperationResponse.IsSuccessful() then
            Error(RemoveErr, ABSOperationResponse.GetError());
    end;

    local procedure InitializeClient(var ABSBlobClient: Codeunit "ABS Blob Client")
    var
        DECASetup: Record "DECA Setup";
        StorageServiceAuthorization: Codeunit "Storage Service Authorization";
        Authorization: Interface "Storage Service Authorization";
    begin
        GetCheckedSetup(DECASetup);
        Authorization := StorageServiceAuthorization.CreateSharedKey(DECASetup.GetStorageAccountKey());
        ABSBlobClient.Initialize(DECASetup."Storage Account Name", DECASetup."Container Name", Authorization);
    end;

    local procedure GetCheckedSetup(var DECASetup: Record "DECA Setup")
    begin
        DECASetup.GetSetup();
        DECASetup.TestField("Storage Account Name");
        DECASetup.TestField("Container Name");
    end;
}
