codeunit 99146 "IKA DN Process"
{
    // Procesa UN documento: extracción con Claude -> conciliación con pedidos ->
    // (opcional) aplicación a pedidos y registro de la recepción.
    // Se ejecuta con Codeunit.Run para que un error no detenga el resto.
    TableNo = "IKA DN Document";

    trigger OnRun()
    begin
        ProcessDocument(Rec);
    end;

    var
        AutoApply: Boolean;
        ForceExtraction: Boolean;

    procedure SetAutoApply(NewAutoApply: Boolean)
    begin
        AutoApply := NewAutoApply;
    end;

    procedure SetForceExtraction(NewForceExtraction: Boolean)
    begin
        ForceExtraction := NewForceExtraction;
    end;

    local procedure ProcessDocument(var DNDocument: Record "IKA DN Document")
    var
        Setup: Record "IKA DN Setup";
        SiblingDocument: Record "IKA DN Document";
        Extraction: Codeunit "IKA DN Extraction";
        POMatcher: Codeunit "IKA DN PO Matcher";
    begin
        Setup.GetSetup();
        if ForceExtraction or (DNDocument.Status in [DNDocument.Status::New, DNDocument.Status::Error]) then
            Extraction.ExtractWithClaude(DNDocument);

        POMatcher.MatchDocument(DNDocument);
        TryAutoApply(DNDocument, Setup);

        SiblingDocument.SetRange("Parent Entry No.", DNDocument."Entry No.");
        SiblingDocument.SetRange(Status, SiblingDocument.Status::Extracted);
        if SiblingDocument.FindSet(true) then
            repeat
                POMatcher.MatchDocument(SiblingDocument);
                TryAutoApply(SiblingDocument, Setup);
            until SiblingDocument.Next() = 0;
    end;

    local procedure TryAutoApply(var DNDocument: Record "IKA DN Document"; Setup: Record "IKA DN Setup")
    var
        ReceiptApplier: Codeunit "IKA DN Receipt Applier";
    begin
        if not (AutoApply and Setup."Auto Apply to Orders") then
            exit;
        if DNDocument.Status <> DNDocument.Status::Matched then
            exit;
        ReceiptApplier.ApplyToOrders(DNDocument);
        if Setup."Auto Post Receipt" then
            ReceiptApplier.PostReceipts(DNDocument);
    end;
}
