// Se ejecuta al cargar el add-in: construye la interfaz y avisa a AL.
IkaMailExplorer.init();
Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlReady', []);
