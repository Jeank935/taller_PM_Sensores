import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sensor_track/models/lectura_sensor.dart';
import 'package:sensor_track/services/supabase_service.dart';
import 'package:sensor_track/main.dart';

void main() {
  testWidgets(
    'Muestra el estado de configuración y permite navegar entre pantallas',
    (probador) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      final servicioSupabase = SupabaseService(
        null,
        errorConfiguracion: 'Configuración pendiente.',
      );

      await probador.pumpWidget(
        AplicacionSensorTrack(servicioSupabase: servicioSupabase),
      );
      expect(find.text('SensorTrack'), findsOneWidget);

      await probador.pump(const Duration(milliseconds: 900));
      await probador.pumpAndSettle();
      expect(find.text('Configuración pendiente.'), findsOneWidget);

      await probador.tap(find.text('Acelerómetro'));
      await probador.pumpAndSettle();
      expect(find.text('Monitoreo en vivo'), findsOneWidget);
      expect(find.text('Guardar medición'), findsWidgets);

      await probador.tap(find.byIcon(Icons.my_location_rounded).last);
      await probador.pumpAndSettle();
      expect(find.text('Obtener ubicación'), findsOneWidget);

      await probador.tap(find.byIcon(Icons.history_rounded));
      await probador.pumpAndSettle();
      expect(find.text('Historial no disponible'), findsOneWidget);

      await probador.tap(find.byIcon(Icons.show_chart_rounded));
      await probador.pumpAndSettle();
      expect(find.text('No se pudieron consultar los datos'), findsWidgets);
    },
  );

  testWidgets('Muestra el historial, el detalle y el gráfico de evolución', (
    probador,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    await probador.pumpWidget(
      AplicacionSensorTrack(servicioSupabase: _ServicioSupabaseDeEjemplo()),
    );
    await probador.pump(const Duration(milliseconds: 900));
    await probador.pumpAndSettle();
    expect(find.text('Conectado'), findsOneWidget);

    await probador.tap(find.byIcon(Icons.history_rounded));
    await probador.pumpAndSettle();
    await probador.tap(find.text('Acelerómetro').first);
    await probador.pumpAndSettle();
    expect(find.text('Detalle de medición'), findsOneWidget);
    expect(find.textContaining('X 1.00'), findsOneWidget);
    await probador.tap(find.byType(BackButton));
    await probador.pumpAndSettle();

    await probador.tap(find.byIcon(Icons.show_chart_rounded));
    await probador.pumpAndSettle();
    expect(find.text('Total de registros'), findsOneWidget);
    await probador.drag(find.byType(ListView), const Offset(0, -700));
    await probador.pumpAndSettle();
    expect(find.text('Últimas 2 capturas · m/s²'), findsOneWidget);
  });
}

class _ServicioSupabaseDeEjemplo extends SupabaseService {
  _ServicioSupabaseDeEjemplo() : super(null, errorConfiguracion: null);

  final _lecturas = [
    LecturaSensor.desdeJson({
      'id': 'b9f8f803-4d44-44ff-ace7-408e05ddf368',
      'sensor_type': 'accelerometer',
      'x': 1.0,
      'y': 2.0,
      'z': 8.0,
      'recorded_at': '2026-11-25T17:00:00Z',
    }),
    LecturaSensor.desdeJson({
      'id': '159ff636-c67a-4525-bca1-acf56cf1b64c',
      'sensor_type': 'accelerometer',
      'x': 3.0,
      'y': 2.5,
      'z': 7.0,
      'recorded_at': '2026-11-25T16:45:00Z',
    }),
  ];

  @override
  Future<void> comprobarConexion() async {}

  @override
  Future<List<LecturaSensor>> consultarHistorial({
    int desplazamiento = 0,
  }) async => _lecturas;

  @override
  Future<List<LecturaSensor>> consultarEvolucion(TipoSensor tipo) async =>
      _lecturas
          .where((lectura) => lectura.tipo == tipo)
          .toList()
          .reversed
          .toList();

  @override
  Future<ResumenSensores> consultarEstadisticas() async =>
      ResumenSensores.desdeJson({
        'total': 2,
        'accelerometer': 2,
        'gyroscope': 0,
        'gps': 0,
        'min_x': 1.0,
        'min_y': 2.0,
        'min_z': 7.0,
        'max_x': 3.0,
        'max_y': 2.5,
        'max_z': 8.0,
      });
}
