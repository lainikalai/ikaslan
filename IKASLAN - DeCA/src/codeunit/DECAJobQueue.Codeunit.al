/// <summary>
/// Para la cola de proyectos: desactiva la descarga de los DeCA cuyo servicio terminó hace más
/// días de los configurados (mínimo 7). El PDF se conserva en Business Central.
/// </summary>
codeunit 50020 "DECA Job Queue"
{
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        DisableExpiredUrls();
    end;

    procedure DisableExpiredUrls(): Integer
    var
        DECASetup: Record "DECA Setup";
        DECAHeader: Record "DECA Header";
        DECAHeader2: Record "DECA Header";
        DECADocumentStorage: Interface "DECA Document Storage";
        DaysOnline: Integer;
        Counter: Integer;
    begin
        DECASetup.GetSetup();
        DaysOnline := DECASetup."Days Online After Service";
        if DaysOnline < 7 then
            DaysOnline := 7;
        DECADocumentStorage := DECASetup."Storage Provider";

        DECAHeader.SetFilter(Status, '<>%1', DECAHeader.Status::Draft);
        DECAHeader.SetRange("URL Disabled", false);
        DECAHeader.SetFilter("Service End Date", '<>%1&<%2', 0D, Today() - DaysOnline);
        if DECAHeader.FindSet() then
            repeat
                DECAHeader2.Get(DECAHeader."No.");
                if DECAHeader2."Blob Name" <> '' then
                    DECADocumentStorage.Remove(DECAHeader2."Blob Name");
                DECAHeader2."URL Disabled" := true;
                DECAHeader2."URL Disabled At" := CurrentDateTime();
                DECAHeader2.Modify();
                Commit(); // el fichero ya no está publicado: se confirma documento a documento
                Counter += 1;
            until DECAHeader.Next() = 0;
        exit(Counter);
    end;
}
