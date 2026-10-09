# Ikaslan Agents (Claude)

Extensión AL para Business Central 28 que reúne en una sola app dos agentes que leen documentos con Claude:

| Agente | Origen | Resultado |
|---|---|---|
| **Pedidos de venta** (antes AGENTEAK 2) | Emails de clientes (cuerpo + PDF/imagen/Excel adjunto) | Solicitud en la bandeja → pedido de venta (manual o automático), con el PDF adjunto |
| **Albaranes de compra** (antes AGENTEAK 3) | Emails de proveedores y/o carpeta de SharePoint/OneDrive | Albarán conciliado con los pedidos de compra abiertos → *Cant. a recibir* y *Nº albarán proveedor* (y, opcionalmente, recepción registrada) |

## Qué es común

- **Configuración** (`IKA Sales Agent Setup`, página 99001): Claude (API key, modelo, esfuerzo...), credenciales
  generales de Microsoft Graph y un apartado para cada agente (buzón, carpetas, límites, automatismos, cola de proyectos).
- **Cuentas de Outlook 365**: las mismas cuentas sirven para los dos agentes; cada agente elige la suya
  (pueden ser la misma). Una cuenta con *Credenciales propias* usa su Tenant Id / Client Id / secreto; las demás,
  las credenciales generales de la configuración.
- **Filtros de correo** (página 99006): una sola lista con *Tipo de documento* = Pedido de venta / Albarán de compra.
  Cada filtro combina los dos modelos:
  - **Instrucciones** en texto libre (botón *…* para editarlas en una ventana).
  - **Plantilla**: tipo de código de artículo, documento valorado y un **ejemplo validado** (la extracción de un
    documento ya revisado, que se guarda con *Usar como ejemplo del filtro* desde la solicitud o el albarán).
  - Cliente o proveedor asociado, filtro de remitente, de asunto y (albaranes de carpeta) de nombre de fichero.
  - Un filtro sin remitente y con asunto `*albar*` acepta albaranes de cualquier remitente.
- **Alias de campos** (página 99116): cómo llama cada cliente o proveedor a los campos ("Su pedido", "F. Entrega"...),
  globales o por cliente/proveedor.
- **Instrucciones en la ficha del cliente** (apartado *Agente de ventas (Claude)*).
- Menú en el Role Center *Business Manager*: *Agente de pedidos*, *Agente de albaranes* y *Configuración agentes*.

## Instalación sobre AGENTEAK 2

La app conserva el **id de AGENTEAK 2** (`626ece17-…`) y sube a la versión **2.0.0.0**, con los rangos 99001–99200.
Al publicarla sobre AGENTEAK 2 se actualiza: se mantienen solicitudes, filtros (pasan a tipo *Pedido de venta*),
cuentas, API key de Claude y secretos de Graph. El codeunit de actualización 99061 da sus valores por defecto a los
campos nuevos de albaranes; si se publica en modo desarrollo y algún campo de albaranes aparece a 0 (p.ej. *Máx.
documentos por ejecución*), basta con rellenarlo en la configuración.

- A partir de aquí **no se debe volver a publicar el proyecto AGENTEAK 2** (versión 1.x) en ese entorno.
- **No se puede tener instalado a la vez AGENTEAK 3**: los objetos de albaranes tienen los mismos IDs y nombres.

## Colas de proyectos

| Agente | Codeunit |
|---|---|
| Pedidos de venta | 99051 `IKA Sales Agent Job` |
| Albaranes | 99156 `IKA DN Job` |

Cada uno se activa por separado (*Agente de pedidos activado* / *Agente de albaranes activado*) y tiene su intervalo.

## Permisos de Entra ID

- Correo: `Mail.ReadWrite` (permiso de aplicación, con consentimiento de administrador). Se puede limitar a los
  buzones de pedidos y albaranes con RBAC for Applications / Application Access Policy de Exchange.
- Carpeta de SharePoint (solo albaranes): `Sites.Selected` concediendo acceso al sitio de compras.
