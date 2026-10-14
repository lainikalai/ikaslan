codeunit 99151 "IKA DN Move Source"
{
    // Mueve el email o el fichero de origen a la carpeta de procesados / errores.
    // Se ejecuta con Codeunit.Run para que un fallo de Graph no detenga el procesamiento.
    TableNo = "IKA DN Document";

    trigger OnRun()
    var
        GraphClient: Codeunit "IKA DN Graph Client";
    begin
        case Rec.Source of
            Rec.Source::Email:
                GraphClient.MoveMessage(Rec, TargetFolder);
            Rec.Source::Folder:
                GraphClient.MoveFile(Rec, TargetFolder);
        end;
    end;

    var
        TargetFolder: Text;

    procedure SetTargetFolder(NewTargetFolder: Text)
    begin
        TargetFolder := NewTargetFolder;
    end;
}
