# Modelos de Datos (Models)

## Resumen
La carpeta `models` agrupa las representaciones estructurales de los objetos de negocio de PocketPOS en lenguaje Dart. Garantiza la seguridad de tipos (Type Safety) en toda la lógica de la aplicación y facilita la serialización (de y hacia mapas/bases de datos).

## Archivos y Clases Clave

### 1. `Product` (`product.dart`)
Representa un artículo del inventario.
- **Atributos Principales**: `id`, `name`, `price`, `cost`, `stock`, `category`, `barcode`.
- **Métodos**: 
  - `toMap()`: Convierte el objeto Product en un Map para insertarlo en la base de datos SQLite.
  - `Product.fromMap(Map)`: Constructor factoría que convierte una fila leída de SQLite (Map) en una instancia de `Product`.
  - `copyWith()`: Utilizado para crear mutaciones del objeto preservando la inmutabilidad de la estructura.

### 2. `CartItem` (`cart_item.dart`)
Representa un producto dentro del carrito de compras actual.
- **Atributos**: Referencia al `Product`, cantidad agregada (`quantity`).
- **Propiedades Calculadas (Getters)**: `totalPrice` devuelve `product.price * quantity`, abstrayendo la lógica matemática de la interfaz de usuario.

### 3. `PaymentMethod` (`payment_method.dart`)
Suele ser un `Enum` o clase de constantes que define cómo se está pagando la transacción actual (e.g. Efectivo, Tarjeta, Transferencia).

### 4. `models.dart` (Archivo Barril / Barrel File)
Agrupa las exportaciones de todos los modelos individuales. 
- **Propósito**: Permite a otros archivos de la aplicación importar un solo archivo (`import 'models/models.dart';`) en lugar de tener múltiples líneas de importación para cada modelo.
