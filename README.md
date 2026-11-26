# SensorTrack

SensorTrack es una app hecha con Flutter para ver cómo se mueve un teléfono y consultar su ubicación. Puedes guardar una medición en Supabase y volver a verla en el historial o en las gráficas.

## Qué puedes hacer en la app

| Pantalla | Para qué sirve |
| --- | --- |
| **Inicio** | Comprueba la conexión con Supabase y muestra qué sensores están disponibles. |
| **Sensores** | Muestra cómo cambian los valores del acelerómetro al mover el teléfono y del giroscopio al girarlo. Puedes pausar el monitoreo o guardar una lectura. |
| **Ubicación** | Obtiene las coordenadas, la precisión y la hora de captura cuando pulsas **Obtener ubicación**. Puedes revisar los datos antes de guardarlos. |
| **Historial** | Lista las mediciones guardadas. Toca una para ver su detalle. |
| **Estadísticas** | Muestra cuántas mediciones hay, los valores más altos y bajos del acelerómetro, la última ubicación y una gráfica por sensor. |

## Estructura del proyecto

El código de la app está en `lib/`. Si quieres cambiar lo que se ve en pantalla, empieza por `pages/`. Si quieres revisar cómo se obtiene o se guarda una medición, entra en `services/`.

```text
SensorTrack/
├── lib/                              Código de la app
│   ├── main.dart                     Inicia SensorTrack y aplica el tema visual
│   ├── models/
│   │   └── lectura_sensor.dart       Define los datos de una medición y su resumen
│   ├── pages/
│   │   ├── splash.dart               Muestra la pantalla de bienvenida
│   │   ├── home.dart                 Organiza la navegación y muestra la conexión
│   │   ├── sensores.dart             Muestra las lecturas de movimiento en vivo
│   │   ├── ubicacion.dart            Permite capturar y guardar una ubicación
│   │   ├── historial.dart            Lista las mediciones guardadas
│   │   ├── detalles.dart             Muestra los datos de una medición
│   │   └── estadisticas.dart         Reúne los totales y las gráficas
│   ├── services/
│   │   ├── sensor_service.dart       Lee el acelerómetro y el giroscopio
│   │   ├── location_service.dart    Pide permiso y obtiene la ubicación
│   │   └── supabase_service.dart    Abre la sesión y guarda o consulta mediciones
│   └── widgets/
│       ├── componentes.dart          Reúne colores y piezas comunes de la interfaz
│       ├── tarjeta_sensor.dart       Presenta una lectura y el botón de guardado
│       └── grafico_sensor.dart       Dibuja la evolución de las mediciones
├── supabase/
│   └── sensor_readings.sql           Prepara la tabla, los permisos y las estadísticas
├── test/
│   └── widget_test.dart              Comprueba la navegación y la vista de los datos
├── docs/
│   └── informe-tecnico.md            Explica la arquitectura con más detalle
├── config/
│   └── supabase.example.json         Plantilla de la configuración anterior en JSON
├── android/                          Archivos para compilar en Android
├── ios/                              Archivos para compilar en iPhone
├── web/                              Archivos para abrir la app en el navegador
├── .env.example                      Plantilla para crear tu archivo .env local
├── pubspec.yaml                      Lista los paquetes y recursos que usa Flutter
├── pubspec.lock                      Registra las versiones de los paquetes instalados
└── README.md                         Guía para preparar y probar SensorTrack
```

## Cómo ponerla en marcha

### 1. Prepara Supabase

1. Abre **SQL Editor** en tu proyecto de Supabase, pega el contenido de [`sensor_readings.sql`](supabase/sensor_readings.sql) y ejecútalo. El script prepara la tabla y los permisos que usa la app.
2. En **Authentication → Sign In / Providers**, activa **Allow anonymous sign-ins** y guarda. Así, la app puede iniciar una sesión sin pedirte correo ni contraseña y cada sesión ve sus propias mediciones.
3. En **Connect**, copia la **Project URL** y la **Publishable key**.

Si ya había mediciones en la tabla antes de configurar los permisos, el administrador puede seguir viéndolas en Supabase. Para que salgan en la app, deben estar asociadas a la sesión que corresponda.

### 2. Configura la app

Abre el proyecto en VS Code y usa la terminal desde la carpeta donde está `pubspec.yaml`. Si todavía no tienes un `.env`, usa este comando en PowerShell para copiar la plantilla [`.env.example`](.env.example).

```powershell
Copy-Item .env.example .env
```

Abre `.env` y reemplaza los valores de ejemplo con los de tu proyecto.

```dotenv
SUPABASE_URL=https://TU_PROYECTO.supabase.co
SUPABASE_PUBLISHABLE_KEY=sb_publishable_TU_CLAVE_PUBLICA
```

La app lee el archivo al abrirse. El `.env` local queda fuera de Git y se incluye al compilar, así que usa únicamente la clave pública de Supabase.

Con **Flutter 3.47 o superior**, instala los paquetes del proyecto.

```powershell
flutter pub get
```

### 3. Abre SensorTrack

**En un teléfono Android**, necesitas el Android SDK y la depuración USB activa. Si estás preparando el equipo por primera vez, sigue la [guía de Flutter para Android](https://docs.flutter.dev/platform-integration/android/setup). Conecta el teléfono con un cable de datos, desbloquéalo y acepta el permiso de depuración si aparece. Lista los dispositivos y reemplaza `ID_DEL_TELEFONO` por el ID que salga junto a tu Android.

```powershell
flutter devices
flutter run -d ID_DEL_TELEFONO
```

**En Chrome**, puedes revisar las pantallas y la conexión con Supabase. Las lecturas disponibles dependen del equipo y de los permisos del navegador. Para comprobar el acelerómetro y el giroscopio del teléfono, usa el dispositivo físico.

```powershell
flutter run -d chrome
```

**En iPhone**, la compilación local requiere una Mac con Xcode y la firma configurada para el dispositivo. Consulta la [guía de Flutter para iOS](https://docs.flutter.dev/platform-integration/ios/setup).

## Cómo probar la app y tomar evidencias

1. En **Inicio**, comprueba que Supabase muestre **Conectado**.
2. En **Sensores**, mueve el teléfono para ver cómo cambia el acelerómetro y gíralo para ver cómo cambia el giroscopio. Pulsa **Guardar medición** dos veces por sensor con lecturas distintas para que se aprecie el cambio en la gráfica.
3. En **Ubicación**, pulsa **Obtener ubicación**, concede el permiso y revisa las coordenadas y la precisión. Pulsa **Guardar medición** para enviarlas a Supabase.
4. Abre **Historial** y toca una medición para ver el detalle. En **Estadísticas**, comprueba que cambie el total y selecciona un sensor en la gráfica.
5. En Supabase, abre **Table Editor → sensor_readings** y verifica que aparezcan las mediciones que guardaste.

Para el taller, toma capturas de **Inicio**, de los valores en **Sensores**, de la ubicación, del historial o la gráfica y de la tabla en Supabase.

## Si algo falla

| Qué ves | Qué revisar |
| --- | --- |
| Solo salen Windows y navegadores en `flutter devices`. | Ejecuta `flutter doctor -v` para revisar el Android SDK. Si ya está listo, comprueba el cable, la depuración USB y el permiso del teléfono. |
| La app pide completar la URL o la clave. | Revisa que `.env` esté junto a `pubspec.yaml` y que contenga ambos valores. Cierra la ejecución y vuelve a abrir la app. |
| Inicio indica que debes activar el acceso anónimo. | Actívalo en Auth de Supabase, guarda y pulsa el botón de recarga en **Inicio**. |
| La app avisa que falta la tabla o la función de estadísticas. | Ejecuta el script SQL en el mismo proyecto cuya URL está en `.env`. Si restringiste la Data API, revisa que el esquema `public` esté disponible. |
| Un sensor aparece sin señal en Chrome. | Prueba el acelerómetro o el giroscopio en el teléfono. |

Puedes ejecutar `flutter test` para comprobar la navegación, el historial, el detalle y la gráfica con datos de ejemplo. El [informe técnico](docs/informe-tecnico.md) explica cómo se capturan, guardan y consultan las mediciones.
