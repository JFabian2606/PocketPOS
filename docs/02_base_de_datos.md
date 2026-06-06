# Base de Datos Local (SQLite)

## Resumen
La carpeta `db` contiene el archivo `db_helper.dart`, que es el núcleo transaccional y de persistencia local (Offline-First) de PocketPOS. Utiliza la librería `sqflite` para manejar una base de datos relacional directamente en el dispositivo del usuario.

## Clase `DatabaseHelper`

Implementa un patrón **Singleton** para garantizar que solo exista una conexión activa a la base de datos durante el ciclo de vida de la aplicación.

### Estructura de Tablas (Esquema)
Al inicializarse, la base de datos `pocketpos.db` crea las siguientes tablas:

1. **`products`**: Almacena el inventario.
   - Campos clave: `id`, `name`, `price`, `stock`, `cost`, `category`, `barcode`, `synced`.
   - Propósito: Proveer acceso ultrarrápido al catálogo sin requerir conexión a internet.

2. **`sales`**: Almacena los recibos o transacciones generales.
   - Campos clave: `id`, `date`, `total`, `discount`, `payment_method`, `synced`.

3. **`sale_items`**: Tabla relacional (1:N) que asocia una venta con los productos vendidos.
   - Campos clave: `id`, `sale_id` (Foreing Key), `product_id`, `product_name`, `quantity`, `price`, `total`.

### Métodos Principales

#### 1. CRUD de Productos
- `insertProduct(Product)`: Agrega un producto nuevo.
- `getProducts()` / `getProductById(id)`: Lee el catálogo para mostrarlo en pantalla.
- `updateProduct(Product)`: Actualiza precios, descripciones o stock.
- `deleteProduct(id)`: Borra un producto del inventario.

#### 2. Gestión de Ventas (Transacciones)
- `processSale(items, paymentMethod, discount)`: Es el método más crítico. Se ejecuta de forma asíncrona al momento de cobrar el carrito.
  - Inserta el registro maestro en la tabla `sales`.
  - Itera sobre los items del carrito, restando el `stock` en la tabla `products` correspondiente a las cantidades vendidas.
  - Inserta el detalle en `sale_items`.
- `getSalesWithDetails()`: Realiza un `JOIN` entre `sales` y `sale_items` para alimentar el historial de reportes.
- `getTotalSalesByDate(date)` / `getTotalSalesByMonth(year, month)`: Utilizados para mostrar gráficas o métricas en la pantalla principal.

## Estrategia Offline-First
Todos los registros en `products` y `sales` incluyen un campo bandera llamado `synced` (0 = no sincronizado, 1 = sincronizado). Esto indica al `SyncService` (Supabase) qué datos locales están pendientes de subirse a la nube una vez que el dispositivo recupere conexión a internet.
