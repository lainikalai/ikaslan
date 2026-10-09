codeunit 99041 "IKA Sales Req. Process"
{
    // Procesa UNA solicitud: extracción con Claude -> resolución en BC -> (opcional) creación del pedido.
    // Se ejecuta con Codeunit.Run para que un error en una solicitud no pare el resto.
    TableNo = "IKA Sales Request Header";

    trigger OnRun()
    begin
        ProcessRequest(Rec);
    end;

    var
        AutoCreate: Boolean;
        ForceExtraction: Boolean;

    procedure SetAutoCreate(NewAutoCreate: Boolean)
    begin
        AutoCreate := NewAutoCreate;
    end;

    procedure SetForceExtraction(NewForceExtraction: Boolean)
    begin
        ForceExtraction := NewForceExtraction;
    end;

    local procedure ProcessRequest(var RequestHeader: Record "IKA Sales Request Header")
    var
        Setup: Record "IKA Sales Agent Setup";
        SiblingRequestHeader: Record "IKA Sales Request Header";
        Extraction: Codeunit "IKA Sales Req. Extraction";
        Resolver: Codeunit "IKA Sales Req. Resolver";
    begin
        Setup.GetSetup();

        if ForceExtraction or (RequestHeader.Status in [RequestHeader.Status::New, RequestHeader.Status::Error]) then
            Extraction.ExtractWithClaude(RequestHeader);

        Resolver.ResolveRequest(RequestHeader);
        TryAutoCreate(RequestHeader, Setup);

        // Pedidos adicionales encontrados en el mismo email
        SiblingRequestHeader.SetRange("Parent Entry No.", RequestHeader."Entry No.");
        SiblingRequestHeader.SetRange(Status, SiblingRequestHeader.Status::Extracted);
        if SiblingRequestHeader.FindSet(true) then
            repeat
                Resolver.ResolveRequest(SiblingRequestHeader);
                TryAutoCreate(SiblingRequestHeader, Setup);
            until SiblingRequestHeader.Next() = 0;
    end;

    local procedure TryAutoCreate(var RequestHeader: Record "IKA Sales Request Header"; Setup: Record "IKA Sales Agent Setup")
    var
        SalesOrderCreator: Codeunit "IKA Sales Order Creator";
    begin
        if not (AutoCreate and Setup."Auto Create Orders") then
            exit;
        if RequestHeader.Status <> RequestHeader.Status::Ready then
            exit;
        SalesOrderCreator.CreateSalesOrder(RequestHeader);
    end;
}
