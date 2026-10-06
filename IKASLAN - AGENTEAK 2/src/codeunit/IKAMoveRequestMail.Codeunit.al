codeunit 99046 "IKA Move Request Mail"
{
    // Mueve el email de una solicitud a otra carpeta del buzón. Se ejecuta con Codeunit.Run
    // para que un fallo de Graph no detenga el procesamiento del resto de emails.
    TableNo = "IKA Sales Request Header";

    trigger OnRun()
    var
        GraphMailClient: Codeunit "IKA Graph Mail Client";
    begin
        GraphMailClient.MoveRequestMessage(Rec, TargetFolder);
    end;

    var
        TargetFolder: Text;

    procedure SetTargetFolder(NewTargetFolder: Text)
    begin
        TargetFolder := NewTargetFolder;
    end;
}
