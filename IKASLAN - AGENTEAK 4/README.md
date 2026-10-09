# Ikaslan Outlook Mail Workspace

Extensión AL para Business Central 28 que trae el correo de **Outlook 365** a BC con Microsoft Graph:

- **Cuentas de Outlook 365**: la del propio usuario (*Añadir mi cuenta*), buzones compartidos o cuentas de
  otro tenant con credenciales propias. Cada usuario ve las cuentas compartidas y las suyas.
- **Bandeja de correo**: listado de emails (no leídos en negrita), sincronización, *Cargar anteriores*,
  vistas *No leídos*, *Con adjuntos* y *Con adjuntos sin vincular*.
- **Carpetas de Outlook**: selector con el árbol completo de carpetas (subcarpetas a cualquier nivel, con sus
  no leídos) y *Mover a carpeta* desde la bandeja o la ficha del email.
- **Ficha del email**: cabecera, cuerpo HTML (con imágenes incrustadas), adjuntos, descarga del email en
  `.eml`, *Abrir en Outlook* y **Responder / Responder a todos / Reenviar** (con ficheros añadidos).
- **Adjuntar a entidades de BC** (cliente, proveedor, contacto, banco, recurso, producto, empleado, activo
  fijo, proyecto) **arrastrando** el email completo o sus adjuntos sobre una zona de destino.

> ⚠️ Compilado con el compilador AL 18 (CodeCop, UICop y PerTenantExtensionCop) contra versiones **simuladas**
> de los objetos estándar, no con los símbolos reales de BC 28: hacer `AL: Download Symbols` + `Ctrl+Shift+B` y
> corregir lo que indique el compilador.

## Carpetas

- En *Correo Outlook 365*, **Carpeta...** (`Ctrl+Mayús+F`) muestra el árbol de carpetas de la cuenta, en el orden
  de Outlook (bandeja de entrada, borradores, enviados, eliminados, no deseado, archivo y después el resto por
  nombre) y con sus no leídos. Al elegir una, la bandeja muestra sus emails; la primera vez se descargan solos.
  *Sincronizar* y *Cargar anteriores* trabajan sobre la carpeta que se está viendo.
- **Carpeta por defecto** vuelve a la carpeta con la que se abre la bandeja: el campo *Carpeta* de la cuenta, que
  ahora también se puede elegir del árbol (asistente de búsqueda en *Cuentas de Outlook 365*).
- El árbol se descarga la primera vez que se abre el selector; *Actualizar carpetas* (F5 en el selector) lo vuelve
  a leer si se crean, renombran o borran carpetas en Outlook.
- **Mover a carpeta...** mueve en Outlook los emails seleccionados (o el email abierto en la ficha).
- Se piden a Graph **Id inmutables**, que no cambian al mover un email: un email movido en Outlook se actualiza
  (cambia de carpeta) en lugar de duplicarse. Los emails ya guardados antes de esta versión no tienen carpeta: se
  tratan como de la carpeta por defecto y se actualizan solos al sincronizar.
- *Todas mis cuentas* muestra los emails de todas las carpetas; la columna *Carpeta* (oculta por defecto) indica
  de cuál es cada uno.

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

## Objetos (rango 99201–99300, prefijo `IKA Mail`)

| Tipo | ID | Nombre |
|---|---|---|
| Table | 99201 | IKA Mail Setup |
| Table | 99206 | IKA Mail Mailbox (cuentas de Outlook 365) |
| Table | 99211 | IKA Mail Message (caché local del listado + cuerpo) |
| Table | 99216 | IKA Mail Attachment |
| Table | 99221 | IKA Mail Link (email/adjunto → entidad) |
| Table | 99226 | IKA Mail Pinned Target (destinos fijados por usuario) |
| Table | 99231 / 99236 | IKA Mail Drop Target / Compose File (temporales) |
| Table | 99241 | IKA Mail Folder (árbol de carpetas de Outlook de cada cuenta) |
| Enum | 99201–99216 | Entity Type, Compose Mode, Target Kind, Account Type |
| Codeunit | 99201 | IKA Mail Graph Client (sincronizar, carpetas, mover, detalle, adjuntos, .eml, leído, responder/reenviar) |
| Codeunit | 99206 | IKA Mail Entity Mgt. (todo lo que depende del tipo de entidad) |
| Codeunit | 99211 | IKA Mail Attach Mgt. (adjuntar, vínculos, datos del visor; evento `OnAfterAttach`) |
| Codeunit | 99216 | IKA Mail Json Helper |
| ControlAddIn | — | IKA Mail Workspace (`src/controladdin/MailWorkspace`) |
| Page | 99201 | IKA Mail Setup |
| Page | 99206 | IKA Mail Mailboxes (*Cuentas de Outlook 365*) |
| Page | 99211 | IKA Mail Messages (*Correo Outlook 365*) |
| Page | 99216 | IKA Mail Message (ficha con el área de trabajo) |
| Page | 99221 | IKA Mail Compose (responder / reenviar) |
| Page | 99226 / 99231 | IKA Mail Links / Linked Emails (FactBox) |
| Page | 99236 | IKA Mail Secret Input |
| Page | 99241 | IKA Mail Folders (selector de carpetas en árbol) |
| PageExt | 99246 | Área de trabajo *Gerente de empresa*: sección **Correo Outlook 365** en el menú (bandeja, no leídos, con adjuntos sin vincular, vínculos, cuentas, configuración) y acceso a la bandeja |
| PageExt | 99201–99241 | FactBox *Emails vinculados* en las fichas de entidad (+ *Documentos adjuntos* en Banco y Contacto) |
| PermissionSet | 99201 | IKA Mail Workspace |

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
6. Abrir *Correo Outlook 365* desde el menú **Correo Outlook 365** del Área de trabajo *Gerente de empresa*
   (o con la búsqueda "Correo") → abrir un email → arrastrar.

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
| AGENTEAK 2 (pedidos de venta) | 99031 IKA Sales Mail Account | 99041 IKA Sales Mail Accounts |
| AGENTEAK 3 (albaranes) | 99136 IKA DN Mail Account | 99151 IKA DN Mail Accounts |
| AGENTEAK 4 (correo) | 99206 IKA Mail Mailbox | 99206 IKA Mail Mailboxes |

Si se unifican en una única extensión, se deja una sola tabla y página de cuentas (la de AGENTEAK 4, que tiene
además el control de acceso por usuario en la bandeja) y una sola configuración de Graph. Los agentes solo
guardan el **código de cuenta** que usan.
