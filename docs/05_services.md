# Servicios Externos e Infraestructura (Services)

## Resumen
La carpeta `services` abstrae el código que se encarga de comunicarse con entidades fuera de la aplicación, como la nube (Supabase), la generación de archivos del sistema operativo (PDFs) o la exportación de reportes (Excel/CSV).

## `SyncService` (`sync_service.dart`)

Es el puente entre la base de datos local (SQLite) y la nube (Supabase Database).

### Lógica de Funcionamiento (Offline-First)
1. **Push (Subida de datos)**: El servicio consulta a la base de datos local SQLite buscando registros donde la bandera `synced == 0`. Al encontrar transacciones (sales) o inventarios nuevos (products), los envía a la tabla correspondiente en la nube mediante llamadas REST (Supabase SDK). Si la subida tiene éxito, actualiza el registro local a `synced = 1`.
2. **Manejo de Errores**: Si el dispositivo no tiene internet al momento de intentar el push, el servicio captura la excepción (ej. `SocketException`) y detiene el proceso silenciosamente. La transacción sigue guardada de manera segura a nivel local.
3. **Pull (Opcional/Híbrido)**: Puede descargar catálogos remotos hacia el dispositivo local para un usuario que inicia sesión en un dispositivo nuevo.

## `TicketPdfService` (`ticket_pdf_service.dart`)

Encargado de formatear y dibujar los comprobantes de venta (Tickets / Facturas).

### Funcionalidad
- Utiliza la librería `pdf` (Dart).
- Recibe un objeto de venta con sus respectivos `CartItem`s.
- Calcula las dimensiones, la fuente y dibuja comandos como el logo, el encabezado del negocio, la tabla de productos (cantidad, descripción, subtotal) y el gran total.
- Termina generando un archivo binario `.pdf` e invocando librerías nativas (`path_provider` y `open_filex`) para guardar el archivo en la memoria del teléfono y disparar el visor de PDF por defecto del sistema (Adobe Reader, Drive PDF, etc.).

## `ExportService` (`export_service.dart`)

Permite a los comercios extraer sus analíticas. Convierte las tablas locales de la base de datos (por ejemplo, reporte de ingresos mensuales) en formatos universales como `.csv` para que el administrador pueda importarlos en Excel y hacer su contabilidad externa.
