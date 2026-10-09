codeunit 99056 "IKA Sales Order Subscribers"
{
    // Mantiene la relación entre los pedidos de venta y las solicitudes del agente.
    // Permisos indirectos: el usuario que borra un pedido puede no tener el conjunto de permisos del agente.
    Permissions = tabledata "IKA Sales Request Header" = rm;

    var
        OrderDeletedLbl: Label 'Se ha eliminado el pedido de venta %1; la solicitud queda pendiente de revisión.', Comment = '%1 = order no.';

    /// <summary>
    /// Al eliminar un pedido de venta creado desde una solicitud, la solicitud vuelve a "Requiere revisión"
    /// y sin nº de pedido, para poder crearlo de nuevo.
    /// No se toca si el pedido se borra al registrarse (Delete sin trigger) o si ya tiene envíos o facturas registrados.
    /// </summary>
    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDeleteSalesHeader(var Rec: Record "Sales Header"; RunTrigger: Boolean)
    var
        RequestHeader: Record "IKA Sales Request Header";
        AgentLog: Record "IKA Sales Agent Log";
        LogMgt: Codeunit "IKA Sales Agent Log Mgt.";
    begin
        if Rec.IsTemporary() or (not RunTrigger) then
            exit;
        if Rec."Document Type" <> Rec."Document Type"::Order then
            exit;

        RequestHeader.SetRange("Sales Order No.", Rec."No.");
        if not RequestHeader.FindSet(true) then
            exit;
        if HasPostedDocuments(Rec."No.") then
            exit;

        repeat
            RequestHeader."Sales Order No." := '';
            RequestHeader.Status := RequestHeader.Status::"Needs Review";
            RequestHeader.AddToErrorMessage(StrSubstNo(OrderDeletedLbl, Rec."No."));
            RequestHeader.Modify();
            if AgentLog.WritePermission() then
                LogMgt.LogWarning(RequestHeader."Entry No.", StrSubstNo(OrderDeletedLbl, Rec."No."));
        until RequestHeader.Next() = 0;
    end;

    local procedure HasPostedDocuments(OrderNo: Code[20]): Boolean
    var
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        if not SalesShipmentHeader.IsEmpty() then
            exit(true);
        SalesInvoiceHeader.SetRange("Order No.", OrderNo);
        exit(not SalesInvoiceHeader.IsEmpty());
    end;
}
