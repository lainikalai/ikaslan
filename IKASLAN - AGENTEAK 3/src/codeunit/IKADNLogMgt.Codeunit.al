codeunit 50270 "IKA DN Log Mgt."
{
    procedure LogInfo(DocumentEntryNo: Integer; MessageText: Text)
    begin
        InsertLog(DocumentEntryNo, "IKA DN Log Type"::Information, MessageText);
    end;

    procedure LogWarning(DocumentEntryNo: Integer; MessageText: Text)
    begin
        InsertLog(DocumentEntryNo, "IKA DN Log Type"::Warning, MessageText);
    end;

    procedure LogError(DocumentEntryNo: Integer; MessageText: Text)
    begin
        InsertLog(DocumentEntryNo, "IKA DN Log Type"::Error, MessageText);
    end;

    procedure LogClaudeCall(DocumentEntryNo: Integer; Model: Text; RequestText: Text; ResponseText: Text; HttpStatus: Integer; InputTokens: Integer; OutputTokens: Integer; DurationMs: Duration; MessageText: Text)
    var
        AgentLog: Record "IKA DN Log";
    begin
        AgentLog.Init();
        AgentLog."Document Entry No." := DocumentEntryNo;
        AgentLog."Log Type" := AgentLog."Log Type"::"Claude Call";
        AgentLog.Message := CopyStr(MessageText, 1, MaxStrLen(AgentLog.Message));
        AgentLog.Model := CopyStr(Model, 1, MaxStrLen(AgentLog.Model));
        AgentLog."HTTP Status" := HttpStatus;
        AgentLog."Input Tokens" := InputTokens;
        AgentLog."Output Tokens" := OutputTokens;
        AgentLog.Duration := DurationMs;
        AgentLog.SetPayloads(RequestText, ResponseText);
        AgentLog.Insert(true);
    end;

    procedure LogGraphCall(DocumentEntryNo: Integer; MessageText: Text; HttpStatus: Integer; ResponseText: Text)
    var
        AgentLog: Record "IKA DN Log";
    begin
        AgentLog.Init();
        AgentLog."Document Entry No." := DocumentEntryNo;
        AgentLog."Log Type" := AgentLog."Log Type"::"Graph Call";
        AgentLog.Message := CopyStr(MessageText, 1, MaxStrLen(AgentLog.Message));
        AgentLog."HTTP Status" := HttpStatus;
        AgentLog.SetPayloads('', ResponseText);
        AgentLog.Insert(true);
    end;

    local procedure InsertLog(DocumentEntryNo: Integer; LogType: Enum "IKA DN Log Type"; MessageText: Text)
    var
        AgentLog: Record "IKA DN Log";
    begin
        AgentLog.Init();
        AgentLog."Document Entry No." := DocumentEntryNo;
        AgentLog."Log Type" := LogType;
        AgentLog.Message := CopyStr(MessageText, 1, MaxStrLen(AgentLog.Message));
        AgentLog.Insert(true);
    end;
}
