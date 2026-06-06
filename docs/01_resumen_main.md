# Arquitectura y Configuración Principal (main.dart)

## Resumen
El archivo `main.dart` es el punto de entrada de la aplicación **PocketPOS**. Su responsabilidad principal es inicializar los servicios básicos antes de renderizar la interfaz gráfica y configurar las rutas globales.

## Componentes Clave

### 1. Inicialización de Flutter y Servicios (main)
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ...
}
```
Antes de ejecutar la app, se configuran servicios asíncronos críticos:
- **Supabase**: Se inicializa la conexión con el backend as-a-service utilizando la URL y la `publishableKey`. Esto habilita la autenticación (Google Sign-In) y la sincronización a la nube.
- **SharedPreferences**: Se lee el estado local persistente para determinar:
  - Si el usuario ya completó el tutorial (`onboarding_complete`).
  - Si el usuario ya tiene una sesión activa (`isLoggedIn`).

### 2. Clase `PocketPOSApp`
Es el Widget raíz de la aplicación (un `StatelessWidget`). 
- **Gestión de Estado Global (Provider):** Envuelve toda la aplicación en un `MultiProvider`. En este caso, inyecta `CartProvider`, permitiendo que el estado del carrito de compras sea accesible desde cualquier pantalla.
- **Tema Global:** Utiliza `AppTheme.theme` para mantener una consistencia visual en todos los widgets de Material.
- **Enrutamiento y Estado Inicial:**
  - Define las rutas base (`/`, `onboarding`, `login`, `home`).
  - Decide la pantalla inicial analizando los valores obtenidos de `SharedPreferences`. Si el onboarding no se ha completado, redirige a Onboarding. Si no hay sesión, redirige al Login. Si todo está correcto, va directo a `MainNavigation` (Home).

## Relación con otras áreas
- Llama a `AppTheme` de la carpeta `theme`.
- Inyecta `CartProvider` de la carpeta `providers`.
- Depende de las pantallas ubicadas en la carpeta `screens`.
