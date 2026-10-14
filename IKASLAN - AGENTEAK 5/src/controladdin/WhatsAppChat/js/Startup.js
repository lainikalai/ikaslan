// Arranque del control: construye la interfaz y avisa a BC de que está listo.
IkaWaChat.init(document.getElementById('controlAddIn'));
Microsoft.Dynamics.NAV.InvokeExtensibilityMethod('ControlReady', []);
