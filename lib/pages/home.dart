import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../models/lectura_sensor.dart';
import '../services/location_service.dart';
import '../services/sensor_service.dart';
import '../services/supabase_service.dart';
import '../widgets/componentes.dart';
import 'estadisticas.dart';
import 'historial.dart';
import 'sensores.dart';
import 'ubicacion.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.servicioSupabase});

  final SupabaseService servicioSupabase;

  @override
  State<HomePage> createState() => _EstadoHomePage();
}

class _EstadoHomePage extends State<HomePage> {
  final _sensores = SensorService();
  final _servicioUbicacion = const LocationService();
  final _visitadas = {0};
  late final AppLifecycleListener _cicloDeVida;
  int _seleccion = 0;
  int _revision = 0;
  int _solicitudUbicacion = 0;
  int _solicitudConexion = 0;
  bool? _conectado;
  String? _errorConexion;
  String _estadoUbicacion = 'Comprobando…';

  @override
  void initState() {
    super.initState();
    _cicloDeVida = AppLifecycleListener(onStateChange: _alCambiarCicloDeVida);
    final cicloDeVida = WidgetsBinding.instance.lifecycleState;
    _sensores.cambiarPrimerPlano(
      cicloDeVida == null || cicloDeVida == AppLifecycleState.resumed,
    );
    unawaited(_comprobarConexion());
    unawaited(_comprobarUbicacion());
  }

  void _alCambiarCicloDeVida(AppLifecycleState estado) {
    final activo = estado == AppLifecycleState.resumed;
    _sensores.cambiarPrimerPlano(activo);
    if (activo) unawaited(_comprobarUbicacion());
  }

  Future<void> _comprobarConexion() async {
    final solicitud = ++_solicitudConexion;
    setState(() {
      _conectado = null;
      _errorConexion = null;
    });
    try {
      await widget.servicioSupabase.comprobarConexion();
      if (!mounted || solicitud != _solicitudConexion) return;
      setState(() => _conectado = true);
    } catch (error) {
      if (!mounted || solicitud != _solicitudConexion) return;
      setState(() {
        _conectado = false;
        _errorConexion = widget.servicioSupabase.mensajeDeError(error);
      });
    }
  }

  Future<void> _comprobarUbicacion() async {
    final solicitud = ++_solicitudUbicacion;
    final estado = await _servicioUbicacion.consultarEstado();
    if (!mounted || solicitud != _solicitudUbicacion) return;
    setState(() => _estadoUbicacion = estado);
  }

  Future<bool> _guardar(LecturaSensor lectura) async {
    try {
      await widget.servicioSupabase.guardarLectura(lectura);
      if (!mounted) return true;
      ++_solicitudConexion;
      setState(() {
        // Avisa al historial y a las estadísticas que hay una nueva lectura.
        _revision++;
        _conectado = true;
        _errorConexion = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${lectura.tipo.etiqueta} guardado en Supabase.'),
        ),
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      final mensaje = widget.servicioSupabase.mensajeDeError(error);
      unawaited(_comprobarConexion());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensaje)));
      return false;
    }
  }

  void _navegar(int indice) => setState(() {
    _seleccion = indice;
    _visitadas.add(indice);
  });

  Widget _pagina(int indice) {
    if (!_visitadas.contains(indice)) return const SizedBox.shrink();
    return switch (indice) {
      0 => _ResumenInicio(
        movimiento: _sensores,
        estadoUbicacion: _estadoUbicacion,
        estadoConexion: _conectado,
        errorConexion: _errorConexion,
        actualizarConexion: _comprobarConexion,
        alNavegar: _navegar,
      ),
      1 => PaginaSensores(
        servicioSensores: _sensores,
        guardarLectura: _guardar,
      ),
      2 => PaginaUbicacion(
        servicioUbicacion: _servicioUbicacion,
        guardarLectura: _guardar,
        alCambiarPermiso: _comprobarUbicacion,
      ),
      3 => PaginaHistorial(
        servicioSupabase: widget.servicioSupabase,
        revision: _revision,
      ),
      _ => PaginaEstadisticas(
        servicioSupabase: widget.servicioSupabase,
        revision: _revision,
      ),
    };
  }

  @override
  void dispose() {
    _cicloDeVida.dispose();
    _sensores.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext contexto) => Scaffold(
    appBar: AppBar(
      title: const Row(
        children: [
          Icon(Icons.sensors_rounded, color: azul),
          SizedBox(width: 10),
          Text('SensorTrack', style: TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    ),
    body: SafeArea(
      bottom: false,
      child: IndexedStack(
        index: _seleccion,
        children: List.generate(5, _pagina),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _seleccion,
      onDestinationSelected: _navegar,
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
        NavigationDestination(
          icon: Icon(Icons.sensors_rounded),
          label: 'Sensores',
        ),
        NavigationDestination(
          icon: Icon(Icons.my_location_rounded),
          label: 'Ubicación',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_rounded),
          label: 'Historial',
        ),
        NavigationDestination(
          icon: Icon(Icons.show_chart_rounded),
          label: 'Estadísticas',
        ),
      ],
    ),
  );
}

class _ResumenInicio extends StatelessWidget {
  const _ResumenInicio({
    required this.movimiento,
    required this.estadoUbicacion,
    required this.estadoConexion,
    required this.errorConexion,
    required this.actualizarConexion,
    required this.alNavegar,
  });

  final SensorService movimiento;
  final String estadoUbicacion;
  final bool? estadoConexion;
  final String? errorConexion;
  final Future<void> Function() actualizarConexion;
  final ValueChanged<int> alNavegar;

  @override
  Widget build(BuildContext contexto) {
    final tema = Theme.of(contexto);
    return ContenidoPagina(
      alActualizar: actualizarConexion,
      elementos: [
        const EncabezadoPagina(
          'Inicio',
          'Monitoreo de movimiento y ubicación.',
        ),
        Panel(
          contenido: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const IconoSensor(Icons.cloud_outlined),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Supabase', style: tema.textTheme.titleMedium),
                        Text(
                          switch (estadoConexion) {
                            true => 'Conectado',
                            false => 'Sin conexión',
                            null => 'Comprobando conexión…',
                          },
                          style: TextStyle(
                            color: switch (estadoConexion) {
                              true => verde,
                              false => naranja,
                              null => colorTextoSecundario,
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Comprobar conexión',
                    onPressed: estadoConexion == null
                        ? null
                        : actualizarConexion,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              if (errorConexion case final mensaje?) ...[
                const SizedBox(height: 12),
                Text(
                  mensaje,
                  style: const TextStyle(color: colorTextoSecundario),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
          child: Text(
            'Sensores del dispositivo',
            style: tema.textTheme.titleLarge,
          ),
        ),
        ListenableBuilder(
          listenable: movimiento,
          builder: (contexto, contenido) => Panel(
            contenido: Column(
              children: [
                for (final tipo in SensorService.tipos)
                  _FilaSensor(tipo, switch (movimiento.estado(tipo)) {
                    EstadoSensor.disponible => 'Disponible',
                    EstadoSensor.esperando => 'Detectando…',
                    EstadoSensor.noDisponible => 'Sin señal del sensor',
                    EstadoSensor.enPausa => 'Lectura en pausa',
                  }, () => alNavegar(1)),
                _FilaSensor(
                  TipoSensor.gps,
                  estadoUbicacion,
                  () => alNavegar(2),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FilaSensor extends StatelessWidget {
  const _FilaSensor(this.tipo, this.estado, this.abrir);

  final TipoSensor tipo;
  final String estado;
  final VoidCallback abrir;

  @override
  Widget build(BuildContext contexto) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: IconoSensor(tipo.icono),
    title: Text(tipo.etiqueta),
    subtitle: Text(estado, style: const TextStyle(color: colorTextoSecundario)),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: abrir,
  );
}
