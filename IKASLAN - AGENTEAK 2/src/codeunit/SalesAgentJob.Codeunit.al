codeunit 50090 "IKA Sales Agent Job"
{
    // Punto de entrada para la cola de proyectos (Job Queue Entry):
    //   1. Importa los emails nuevos del buzón que cumplen los filtros.
    //   2. Procesa cada solicitud nueva (Claude + resolución + creación automática si procede).
    //   3. Mueve cada email a la carpeta de procesados o de errores.
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        RunAgent();
    end;

    var
        Setup: Record "IKA Sales Agent Setup";
        LogMgt: Codeunit "IKA Sales Agent Log Mgt.";
        DisabledLbl: Label 'El agente de ventas está desactivado en la configuración.';
        ImportErrLbl: Label 'Error al importar emails: %1', Comment = '%1 = error';
        MoveErrLbl: Label 'No se pudo mover el email en el buzón: %1', Comment = '%1 = error';
        RunSummaryLbl: Label 'Ejecución terminada: %1 email(s) importado(s), %2 solicitud(es) procesada(s), %3 con error.', Comment = '%1 = imported, %2 = processed, %3 = errors';

    procedure RunAgent()
    var
        RequestHeader: Record "IKA Sales Request Header";
        TempRequestHeader: Record "IKA Sales Request Header" temporary;
        GraphMailClient: Codeunit "IKA Graph Mail Client";
        ImportedCount: Integer;
        ProcessedCount: Integer;
        ErrorCount: Integer;
    begin
        Setup.GetSetup();
        if not Setup.Enabled then begin
            LogMgt.LogWarning(0, DisabledLbl);
            exit;
        end;

        if Setup."Mailbox Address" <> '' then begin
            Commit();
            ClearLastError();
            // Codeunit.Run (y no TryFunction) porque la importación hace Commit por cada email
            if not GraphMailClient.Run() then
                LogMgt.LogError(0, StrSubstNo(ImportErrLbl, GetLastErrorText()));
            ImportedCount := GraphMailClient.GetLastImportedCount();
            Commit();
        end;

        // Se copia la lista primero: al procesar se crean solicitudes nuevas (varios pedidos por email)
        RequestHeader.SetRange(Status, RequestHeader.Status::New);
        RequestHeader.SetRange("Parent Entry No.", 0);
        if RequestHeader.FindSet() then
            repeat
                TempRequestHeader := RequestHeader;
                TempRequestHeader.Insert();
            until RequestHeader.Next() = 0;

        if TempRequestHeader.FindSet() then
            repeat
                RequestHeader.Get(TempRequestHeader."Entry No.");
                if ProcessOne(RequestHeader) then
                    ProcessedCount += 1
                else
                    ErrorCount += 1;
            until TempRequestHeader.Next() = 0;

        LogMgt.LogInfo(0, StrSubstNo(RunSummaryLbl, ImportedCount, ProcessedCount, ErrorCount));
    end;

    /// <summary>
    /// Procesa una solicitud aislando los errores. Devuelve false si ha fallado.
    /// </summary>
    procedure ProcessOne(var RequestHeader: Record "IKA Sales Request Header"): Boolean
    var
        SalesReqProcess: Codeunit "IKA Sales Req. Process";
        Success: Boolean;
        ErrorText: Text;
    begin
        Setup.GetSetup();
        Commit();
        ClearLastError();
        SalesReqProcess.SetAutoCreate(true);
        Success := SalesReqProcess.Run(RequestHeader);
        if not Success then begin
            ErrorText := GetLastErrorText();
            RequestHeader.Get(RequestHeader."Entry No.");
            RequestHeader.Status := RequestHeader.Status::Error;
            RequestHeader."Error Message" := CopyStr(ErrorText, 1, MaxStrLen(RequestHeader."Error Message"));
            RequestHeader."Processed At" := CurrentDateTime();
            RequestHeader.Modify();
            LogMgt.LogError(RequestHeader."Entry No.", ErrorText);
        end;
        Commit();

        RequestHeader.Get(RequestHeader."Entry No.");
        if RequestHeader.Source = RequestHeader.Source::Email then
            if Success then
                MoveMail(RequestHeader, Setup."Processed Folder")
            else
                MoveMail(RequestHeader, Setup."Error Folder");
        exit(Success);
    end;

    local procedure MoveMail(var RequestHeader: Record "IKA Sales Request Header"; FolderName: Text)
    var
        MoveRequestMail: Codeunit "IKA Move Request Mail";
    begin
        if FolderName = '' then
            exit;
        Commit();
        ClearLastError();
        MoveRequestMail.SetTargetFolder(FolderName);
        if not MoveRequestMail.Run(RequestHeader) then
            LogMgt.LogError(RequestHeader."Entry No.", StrSubstNo(MoveErrLbl, GetLastErrorText()));
        Commit();
    end;

    /// <summary>
    /// Crea (o reutiliza) la entrada recurrente de la cola de proyectos que ejecuta el agente.
    /// </summary>
    procedure CreateJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobDescriptionLbl: Label 'Agente de ventas (Claude): leer emails y crear pedidos';
        JobExistsMsg: Label 'Ya existe la entrada de cola de proyectos %1. Se ha puesto en estado Preparado.', Comment = '%1 = description';
        JobCreatedMsg: Label 'Se ha creado la entrada de cola de proyectos cada %1 minutos.', Comment = '%1 = minutes';
    begin
        Setup.GetSetup();
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"IKA Sales Agent Job");
        if JobQueueEntry.FindFirst() then begin
            JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
            Message(JobExistsMsg, JobQueueEntry.Description);
            exit;
        end;

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"IKA Sales Agent Job";
        JobQueueEntry.Description := CopyStr(JobDescriptionLbl, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Run on Mondays" := true;
        JobQueueEntry."Run on Tuesdays" := true;
        JobQueueEntry."Run on Wednesdays" := true;
        JobQueueEntry."Run on Thursdays" := true;
        JobQueueEntry."Run on Fridays" := true;
        JobQueueEntry."Run on Saturdays" := false;
        JobQueueEntry."Run on Sundays" := false;
        JobQueueEntry."No. of Minutes between Runs" := Setup."Job Interval (min)";
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Rerun Delay (sec.)" := 60;
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime();
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
        Message(JobCreatedMsg, Setup."Job Interval (min)");
    end;
}
