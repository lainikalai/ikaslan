# Ikaslan WhatsApp Connector

Extensión AL para Business Central 28 que integra **WhatsApp Business (Cloud API de Meta)**:

- **Enviar desde BC** facturas, pedidos, albaranes, ofertas y pedidos de compra en PDF, mensajes con
  **plantillas aprobadas** (con variables rellenadas desde los campos del documento) y texto libre.
- **Recibir** los mensajes de clientes y proveedores mediante una **Azure Function** (incluida) que entrega
  cada mensaje a una página API de BC.
- **Chat dentro de BC** (control add-in): burbujas, ✓✓ de entregado/leído, imágenes, respuestas rápidas, Intro
  para enviar. Bandeja a dos paneles (lista + chat) y pila de actividades en el Área de trabajo.
- **Clientes, proveedores, contactos y comerciales**: vinculación automática por teléfono; cada conversación tiene
  su **comercial asignado** (*Mis conversaciones*) y se le puede avisar por WhatsApp con *Avisar al comercial*.
- Descarga de las fotos/PDF/audios recibidos y adjuntarlos a la ficha.
- **Sin API**: botón *Abrir en mi WhatsApp* (enlace `wa.me`) en fichas, conversaciones y diálogo de envío.

> ⚠️ Compilado con el compilador AL 18 (CodeCop, UICop y PerTenantExtensionCop) contra versiones **simuladas**
> de los objetos estándar (Customer, Vendor, Temp Blob...), no con los símbolos reales de BC 28: hacer
> `AL: Download Symbols` + `Ctrl+Shift+B` y corregir lo que indique el compilador. La Azure Function tiene
> pruebas (`npm test`) de la normalización y de la firma.

## Arquitectura

```
                    ENVÍO                                         RECEPCIÓN
BC ── HttpClient ──► graph.facebook.com          Cliente ──► Meta ──► Azure Function ──► API de BC
   /{phone-id}/messages (texto, plantilla, doc)                      (firma + normaliza)   inboundEvents
   /{phone-id}/media (sube el PDF)                                                         │
                                                                                           ▼
                                               Cola de proyectos / al abrir la bandeja: "IKA WA Inbound Processor"
                                               → conversaciones + mensajes + estados (entregado/leído/error)
                                               → descarga de ficheros → vincular por teléfono
```

¿Por qué una Azure Function? Meta entrega los mensajes por **webhook**, que exige responder a una verificación
(`hub.challenge`) y comprobar la firma `X-Hub-Signature-256`. BC no puede exponer un endpoint así, pero sí
una **página API**. La función, unas 200 líneas, hace de puente. En el plan de consumo de Azure su coste es
prácticamente nulo para estos volúmenes.

## Interfaz: chat y bandeja

- **Bandeja *WhatsApp*** (`IKA WA Conversations`): lista de conversaciones (no leídas en negrita) y, en el panel
  de FactBox, el **chat** de la seleccionada: se puede leer y contestar sin abrir nada. Al seleccionar una
  conversación se marcan sus mensajes como leídos (y el cliente ve el doble check azul, si está configurado).
- **Ficha de la conversación**: el mismo chat a pantalla completa, con la entidad vinculada, la ventana de 24 h y
  el comercial. La lista clásica de mensajes sigue disponible (*Detalle de mensajes*, oculta: personalizar la página).
- **Chat** (control add-in `IKA WA Chat`, `src/controladdin/WhatsAppChat`):
  - Intro envía, Mayús+Intro hace salto de línea; 📎 envía un fichero con el texto escrito como pie.
  - ✓ enviado, ✓✓ entregado, ✓✓ azul leído, ⚠ error (con el mensaje de Meta).
  - Imágenes bajo demanda (*Ver imagen*), descarga de ficheros y *Adjuntar a la ficha*.
  - **Respuestas rápidas**: botones encima de la caja de texto. Variables `{nombre}`, `{comercial}`, `{usuario}`.
  - Con la ventana de 24 h cerrada, la caja de texto se sustituye por *Enviar plantilla*.
  - Se actualiza solo cada 15 s mientras está visible (procesa los eventos pendientes y vuelve a pintar solo si
    algo ha cambiado). Muestra los últimos 200 mensajes.
- **Pila de actividades** (`IKA WA Activities`) en las Áreas de trabajo *Gerente de empresa*, *Procesador de
  pedidos* y *Agente de compras*: *Mis no leídas*, *No leídas*, *Ventana cierra en < 4 h* y *Sin vincular*.
  Cada cifra abre la bandeja ya filtrada.

La ficha de la conversación no es editable: la vinculación (*Vincular > Cliente / Proveedor / Contacto /
Vendedor/comprador / Buscar por teléfono*) y el comercial (*Asignar comercial*) se cambian con acciones. Así no
choca con los cambios que hace el chat en la misma conversación (no leídos, último mensaje).

## Comerciales

- El tipo de entidad **Vendedor/comprador** permite chatear con los comerciales de la empresa (teléfono de la
  ficha *Vendedor/Comprador*). La ficha tiene el FactBox, *Enviar WhatsApp*, *Abrir en mi WhatsApp* y
  *Conversaciones asignadas*.
- **Comercial asignado** de cada conversación: al vincularla se toma el *Cód. vendedor* del cliente o contacto o
  el *Cód. comprador* del proveedor. Se puede cambiar con *Asignar comercial*.
- ***Mis conversaciones***: filtra la bandeja por el vendedor/comprador del usuario (*Configuración usuarios*,
  campo *Cód. vendedor/comprador*). Con *Abrir con "Mis conversaciones"* en la configuración, la bandeja se abre
  ya filtrada.
- ***Avisar al comercial***: le envía por WhatsApp *"WhatsApp de <cliente> (+34...): <último mensaje>"*. Si el
  comercial no ha escrito al número de la empresa en las últimas 24 h, WhatsApp exige una plantilla: se abre el
  diálogo de envío (conviene tener una plantilla *utility* tipo `aviso_comercial` con `{{1}}` = texto).
- Para conversaciones creadas antes de esta versión: *Configuración WhatsApp > Asignar comerciales a las conversaciones*.

## Reglas de WhatsApp que la extensión respeta

| Situación | Qué se puede enviar |
|---|---|
| El cliente ha escrito en las **últimas 24 h** (ventana abierta) | Texto libre, PDF, imágenes y también plantillas |
| Ventana cerrada, o el cliente nunca ha escrito | **Solo plantillas aprobadas por Meta** |

- La ventana se muestra en cada conversación y en el diálogo de envío. Si está cerrada, el diálogo obliga a usar plantilla.
- **Coste**: Meta cobra por mensaje de plantilla según su categoría (*utility*, *marketing*, *authentication*) y el país.
  Las respuestas dentro de la ventana suelen ser gratuitas. **Revise la tarifa vigente de Meta**, porque ha cambiado varias veces.
- **Consentimiento (opt-in)**: hace falta permiso del cliente para escribirle por WhatsApp (también por RGPD).
- **IA**: Meta restringe en la API los *chatbots de IA de propósito general*. El punto de extensión
  `OnAfterInboundMessage` permite conectar el agente de pedidos con Claude (AGENTEAK 2), con revisión humana.
  Revise la política vigente de Meta antes de responder automáticamente con IA.

## Plantillas y variables

Las plantillas se crean en **WhatsApp Manager** (Meta) y se traen a BC con *Sincronizar plantillas*. Ejemplo de
plantilla `factura_emitida`, categoría *Utility*, idioma `es`, **cabecera de tipo Documento**:

> Hola {{1}}, le enviamos la factura {{2}} por importe de {{3}} €. Gracias por su confianza.

Con *Variables* se indica de dónde sale cada `{{n}}` según el documento desde el que se envía:

| Tabla | Variable | Origen | Campo |
|---|---|---|---|
| 112 Hist. cab. factura venta | 1 | Nombre del destinatario | |
| 112 | 2 | Campo del documento | 3 "Nº" |
| 112 | 3 | Campo del documento | 61 "Importe IVA incl." |

Con `Id tabla = 0` la variable vale para cualquier documento. En el diálogo de envío los valores se pueden revisar
y corregir antes de enviar. El PDF sale del informe configurado en **Selección de informes** (el mismo que se
usa para enviar por email).

## Objetos (rango 99301–99400, prefijo `IKA WA`)

| Tipo | ID | Nombre |
|---|---|---|
| Table | 99301 | IKA WA Setup |
| Table | 99306 | IKA WA Account (número de WhatsApp Business; token en Isolated Storage) |
| Table | 99311 / 99316 | IKA WA Template / Template Param |
| Table | 99321 | IKA WA Conversation (ventana de 24 h, entidad vinculada) |
| Table | 99326 | IKA WA Message (enviados y recibidos, estado, fichero) |
| Table | 99331 | IKA WA Inbound Event (cola de entrada de la API) |
| Table | 99336 | IKA WA Quick Reply (respuestas rápidas del chat) |
| Table | 99341 | IKA WA Cue (pila de actividades) |
| Enum | 99301–99336 | Direction, Message Status, Message Type, Entity Type (cliente, proveedor, contacto, vendedor/comprador), Template Status, Header Type, Param Source, Event Kind |
| Codeunit | 99301 | IKA WA Cloud API (texto, ficheros, plantillas, media, leído, sincronizar plantillas) |
| Codeunit | 99306 | IKA WA Inbound Processor (cola → mensajes; evento `OnAfterInboundMessage`) |
| Codeunit | 99311 | IKA WA Media Downloader |
| Codeunit | 99316 | IKA WA Phone Mgt. (normalizar teléfonos, buscar entidad, `wa.me`, adjuntar) |
| Codeunit | 99321 | IKA WA Document Sender (PDF con Selección de informes + variables) |
| Codeunit | 99326 | IKA WA Json Helper |
| Codeunit | 99331 | IKA WA Job (cola de proyectos) |
| Codeunit | 99336 | IKA WA Chat Mgt. (datos y acciones del chat, vinculación, comercial) |
| Page | 99301 / 99306 | IKA WA Setup / Accounts |
| Page | 99311 / 99316 | IKA WA Templates / Template Params |
| Page | 99321 / 99326 | IKA WA Conversations / Entity Conversations (FactBox) |
| Page | 99331 / 99336 | IKA WA Conversation / Messages Part |
| Page | 99341 | IKA WA Send (diálogo de envío) |
| Page | 99346 | IKA WA Inbound Events |
| Page | 99351 | IKA WA Secret Input |
| Page (API) | 99356 | IKA WA Inbound API — `api/ikaslan/whatsapp/v1.0/inboundEvents` |
| Page | 99361 | IKA WA Quick Replies |
| Page | 99366 | IKA WA Activities (pila para Áreas de trabajo) |
| Page | 99371 | IKA WA Chat Part (chat; en la ficha y como FactBox de la bandeja) |
| ControlAddIn | — | IKA WA Chat (`src/controladdin/WhatsAppChat`) |
| PageExt | 99301–99311 | Ficha cliente, proveedor, contacto: FactBox + *Enviar WhatsApp* + *Abrir en mi WhatsApp* |
| PageExt | 99316–99336 | *Enviar por WhatsApp* en Hist. factura venta, Pedido venta, Hist. albarán venta, Oferta venta, Pedido compra |
| PageExt | 99341 | Ficha vendedor/comprador: FactBox + *Enviar WhatsApp* + *Abrir en mi WhatsApp* + *Conversaciones asignadas* |
| PageExt | 99346–99356 | Pila de WhatsApp en las Áreas de trabajo Gerente de empresa, Procesador de pedidos y Agente de compras |
| PermissionSet | 99301 | IKA WA User (usuarios) |
| PermissionSet | 99306 | IKA WA Inbound (solo para la aplicación de la Azure Function) |
| Azure Function | — | `azure-function/` (Node.js 20+, Azure Functions v4) |

## Puesta en marcha

### 1. Meta (WhatsApp Business Platform)
1. Cuenta de **Meta Business** verificada (Business Manager).
2. En **developers.facebook.com** crear una app de tipo *Business* y añadir el producto **WhatsApp**.
3. Dar de alta el **número de teléfono** de la empresa (un número dedicado es lo más sencillo) y que Meta apruebe el nombre visible.
4. Anotar el **Phone Number ID** y el **WhatsApp Business Account ID** (WhatsApp > API Setup).
5. En Business Manager crear un **usuario del sistema**, asignarle la app y la cuenta de WhatsApp, y generar un
   **token permanente** con permisos `whatsapp_business_messaging` y `whatsapp_business_management`.
6. Crear las **plantillas** en WhatsApp Manager y esperar a que estén aprobadas.

### 2. Business Central
1. Copiar la carpeta a `C:\Users\IAU\Documents\BEZEROAK\IKASLAN\IKASLAN - AGENTEAK 5`, ajustar `publisher`,
   `launch.json`, `Download Symbols`, compilar y publicar (en sandbox: permitir HttpClient).
2. *Cuentas de WhatsApp Business*: código, número visible, Phone Number ID, Business Account ID →
   *Establecer token* → *Probar conexión* → *Sincronizar plantillas*.
3. *Configuración WhatsApp*: cuenta por defecto y prefijo de país (34).
4. *Plantillas* → *Variables* para cada plantilla y documento.
5. Asignar el conjunto de permisos **IKA WA User**.
6. Comerciales: teléfono móvil en cada ficha *Vendedor/Comprador* y, en *Configuración usuarios*, el
   *Cód. vendedor/comprador* de cada usuario (para *Mis conversaciones*).
7. *Respuestas rápidas*: crear las habituales (p.ej. `Hola {nombre}, gracias por escribirnos.`).
8. Probar: en una factura registrada, *Enviar por WhatsApp*; y abrir *WhatsApp* (bandeja) para ver el chat.

### 3. Recepción (Azure Function)
1. **Entra ID**: nuevo registro de aplicación para la API de BC, con permiso de aplicación
   *Dynamics 365 Business Central > API.ReadWrite.All* (consentimiento de administrador) y un secreto.
2. En BC, página **Aplicaciones de Microsoft Entra**: dar de alta ese Client Id, estado *Habilitado*, y asignarle
   **solo** el conjunto de permisos **IKA WA Inbound**.
3. Obtener el **Id de la empresa**: `GET https://api.businesscentral.dynamics.com/v2.0/{tenant}/{entorno}/api/v2.0/companies`.
4. Desplegar `azure-function/` en una Function App (Node 20, plan de consumo) desde VS Code (extensión Azure Functions)
   y configurar en *Configuración de la aplicación* las variables de `local.settings.sample.json`.
   El **App Secret** está en Meta: *App settings > Basic*.
5. En Meta: *WhatsApp > Configuration > Webhook*: URL `https://<function-app>.azurewebsites.net/api/whatsapp`,
   *Verify token* = `WA_VERIFY_TOKEN`, y suscribirse al campo **messages**.
6. En BC: *Crear entrada de cola de proyectos* (cada 2 min). La bandeja también procesa lo pendiente al abrirse.
7. Escribir al número desde un móvil y comprobar *Eventos recibidos* y *WhatsApp* (conversaciones).

> BC **on-premises**: la URL de la API es `https://<servidor>:<puerto>/<instancia>/api/ikaslan/whatsapp/v1.0/...`,
> y hay que exponerla de forma segura (o usar la Function para dejar los eventos en una cola que BC consulte).

Pruebas locales de la función: `cd azure-function && npm install && npm test`.

## Siguientes pasos posibles

- **Pedidos por WhatsApp**: suscribirse a `OnAfterInboundMessage` y crear una solicitud en la bandeja del agente de
  ventas (AGENTEAK 2), para que Claude extraiga cliente, productos y cantidades del texto o de la foto.
- **Envío masivo** de recordatorios de cobro (plantilla *utility*) desde *Movs. clientes* vencidos.
- **Acciones desde el chat**: crear oferta o pedido para el cliente vinculado, enviar su última factura o
  albarán, registrar la conversación como interacción del contacto.
- **Cuentas comunes**: si se unifican AGENTEAK 2–5, la cuenta de WhatsApp sigue el mismo patrón que las cuentas de
  Outlook 365 (código + credencial en Isolated Storage + acceso por usuario + probar conexión).
