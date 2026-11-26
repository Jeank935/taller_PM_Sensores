import 'package:material_ui/material_ui.dart';

import '../models/lectura_sensor.dart';
import '../services/sensor_service.dart';
import 'componentes.dart';

class TarjetaSensor extends StatelessWidget {
  const TarjetaSensor({
    super.key,
    required this.tipo,
    required this.lectura,
    required this.estado,
    required this.pendiente,
    required this.guardada,
    required this.guardandoLectura,
    required this.alGuardar,
    required this.alDescartarPendiente,
  });

  final TipoSensor tipo;
  final LecturaSensor? lectura;
  final EstadoSensor estado;
  final bool pendiente;
  final bool guardada;
  final bool guardandoLectura;
  final VoidCallback? alGuardar;
  final VoidCallback? alDescartarPendiente;

  @override
  Widget build(BuildContext contexto) => Panel(
    contenido: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconoSensor(tipo.icono),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                tipo.etiqueta,
                style: Theme.of(contexto).textTheme.titleLarge,
              ),
            ),
            Text(
              tipo.unidad,
              style: const TextStyle(color: colorTextoSecundario),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (lectura case final lecturaActual?) ...[
          ValoresLectura(lecturaActual),
          Text(
            '${pendiente ? 'Pendiente de guardar · ' : ''}${formatearFechaYHora(contexto, lecturaActual.fechaCaptura)}',
            style: const TextStyle(color: colorTextoSecundario),
          ),
        ] else
          Text(switch (estado) {
            EstadoSensor.noDisponible =>
              'Sensor no disponible. Puedes reiniciar el monitoreo.',
            EstadoSensor.enPausa =>
              'Activa el monitoreo para capturar una lectura.',
            _ => 'Esperando la primera lectura…',
          }),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: alGuardar,
          icon: const Icon(Icons.save_outlined),
          label: Text(switch ((guardandoLectura, guardada, pendiente)) {
            (true, _, _) => 'Guardando…',
            (_, true, _) => 'Medición guardada',
            (_, _, true) => 'Reintentar guardado',
            _ => 'Guardar medición',
          }),
        ),
        if (pendiente)
          TextButton(
            onPressed: alDescartarPendiente,
            child: const Text('Volver a la lectura en vivo'),
          ),
      ],
    ),
  );
}
