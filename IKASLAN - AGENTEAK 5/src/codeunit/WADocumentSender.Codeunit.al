codeunit 50630 "IKA WA Document Sender"
{
    // Envío de documentos de BC por WhatsApp: genera el PDF con el informe configurado en
    // "Selección de informes" (el mismo que se usa para el email) y abre el diálogo de envío.

    var
        PhoneMgt: Codeunit "IKA WA Phone Mgt.";

    procedure SendSalesDocument(RecordVariant: Variant; ReportUsage: Enum "Report Selection Usage"; CustomerNo: Code[20]; DocumentNo: Code[20]; FileNamePrefix: Text)
    var
        ReportSelections: Record "Report Selections";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
    begin
        ReportSelections.GetPdfReportForCust(TempBlob, ReportUsage, RecordVariant, CustomerNo);
        RecRef.GetTable(RecordVariant);
        OpenSendDialog("IKA WA Entity Type"::Customer, CustomerNo, TempBlob, BuildFileName(FileNamePrefix, DocumentNo), RecRef.RecordId, DocumentNo);
    end;

    procedure SendPurchaseDocument(RecordVariant: Variant; ReportUsage: Enum "Report Selection Usage"; VendorNo: Code[20]; DocumentNo: Code[20]; FileNamePrefix: Text)
    var
        ReportSelections: Record "Report Selections";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
    begin
        ReportSelections.GetPdfReportForVend(TempBlob, ReportUsage, RecordVariant, VendorNo);
        RecRef.GetTable(RecordVariant);
        OpenSendDialog("IKA WA Entity Type"::Vendor, VendorNo, TempBlob, BuildFileName(FileNamePrefix, DocumentNo), RecRef.RecordId, DocumentNo);
    end;

    /// <summary>
    /// Mensaje (plantilla o texto) a una entidad, sin documento.
    /// </summary>
    procedure SendToEntity(EntityType: Enum "IKA WA Entity Type"; EntityNo: Code[20])
    var
        TempBlob: Codeunit "Temp Blob";
        EmptyRecordId: RecordId;
    begin
        OpenSendDialog(EntityType, EntityNo, TempBlob, '', EmptyRecordId, '');
    end;

    local procedure OpenSendDialog(EntityType: Enum "IKA WA Entity Type"; EntityNo: Code[20]; var TempBlob: Codeunit "Temp Blob"; FileName: Text; SourceRecordId: RecordId; DocumentNo: Code[20])
    var
        WASend: Page "IKA WA Send";
    begin
        WASend.SetContext(EntityType, EntityNo, PhoneMgt.GetEntityPhone(EntityType, EntityNo), TempBlob, FileName, SourceRecordId, DocumentNo);
        WASend.RunModal();
    end;

    local procedure BuildFileName(Prefix: Text; DocumentNo: Code[20]): Text
    begin
        exit(DelChr(Prefix + ' ' + DocumentNo, '=', '\/:*?"<>|') + '.pdf');
    end;

    /// <summary>
    /// Valores de las variables {{1}}, {{2}}... de la plantilla según su configuración para la tabla
    /// del documento (o la configuración genérica, con Id tabla 0).
    /// </summary>
    procedure GetParameterValues(WATemplate: Record "IKA WA Template"; SourceRecordId: RecordId; RecipientName: Text): List of [Text]
    var
        TemplateParam: Record "IKA WA Template Param";
        CompanyInformation: Record "Company Information";
        RecRef: RecordRef;
        FieldRef: FieldRef;
        Values: List of [Text];
        Value: Text;
        HasRecord: Boolean;
        i: Integer;
    begin
        if SourceRecordId.TableNo <> 0 then
            HasRecord := RecRef.Get(SourceRecordId);
        for i := 1 to WATemplate."No. of Body Parameters" do begin
            Value := '';
            if FindParam(WATemplate, SourceRecordId.TableNo, i, TemplateParam) then
                case TemplateParam.Source of
                    TemplateParam.Source::Constant:
                        Value := TemplateParam."Constant Value";
                    TemplateParam.Source::"Company Name":
                        begin
                            CompanyInformation.Get();
                            Value := CompanyInformation.Name;
                        end;
                    TemplateParam.Source::"Recipient Name":
                        Value := RecipientName;
                    TemplateParam.Source::Field:
                        if HasRecord and (TemplateParam."Field No." <> 0) then begin
                            FieldRef := RecRef.Field(TemplateParam."Field No.");
                            if FieldRef.Class = FieldClass::FlowField then
                                FieldRef.CalcField();
                            Value := Format(FieldRef.Value);
                        end;
                end;
            Values.Add(Value);
        end;
        exit(Values);
    end;

    local procedure FindParam(WATemplate: Record "IKA WA Template"; TableId: Integer; ParameterNo: Integer; var TemplateParam: Record "IKA WA Template Param"): Boolean
    begin
        if TemplateParam.Get(WATemplate."Account Code", WATemplate.Name, WATemplate."Language Code", TableId, ParameterNo) then
            exit(true);
        exit(TemplateParam.Get(WATemplate."Account Code", WATemplate.Name, WATemplate."Language Code", 0, ParameterNo));
    end;
}
