import 'package:material_ui/material_ui.dart';

import '../models/lectura_sensor.dart';
import '../services/supabase_service.dart';
import '../widgets/componentes.dart';
import '../widgets/grafico_sensor.dart';

class PaginaEstadisticas extends StatefulWidget {
  const PaginaEstadisticas({
    super.key,
    required this.servicioSupabase,
    required this.revision,
  });

  final SupabaseService servicioSupabase;
  final int revision;

  @override
  State<PaginaEstadisticas> createState() => _EstadoPaginaEstadisticas();
}

class _EstadoPaginaEstadisticas extends State<PaginaEstadisticas> {
  var _seleccion = TipoSensor.acelerometro;
  late Future<ResumenSensores> _resumen;
  late Future<List<LecturaSensor>> _evolucion;

  @override
  void initState() {
    super.initState();
    _recargar();
  }

  @override
  void didUpdateWidget(PaginaEstadisticas widgetAnterior) {
    super.didUpdateWidget(widgetAnterior);
    if (widget.revision != widgetAnterior.revision) _recargar();
  }

  void _recargar() {
    _resumen = widget.servicioSupabase.consultarEstadisticas();
    _evolucion = widget.servicioSupabase.consultarEvolucion(_seleccion);
  }

  Future<void> _actualizar() async {
    setState(_recargar);
    try {
      await Future.wait<Object>([_resumen, _evolucion]);
    } catch (_) {
      // Cada consulta muestra su propio error en pantalla.
    }
  }

  @override
  Widget build(BuildContext contexto) => ContenidoPagina(
    alActualizar: _actualizar,
    elementos: [
      const EncabezadoPagina(
        'Estadísticas',
        'Resumen y evolución de las mediciones guardadas.',
      ),
      FutureBuilder<ResumenSensores>(
        future: _resumen,
        builder: (contexto, resultado) {
          if (resultado.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (resultado.error case final error?) {
            return _panelError(error, _actualizar);
          }
          final resumen = resultado.requireData;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Panel(
                contenido: Column(
                  children: [
                    DatoSensor('Total de registros', '${resumen.total}'),
                    const Divider(),
                    for (final tipo in TipoSensor.disponibles)
                      DatoSensor(tipo.etiqueta, '${resumen.conteos[tipo]}'),
                  ],
                ),
              ),
              _ValoresExtremos(resumen),
              Panel(
                contenido: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Última ubicación',
                      style: Theme.of(contexto).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (resumen.ultimaUbicacion case final lectura?) ...[
                      ValoresLectura(lectura),
                      Text(
                        formatearFechaYHora(contexto, lectura.fechaCaptura),
                        style: const TextStyle(color: colorTextoSecundario),
                      ),
                    ] else
                      const Text(
                        'Aún no hay ubicaciones guardadas.',
                        style: TextStyle(color: colorTextoSecundario),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      Panel(
        contenido: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Evolución de las mediciones',
              style: Theme.of(contexto).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            DropdownButton<TipoSensor>(
              value: _seleccion,
              isExpanded: true,
              items: [
                for (final tipo in TipoSensor.disponibles)
                  DropdownMenuItem(value: tipo, child: Text(tipo.etiqueta)),
              ],
              onChanged: (tipo) {
                if (tipo == null || tipo == _seleccion) return;
                setState(() {
                  _seleccion = tipo;
                  _evolucion = widget.servicioSupabase.consultarEvolucion(tipo);
                });
              },
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<LecturaSensor>>(
              future: _evolucion,
              builder: (contexto, resultado) {
                if (resultado.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (resultado.error case final error?) {
                  return _panelError(error, () {
                    setState(
                      () => _evolucion = widget.servicioSupabase
                          .consultarEvolucion(_seleccion),
                    );
                  });
                }
                final lecturas = resultado.requireData;
                return lecturas.isEmpty
                    ? const Text('Aún no hay fechas y valores para graficar.')
                    : GraficoSensor(tipo: _seleccion, lecturas: lecturas);
              },
            ),
          ],
        ),
      ),
    ],
  );

  Widget _panelError(Object error, VoidCallback reintentar) => PanelMensaje(
    icono: Icons.cloud_off_outlined,
    titulo: 'No se pudieron consultar los datos',
    mensaje: widget.servicioSupabase.mensajeDeError(error),
    accion: OutlinedButton(
      onPressed: reintentar,
      child: const Text('Reintentar'),
    ),
  );
}

class _ValoresExtremos extends StatelessWidget {
  const _ValoresExtremos(this.resumen);

  final ResumenSensores resumen;

  @override
  Widget build(BuildContext contexto) => Panel(
    contenido: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Acelerómetro · mín. y máx. (m/s²)',
          style: Theme.of(contexto).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final (indice, eje) in ['X', 'Y', 'Z'].indexed)
          DatoSensor(
            'Eje $eje',
            '${formatearMedicion(resumen.minimos[indice])} / ${formatearMedicion(resumen.maximos[indice])}',
          ),
      ],
    ),
  );
}
