import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

enum TipoSensor {
  acelerometro('accelerometer', 'Acelerómetro', 'm/s²', Icons.speed_rounded),
  giroscopio('gyroscope', 'Giroscopio', 'rad/s', Icons.screen_rotation_rounded),
  gps('gps', 'GPS', 'm', Icons.my_location_rounded),
  desconocido('', 'Otro sensor', '', Icons.sensors_rounded);

  const TipoSensor(this.valor, this.etiqueta, this.unidad, this.icono);

  final String valor;
  final String etiqueta;
  final String unidad;
  final IconData icono;

  static const disponibles = [acelerometro, giroscopio, gps];

  static TipoSensor desdeValor(String? valor) => disponibles.firstWhere(
    (tipo) => tipo.valor == valor,
    orElse: () => desconocido,
  );
}

class LecturaSensor {
  const LecturaSensor._({
    required this.id,
    required this.tipo,
    required this.fechaCaptura,
    this.x,
    this.y,
    this.z,
    this.latitud,
    this.longitud,
    this.precision,
  });

  factory LecturaSensor.movimiento(
    TipoSensor tipo,
    double x,
    double y,
    double z,
    DateTime fechaCaptura,
  ) => LecturaSensor._(
    id: const Uuid().v4(),
    tipo: tipo,
    fechaCaptura: fechaCaptura,
    x: x,
    y: y,
    z: z,
  );

  factory LecturaSensor.ubicacion({
    required double latitud,
    required double longitud,
    required double precision,
    required DateTime fechaCaptura,
  }) => LecturaSensor._(
    id: const Uuid().v4(),
    tipo: TipoSensor.gps,
    fechaCaptura: fechaCaptura,
    latitud: latitud,
    longitud: longitud,
    precision: precision,
  );

  factory LecturaSensor.desdeJson(Map<String, dynamic> json) => LecturaSensor._(
    id: json['id'] as String,
    tipo: TipoSensor.desdeValor(json['sensor_type'] as String?),
    fechaCaptura: DateTime.tryParse(json['recorded_at'] as String? ?? ''),
    x: (json['x'] as num?)?.toDouble(),
    y: (json['y'] as num?)?.toDouble(),
    z: (json['z'] as num?)?.toDouble(),
    latitud: (json['latitude'] as num?)?.toDouble(),
    longitud: (json['longitude'] as num?)?.toDouble(),
    precision: (json['accuracy'] as num?)?.toDouble(),
  );

  final String id;
  final TipoSensor tipo;
  final DateTime? fechaCaptura;
  final double? x;
  final double? y;
  final double? z;
  final double? latitud;
  final double? longitud;
  final double? precision;

  Map<String, dynamic> aJson() => {
    'id': id,
    'sensor_type': tipo.valor,
    'x': x,
    'y': y,
    'z': z,
    'latitude': latitud,
    'longitude': longitud,
    'accuracy': precision,
    'recorded_at': fechaCaptura?.toUtc().toIso8601String(),
  };
}

class ResumenSensores {
  ResumenSensores.desdeJson(Map<String, dynamic> json)
    : total = (json['total'] as num).toInt(),
      conteos = {
        for (final tipo in TipoSensor.disponibles)
          tipo: (json[tipo.valor] as num).toInt(),
      },
      minimos = [
        for (final eje in ['x', 'y', 'z'])
          (json['min_$eje'] as num?)?.toDouble(),
      ],
      maximos = [
        for (final eje in ['x', 'y', 'z'])
          (json['max_$eje'] as num?)?.toDouble(),
      ],
      ultimaUbicacion = json['latest_location'] == null
          ? null
          : LecturaSensor.desdeJson(
              json['latest_location'] as Map<String, dynamic>,
            );

  final int total;
  final Map<TipoSensor, int> conteos;
  final List<double?> minimos;
  final List<double?> maximos;
  final LecturaSensor? ultimaUbicacion;
}
