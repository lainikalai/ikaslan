# Ikaslan Sales Agent (Claude)

Extensión AL para Business Central 28 que hace de "agente de ventas" con Claude en lugar de Copilot:
lee pedidos que llegan por email a un buzón de Outlook, Claude extrae los datos (del cuerpo o de los
adjuntos) y BC crea el pedido de venta validando los campos estándar, de modo que **precios y
descuentos los calcula BC**.

> ⚠️ Código generado sin compilar. Antes de usarlo: `AL: Download Symbols` + `Ctrl+Shift+B`
> y corregir lo que indique el compilador (nombres de métodos de la System App que cambien entre versiones, etc.).

## Idea clave: Claude extrae, Business Central decide

```
Outlook (Graph) ──► Bandeja de solicitudes ──► Claude (extracción JSON) ──► Resolución en AL ──► Pedido de venta
   filtros de             (tabla intermedia,        structured outputs:          cliente, envío,        Validate()
   remitente/asunto        revisión manual)         esquema fijo de pedido       productos, UdM          → precios BC
```

1. **Importación** (`IKA Graph Mail Client`): una entrada de la cola de proyectos lee el buzón cada X
   minutos con Microsoft Graph. Solo se importan los emails que cumplen algún **filtro de correo**
   (remitente/asunto con comodines `*`/`?`); el resto no se toca. Duplicados por *Internet Message-ID*.
2. **Extracción** (`IKA Claude API Client`): se envía a la Messages API de Anthropic:
   - cuerpo del email como texto;
   - **PDF** e **imágenes** en base64 (Claude los lee de forma nativa);
   - **Excel** (xlsx) convertido a CSV con `Excel Buffer`; CSV/TXT como texto.

   Se usa **structured outputs** (`output_config.format` con `json_schema`), así que la respuesta es
   siempre un JSON válido con `orders[] → lines[]`, `confidence` y `warnings`.
   (No se usa `tool_choice` forzado: los modelos actuales Opus 5.5 / Sonnet 5.5 lo rechazan.)
3. **Resolución** (`IKA Sales Req. Resolver`), determinista y auditable, sin IA:
   - **Cliente**: cliente fijado en el filtro de correo → nº cliente → NIF → email → dominio del remitente → nombre.
   - **Dirección de envío**: por C.P. + dirección, o por nombre.
   - **Producto**: *Item Reference* de tipo Cliente → nº de producto → otras referencias (EAN) → descripción.
   - **Unidad de medida**: por código o por descripción de la unidad.
   - **Duplicados**: mismo cliente + nº documento externo en pedidos o facturas registradas.
   - Estado final: **Lista para crear** (todo cuadra y confianza ≥ mínimo) o **Requiere revisión**.
4. **Creación del pedido** (`IKA Sales Order Creator`): `Validate` de cliente, dirección de envío,
   nº documento externo, fecha de entrega, producto, variante, UdM y cantidad. Las líneas no
   identificadas se añaden como comentario `[NO IDENTIFICADO]` (configurable), nunca se pierden.
5. **Buzón**: el email se mueve a la carpeta de procesados o de errores.

Si `Crear pedidos automáticamente` está desactivado (recomendado al principio), todo queda en la
**Bandeja de solicitudes** para que un usuario revise y pulse *Crear pedido de venta*.

## Modos de uso

| Modo | Cómo |
|---|---|
| Automático | Cola de proyectos → `IKA Sales Agent Job` (cada N minutos) |
| Bajo demanda | Bandeja → *Leer buzón y procesar*, o Configuración → *Ejecutar ahora* |
| Manual desde fichero | Bandeja → *Nueva desde fichero* (PDF, foto, Excel...) |
| Manual desde texto | Bandeja → *Nuevo* → pegar el texto en *Cuerpo del email* → *Procesar con Claude* |
| Corrección | En la ficha: asignar cliente/producto a mano → *Volver a resolver* (no llama a Claude) |
| Aprendizaje | En una línea: *Guardar como referencia de cliente*, y la próxima vez se reconoce sola |

## Objetos (rango 99001–99100, prefijo `IKA`)

| Tipo | ID | Nombre |
|---|---|---|
| Table | 99001 | IKA Sales Agent Setup |
| Table | 99006 | IKA Sales Agent Mail Filter |
| Table | 99011 | IKA Sales Request Header |
| Table | 99016 | IKA Sales Request Line |
| Table | 99021 | IKA Sales Request Attachment |
| Table | 99026 | IKA Sales Agent Log |
| Table | 99031 | IKA Sales Mail Account (cuentas de Outlook 365) |
| TableExt | 99001 | IKA Sales Header (campo `IKA Sales Request Entry No.`) |
| Enum | 99001–99026 | Status, Match Status, Log Type, Claude Effort, Source, Mail Account Type |
| Codeunit | 99001 | IKA Claude API Client |
| Codeunit | 99006 | IKA Graph Mail Client |
| Codeunit | 99011 | IKA Sales Req. Extraction |
| Codeunit | 99016 | IKA Sales Req. Resolver |
| Codeunit | 99021 | IKA Sales Order Creator (eventos `OnBeforeModifySalesHeader`, `OnBeforeInsertSalesLine`) |
| Codeunit | 99026 | IKA Sales Agent Json Helper |
| Codeunit | 99031 | IKA Sales Agent Log Mgt. |
| Codeunit | 99036 | IKA Attachment To Text |
| Codeunit | 99041 | IKA Sales Req. Process |
| Codeunit | 99046 | IKA Move Request Mail |
| Codeunit | 99051 | IKA Sales Agent Job (cola de proyectos) |
| Page | 99001 | IKA Sales Agent Setup |
| Page | 99006 | IKA Sales Agent Mail Filters |
| Page | 99011 | IKA Sales Requests (bandeja) |
| Page | 99016 | IKA Sales Request (ficha) |
| Page | 99021 | IKA Sales Request Subform |
| Page | 99026 | IKA Sales Req. Attachments |
| Page | 99031 | IKA Sales Agent Log |
| Page | 99036 | IKA Secret Input |
| Page | 99041 | IKA Sales Mail Accounts |
| PageExt | 99001 | IKA Sales Order |
| PermissionSet | 99001 | IKA Sales Agent |

> Si el cliente ya tiene objetos en 99001–99100, cambia el rango en `app.json` y renumera.
> Cambia también `"publisher"` en `app.json` (ahora `PUBLISHER`).

## Puesta en marcha

### 1. Proyecto en VS Code
1. Copiar esta carpeta a `C:\Users\IAU\Documents\BEZEROAK\IKASLAN\IKASLAN - AGENTEAK 2`.
2. Ajustar `app.json` (publisher; `target` = `Cloud` vale también para on-prem).
3. Rellenar `.vscode/launch.json` (sandbox o servidor on-prem).
4. `AL: Download Symbols` → `Ctrl+Shift+B` → publicar.
5. En sandbox: en *Administración de extensiones* → la extensión → *Configurar* →
   activar **Permitir solicitudes HttpClient**.

### 2. Claude (Anthropic)
1. Crear una API key en <https://console.anthropic.com> (Settings → API keys).
2. En BC: *Configuración agente de ventas (Claude)* → *Establecer API key de Claude*
   (se guarda cifrada en Isolated Storage, nunca en una tabla).
3. *Probar conexión con Claude*.
4. Modelo: por defecto `claude-opus-5-5`. Para abaratar se puede poner `claude-sonnet-5-5`
   (la mitad de precio). Esfuerzo *Medio* es suficiente para la mayoría de pedidos.

Coste orientativo con Opus 5.5 ($4 / $20 por millón de tokens de entrada/salida): un email con un PDF
de 1–2 páginas ronda los 3.000–6.000 tokens de entrada y 1.000–2.000 de salida → **2–6 céntimos de $
por pedido**. El registro guarda los tokens de cada llamada.

### 3. Outlook (Microsoft Graph)
1. Entra ID → *Registros de aplicaciones* → *Nuevo registro* (p.ej. `BC Sales Agent`).
2. *Permisos de API* → Microsoft Graph → **Permisos de aplicación** → `Mail.ReadWrite` →
   *Conceder consentimiento de administrador*.
3. *Certificados y secretos* → nuevo secreto de cliente.
4. **Muy recomendable**: limitar la aplicación al buzón de pedidos (por defecto `Mail.ReadWrite` de
   aplicación da acceso a TODOS los buzones). En Exchange Online PowerShell, con *RBAC for Applications*:
   ```powershell
   New-ServicePrincipal -AppId <ClientId> -ObjectId <ObjectId de la aplicación empresarial>
   New-ManagementScope -Name "BC Sales Agent" -RecipientRestrictionFilter "PrimarySmtpAddress -eq 'pedidos@empresa.com'"
   New-ManagementRoleAssignment -App <ClientId> -Role "Application Mail.ReadWrite" -CustomResourceScope "BC Sales Agent"
   ```
   (y entonces quitar el permiso `Mail.ReadWrite` de Entra ID, que concede acceso global).
5. En BC, *Configuración agente de ventas*: Tenant Id, Client Id y *Establecer secreto de Graph*
   (credenciales generales).
6. *Cuentas de Outlook 365*: dar de alta el buzón de pedidos (o *Añadir mi cuenta* para usar el del
   usuario) con su carpeta origen (`inbox` o el nombre de una subcarpeta). Una cuenta de **otro tenant**
   de Microsoft 365 puede llevar sus propias credenciales (*Credenciales propias* + Tenant Id, Client Id
   y *Establecer secreto propio*). *Probar conexión*.
7. En la configuración, elegir la *Cuenta de Outlook 365* y las carpetas de procesados/errores
   (crearlas antes en Outlook). *Probar conexión con Outlook*.

> La tabla y la página de cuentas tienen la misma estructura en AGENTEAK 2, 3 y 4, para poder dejar una
> sola si se unifican las extensiones.

### 4. Filtros y cola de proyectos
1. *Filtros de correo*: p.ej. remitente `*@cliente.com` y asunto `*pedido*`; si cada dominio es un
   cliente, informar el *Nº cliente asociado*. **Sin filtros activos no se procesa ningún email.**
2. Probar con *Ejecutar ahora* y revisar la bandeja y el registro.
3. *Crear entrada de cola de proyectos* (lunes–viernes cada N minutos) y marcar *Activado*.
4. Cuando la tasa de acierto sea buena, activar *Crear pedidos automáticamente*.

## Protección de datos

Los emails y adjuntos (datos de clientes) se envían a la API de Anthropic. Revisar el acuerdo de
tratamiento de datos (DPA) de Anthropic y la política de retención de la organización, e informar si
los clientes tienen requisitos contractuales al respecto. Solo se envían los emails que cumplen los
filtros, y las imágenes en línea (firmas, logos) no se envían.

## Siguientes pasos posibles

- **Modo agéntico**: dar a Claude herramientas (`buscar_cliente`, `buscar_producto`, `ver_historico_pedidos`)
  y hacer el bucle de *tool use* en AL para que resuelva él mismo las ambigüedades.
- **Respuesta al cliente**: enviar con Graph (`/sendMail`) la confirmación del pedido, o lo que no se pudo
  identificar, redactada por Claude.
- Mismo motor para **ofertas**, **pedidos de compra** (confirmaciones de proveedor) o **facturas de compra**.
- **Batería de emails reales** de prueba (anonimizados) para ajustar el prompt (`Extra Instructions`)
  y medir el porcentaje de acierto antes de activar la creación automática.
