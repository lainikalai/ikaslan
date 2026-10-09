# DeCA para Business Central 28 (SaaS)

Genera el Documento electrónico de Control Administrativo exigido en el transporte público
interior de mercancías por carretera (Orden FOM/2861/2012, art. 6; Resolución de 5 de junio
de 2026, BOE-A-2026-12784).

Sirve para los dos casos. El rol se elige por empresa en **Configuración DeCA**:

| Rol de la empresa | Cargador contractual | Transportista efectivo |
|---|---|---|
| Cargador contractual | La empresa (Información de empresa) | El transportista del documento |
| Transportista efectivo | El cliente del documento | La empresa |

## Antes de compilar

1. `app.json`: cambie `publisher` y, si hace falta, el rango de IDs (usa 50000-50040).
2. `.vscode/launch.json`: indique `tenant` y `environmentName`.
3. `AL: Download Symbols` y `Ctrl+Shift+B`.

## Puesta en marcha en cada empresa

1. **Azure Storage**: cree una cuenta y un contenedor. La URL del QR debe descargar el PDF sin
   credenciales, así que elija una de estas dos opciones:
   - acceso anónimo de lectura a nivel de *blob* en el contenedor, o
   - un token SAS de solo lectura (permiso `r`) sobre el contenedor, que se añade a la URL.
     Su caducidad debe superar el fin del servicio más los días de descarga.
2. **Configuración DeCA**: rol, nº de serie, cuenta, contenedor, clave de la cuenta y, en su caso,
   el token SAS.
3. **Transportistas** (solo cargadores): denominación social, NIF y email de cada transportista.
4. **Cola de proyectos**: entrada periódica diaria para el codeunit 50020 `DECA Job Queue`.
5. Asigne los conjuntos de permisos `DECA - Edit` y `DECA - Admin`.

## Uso

- **Crear DeCA** en pedido de venta, albarán de venta registrado, pedido de transferencia y envío
  de transferencia registrado. **Crear DeCA agrupado** en la lista de albaranes registrados.
  También se puede crear a mano desde la lista **DeCA**.
- Complete matrícula y conductor y pulse **Emitir**: se fija la URL, se genera el PDF con el QR,
  se publica y se guarda una copia en Business Central con la fecha y hora de creación.
- **Enviar por email** o **Descargar PDF** para entregarlo al conductor.
- **Modificar (nueva versión)**: nuevo DeCA con nueva URL y QR; exige motivo y conserva el original.

## Qué cubre de la norma

| Requisito | Dónde |
|---|---|
| Datos del art. 6 | `DECA Header`, `DECA Line`, `CheckMandatory` |
| Fichero antes del inicio, con fecha y hora registradas | `Issue`, campo `Issued At` |
| PDF nativo de 5 MB como máximo, con QR | report 50000, `Issue` |
| URL https única, descarga directa sin credenciales | `DECA Azure Blob Storage` |
| Descarga activa hasta 7 días después del servicio | `DECA Job Queue` |
| Conservación de un año | copia en `PDF Content`; borrado bloqueado |
| Modificación trazable | `CreateReplacement` |
| Varios envíos en un DeCA | líneas; control de mismo transportista y cargador |

## Pendiente de comprobar en su entorno

- El proyecto no se ha compilado contra los símbolos de BC 28.
- El layout RDLC se ha escrito a mano: revise el tamaño del QR y léalo con un móvil.
- Compruebe en las propiedades del PDF que constan las fechas de creación y modificación.
- Los pesos se toman del campo "Peso bruto" de las líneas y se suponen en kg.
