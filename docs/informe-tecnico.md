# Informe técnico de SensorTrack

**Desarrollo de Plataformas Móviles · Jean Carlos Cuenca Alvarado**

SensorTrack es una aplicación móvil en Flutter y Dart para monitorear la aceleración, la velocidad angular y la ubicación del teléfono. Un toque en **Guardar medición** envía la lectura seleccionada a Supabase. El historial y las estadísticas se consultan desde el mismo dispositivo.

## Arquitectura

| Componente | Responsabilidad |
| --- | --- |
| `lib/main.dart` y `lib/pages/` | Inicialización, splash, navegación, monitoreo, captura GPS, historial, detalle y estadísticas. |
| `lib/services/sensor_service.dart` | Suscripciones del acelerómetro y giroscopio con `sensors_plus`, a un intervalo solicitado de 250 ms. Las suscripciones se cierran al pausar el monitoreo, enviar la app a segundo plano o salir. |
| `lib/models/lectura_sensor.dart` | Modelo común para las lecturas. Contiene el tipo, el UUID, los ejes o coordenadas y el instante de captura. |
| `lib/services/supabase_service.dart` | Sesión de Supabase, comprobación de conexión, persistencia, historial paginado y consultas estadísticas. |
| `lib/services/location_service.dart` | Consulta de disponibilidad del GPS, permisos y captura de coordenadas. |
| `lib/widgets/` | Componentes reutilizables, tarjeta del sensor y gráfico de evolución. |
| `supabase/sensor_readings.sql` | Tabla PostgreSQL, índices, políticas RLS y función SQL para resumir las lecturas. |

## Captura y persistencia

`sensors_plus` entrega aceleración en m/s² y velocidad angular en rad/s para los ejes X, Y y Z. `geolocator` solicita permiso de ubicación cuando el usuario realiza una captura y devuelve latitud, longitud, precisión en metros e instante de la lectura. SensorTrack muestra el instante en la zona horaria del teléfono y lo guarda en UTC en la columna `recorded_at`.

El guardado es manual para ambos tipos de captura. Cada lectura conserva el UUID en los reintentos para que una respuesta perdida no genere dos filas. Los errores de permisos, ausencia de sensor y conexión se muestran en pantalla. Supabase Auth establece una sesión anónima y PostgreSQL aplica RLS con el identificador de la sesión como propietario. Los tres campos GPS solo se envían cuando el usuario confirma el guardado.

## Historial y visualización

El historial carga 25 registros por página y permite abrir el detalle de cada fila. La base de datos calcula el total, los conteos por sensor y los extremos del acelerómetro por eje sobre el historial completo de la sesión. También devuelve la última posición guardada. Con `fl_chart` se representan hasta 30 lecturas en orden de captura. Los sensores de movimiento muestran X, Y y Z y el GPS muestra la evolución de la precisión. Al tocar el gráfico se puede consultar la fecha, la hora y el valor.

## Validación en un dispositivo físico

La demostración consiste en abrir la app, observar cómo cambian los ejes al desplazar y girar el teléfono, guardar dos lecturas de cada sensor de movimiento, capturar y guardar una ubicación, y contrastar el historial y las estadísticas con la tabla `sensor_readings` en Supabase. El [README](../README.md) incluye las evidencias que se deben tomar durante esta prueba.

El análisis estático y las pruebas de Flutter para navegación, historial, detalle y gráfica finalizaron correctamente. En PostgreSQL se verificaron el reintento sin duplicados, las estadísticas, la separación entre sesiones y la conservación de filas anteriores. La compilación web también se completó. El arranque automatizado de Chrome quedó bloqueado en el entorno de prueba. Queda pendiente comprobar la captura en el teléfono y guardar las evidencias del proyecto Supabase utilizado en la demostración.
