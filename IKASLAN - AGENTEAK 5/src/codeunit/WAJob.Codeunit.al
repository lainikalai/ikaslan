codeunit 50660 "IKA WA Job"
{
    // Cola de proyectos: procesa los eventos que ha dejado la Azure Function (cada 1-5 minutos).
    TableNo = "Job Queue Entry";

    trigger OnRun()
    var
        InboundProcessor: Codeunit "IKA WA Inbound Processor";
    begin
        InboundProcessor.ProcessPending();
    end;

    procedure CreateJobQueueEntry()
    var
        JobQueueEntry: Record "Job Queue Entry";
        JobDescriptionLbl: Label 'WhatsApp: procesar mensajes recibidos';
        JobExistsMsg: Label 'Ya existe la entrada de cola de proyectos %1. Se ha puesto en estado Preparado.', Comment = '%1 = description';
        JobCreatedMsg: Label 'Se ha creado la entrada de cola de proyectos (cada 2 minutos).';
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"IKA WA Job");
        if JobQueueEntry.FindFirst() then begin
            JobQueueEntry.SetStatus(JobQueueEntry.Status::Ready);
            Message(JobExistsMsg, JobQueueEntry.Description);
            exit;
        end;
        JobQueueEntry.Init();
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"IKA WA Job";
        JobQueueEntry.Description := CopyStr(JobDescriptionLbl, 1, MaxStrLen(JobQueueEntry.Description));
        JobQueueEntry."Recurring Job" := true;
        JobQueueEntry."Run on Mondays" := true;
        JobQueueEntry."Run on Tuesdays" := true;
        JobQueueEntry."Run on Wednesdays" := true;
        JobQueueEntry."Run on Thursdays" := true;
        JobQueueEntry."Run on Fridays" := true;
        JobQueueEntry."Run on Saturdays" := true;
        JobQueueEntry."Run on Sundays" := true;
        JobQueueEntry."No. of Minutes between Runs" := 2;
        JobQueueEntry."Maximum No. of Attempts to Run" := 3;
        JobQueueEntry."Rerun Delay (sec.)" := 30;
        JobQueueEntry."Earliest Start Date/Time" := CurrentDateTime();
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
        Message(JobCreatedMsg);
    end;
}
