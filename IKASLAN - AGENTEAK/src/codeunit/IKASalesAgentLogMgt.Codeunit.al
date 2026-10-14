codeunit 99031 "IKA Sales Agent Log Mgt."
{
    procedure LogInfo(RequestEntryNo: Integer; MessageText: Text)
    begin
        InsertLog(RequestEntryNo, "IKA Agent Log Type"::Information, MessageText);
    end;

    procedure LogWarning(RequestEntryNo: Integer; MessageText: Text)
    begin
        InsertLog(RequestEntryNo, "IKA Agent Log Type"::Warning, MessageText);
    end;

    procedure LogError(RequestEntryNo: Integer; MessageText: Text)
    begin
        InsertLog(RequestEntryNo, "IKA Agent Log Type"::Error, MessageText);
    end;

    procedure LogClaudeCall(RequestEntryNo: Integer; Model: Text; RequestText: Text; ResponseText: Text; HttpStatus: Integer; InputTokens: Integer; OutputTokens: Integer; DurationMs: Duration; MessageText: Text)
    var
        ModelPrice: Record "IKA Claude Model Price";
        AgentLog: Record "IKA Sales Agent Log";
    begin
        AgentLog.Init();
        AgentLog."Request Entry No." := RequestEntryNo;
        AgentLog."Log Type" := AgentLog."Log Type"::"Claude Call";
        AgentLog.Message := CopyStr(MessageText, 1, MaxStrLen(AgentLog.Message));
        AgentLog.Model := CopyStr(Model, 1, MaxStrLen(AgentLog.Model));
        AgentLog."HTTP Status" := HttpStatus;
        AgentLog."Input Tokens" := InputTokens;
        AgentLog."Output Tokens" := OutputTokens;
        AgentLog."Cost (USD)" := ModelPrice.CalcCostOnDate(Model, InputTokens, OutputTokens, DT2Date(CurrentDateTime()),
            AgentLog."Input Price per MTok", AgentLog."Output Price per MTok", AgentLog."Price Valid From");
        AgentLog.Duration := DurationMs;
        AgentLog.SetPayloads(RequestText, ResponseText);
        AgentLog.Insert(true);
    end;

    procedure LogGraphCall(RequestEntryNo: Integer; MessageText: Text; HttpStatus: Integer; ResponseText: Text)
    var
        AgentLog: Record "IKA Sales Agent Log";
    begin
        AgentLog.Init();
        AgentLog."Request Entry No." := RequestEntryNo;
        AgentLog."Log Type" := AgentLog."Log Type"::"Graph Call";
        AgentLog.Message := CopyStr(MessageText, 1, MaxStrLen(AgentLog.Message));
        AgentLog."HTTP Status" := HttpStatus;
        AgentLog.SetPayloads('', ResponseText);
        AgentLog.Insert(true);
    end;

    local procedure InsertLog(RequestEntryNo: Integer; LogType: Enum "IKA Agent Log Type"; MessageText: Text)
    var
        AgentLog: Record "IKA Sales Agent Log";
    begin
        AgentLog.Init();
        AgentLog."Request Entry No." := RequestEntryNo;
        AgentLog."Log Type" := LogType;
        AgentLog.Message := CopyStr(MessageText, 1, MaxStrLen(AgentLog.Message));
        AgentLog.Insert(true);
    end;
}
