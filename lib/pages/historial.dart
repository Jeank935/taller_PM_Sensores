import 'package:material_ui/material_ui.dart';

import '../models/lectura_sensor.dart';
import '../services/supabase_service.dart';
import '../widgets/componentes.dart';
import 'detalles.dart';

class PaginaHistorial extends StatefulWidget {
  const PaginaHistorial({
    super.key,
    required this.servicioSupabase,
    required this.revision,
  });

  final SupabaseService servicioSupabase;
  final int revision;

  @override
  State<PaginaHistorial> createState() => _EstadoPaginaHistorial();
}

class _EstadoPaginaHistorial extends State<PaginaHistorial> {
  final _lecturas = <LecturaSensor>[];
  bool _cargando = true;
  bool _hayMas = false;
  String? _error;
  int _solicitud = 0;

  @override
  void initState() {
    super.initState();
    _cargar(reiniciar: true);
  }

  @override
  void didUpdateWidget(PaginaHistorial widgetAnterior) {
    super.didUpdateWidget(widgetAnterior);
    if (widgetAnterior.revision != widget.revision) _cargar(reiniciar: true);
  }

  Future<void> _cargar({required bool reiniciar}) async {
    if (_cargando && !reiniciar) return;
    final solicitud = ++_solicitud;
    setState(() {
      _cargando = true;
      _error = null;
      if (reiniciar) {
        _lecturas.clear();
        _hayMas = false;
      }
    });
    try {
      final filas = await widget.servicioSupabase.consultarHistorial(
        desplazamiento: _lecturas.length,
      );
      if (!mounted || solicitud != _solicitud) return;
      setState(() {
        _lecturas.addAll(filas);
        _hayMas = filas.length == SupabaseService.tamanoPaginaHistorial;
        _cargando = false;
      });
    } catch (error) {
      if (!mounted || solicitud != _solicitud) return;
      setState(() {
        _error = widget.servicioSupabase.mensajeDeError(error);
        _cargando = false;
      });
    }
  }

  void _abrirLectura(LecturaSensor lectura) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => PaginaDetalles(lectura: lectura)),
    );
  }

  @override
  Widget build(BuildContext contexto) => ContenidoPagina(
    alActualizar: () => _cargar(reiniciar: true),
    elementos: [
      const EncabezadoPagina('Historial', 'Mediciones guardadas en Supabase.'),
      for (final lectura in _lecturas)
        Panel(
          contenido: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: IconoSensor(lectura.tipo.icono),
            title: Text(lectura.tipo.etiqueta),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatearFechaYHora(contexto, lectura.fechaCaptura),
                    style: const TextStyle(color: colorTextoSecundario),
                  ),
                  const SizedBox(height: 4),
                  if (lectura.tipo == TipoSensor.gps)
                    Text(
                      '${formatearMedicion(lectura.latitud, 5)}, ${formatearMedicion(lectura.longitud, 5)}',
                    )
                  else
                    ValoresLectura(lectura, compacto: true),
                ],
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _abrirLectura(lectura),
          ),
        ),
      if (_cargando) const Center(child: CircularProgressIndicator()),
      if (_error case final error?)
        PanelMensaje(
          icono: Icons.cloud_off_outlined,
          titulo: 'Historial no disponible',
          mensaje: error,
          accion: OutlinedButton(
            onPressed: () => _cargar(reiniciar: _lecturas.isEmpty),
            child: const Text('Reintentar'),
          ),
        )
      else if (!_cargando && _hayMas)
        OutlinedButton(
          onPressed: () => _cargar(reiniciar: false),
          child: const Text('Cargar más mediciones'),
        )
      else if (!_cargando && _lecturas.isEmpty)
        const PanelMensaje(
          icono: Icons.history_rounded,
          titulo: 'Sin mediciones guardadas',
          mensaje:
              'Guarda una lectura desde Sensores o Ubicación para verla aquí.',
        ),
    ],
  );
}
