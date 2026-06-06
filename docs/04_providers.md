# Manejo de Estado (Providers)

## Resumen
La carpeta `providers` contiene las clases que heredan de `ChangeNotifier` (paquete `provider`). Su propósito es centralizar la lógica de negocio temporal y notificar a la interfaz gráfica (`UI`) cuándo debe redibujarse, aislando la lógica compleja de las clases visuales (`Widgets`).

## `CartProvider` (`cart_provider.dart`)

Es el motor transaccional en vivo de la aplicación. Maneja todo lo que sucede antes de que una venta se finalice e inserte en la base de datos.

### Propiedades de Estado
- `List<CartItem> _items`: La lista de productos en el carrito actualmente.
- `double _discount`: Descuento aplicado (global o parcial).
- `PaymentMethod _paymentMethod`: Forma de pago seleccionada por el cajero.

### Propiedades Calculadas (Getters reactivos)
- `items`, `discount`, `paymentMethod`: Exponen el estado de solo lectura.
- `subtotal`: Suma de todos los `CartItem.totalPrice`.
- `total`: Calcula `subtotal - discount`. 

### Métodos Principales y Lógica de Negocio
- `addProduct(Product)`: 
  - Regla de Negocio Crítica: Verifica que el stock del producto sea mayor a 0 y que el carrito no intente agregar más unidades de las disponibles en el inventario físico (`p.stock`).
  - Si el producto ya está en el carrito, incrementa su `quantity`. Si no, crea un nuevo `CartItem`.
  - Finaliza llamando a `notifyListeners()` para que el contador rojo de la esquina inferior (o la pantalla del carrito) se actualice.
- `removeProduct(Product)` / `decreaseQuantity(Product)`: Manejan la remoción gradual o total de artículos.
- `clearCart()`: Vacía las listas y resetea los totales a cero una vez que la base de datos ha procesado la venta satisfactoriamente.

## Integración con la UI
En la pantalla `ProductsScreen`, se utiliza `context.read<CartProvider>().addProduct(...)` para mutar el estado sin escuchar cambios gráficos en el botón, mientras que en `CartScreen` se usa `context.watch<CartProvider>()` para redibujar el listado entero cuando un ítem es modificado.
