# Ikaslan Delivery Note Agent (Claude)

Extensión AL para Business Central 28 que captura los **albaranes de proveedor** con Claude, como
hacen Document Capture o Continia, y los **concilia con los pedidos de compra** abiertos:

- **Origen**: buzón de Outlook y/o una carpeta de SharePoint/OneDrive (Microsoft Graph), o un
  fichero subido a mano.
- **Extracción**: proveedor, nº de albarán, fecha, pedidos citados y líneas (código de proveedor,
  nuestro código, EAN, descripción, cantidad, unidad, precio, descuento, lote, caducidad).
- **Registro**: todo queda en tablas intermedias (bandeja + líneas + ficheros + log de llamadas).
- **Conciliación**: cada línea se asigna a una línea de pedido de compra con cantidad pendiente,
  detectando discrepancias de cantidad y precio y posibles duplicados.
- **Aplicación**: rellena *Nº albarán proveedor* y *Cant. a recibir* en los pedidos y, opcionalmente,
  registra la recepción.

> ⚠️ Código generado sin compilar. Antes de usarlo: `AL: Download Symbols` + `Ctrl+Shift+B`
> y corregir lo que indique el compilador.

## Plantillas: conocimiento en vez de coordenadas

Las soluciones clásicas usan **OCR + plantillas posicionales** (zonas del documento donde está cada
campo). Funcionan, pero cuesta mucho crearlas y se rompen cuando el proveedor cambia el formato, el
albarán ocupa dos páginas o llega escaneado torcido. Claude lee el documento como una persona, así que
aquí la *plantilla* de cada proveedor guarda **conocimiento**, no posiciones:

| Elemento | Dónde | Para qué |
|---|---|---|
| **Identificación** | Plantilla: filtro de remitente, asunto y nombre de fichero | Saber de qué proveedor es el documento *antes* de llamar a Claude y darle su plantilla |
| **Alias de campos** | *Alias de campos* (globales o por proveedor) | "Su pedido", "Vuestra ref.", "Pedido cliente" → nuestro nº de pedido; "Nº Lote", "Batch"... |
| **Tipo de código** | Plantilla: *El código de artículo del albarán es* | Si el código impreso es el del proveedor, el nuestro o el EAN |
| **Instrucciones** | Plantilla: texto libre | "Las cantidades vienen en cajas de 6", "ignora la columna Bultos"... |
| **Ejemplo validado** | Ficha del albarán → *Usar como ejemplo de la plantilla* | Se envía a Claude el JSON de un albarán ya revisado de ese proveedor como guía. Es "entrenar" la plantilla con un clic |

Además, la conciliación **aprende** de las correcciones:
- *Guardar como referencia de proveedor* crea una *Referencia de producto* de tipo Proveedor y la
  próxima vez el producto se reconoce solo.
- *Elegir línea de pedido* permite asignar a mano una línea del albarán a una línea de pedido.

## Flujo

```
Outlook / SharePoint ──► Bandeja de albaranes ──► Claude (JSON con esquema fijo) ──► Conciliación en AL ──► Pedido de compra
  plantilla por              (registro de todo)       + plantilla del proveedor         proveedor, productos,      Cant. a recibir,
  remitente/fichero                                    (alias, reglas, ejemplo)          líneas de pedido,          Nº albarán proveedor,
                                                                                         discrepancias              [registrar recepción]
```

### Conciliación (`IKA DN PO Matcher`, sin IA)
1. **Proveedor**: plantilla → NIF → *Nuestro nº cuenta* del proveedor → email → dominio del remitente → nombre.
2. **Producto**: referencia de proveedor → catálogo *Productos proveedor* → *Cód. proveedor* de la ficha →
   nuestro nº → EAN → *Cód. proveedor* en pedidos abiertos → descripción (primero en pedidos abiertos del proveedor).
3. **Pedido**: el nº citado se busca como nº exacto, *Nº pedido proveedor*, *Su referencia* o nº que
   termina igual ("123" → "PC-000123").
4. **Línea de pedido**: la del pedido citado en la línea, después la de los pedidos de la cabecera y,
   si se permite, cualquier pedido abierto del proveedor. Se elige la línea con pendiente suficiente
   (descontando lo ya asignado por otras líneas del mismo albarán) y fecha de recepción más temprana.
   Las unidades se convierten a la unidad del pedido.
5. **Discrepancias**: cantidad mayor que el pendiente; precio neto (precio × (1 − dto.)) fuera de la
   tolerancia. Se pueden aceptar línea a línea (*Aceptar discrepancia*).
6. **Duplicados**: mismo proveedor + nº de albarán ya procesado o con recepción registrada.
7. **Estado**: *Conciliado* si todo cuadra y la confianza supera el mínimo; si no, *Requiere revisión*.

## Objetos (rango 99101–99200, prefijo `IKA DN`)

Es independiente de la extensión de ventas (AGENTEAK 2), así que se pueden instalar las dos.

| Tipo | ID | Nombre |
|---|---|---|
| Table | 99101 | IKA DN Setup |
| Table | 99106 | IKA DN Vendor Template |
| Table | 99111 | IKA DN Field Alias |
| Table | 99116 | IKA DN Document |
| Table | 99121 | IKA DN Document Line |
| Table | 99126 | IKA DN File |
| Table | 99131 | IKA DN Log |
| Table | 99136 | IKA DN Mail Account (cuentas de Outlook 365) |
| TableExt | 99101 | IKA DN Purchase Header |
| Enum | 99101–99136 | Status, Match Status, Source, Log Type, Claude Effort, Alias Field, Item Code Type, Mail Account Type |
| Codeunit | 99101 | IKA DN Claude Client (prompt + plantilla + esquema JSON) |
| Codeunit | 99106 | IKA DN Graph Client (correo + SharePoint/OneDrive) |
| Codeunit | 99111 | IKA DN Extraction |
| Codeunit | 99116 | IKA DN Vendor Item Resolver |
| Codeunit | 99121 | IKA DN PO Matcher |
| Codeunit | 99126 | IKA DN Receipt Applier (eventos `OnBeforeModifyPurchaseHeader/Line`) |
| Codeunit | 99131 | IKA DN Json Helper |
| Codeunit | 99136 | IKA DN Log Mgt. |
| Codeunit | 99141 | IKA DN File To Text (Excel → CSV) |
| Codeunit | 99146 | IKA DN Process |
| Codeunit | 99151 | IKA DN Move Source |
| Codeunit | 99156 | IKA DN Job (cola de proyectos) |
| Page | 99101 | IKA DN Setup |
| Page | 99106 / 99111 | IKA DN Vendor Templates / Template |
| Page | 99116 | IKA DN Field Aliases |
| Page | 99121 / 99126 / 99131 | IKA DN Documents / Document / Document Subform |
| Page | 99136 | IKA DN Files |
| Page | 99141 | IKA DN Log |
| Page | 99146 | IKA DN Secret Input |
| Page | 99151 | IKA DN Mail Accounts |
| PageExt | 99101 | IKA DN Purchase Order |
| PermissionSet | 99101 | IKA DN Agent |

## Puesta en marcha

1. Copiar la carpeta a `C:\Users\IAU\Documents\BEZEROAK\IKASLAN\IKASLAN - AGENTEAK 3`, ajustar
   `publisher` en `app.json` y `launch.json`, `Download Symbols`, compilar y publicar.
   En sandbox: permitir solicitudes HttpClient para la extensión.
2. **Claude**: *Establecer API key de Claude* → *Probar conexión con Claude*.
3. **Registro de aplicación en Entra ID** (se puede reutilizar el de AGENTEAK 2) con permisos de aplicación:
   - correo: `Mail.ReadWrite`, limitado al buzón de albaranes con RBAC for Applications de Exchange;
   - carpeta: `Sites.Selected`, concediendo a la app acceso de escritura solo al sitio de compras
     (`POST /sites/{site-id}/permissions`), o `Files.ReadWrite.All`, que da acceso a todo y no se recomienda.
4. **Correo**: en *Cuentas de Outlook 365* dar de alta el buzón de albaranes (o *Añadir mi cuenta*)
   con su carpeta origen; una cuenta de otro tenant puede llevar credenciales propias. En la configuración
   elegir la *Cuenta de Outlook 365*, las carpetas de procesados/errores y si se aceptan remitentes sin
   plantilla (filtro de asunto genérico). La carpeta de SharePoint usa siempre las credenciales generales.
5. **Carpeta**: *Sitio SharePoint* (`empresa.sharepoint.com:/sites/Compras`) → *Obtener Drive Id*;
   rutas de entrada, procesados y errores dentro de la biblioteca (crearlas antes).
   > BC en la nube no puede leer una carpeta de red local. Si los albaranes se dejan en una carpeta del
   > servidor, se sincroniza con OneDrive/SharePoint, o se mueven con Power Automate a la biblioteca.
   > En on-prem se podría cambiar `target` a `OnPrem` y leer la carpeta con *File Management*.
6. **Alias globales**: cargar los nombres habituales, p.ej. *Nº pedido (nuestro)*: "Su pedido",
   "Vuestro pedido", "Su ref.", "Pedido cliente", "S/Pedido"; *Lote*: "Lote", "Batch", "L.".
7. **Plantillas** para los proveedores principales: filtro de remitente o fichero, tipo de código e instrucciones.
8. Probar con *Nuevo desde fichero* y con *Ejecutar ahora*. Corregir, crear referencias de proveedor y
   marcar un buen albarán de cada proveedor como *ejemplo*.
9. *Crear entrada de cola de proyectos* y *Activado*. Activar *Aplicar automáticamente a pedidos* y
   *Registrar recepción automáticamente* solo cuando el acierto sea alto.

Coste orientativo con `claude-opus-5-5` ($4 / $20 por millón de tokens de entrada/salida): un albarán PDF de
1–2 páginas ronda los 3.000–8.000 tokens de entrada (más si la plantilla lleva un ejemplo) y 1.000–3.000 de
salida → **3–10 céntimos de $ por albarán**. Con `claude-sonnet-5-5`, aproximadamente la mitad.

## Pendiente / siguientes pasos

- **Lotes y caducidades**: se extraen y se guardan en la línea, pero todavía no se crea el seguimiento de
  producto (Reservation Entry / Item Tracking) en la línea de pedido. Es el siguiente paso natural si se
  trabaja con lotes.
- **Una línea de albarán que cubra varias líneas de pedido** (el pendiente está repartido): ahora se asigna a la
  mejor línea y se marca discrepancia si no alcanza. Se puede ampliar para repartir automáticamente.
- **Facturas de proveedor**: mismo motor, con un esquema de factura y conciliación contra recepciones
  registradas (*Obtener líneas de recepción*).
- **Respuesta al proveedor** con las incidencias (cantidades o precios distintos), redactada por Claude.
- **Base común**: si se mantienen varias extensiones de agentes, mover a una app base compartida el cliente de
  Claude, el de Graph, el JSON helper y el log.
