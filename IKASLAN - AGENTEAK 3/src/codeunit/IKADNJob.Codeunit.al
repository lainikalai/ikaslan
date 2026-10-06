codeunit 50300 "IKA DN Job"
{
    // Punto de entrada de la cola de proyectos:
    //   1. Importa emails y ficheros nuevos.
    //   2. Procesa cada documento nuevo (Claude + conciliación + aplicación si procede).
    //   3. Mueve el origen a la carpeta de procesados o errores.
    TableNo = "Job Queue Entry";

    trigger OnRun()
    begin
        RunAgent();
    end;

    var
        Setup: Record "IKA DN Setup";
        LogMgt: Codeunit "IKA DN Log Mgt.";
        DisabledLbl: Label 'El agente de albaranes está desactivado en la configuración.';
        ImportErrLbl: Label 'Error al importar documentos: %1', Comment = '%1 = error';
        MoveErrLbl: Label 'No se pudo mover el origen: %1', Comment = '%1 = error';
        RunSummaryLbl: Label 'Ejecución terminada: %1 documento(s) importado(s), %2 procesado(s), %3 con error.', Comment = '%1 = imported, %2 = processed, %3 = errors';

    procedure RunAgent()
    var
        DNDocument: Record "IKA DN Document";
        TempDNDocument: Record "IKA DN Document" temporary;
        GraphClient: Codeunit "IKA DN Graph Client";
        ImportedCount: Integer;
        ProcessedCount: Integer;
        ErrorCount: Integer;
    begin
        Setup.GetSetup();
        if not Setup.Enabled then begin
            LogMgt.LogWarning(0, DisabledLbl);
            exit;
        end;

        if Setup."Mail Enabled" or Setup."Folder Enabled" then begin
            Commit();
            ClearLastError();
            // Codeunit.Run (no TryFunction) porque la importación hace Commit por documento
            if not GraphClient.Run() then
                LogMgt.LogError(0, StrSubstNo(ImportErrLbl, GetLastErrorText()));
            ImportedCount := GraphClient.GetLastImportedCount();
            Commit();
        end;

        DNDocument.SetRange(Status, DNDocument.Status::New);
        DNDocument.SetRange("Parent Entry No.", 0);
        if DNDocument.FindSet() then
            repeat
                TempDNDocument := DNDocument;
                TempDNDocument.Insert();
            until DNDocument.Next() = 0;

        if TempDNDocument.FindSet() then
            repeat
                DNDocument.Get(TempDNDocument."Entry No.");
                if ProcessOne(DNDocument, true) then
                    ProcessedCount += 1
                else
                    ErrorCount += 1;
            until TempDNDocument.Next() = 0;

        LogMgt.LogInfo(0, StrSubstNo(RunSummaryLbl, ImportedCount, ProcessedCount, ErrorCount));
    end;

    procedure ProcessOne(var DNDocument: Record "IKA DN Document"; AutoApply: Boolean): Boolean
    var
        DNProcess: Codeunit "IKA DN Process";
        Success: Boolean;
        ErrorText: Text;
    begin
        Setup.GetSetup();
        Commit();
        ClearLastError();
        DNProcess.SetAutoApply(AutoApply);
        Success := DNProcess.Run(DNDocument);
        if not Success then begin
            ErrorText := GetLastErrorText();
            DNDocument.Get(DNDocument."Entry No.");
            DNDocument.Status := DNDocument.Status::Error;
            DNDocument."Review Notes" := CopyStr(ErrorText, 1, MaxStrLen(DNDocument."Review Notes"));
            DNDocument."Processed At" := CurrentDateTime();
            DNDocument.Modify();
            LogMgt.LogError(DNDocument."Entry No.", ErrorText);
        end;
        Commit();

        DNDocument.Get(DNDocument."Entry No.");
        case DNDocument.Source of
            DNDocument.Source::Email:
                if Success then
                    MoveSource(DNDocument, Setup."Mail Processed Folder")
                else
                    MoveSource(DNDocument, Setup."Mail Error Folder");
            DNDocument.Source::Folder:
                if Success then
                    MoveSource(DNDocument, Setup."Folder Processed Path")
                else
                    MoveSource(DNDocument, Setup."Folder Error Path");
        end;
        exit(Success);
    end;

    local procedure MoveSource(var DNDocument: Record "IKA DN Document"; Target: Text)
    var
        DNMoveSource: Codeunit "IKA DN Move Source";
    begin
        if Target = '' then
            exit;
        Commit();
        ClearLastError();
        DNMoveSource.SetTargetFolder(Target);
        if not DNMoveSource.Run(DNDocument) then
            LogMgt.LogError(DNDocument."Entry No.", StrSubstNo(MoveErrLbl, GetLastErrorText()));
        Commit();
    end;

    procedure CreateJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobDescriptionLbl: Label 'Agente de albaranes (Claude): leer y conciliar albaranes';
        JobExistsMsg: Label 'Ya existe la entrada de cola de proyectos %1. Se ha puesto en estado Preparado.', Comment = '%1 = description';
        JobCreatedMsg: Label 'Se ha creado la entrada de cola de proyectos cada %1 minutos.', Comment = '%1 = minutes';
    begin
        Setup.GetSetup();
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"IKA DN Job");
        if JobQueueEntry.FindFirst() then begin
            JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
            Message(JobExistsMsg, JobQueueEntry.Description);
            exit;
        end;

        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"IKA DN Job";
        JobQueueEntry.Description := CopyStr(JobDescriptionLbl, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Run on Mondays" := true;
        JobQueueEntry."Run on Tuesdays" := true;
        JobQueueEntry."Run on Wednesdays" := true;
        JobQueueEntry."Run on Thursdays" := true;
        JobQueueEntry."Run on Fridays" := true;
        JobQueueEntry."No. of Minutes between Runs" := Setup."Job Interval (min)";
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Rerun Delay (sec.)" := 60;
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime();
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
        Message(JobCreatedMsg, Setup."Job Interval (min)");
    end;
}
