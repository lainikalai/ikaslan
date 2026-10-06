permissionset 99306 "IKA WA Inbound"
{
    // Para el registro de aplicación que usa la Azure Function: solo puede insertar eventos
    // en la cola de entrada a través de la página API.
    Caption = 'WhatsApp - API de entrada';
    Assignable = true;

    Permissions =
        tabledata "IKA WA Inbound Event" = RI,
        table "IKA WA Inbound Event" = X,
        page "IKA WA Inbound API" = X;
}
