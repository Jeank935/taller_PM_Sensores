import 'package:material_ui/material_ui.dart';

import '../models/lectura_sensor.dart';
import '../services/sensor_service.dart';
import '../widgets/componentes.dart';
import '../widgets/tarjeta_sensor.dart';

class PaginaSensores extends StatefulWidget {
  const PaginaSensores({
    super.key,
    required this.servicioSensores,
    required this.guardarLectura,
  });

  final SensorService servicioSensores;
  final GuardarLectura guardarLectura;

  @override
  State<PaginaSensores> createState() => _EstadoPaginaSensores();
}

class _EstadoPaginaSensores extends State<PaginaSensores> {
  final _lecturasPendientes = <TipoSensor, LecturaSensor>{};
  final _ultimasGuardadas = <TipoSensor, String>{};
  TipoSensor? _guardando;

  Future<void> _guardar(LecturaSensor lectura) async {
    setState(() => _guardando = lectura.tipo);
    final exito = await widget.guardarLectura(lectura);
    if (!mounted) return;
    setState(() {
      _guardando = null;
      if (exito) {
        _ultimasGuardadas[lectura.tipo] = lectura.id;
        _lecturasPendientes.remove(lectura.tipo);
      } else {
        _lecturasPendientes[lectura.tipo] = lectura;
      }
    });
  }

  @override
  Widget build(BuildContext contexto) => ListenableBuilder(
    listenable: widget.servicioSensores,
    builder: (contexto, contenido) => ContenidoPagina(
      elementos: [
        const EncabezadoPagina(
          'Sensores',
          'Lecturas de movimiento en tiempo real.',
        ),
        Panel(
          contenido: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Monitoreo en vivo'),
            subtitle: Text(
              widget.servicioSensores.habilitado ? 'Activo' : 'En pausa',
            ),
            value: widget.servicioSensores.habilitado,
            onChanged: widget.servicioSensores.cambiarMonitoreo,
          ),
        ),
        for (final tipo in SensorService.tipos) _tarjetaPara(tipo),
      ],
    ),
  );

  Widget _tarjetaPara(TipoSensor tipo) {
    final lecturaPendiente = _lecturasPendientes[tipo];
    final lectura =
        lecturaPendiente ?? widget.servicioSensores.ultimaLectura(tipo);
    final guardada = lectura != null && _ultimasGuardadas[tipo] == lectura.id;
    return TarjetaSensor(
      tipo: tipo,
      lectura: lectura,
      estado: widget.servicioSensores.estado(tipo),
      pendiente: lecturaPendiente != null,
      guardada: guardada,
      guardandoLectura: _guardando == tipo,
      alGuardar: lectura == null || _guardando != null || guardada
          ? null
          : () => _guardar(lectura),
      alDescartarPendiente: _guardando != null
          ? null
          : () => setState(() => _lecturasPendientes.remove(tipo)),
    );
  }
}
