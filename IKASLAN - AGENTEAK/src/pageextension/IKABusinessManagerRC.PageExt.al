pageextension 99011 "IKA Business Manager RC" extends "Business Manager Role Center"
{
    actions
    {
        addlast(Sections)
        {
            group("IKA Agents")
            {
                Caption = 'Agentes (Claude)';
                ToolTip = 'Configuración de los agentes y bandejas de solicitudes de venta y albaranes de proveedor.';

                action("IKA Sales Agent Setup")
                {
                    ApplicationArea = All;
                    Caption = 'Configuración';
                    RunObject = page "IKA Sales Agent Setup";
                    ToolTip = 'Claude, credenciales de Microsoft Graph, buzones, creación automática de pedidos, conciliación de albaranes y colas de proyectos.';
                }
                action("IKA Sales Requests")
                {
                    ApplicationArea = All;
                    Caption = 'Solicitudes de venta (Claude)';
                    RunObject = page "IKA Sales Requests";
                    ToolTip = 'Bandeja de solicitudes de venta recibidas por email de los clientes.';
                }
                action("IKA DN Documents")
                {
                    ApplicationArea = All;
                    Caption = 'Albaranes de proveedor (Claude)';
                    RunObject = page "IKA DN Documents";
                    ToolTip = 'Bandeja de albaranes de proveedor recibidos por email o carpeta y su conciliación con los pedidos de compra.';
                }
                action("IKA Sales Requests Pending")
                {
                    ApplicationArea = All;
                    Caption = 'Solicitudes pendientes de revisión';
                    RunObject = page "IKA Sales Requests";
                    RunPageView = where(Status = filter("Needs Review" | Ready | Error));
                    ToolTip = 'Solicitudes que requieren revisión, listas para crear o con error.';
                }
                action("IKA DN Documents Pending")
                {
                    ApplicationArea = All;
                    Caption = 'Albaranes pendientes de revisión';
                    RunObject = page "IKA DN Documents";
                    RunPageView = where(Status = filter("Needs Review" | Matched | Error));
                    ToolTip = 'Albaranes que requieren revisión, conciliados pendientes de aplicar o con error.';
                }
                action("IKA Sales Agent Mail Filters")
                {
                    ApplicationArea = All;
                    Caption = 'Filtros de correo';
                    RunObject = page "IKA Sales Agent Mail Filters";
                    ToolTip = 'Remitentes, asuntos, cuerpo y ficheros que se procesan como pedidos o albaranes, con su cliente o proveedor, instrucciones y ejemplo.';
                }
                action("IKA Field Aliases")
                {
                    ApplicationArea = All;
                    Caption = 'Alias de campos';
                    RunObject = page "IKA Field Aliases";
                    ToolTip = 'Cómo aparecen los campos en los documentos de clientes y proveedores.';
                }
                action("IKA Sales Mail Accounts")
                {
                    ApplicationArea = All;
                    Caption = 'Cuentas de Outlook 365';
                    RunObject = page "IKA Sales Mail Accounts";
                    ToolTip = 'Buzones de correo que pueden leer los agentes.';
                }
                action("IKA Claude Cost Comparison")
                {
                    ApplicationArea = All;
                    Caption = 'Costes reales de Claude';
                    RunObject = page "IKA Claude Cost Comparison";
                    ToolTip = 'Coste facturado por Anthropic frente al calculado en BC, por día y modelo.';
                }
                action("IKA Claude Model Prices")
                {
                    ApplicationArea = All;
                    Caption = 'Precios de Claude';
                    RunObject = page "IKA Claude Model Prices";
                    ToolTip = 'Precio por millón de tokens de cada modelo, para calcular el coste de cada llamada.';
                }
                action("IKA Sales Agent Log")
                {
                    ApplicationArea = All;
                    Caption = 'Registro (pedidos)';
                    RunObject = page "IKA Sales Agent Log";
                    ToolTip = 'Registro de llamadas y eventos del agente de pedidos.';
                }
                action("IKA DN Log")
                {
                    ApplicationArea = All;
                    Caption = 'Registro (albaranes)';
                    RunObject = page "IKA DN Log";
                    ToolTip = 'Registro de llamadas y eventos del agente de albaranes.';
                }
            }
        }
    }
}
