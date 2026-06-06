# Interfaz de Usuario y Pantallas (Screens & UI)

## Resumen
La capa de presentación de PocketPOS se ubica principalmente en la carpeta `screens`, utilizando la paleta de colores y lineamientos de Material Design definidos en la carpeta `theme`.

## Componentes de Interfaz

### `MainNavigation` (`main_navigation.dart`)
Es el contenedor o andamio estructural principal (`Scaffold`) tras haber iniciado sesión. Alberga una `BottomNavigationBar` en la parte inferior de la pantalla que permite alternar entre tres grandes módulos: Inicio (Home), Catálogo/Venta (Products) y Configuraciones (Settings). 
- Utiliza un `IndexedStack` para mantener el estado en vivo de las tres pantallas. Esto significa que si el usuario empieza a bajar por el listado de productos y cambia a la vista de "Configuraciones", al regresar a "Productos" el listado se mantendrá en la misma posición.

### `ProductsScreen` (`products_screen.dart`)
Es la pantalla de ventas y catálogo.
- Lee el catálogo mediante `db_helper`.
- Pinta un `SliverGrid` para visualizar los artículos de forma compacta.
- Cuenta con un botón dinámico (+) que consulta el stock restante e interactúa con `CartProvider`. Si se deja presionado el botón (Long Press), lleva a la pantalla de edición administrativa del producto.

### `CartScreen` (`cart_screen.dart`)
La pantalla de liquidación (Checkout).
- Depende 100% de los datos que inyecta `CartProvider`.
- Permite aplicar descuentos, elegir métodos de pago e ingresar la cantidad de efectivo recibido (para calcular "Devueltas/Cambio").
- Al presionar el botón "Completar Venta":
  1. Llama a la base de datos `processSale`.
  2. Genera una copia inmutable del carrito.
  3. Lanza el diálogo de confirmación y emite la orden a `TicketPdfService` para imprimir el PDF.
  4. Limpia el `CartProvider` para un nuevo cliente.

### `HomeScreen` & `SalesReportScreen`
Muestran las analíticas financieras. Utilizan gráficos o resúmenes en texto para reportar ingresos mensuales, el ticket promedio o la transacción más reciente. Leen la información mediante los agregadores de `db_helper`.

### `ProductFormScreen` (`product_form_screen.dart`)
Pantalla administrativa protegida (usualmente). Permite crear o sobreescribir un `Product` existente en SQLite. Soporta escaneo de código de barras mediante cámara.

### Optimización de Renderizado (Performance)
Las pantallas principales están optimizadas mediante la transformación de variables estáticas. Se evita leer de `SharedPreferences` (I/O en disco) de manera síncrona dentro del árbol de widgets `build()`, lo cual eliminó por completo las caídas de *framerate* e incrementó el rendimiento a unos constantes **60 FPS** incluso bajo pruebas de estrés en motores gráficos limitados.
