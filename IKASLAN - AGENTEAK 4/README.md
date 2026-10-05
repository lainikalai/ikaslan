# Ikaslan Outlook Mail Workspace

Extensión AL para Business Central 28 que trae el correo de **Outlook 365** a BC con Microsoft Graph:

- **Cuentas de Outlook 365**: la del propio usuario (*Añadir mi cuenta*), buzones compartidos o cuentas de
  otro tenant con credenciales propias. Cada usuario ve las cuentas compartidas y las suyas.
- **Bandeja de correo**: listado de emails (no leídos en negrita), sincronización, *Cargar anteriores*,
  vistas *No leídos*, *Con adjuntos* y *Con adjuntos sin vincular*.
- **Ficha del email**: cabecera, cuerpo HTML (con imágenes incrustadas), adjuntos, descarga del email en
  `.eml`, *Abrir en Outlook* y **Responder / Responder a todos / Reenviar** (con ficheros añadidos).
- **Adjuntar a entidades de BC** (cliente, proveedor, contacto, banco, recurso, producto, empleado, activo
  fijo, proyecto) **arrastrando** el email completo o sus adjuntos sobre una zona de destino.

> ⚠️ Código generado sin compilar. `AL: Download Symbols` + `Ctrl+Shift+B` y corregir lo que indique el compilador.

## Cómo funciona el drag & drop

El cliente web de BC **no permite arrastrar entre dos páginas distintas**, por ejemplo del email a una ficha de
cliente abierta en otra pestaña: cada página es independiente y AL no tiene un evento "soltar" entre páginas.
Por eso el origen y los destinos están **en la misma página**, dentro de un *control add-in*
(`IKA Mail Workspace`, HTML/JavaScript), donde el drag & drop es el nativo del navegador:

```
┌──────────────── Ficha del email ─────────────────────────────────────────────┐
│ De / Asunto / Fecha / Para / CC               Destino: [Cliente ▼] [10000 …]  │
├───────────────────────────────────────────────┬──────────────────────────────┤
│  Cuerpo del email (iframe aislado, sin JS)    │  ADJUNTAR A…                 │
│                                               │ ┌──────────────────────────┐ │
│                                               │ │ SELECCIONADO  📌 ↗       │ │
│                                               │ │ Cliente 10000            │ │
│                                               │ │ Adatum Corporation       │ │
│                                               │ └──────────────────────────┘ │
│                                               │ ┌──────────────────────────┐ │
├───────────────────────────────────────────────┤ │ SUGERIDO (por remitente) │ │
│ EMAIL Y ADJUNTOS — arrastre a un destino      │ │ Proveedor 30000          │ │
│ [✉ 20261005 Pedido.eml] [📎 oferta.pdf 210 KB]│ └──────────────────────────┘ │
│ [📎 tarifa.xlsx ✓ Cliente 10000]               │ ┌──────────────────────────┐ │
│                                               │ │ FIJADO   Banco BBVA      │ │
│                                               │ └──────────────────────────┘ │
└───────────────────────────────────────────────┴──────────────────────────────┘
```

- **Elementos arrastrables**: el email completo (`.eml`, que se abre con Outlook e incluye sus adjuntos) y cada adjunto.
  Los ya vinculados muestran `✓ Cliente 10000`.
- **Zonas de destino**:
  - **Seleccionado**: el tipo y nº elegidos en el grupo *Destino* (con lookup a la entidad).
  - **Sugeridos**: clientes, proveedores y contactos con el email del remitente o, si no hay, del mismo dominio corporativo.
    Al abrir el email, el primero se propone como destino.
  - **Fijados**: entidades que el usuario fija (📌) para tenerlas siempre a mano, p.ej. el banco o el proyecto del día.
- Al soltar, el fichero se guarda en los **adjuntos estándar de BC** (*Document Attachment*): aparece en el FactBox
  *Documentos adjuntos* de la ficha de la entidad. Además queda un registro en *Emails vinculados a entidades*.
- También se pueden **soltar ficheros desde el escritorio** o desde Outlook de escritorio sobre un destino (máx. 10 MB).
- **Sin ratón** (tablet/móvil): tocar un elemento y pulsar *Adjuntar aquí* en el destino. También hay acciones
  *Adjuntar email al destino* y *Adjuntar todos los ficheros al destino*.
- **Al revés**: en las fichas de cliente, proveedor, contacto, banco, recurso, producto, empleado, activo y proyecto
  se añade el FactBox **Emails vinculados**, desde el que se abre el email de origen.

### Seguridad del visor
- El HTML del email se muestra en un `iframe` con `sandbox` **sin scripts**, sin acceso al origen de BC y sin
  referrer. Los enlaces se abren en una pestaña nueva.
- *Bloquear imágenes externas* (activado por defecto) añade una Content-Security-Policy que solo permite imágenes
  incrustadas, para evitar píxeles de seguimiento.

## Objetos (rango 50400–50599, prefijo `IKA Mail`)

| Tipo | ID | Nombre |
|---|---|---|
| Table | 50400 | IKA Mail Setup |
| Table | 50410 | IKA Mail Mailbox (cuentas de Outlook 365) |
| Table | 50420 | IKA Mail Message (caché local del listado + cuerpo) |
| Table | 50430 | IKA Mail Attachment |
| Table | 50440 | IKA Mail Link (email/adjunto → entidad) |
| Table | 50450 | IKA Mail Pinned Target (destinos fijados por usuario) |
| Table | 50460 / 50470 | IKA Mail Drop Target / Compose File (temporales) |
| Enum | 50400–50430 | Entity Type, Compose Mode, Target Kind, Account Type |
| Codeunit | 50400 | IKA Mail Graph Client (sincronizar, detalle, adjuntos, .eml, leído, responder/reenviar) |
| Codeunit | 50410 | IKA Mail Entity Mgt. (todo lo que depende del tipo de entidad) |
| Codeunit | 50420 | IKA Mail Attach Mgt. (adjuntar, vínculos, datos del visor; evento `OnAfterAttach`) |
| Codeunit | 50430 | IKA Mail Json Helper |
| ControlAddIn | — | IKA Mail Workspace (`src/controladdin/MailWorkspace`) |
| Page | 50400 | IKA Mail Setup |
| Page | 50410 | IKA Mail Mailboxes (*Cuentas de Outlook 365*) |
| Page | 50420 | IKA Mail Messages (*Correo Outlook 365*) |
| Page | 50430 | IKA Mail Message (ficha con el área de trabajo) |
| Page | 50440 | IKA Mail Compose (responder / reenviar) |
| Page | 50450 / 50455 | IKA Mail Links / Linked Emails (FactBox) |
| Page | 50470 | IKA Mail Secret Input |
| PageExt | 50400–50408 | FactBox *Emails vinculados* en las fichas de entidad (+ *Documentos adjuntos* en Banco y Contacto) |
| PermissionSet | 50400 | IKA Mail Workspace |

Para añadir otro tipo de entidad: un valor en el enum `IKA Mail Entity Type` y un caso en cada procedimiento de
`IKA Mail Entity Mgt.`. Si su tabla no la soporta *Document Attachment* de serie, añadirla también en el
suscriptor `DocumentAttachmentOnAfterInitFieldsFromRecRef` de `IKA Mail Attach Mgt.`.

## Puesta en marcha

1. Copiar la carpeta a `C:\Users\IAU\Documents\BEZEROAK\IKASLAN\IKASLAN - AGENTEAK 4`, ajustar `publisher`
   en `app.json` y `launch.json`, `Download Symbols`, compilar y publicar (en sandbox: permitir HttpClient).
2. **Entra ID**: registro de aplicación (puede ser el mismo de AGENTEAK 2/3) con permisos **de aplicación**
   `Mail.ReadWrite` y `Mail.Send` + consentimiento de administrador, y un secreto de cliente.
   **Limitar el acceso** a los buzones dados de alta con *RBAC for Applications* de Exchange Online
   (ver README de AGENTEAK 2). Sin esto, la aplicación puede leer cualquier buzón del tenant.
3. *Configuración correo Outlook 365*: Tenant Id, Client Id, *Establecer secreto* y opciones del visor.
4. *Cuentas de Outlook 365*: cada usuario puede usar *Añadir mi cuenta* (toma el email de su usuario de BC) y el
   administrador da de alta los buzones compartidos. Para una cuenta de otro tenant: *Credenciales propias* +
   Tenant Id, Client Id y *Establecer secreto propio*. *Probar conexión* y *Sincronizar*.
5. Asignar el conjunto de permisos **IKA Mail Workspace** a los usuarios.
6. Abrir *Correo Outlook 365* (búsqueda "Correo") → abrir un email → arrastrar.

## Consideraciones

- **Permisos de aplicación frente a delegados**: con permisos de aplicación BC accede al buzón en nombre de la
  aplicación, y es la extensión la que limita qué cuentas ve cada usuario (*Solo para el usuario*). Una mejora
  futura es usar permisos **delegados** (OAuth con el usuario, codeunit `OAuth2`), de modo que cada usuario solo
  pueda acceder a su propio buzón por diseño.
- **Espacio en BC**: los ficheros adjuntados se guardan en la base de datos de BC (capacidad del entorno).
  Los emails solo se guardan como caché del listado y del cuerpo de los emails abiertos.
- **Ficheros al responder**: máx. 3 MB por fichero (límite del endpoint de Graph; para más hace falta una *upload session*).
- **Adjuntos de tipo enlace** (OneDrive/SharePoint) no se pueden descargar ni adjuntar desde BC: se abren en Outlook.

## Unificación con AGENTEAK 2 y 3

Las tres extensiones tienen la **misma estructura de cuentas de Outlook 365** (tabla + página con *Añadir mi cuenta*,
credenciales propias opcionales y *Probar conexión*):

| Extensión | Tabla | Página |
|---|---|---|
| AGENTEAK 2 (pedidos de venta) | 50060 IKA Sales Mail Account | 50080 IKA Sales Mail Accounts |
| AGENTEAK 3 (albaranes) | 50270 IKA DN Mail Account | 50290 IKA DN Mail Accounts |
| AGENTEAK 4 (correo) | 50410 IKA Mail Mailbox | 50410 IKA Mail Mailboxes |

Si se unifican en una única extensión, se deja una sola tabla y página de cuentas (la de AGENTEAK 4, que tiene
además el control de acceso por usuario en la bandeja) y una sola configuración de Graph. Los agentes solo
guardan el **código de cuenta** que usan.
