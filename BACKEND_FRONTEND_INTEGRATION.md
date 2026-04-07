# Gestión de Datos de Usuario - Backend y Frontend

## 📋 Resumen de Implementación

Se ha configurado un sistema completo de gestión de datos de usuario entre el backend (Node.js + MongoDB) y el frontend (Flutter). La pestaña de perfil ahora se conecta directamente con el backend en lugar de usar almacenamiento local.

---

## 🔌 Nuevos Endpoints en Backend

### 1. **GET `/users/me`** ✅ (Ya existía)
- **Descripción**: Obtiene los datos del usuario autenticado
- **Autenticación**: Requerida (Bearer Token)
- **Headers**: 
  ```
  Authorization: Bearer <token_jwt>
  Content-Type: application/json
  ```
- **Respuesta (200)**:
  ```json
  {
    "_id": "...",
    "email": "usuario@email.com",
    "firstname": "Juan",
    "lastname": "Pérez",
    "role": 0,
    "auth_provider": "barbapp"
  }
  ```

### 2. **PUT `/users/profile`** ✨ (Nuevo)
- **Descripción**: Actualiza el nombre y apellido del usuario
- **Autenticación**: Requerida (Bearer Token)
- **Body**:
  ```json
  {
    "firstname": "Juan",
    "lastname": "Pérez"
  }
  ```
- **Respuesta (200)**:
  ```json
  {
    "message": "Perfil actualizado exitosamente",
    "user": { ... }
  }
  ```
- **Errores**:
  - 400: Debe proporcionar al menos nombre o apellido
  - 404: Usuario no encontrado
  - 500: Error interno del servidor

### 3. **PATCH `/users/password`** ✨ (Nuevo)
- **Descripción**: Cambia la contraseña del usuario
- **Autenticación**: Requerida (Bearer Token)
- **Body**:
  ```json
  {
    "currentPassword": "contraseña_actual",
    "newPassword": "contraseña_nueva",
    "confirmPassword": "contraseña_nueva"
  }
  ```
- **Respuesta (200)**:
  ```json
  {
    "message": "Contraseña actualizada exitosamente"
  }
  ```
- **Errores**:
  - 400: Campos inválidos o contraseñas no coinciden
  - 401: Contraseña actual incorrecta
  - 403: Usuario autenticado por Google (no puede cambiar contraseña)
  - 404: Usuario no encontrado
  - 500: Error interno del servidor

---

## 🎨 Cambios en Frontend

### Nuevos Archivos

**`lib/services/user_service.dart`**
- Servicio centralizado para todas las llamadas API relacionadas con usuarios
- Maneja autenticación con Bearer Token
- Métodos:
  - `getCurrentUser()`: Obtiene datos del usuario actual
  - `updateProfile(firstname, lastname)`: Actualiza perfil
  - `changePassword(...)`: Cambia contraseña

### Archivo Modificado

**`lib/features/profile/profile_page.dart`**
- Ahora carga datos desde el backend en lugar de SharedPreferences
- Diálogos interactivos para editar perfil y cambiar contraseña
- Indicador de carga mientras se obtienen los datos
- Manejo de errores con SnackBars
- Métodos:
  - `loadUserData()`: Carga datos del servidor
  - `_showEditProfileDialog()`: Diálogo para editar nombre y apellido
  - `_showChangePasswordDialog()`: Diálogo para cambiar contraseña

---

## 🔄 Flujo de Datos

```
┌─────────────┐
│   Flutter   │
│   Frontend  │
└──────┬──────┘
       │
       │ UserService.getCurrentUser()
       │ (Incluye token JWT en headers)
       ▼
┌─────────────────────────────┐
│ Backend - GET /users/me     │
│ (Valida token)              │
│ (Consulta MongoDB)          │
└──────┬──────────────────────┘
       │
       ▼
┌─────────────────────────────────────────┐
│ ProfilePage muestra:                    │
│ - Nombre + Apellido (cargados)          │
│ - Email                                 │
│ - Opciones: Editar, Cambiar contraseña  │
└─────────────────────────────────────────┘

┌─────────────────────────────────────┐
│ Usuario hace clic en "Editar perfil" │
└──────┬──────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────┐
│ Diálogo: Ingresar nuevo nombre/apellido  │
└──────┬───────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────┐
│ UserService.updateProfile()              │
│ (Envía PUT /users/profile con token)     │
└──────┬───────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────┐
│ Backend actualiza en MongoDB             │
│ Retorna usuario actualizado              │
└──────┬───────────────────────────────────┘
       │
       ▼
┌──────────────────────────────────────────┐
│ Frontend actualiza UI                    │
│ Muestra confirmar con SnackBar           │
└──────────────────────────────────────────┘
```

---

## 🔒 Seguridad

### 1. **Autenticación JWT**
- Todos los endpoints nuevos requieren token JWT válido
- El token se envía en el header `Authorization: Bearer <token>`
- El middleware `authMiddleware` valida el token antes de procesar

### 2. **Validaciones en Backend**
- Email único (no se permite duplicados)
- Contraseña con mínimo 8 caracteres
- Validación de contraseña actual antes de cambiar
- Manejo especial para usuarios autenticados por Google

### 3. **Encriptación de Contraseñas**
- Se usa bcryptjs para hashear contraseñas
- La contraseña nunca se retorna en las respuestas (se usa `.select("-password")`)

### 4. **Logs de Seguridad**
- Se registra cada operación con IP, fecha y resultado
- Errores detallados ayudan en debugging

---

## 🧪 Cómo Probar

### 1. **Asegúrate de que el servidor está corriendo**
```bash
cd backend
npm install
npm start
# Debe estar en http://localhost:3000
```

### 2. **En Flutter, asegúrate de tener http package**
```yaml
# pubspec.yaml
dependencies:
  http: ^1.1.0
  shared_preferences: ^2.0.0
```

### 3. **Flujo de prueba**
1. Inicia sesión en la app
2. Ve a la pestaña de perfil
3. Espera a que carguen los datos del servidor
4. Haz clic en "Editar perfil" para cambiar nombre/apellido
5. Haz clic en "Cambiar contraseña" para actualizar contraseña
6. Cierra sesión (limpia SharedPreferences y JWT)

### 4. **Pruebas con Postman/Insomnia**
```bash
# Primero obtén un token loginando
POST http://localhost:3000/auth/login
{
  "email": "usuario@email.com",
  "password": "password123"
}

# Luego usa el token en los nuevos endpoints
GET http://localhost:3000/users/me
Headers: {"Authorization": "Bearer <tu_token>"}

PUT http://localhost:3000/users/profile
Headers: {"Authorization": "Bearer <tu_token>"}
Body: {"firstname": "Juan", "lastname": "Pérez"}

PATCH http://localhost:3000/users/password
Headers: {"Authorization": "Bearer <tu_token>"}
Body: {
  "currentPassword": "antiguo123",
  "newPassword": "nuevo12345",
  "confirmPassword": "nuevo12345"
}
```

---

## 🔄 Mejoras Futuras

1. **Fotografía de Perfil**
   - Agregar campo `profilePicture` en User Model
   - Endpoint para subir/actualizar foto
   - Mostrar avatar en la UI

2. **Teléfono y Ubicación**
   - Agregar campos `phone` y `address`
   - Actualizar schema y endpoint

3. **Historial de Cambios**
   - Registrar cuándo se actualizaron los datos
   - Timestamps automáticos

4. **Variables de Entorno**
   - Configurar `_baseUrl` desde archivo `.env`
   - Diferentes URLs para desarrollo/producción

5. **Validación en Frontend**
   - Validar emails con regex
   - Mostrar requisitos de contraseña en tiempo real
   - Verificación de contraseña con spinner

---

## ⚙️ Configuración Necesaria

1. **Backend (`backend/.env`)**
   ```
   JWT_SECRET=tu_secret_key_super_seguro
   MONGODB_URI=mongodb://localhost:27017/barbapp
   PORT=3000
   ```

2. **Frontend (`pubspec.yaml`)**
   - Asegúrate de tener los packages correctos instalados

3. **CORS**
   - Backend ya tiene CORS habilitado
   - URL del frontend debe estar en whitelist si usas en producción

---

## 📱 Estructura Final

```
📁 Backend (src/)
  📄 controllers/auth.controller.js
    ✅ email()
    ✅ google()
    ✅ register()
    ✅ login()
    ✨ updateProfile()      [NUEVO]
    ✨ changePassword()     [NUEVO]

  📄 routes/auth.routes.js
    ✅ GET  /users/me
    ✨ PUT  /users/profile   [NUEVO]
    ✨ PATCH /users/password [NUEVO]

📁 Frontend (lib/)
  ✨ services/user_service.dart [NUEVO]
    - getCurrentUser()
    - updateProfile()
    - changePassword()

  📄 features/profile/profile_page.dart [ACTUALIZADO]
    - Conectado con backend
    - Diálogos interactivos
    - Manejo de errores
```

---

## ✅ Checklist de Implementación

- [x] Crear endpoints en backend
- [x] Crear servicio de usuario en Flutter
- [x] Actualizar profile_page.dart
- [x] Implementar diálogos para editar
- [x] Agregar manejo de errores
- [x] Documentar API
- [ ] Pruebas unitarias
- [ ] Pruebas de integración
- [ ] Despliegue a producción

