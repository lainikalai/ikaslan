# Ikaslan CRM Connector

Extensión AL para Business Central 28 que conecta con **Microsoft Dynamics 365 Customer Engagement** (el "Microsoft
CRM" en la nube; los datos están en Dataverse) para **consultar el CRM desde BC**, en directo y sin copiar datos.

> Fase 1: **solo lectura**. La sincronización de contactos de BC con el CRM será la fase 2.
>
> ⚠️ Compilado con el compilador AL 18 (CodeCop, UICop y PerTenantExtensionCop) contra versiones **simuladas** de los
> objetos estándar, no con los símbolos reales de BC 28, y sin probar contra un CRM real: hacer
> `AL: Download Symbols` + `Ctrl+Shift+B` y probar la conexión.

## Qué hace

| Página | Contenido |
|---|---|
| **Cuentas del CRM** | Cuentas (empresas) con búsqueda por nombre, nº de cuenta, email o ciudad; *Incluir inactivas* |
| **Cuenta del CRM** (ficha) | Datos de la cuenta + sus **contactos**, **oportunidades abiertas** y **últimas actividades** |
| **Contactos del CRM** | Personas, con su cuenta; búsqueda por nombre, email o teléfono |
| **Clientes potenciales del CRM** | Prospectos (los más recientes primero), *Solo abiertos* |
| **Oportunidades del CRM** | Oportunidades por fecha de cierre, *Solo abiertas*, total de ingresos estimados |
| **Vínculos con el CRM** | Qué cliente, proveedor o contacto de BC está vinculado con qué registro del CRM |

- En todas: **Abrir en el CRM** abre el registro en el navegador.
- **FactBox *CRM*** en las fichas de **cliente**, **proveedor** y **contacto** (si *Activado* en la configuración):
  registro vinculado del CRM, teléfono, email, propietario, **oportunidades abiertas** e importe, y **última actividad**.
  - **Vincular con el CRM**: propone la cuenta (o el contacto) con el mismo email o, si no, el mismo nombre; si no hay
    ninguno, abre la lista del CRM para buscarlo.
  - Cliente y proveedor → **cuenta**; contacto de BC de tipo *Empresa* → **cuenta**; de tipo *Persona* → **contacto**.
  - Si el CRM no responde, el FactBox muestra el error y la ficha se puede usar con normalidad.
- Menú **CRM** en el Área de trabajo *Gerente de empresa*.

Nombres en el CRM: **Cuenta** (account) = empresa; **Contacto** (contact) = persona; **Cliente potencial** (lead) =
prospecto; **Oportunidad** (opportunity); **Actividades** (llamadas, citas, correos, tareas).

## Puesta en marcha

### 1. Registro de aplicación (Entra ID)
1. Se puede reutilizar el registro de aplicación de Outlook (AGENTEAK) si es del mismo tenant, o crear uno nuevo:
   *Entra ID → Registros de aplicaciones → Nuevo registro*.
2. *Certificados y secretos → Nuevo secreto de cliente*: copiar el **Valor** (no el Id del secreto).
3. No hace falta añadir permisos de API: el acceso al CRM se da en el paso 2.

### 2. Usuario de aplicación en el CRM
1. **Centro de administración de Power Platform** (admin.powerplatform.microsoft.com) → *Entornos* → entorno del CRM →
   *Configuración* → *Usuarios y permisos* → **Usuarios de aplicación** → *Nuevo usuario de aplicación*.
2. Elegir el registro de aplicación del paso 1, la unidad de negocio y un **rol de seguridad** con permiso de
   **lectura** (nivel organización) sobre Cuenta, Contacto, Cliente potencial, Oportunidad y Actividad.
   Lo más limpio es crear un rol "Business Central (lectura)"; para la fase 2 necesitará también escritura.

### 3. Business Central
1. Publicar la extensión y asignar el conjunto de permisos **IKA CRM**.
2. **Configuración CRM**: *URL del CRM* (p.ej. `https://empresa.crm4.dynamics.com`), *Tenant Id*, *Client Id*,
   **Establecer secreto** → **Probar conexión** (muestra la organización y el usuario de aplicación).
3. Marcar **Activado** para ver el FactBox *CRM* en las fichas.

## Objetos (rango 99401–99500, prefijo `IKA CRM`)

| Tipo | ID | Nombre |
|---|---|---|
| Table | 99401 | IKA CRM Setup (URL, Tenant Id, Client Id; secreto en Isolated Storage) |
| Table | 99406–99426 | IKA CRM Account / Contact / Lead / Opportunity / Activity Buffer (temporales) |
| Table | 99431 | IKA CRM Link (registro de BC ↔ registro del CRM) |
| Enum | 99401 | IKA CRM Entity |
| Codeunit | 99401 | IKA CRM Web API (token de aplicación, GET a la API web de Dataverse, prueba de conexión) |
| Codeunit | 99406 | IKA CRM Json Helper |
| Codeunit | 99411 | IKA CRM Data Mgt. (consultas OData de cada entidad) |
| Codeunit | 99416 | IKA CRM Link Mgt. (proponer, vincular, quitar vínculo) |
| Page | 99401 | IKA CRM Setup |
| Page | 99406 / 99411 | IKA CRM Accounts / Account (ficha) |
| Page | 99416 / 99421 / 99426 | IKA CRM Contacts / Leads / Opportunities |
| Page | 99431 / 99436 / 99441 | Partes: Contacts / Opportunities / Activities |
| Page | 99446 | IKA CRM FactBox |
| Page | 99451 | IKA CRM Links |
| Page | 99456 | IKA CRM Secret Input |
| PageExt | 99401–99411 | Fichas de cliente, proveedor y contacto (FactBox *CRM*) |
| PageExt | 99416 | Menú **CRM** en el Área de trabajo *Gerente de empresa* |
| PermissionSet | 99401 | IKA CRM |

## Detalles técnicos
- API web de Dataverse `https://<entorno>/api/data/v9.2`, autenticación de aplicación (client credentials) con
  scope `https://<entorno>/.default`. El token se reutiliza mientras no caduca.
- Se piden los **valores con formato** (`Prefer: odata.include-annotations="OData.Community.Display.V1.FormattedValue"`)
  para mostrar nombres de búsquedas (propietario, cuenta...) y etiquetas de conjuntos de opciones (estado, origen...).
- Cada lista trae como máximo *Nº máx. de registros por consulta* (200 por defecto); para el resto, usar la búsqueda.

## Fase 2 (siguiente): sincronización
- Emparejar en bloque los clientes, proveedores y contactos de BC con el CRM (CIF, email, nombre) desde una página de
  propuestas.
- Sincronización automática de lo emparejado, campo a campo y en el sentido que se decida.
- Crear en BC el contacto o el cliente a partir de un cliente potencial cualificado.
- Valorar la integración estándar de BC con Dataverse para la parte de sincronización.
