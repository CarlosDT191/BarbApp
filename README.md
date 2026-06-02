# 💈 BarbApp 💈

**Plataforma integral de reservas para peluquerías y barberías**

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-blue?logo=flutter)](https://flutter.dev)
[![Node.js](https://img.shields.io/badge/Node.js-Express-green?logo=node.js)](https://nodejs.org)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-yellow?logo=firebase)](https://firebase.google.com)
[![Google Cloud](https://img.shields.io/badge/Google%20Cloud-Enabled-4285F4?logo=googlecloud&logoColor=white)](https://cloud.google.com)
---

## Índice

- [Presentación del Proyecto](#presentación-del-proyecto)
- [Stack Técnico](#stack-técnico)
- [Características Principales](#características-principales)
- [Requisitos Previos](#requisitos-previos)
- [Instalación y Configuración](#instalación-y-configuración)
- [Guía para Desarrolladores](#guía-para-desarrolladores)
- [Arquitectura de la Aplicación](#arquitectura-de-la-aplicación)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Variables de Entorno](#variables-de-entorno)
- [Comandos Útiles](#comandos-útiles)
- [Soporte](#soporte)

---

## Presentación del Proyecto

**BarbApp** es una solución empresarial diseñada para facilitar la gestión de servicios de peluquería y/o barberías. Proporciona:

- **Para Clientes**: Una plataforma intuitiva para descubrir, reservar y gestionar citas
- **Para Propietarios**: Un dashboard administrativo para gestionar mis negocios, ya sea para modificar ofertas, horario, personal; para la visualización de citas y reservas, etc.
- **Escalabilidad**: Arquitectura robusta preparada para crecimiento empresarial
- **Experiencia Multiplataforma**: Disponible en Android principalmente

### Objetivo

Permitir a los usuarios acceder más fácilmente a una multitud de negocios y permitir a los propietarios de locales de peluquería y/o barbería, aumentar su visibilidad de cara al público.

### Valores

- **Seguridad**: Autenticación robusta y protección de datos
- **Rendimiento**: Optimización en tiempo real
- **Usabilidad**: Interfaz intuitiva y accesible

---

## Stack Técnico

### Frontend (Flutter)

| Tecnología | Versión | Propósito |
|-----------|---------|----------|
| **Flutter** | 3.9.2+ | Framework multiplataforma |
| **Firebase Core** | 3.1.1 | Backend como servicio |
| **Firebase Auth** | 5.0.0 | Autenticación |
| **Firebase Messaging** | 15.1.0 | Notificaciones push |
| **Google Sign-In** | 6.2.1 | OAuth con Google |
| **Google Maps** | 2.5.0 | Ubicación y mapas |
| **Table Calendar** | 3.0.9 | Componente de calendario |
| **Geolocator** | 13.0.2 | Servicios de geolocalización |

### Backend (Node.js)

| Tecnología | Versión | Propósito |
|-----------|---------|----------|
| **Express.js** | 5.1.0 | Framework REST API |
| **MongoDB** | 7.0.0 | Base de datos NoSQL |
| **Mongoose** | 9.0.0 | ODM para MongoDB |
| **Firebase Admin** | 12.7.0 | Admin SDK |
| **JWT** | 9.0.2 | Autenticación basada en tokens |
| **bcryptjs** | 3.0.3 | Hash de contraseñas |
| **CORS** | 2.8.5 | Manejo de CORS |
| **Dotenv** | 17.2.3 | Variables de entorno |

---

## Características Principales

### Gestión de Usuarios
- ✅ Registro y login con Google
- ✅ Autenticación multi-rol (Cliente/Propietario)
- ✅ Gestión de perfiles personalizados

### Reservas
- ✅ Sistema inteligente de disponibilidad
- ✅ Calendario interactivo
- ✅ Confirmación automática de citas
- ✅ Cancelación con notificación

### Gestión de Negocios
- ✅ Perfil de negocio completo
- ✅ Catálogo de servicios y precios
- ✅ Configuración de horarios

### Notificaciones
- ✅ Notificaciones push en tiempo real
- ✅ Confirmación de citas
- ✅ Recordatorios antes de la cita
- ✅ Alertas de cambios

### Favoritos
- ✅ Guardar negocios favoritos
- ✅ Recomendaciones personalizadas
- ✅ Seguimiento de negocios

### Ubicación
- ✅ Google Maps integrado
- ✅ Geolocalización automática
- ✅ Búsqueda de negocios cercanos

---

## Requisitos Previos

Antes de comenzar, asegúrate de tener instalado:

### Herramientas Obligatorias

1. **Flutter SDK** (v3.9.2 o superior)
   ```bash
   # Descargar desde: https://flutter.dev/docs/get-started/install
   flutter --version  # Esto se hace si se quiere utilizar la aplicación móvil a través de un emulador Android
   ```

2. **Node.js** (v16+ o superior)
   ```bash
   # Descargar desde: https://nodejs.org/
   node --version && npm --version
   ```

3. **Android Studio** (para desarrollo Android)
   - Incluye Android SDK, emulador y herramientas
   - Descargar: https://developer.android.com/studio

4. **Git**
   ```bash
   git --version
   ```

### Cuentas Necesarias

- [Firebase Console](https://firebase.google.com/console) - Proyecto configurado
- [Google Cloud Console](https://console.cloud.google.com) - OAuth 2.0 credenciales
- [MongoDB Atlas](https://www.mongodb.com/cloud/atlas) - Base de datos en la nube (o local)

---

## Instalación y Configuración

### Paso 1: Clonar el Repositorio

```bash
git clone https://github.com/tu-usuario/BarbApp.git
cd BarbApp
```

### Paso 2: Configurar Variables de Entorno

#### Frontend (.env)
```bash
# Crear archivo: assets/.env
cp assets/template.env assets/.env

# Editar assets/.env con tus valores:
FIREBASE_PROJECT_ID=tu-proyecto-id
FIREBASE_API_KEY=tu-api-key
FIREBASE_AUTH_DOMAIN=tu-auth-domain
GOOGLE_MAPS_API_KEY=tu-maps-api-key
API_BASE_URL=http://tu-backend-url
```

#### Backend (.env)
```bash
# Crear archivo: backend/.env
cp backend/template.env backend/.env

# Editar backend/.env con tus valores:
PORT=3000
MONGODB_URI=mongodb+srv://usuario:password@cluster.mongodb.net/barbapp
JWT_SECRET=tu-super-secreto-jwt
FIREBASE_ADMIN_KEY=tu-firebase-admin-key
GOOGLE_CLIENT_ID=tu-google-client-id
GOOGLE_CLIENT_SECRET=tu-google-client-secret
NODE_ENV=development
```

### Paso 3: Instalar Dependencias del Frontend

```bash
# Obtener todas las dependencias Flutter
flutter pub get

# (Opcional) Actualizar dependencias
flutter pub upgrade
```

### Paso 4: Instalar Dependencias del Backend

```bash
cd backend
npm install
cd ..
```

### Paso 5: Configurar Firebase

1. Ve a [Firebase Console](https://firebase.google.com/console)
2. Crea un nuevo proyecto o usa uno existente
3. Habilita: Authentication, Firestore, Cloud Messaging
4. Descarga `google-services.json` (Android) y colócalo en `android/app/`
5. Descarga `GoogleService-Info.plist` (iOS) y colócalo en `ios/Runner/`
6. Genera la clase `firebase_options.dart`:
   ```bash
   flutter pub run firebase_core:configure
   ```

### Paso 6: Configurar Google Cloud

1. Ve a [Google Cloud Console](https://cloud.google.com/console)
2. Crea un nuevo proyecto o usa uno existente
3. Habilita: APIs y servicios, concretamente la API de Google Calendar y Google Maps. 
4. Obtén las credenciales necesarias para rellenar las variables de entorno.

### Paso 7: Verificar la Instalación

```bash
# Ejecutar diagnóstico de Flutter
flutter doctor

# Debe mostrar:
# ✓ Flutter (Channel stable, v3.x.x)
# ✓ Android toolchain
# ✓ Xcode (si es macOS)
# ✓ VS Code / Android Studio
```

---

## Guía para Desarrolladores

### Estructura del Proyecto

```
BarbApp/
├── lib/                          # Código fuente Frontend (Flutter)
│   ├── main.dart                 # Punto de entrada
│   ├── config/                   # Configuraciones globales
│   │   ├── api_config.dart
│   │   ├── firebase_options.dart
│   │   └── google_auth_config.dart
│   ├── features/                 # Módulos de características
│   │   ├── auth/                 # Autenticación
│   │   ├── home/                 # Página principal
│   │   ├── business/             # Gestión de negocios
│   │   ├── reservations/         # Gestión de reservas
│   │   ├── calendar/             # Calendario
│   │   ├── favorites/            # Favoritos
│   │   ├── profile/              # Perfil de usuario
│   │   ├── notifications/        # Notificaciones
│   │   └── routes/               # Rutas de navegación
│   ├── models/                   # Modelos de datos
│   │   ├── booking_models.dart
│   │   ├── reservation.dart
│   │   └── service_types.dart
│   └── services/                 # Servicios (API, Firebase, etc.)
│       ├── business_service.dart
│       ├── reservation_service.dart
│       ├── user_service.dart
│       ├── google_calendar_service.dart
│       ├── push_notification_service.dart
│       └── favorite_service.dart
├── backend/                      # Código Backend (Node.js/Express)
│   ├── server.js                 # Punto de entrada del servidor
│   ├── package.json              # Dependencias Node.js
│   └── src/
│       ├── app.js                # Aplicación Express
│       ├── config/               # Configuraciones
│       ├── controllers/          # Controladores (lógica de negocio)
│       ├── models/               # Modelos Mongoose
│       ├── routes/               # Rutas API
│       ├── middleware/           # Middlewares (autenticación, validación)
│       └── services/             # Servicios (lógica compartida)
├── test/                         # Tests unitarios
├── android/                      # Código nativo Android
├── ios/                          # Código nativo iOS
├── web/                          # Versión Web
├── pubspec.yaml                  # Dependencias Flutter
├── package.json                  # Configuración del proyecto
└── README.md                     # Este archivo

```

### Convenciones de Código

#### Flutter/Dart
```dart
// ✓ Nombres de clases en PascalCase
class UserService {
  
  // ✓ Nombres de métodos en camelCase
  Future<User> fetchUser(String userId) async {
    
  }
  
  // ✓ Variables privadas con _
  final String _apiKey = 'xxx';
  
  // ✓ Constantes en UPPER_SNAKE_CASE
  static const String API_BASE_URL = 'https://api.example.com';
}

// ✓ Comentarios de documentación
/// Obtiene la lista de servicios disponibles.
/// 
/// Returns:
///   List<ServiceType> - Lista de servicios ordenados por categoría.
/// 
/// Throws:
///   ServiceException - Si hay error en la conexión.
Future<List<ServiceType>> getServices() async {
  // implementación
}
```

#### Node.js/Express
```javascript
// ✓ Rutas bien organizadas
router.get('/api/users/:id', authenticate, getUser);
router.post('/api/reservations', authenticate, createReservation);

// ✓ Manejo de errores consistente
try {
  const user = await User.findById(userId);
  if (!user) {
    return res.status(404).json({ error: 'Usuario no encontrado' });
  }
  res.json(user);
} catch (error) {
  console.error('Error:', error);
  res.status(500).json({ error: 'Error interno del servidor' });
}

// ✓ Variables de entorno
const API_PORT = process.env.PORT || 3000;
const DB_URI = process.env.MONGODB_URI;
```

### Proceso de Desarrollo

#### 1. **Crear una Nueva Feature**

```bash
# Frontend
# Crear carpeta en lib/features/
mkdir -p lib/features/mi-feature

# Estructura recomendada:
# lib/features/mi-feature/
# ├── screens/
# ├── widgets/
# ├── models/
# └── services/
```

#### 2. **Trabajar con Ramas Git**

```bash
# Crear rama feature
git checkout -b feature/nombre-descriptivo

# Realizar cambios, commits
git add .
git commit -m "feat: descripción clara del cambio"

# Push a rama
git push origin feature/nombre-descriptivo

# Crear Pull Request en GitHub
```

#### 3. **Testing**

```bash
# Frontend - Ejecutar tests
flutter test

# Backend - Ejecutar tests
cd backend && npm test
```

#### 4. **Validar el Código**

```bash
# Análisis estático Flutter
flutter analyze

# Verificar formato Dart
dart format lib/ --set-exit-if-changed
```

### Hot Reload y Debug

```bash
# Ejecutar app en modo debug con hot reload
flutter run

# Debug en dispositivo específico
flutter run -d <device_id>

# Debug con Chrome DevTools
flutter run -d chrome

# Ver lista de dispositivos
flutter devices
```

---

## Arquitectura de la Aplicación

### Patrones Arquitectónicos

#### MVC + Servicios (Frontend)
```
Vista (UI) ←→ Controlador ←→ Servicios ←→ API Backend
   (Widgets)    (State)    (Business Logic)
```

#### MVC (Backend)
```
Cliente (App) ←→ Rutas (Routes) ←→ Controladores ←→ Servicios ←→ Base de Datos
                  (API Endpoints)  (Lógica)      (Persistencia)
```

### Flujo de Autenticación

```
┌─────────────┐
│    Usuario  │
└──────┬──────┘
       │ Google Sign-In
       ▼
┌──────────────────────┐
│  Google Auth Server  │
└──────┬───────────────┘
       │ Token ID
       ▼
┌──────────────────────┐
│ Firebase Auth        │
└──────┬───────────────┘
       │ JWT Token
       ▼
┌──────────────────────┐
│ Backend Node.js      │ ◄─── Valida JWT
└──────┬───────────────┘
       │ Session Iniciada
       ▼
┌──────────────────────┐
│ Aplicación Flutter   │
└──────────────────────┘
```

### Flujo de Reservación

```
1. Cliente selecciona negocio y servicio
   ↓
2. Sistema consulta disponibilidad (API Backend)
   ↓
3. Backend verifica calendario de empleados
   ↓
4. Frontend muestra horarios disponibles
   ↓
5. Cliente confirma reservación
   ↓
6. Backend guarda en MongoDB y notifica
   ↓
7. Push notification al cliente y negocio
   ↓
8. Google Calendar se actualiza (si sincronizado)
```

### Seguridad

- **Autenticación**: JWT + Firebase Auth
- **Autorización**: Role-based access control (RBAC)
- **Validación**: Schema validation en backend
- **CORS**: Configurado para dominios autorizados
- **HTTPS**: Obligatorio en producción
- **Contraseñas**: Hash con bcryptjs (salt rounds: 10)

---

## Estructura del Proyecto Detallada

### Frontend - lib/features/

```
auth/
├── login_page.dart           # Pantalla de login
├── signup_page.dart          # Registro
├── forgot_password.dart      # Recuperar contraseña
└── auth_service.dart         # Servicios de autenticación

home/
├── home_page_client.dart     # Página principal cliente
├── home_page_owner.dart      # Página principal propietario
└── home_service.dart         # Servicios de home

business/
├── business_profile.dart     # Perfil del negocio
├── service_management.dart   # Gestión de servicios
├── employee_management.dart  # Gestión de empleados
└── business_service.dart     # API service

reservations/
├── reservation_list.dart     # Lista de reservas
├── create_reservation.dart   # Crear reservación
├── reservation_detail.dart   # Detalle de reservación
└── reservation_service.dart  # API service

calendar/
├── calendar_view.dart        # Vista de calendario
├── availability_config.dart  # Configurar disponibilidad
└── google_calendar_service.dart  # Sincronización

profile/
├── profile_screen.dart       # Perfil de usuario
├── edit_profile.dart         # Editar perfil
└── user_service.dart         # API service

notifications/
├── notification_screen.dart  # Centro de notificaciones
├── notification_detail.dart  # Detalle
└── push_notification_service.dart  # Service
```

### Backend - src/

```
controllers/
├── authController.js         # Lógica de autenticación
├── businessController.js     # Lógica de negocios
├── reservationController.js  # Lógica de reservas
└── userController.js         # Lógica de usuarios

models/
├── User.js                   # Schema de usuario
├── Business.js               # Schema de negocio
├── Reservation.js            # Schema de reservación
├── Service.js                # Schema de servicio
└── Employee.js               # Schema de empleado

routes/
├── authRoutes.js             # POST /auth/login, /auth/register
├── businessRoutes.js         # CRUD /businesses
├── reservationRoutes.js      # CRUD /reservations
└── userRoutes.js             # CRUD /users

middleware/
├── authMiddleware.js         # Validar JWT
├── validationMiddleware.js   # Validar datos
└── errorHandler.js           # Manejo de errores

services/
├── emailService.js           # Envío de correos
├── notificationService.js    # Push notifications
├── calendarService.js        # Sincronización Google Calendar
└── storageService.js         # Almacenamiento de archivos
```

---

## Variables de Entorno

### Frontend (assets/.env)

```env
# Firebase Configuration
FIREBASE_PROJECT_ID=tu-proyecto-id
FIREBASE_API_KEY=tu-api-key
FIREBASE_AUTH_DOMAIN=tu-auth-domain.firebaseapp.com
FIREBASE_DATABASE_URL=https://tu-proyecto.firebaseio.com
FIREBASE_STORAGE_BUCKET=tu-proyecto.appspot.com
FIREBASE_MESSAGING_SENDER_ID=tu-sender-id
FIREBASE_APP_ID=tu-app-id

# API Configuration
API_BASE_URL=http://localhost:3000
API_TIMEOUT=30

# Google Services
GOOGLE_MAPS_API_KEY=tu-maps-api-key
GOOGLE_CLIENT_ID=tu-google-client-id.apps.googleusercontent.com

# App Settings
APP_NAME=BarbApp
APP_VERSION=1.0.1
DEBUG_MODE=true
```

### Backend (.env)

```env
# Server Configuration
PORT=3000
NODE_ENV=development
CORS_ORIGIN=http://localhost:8080,https://app.barbapp.com

# Database
MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/barbapp?retryWrites=true&w=majority
DATABASE_NAME=barbapp

# Authentication
JWT_SECRET=tu-super-secreto-jwt-aleatorio-y-seguro
JWT_EXPIRES_IN=7d
REFRESH_TOKEN_SECRET=tu-refresh-token-secret

# Firebase Admin
FIREBASE_ADMIN_KEY={
  "type": "service_account",
  "project_id": "tu-proyecto-id",
  ...
}

# Google OAuth
GOOGLE_CLIENT_ID=tu-google-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=tu-google-client-secret
GOOGLE_REDIRECT_URL=http://localhost:3000/auth/google/callback

# Email Service (Opcional)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=tu-email@gmail.com
SMTP_PASS=tu-app-password

# Logging
LOG_LEVEL=debug
```

---

## Comandos Útiles

### Frontend

```bash
# Limpiar caché y regenerar
flutter clean && flutter pub get

# Compilar APK para Android
flutter build apk --split-per-abi

# Compilar AAB para Google Play
flutter build appbundle

# Construir para iOS
flutter build ios

# Construir para Web
flutter build web

# Ejecutar con verbose para debugging
flutter run -v

# Ejecutar tests
flutter test

# Generar cobertura de tests
flutter test --coverage

# Analizar código
flutter analyze

# Formatear código
dart format lib/ -i
```

### Backend

```bash
# Instalar dependencias
npm install

# Ejecutar en desarrollo (con nodemon)
npm start

# Ejecutar tests
npm test

# Linter
npm run lint

# Compilar tipos de TypeScript (si aplica)
npm run build

# Ver logs en tiempo real
tail -f logs/app.log
```

### General

```bash
# Git - Crear rama
git checkout -b feature/mi-feature

# Git - Commit con mensaje descriptivo
git commit -m "feat: agregar nueva feature"

# Git - Push
git push origin feature/mi-feature

# Verificar estado
flutter doctor
```

---

### Checklist de Código

Antes de enviar un PR:

```markdown
- [ ] Código sigue las convenciones del proyecto
- [ ] Tests pasan sin errores
- [ ] Sin warnings en `flutter analyze`
- [ ] Cambios están documentados
- [ ] Variables de entorno actualizadas
- [ ] Screenshots de UI changes (si aplica)
- [ ] Commit messages son claros
- [ ] No hay conflictos con main
```

---

## Soporte y Recursos

### Documentación Oficial

- [Flutter Documentation](https://flutter.dev/docs)
- [Express.js Guide](https://expressjs.com/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Firebase Documentation](https://firebase.google.com/docs)

### Problemas Comunes

#### Flutter no encuentra dispositivos
```bash
# Verificar dispositivos conectados
flutter devices

# Si está vacío:
# - Conectar dispositivo físico o abrir emulador
# - macOS: xcode-select --install
# - Windows: Instalar Android Studio
```

#### Error de conexión a MongoDB
```bash
# Verificar MONGODB_URI en .env
# - Comprobar credenciales
# - Verificar whitelist de IP en MongoDB Atlas
# - Probar conexión: mongo "mongodb+srv://user:pass@cluster.mongodb.net"
```

#### Problemas con Firebase
- Verificar archivos `google-services.json` y `GoogleService-Info.plist`
- Regenear con: `flutter pub run firebase_core:configure`
- Comprobar permisos en Firebase Console

### Contacto

- **Issues**: [GitHub Issues](https://github.com/CarlosDT191/BarbApp/issues)
- **Discussions**: [GitHub Discussions](https://github.com/CarlosDT191/BarbApp/discussions)

### Hoja de Ruta (Roadmap)

- v1.0 - Autenticación y reservas básicas
- v1.1 - Integración con Google Calendar y pulido de funcionalidades

---

**Última actualización**: Mayo 2026
**Versión**: 1.0.1
**Mantener por**: Equipo de Desarrollo BarbApp
