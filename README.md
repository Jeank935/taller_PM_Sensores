# SensorTrack

Aplicación móvil en Flutter y Dart para capturar aceleración, velocidad angular y ubicación GPS. Permite guardar lecturas en Supabase, consultar su detalle y visualizar estadísticas.

## Configuración de Supabase

1. Abre **SQL Editor** en el proyecto de Supabase y ejecuta [`supabase/sensor_readings.sql`](supabase/sensor_readings.sql). El script crea la tabla si hace falta. Si la tabla ya existe con el esquema del taller, conserva sus filas y agrega el propietario, las políticas RLS, los índices y la función de estadísticas.
2. En **Authentication → Sign In / Providers**, habilita **Anonymous Sign-Ins**. Cada instalación obtiene su propia sesión y solo puede consultar las mediciones asociadas a esa sesión.
3. En **Connect**, copia la **Project URL** y la **Publishable key**. Crea `config/supabase.local.json` a partir de [`config/supabase.example.json`](config/supabase.example.json) y completa ambos valores. Este archivo queda fuera de Git.
4. Si deshabilitaste la Data API o limitaste sus esquemas expuestos, habilítala para `public`. El script concede a `authenticated` el acceso que requiere la app.

Las filas anteriores a esta configuración que carecen de `owner_id` siguen visibles en el panel de Supabase para el administrador. Para incluirlas en el historial de la app, el administrador debe asignarlas a la cuenta anónima que corresponda. La sesión persiste mientras se conserven los datos de la app en el teléfono.

## Ejecución

Se requiere Flutter 3.47 o superior. Para Android, usa JDK 17, el SDK de Android y un teléfono con **Depuración USB** habilitada. Para ejecutar en un iPhone se requiere macOS, Xcode y la firma del dispositivo.

```bash
flutter pub get
flutter devices
flutter run --dart-define-from-file=config/supabase.local.json
```

Para revisar la app desde Chrome con la misma configuración de Supabase:

```bash
flutter run -d chrome --dart-define-from-file=config/supabase.local.json
```

En Chrome, la disponibilidad de los sensores depende del equipo y del navegador. La ubicación se solicita al pulsar **Obtener ubicación**. Para las evidencias del taller, usa un teléfono físico.

## Funciones

| Pantalla | Contenido |
| --- | --- |
| Inicio | Disponibilidad del acelerómetro, giroscopio y GPS. Comprobación de conexión con Supabase. |
| Sensores | Ejes X, Y y Z en vivo, pausa del monitoreo y guardado de cada lectura. |
| Ubicación | Permiso de ubicación, latitud, longitud, precisión y fecha de captura. Guardado por acción del usuario. |
| Historial | Registros paginados desde Supabase y detalle por medición. |
| Estadísticas | Total, conteos por sensor, mínimos y máximos por eje del acelerómetro, última ubicación y gráfico por sensor. |

## Evidencias y demostración

| Evidencia | Paso en el dispositivo físico |
| --- | --- |
| Inicio y conexión | Abre la app y captura **Inicio** con Supabase conectado. |
| Sensores | Desplaza y gira el teléfono para observar los cambios de los ejes. Guarda al menos dos lecturas distintas de cada sensor y captura **Sensores**. |
| GPS | Obtén y guarda una ubicación. Captura latitud, longitud, precisión y hora con una ubicación elegida para la demostración. |
| Historial y estadísticas | Abre el detalle de una lectura. Captura el historial y el gráfico de evolución con sus conteos. |
| Base de datos | En **Table Editor → sensor_readings**, verifica los tres tipos de registro y contrasta la fecha de captura con el historial de la app. |

Consulta el [informe técnico](docs/informe-tecnico.md) para revisar la arquitectura, el manejo de permisos y la persistencia.
