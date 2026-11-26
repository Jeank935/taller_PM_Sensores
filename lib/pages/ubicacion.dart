import 'package:material_ui/material_ui.dart';

import '../models/lectura_sensor.dart';
import '../services/location_service.dart';
import '../widgets/componentes.dart';

class PaginaUbicacion extends StatefulWidget {
  const PaginaUbicacion({
    super.key,
    required this.servicioUbicacion,
    required this.guardarLectura,
    required this.alCambiarPermiso,
  });

  final LocationService servicioUbicacion;
  final GuardarLectura guardarLectura;
  final VoidCallback alCambiarPermiso;

  @override
  State<PaginaUbicacion> createState() => _EstadoPaginaUbicacion();
}

class _EstadoPaginaUbicacion extends State<PaginaUbicacion> {
  LecturaSensor? _lectura;
  String? _error;
  Future<bool> Function()? _abrirAjustes;
  bool _capturando = false;
  bool _guardando = false;
  bool _guardada = false;

  Future<void> _capturar() async {
    setState(() {
      _capturando = true;
      _guardada = false;
      _lectura = null;
      _error = null;
      _abrirAjustes = null;
    });
    try {
      _lectura = await widget.servicioUbicacion.capturar();
    } on ErrorUbicacion catch (fallo) {
      _error = fallo.mensaje;
      _abrirAjustes = fallo.abrirAjustes;
    } finally {
      if (mounted) {
        setState(() => _capturando = false);
        widget.alCambiarPermiso();
      }
    }
  }

  Future<void> _guardar(LecturaSensor lectura) async {
    setState(() => _guardando = true);
    final guardada = await widget.guardarLectura(lectura);
    if (!mounted) return;
    setState(() {
      _guardando = false;
      _guardada = guardada;
    });
  }

  Future<void> _abrirConfiguracion() async {
    try {
      if (await _abrirAjustes?.call() ?? false) return;
    } catch (_) {
      // Algunos dispositivos requieren abrir los ajustes manualmente.
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abre los ajustes desde tu dispositivo.')),
    );
  }

  @override
  Widget build(BuildContext contexto) => ContenidoPagina(
    elementos: [
      const EncabezadoPagina(
        'Ubicación',
        'Captura las coordenadas GPS y su precisión.',
      ),
      Panel(
        contenido: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Al tocar «Guardar medición», se enviará esta ubicación a Supabase.',
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _capturando || _guardando ? null : _capturar,
              icon: const Icon(Icons.my_location_rounded),
              label: Text(
                _capturando ? 'Buscando ubicación…' : 'Obtener ubicación',
              ),
            ),
            if (_capturando) const LinearProgressIndicator(),
            if (_error case final mensaje?) ...[
              const SizedBox(height: 12),
              Text(mensaje, style: const TextStyle(color: ambar)),
              if (_abrirAjustes != null)
                TextButton(
                  onPressed: _abrirConfiguracion,
                  child: const Text('Abrir ajustes'),
                ),
            ],
          ],
        ),
      ),
      if (_lectura case final lectura?)
        Panel(
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ValoresLectura(lectura),
              const SizedBox(height: 6),
              Text(
                formatearFechaYHora(contexto, lectura.fechaCaptura),
                style: const TextStyle(color: colorTextoSecundario),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _guardando || _guardada
                    ? null
                    : () => _guardar(lectura),
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  _guardando
                      ? 'Guardando…'
                      : _guardada
                      ? 'Medición guardada'
                      : 'Guardar medición',
                ),
              ),
            ],
          ),
        ),
    ],
  );
}
