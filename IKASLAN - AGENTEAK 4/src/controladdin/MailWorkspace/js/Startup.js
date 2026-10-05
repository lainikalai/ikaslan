// Se ejecuta al cargar el add-in: construye la interfaz y avisa a AL.
IkaMail.init();
Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlReady', []);
