import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/lectura_sensor.dart';

enum EstadoSensor { esperando, disponible, noDisponible, enPausa }

class SensorService extends ChangeNotifier {
  static const tipos = [TipoSensor.acelerometro, TipoSensor.giroscopio];
  static const _intervalo = Duration(milliseconds: 250);

  final _lecturas = <TipoSensor, LecturaSensor>{};
  final _noDisponibles = <TipoSensor>{};
  final _suscripciones = <StreamSubscription<LecturaSensor>>[];
  Timer? _temporizadorDisponibilidad;
  bool _enPrimerPlano = true;
  bool _monitoreando = false;
  bool _actualizando = false;
  bool _liberado = false;
  bool habilitado = true;

  LecturaSensor? ultimaLectura(TipoSensor tipo) => _lecturas[tipo];

  EstadoSensor estado(TipoSensor tipo) {
    if (_noDisponibles.contains(tipo)) return EstadoSensor.noDisponible;
    if (_lecturas.containsKey(tipo)) return EstadoSensor.disponible;
    return habilitado ? EstadoSensor.esperando : EstadoSensor.enPausa;
  }

  void cambiarMonitoreo(bool valor) {
    habilitado = valor;
    unawaited(_actualizar());
  }

  void cambiarPrimerPlano(bool valor) {
    _enPrimerPlano = valor;
    unawaited(_actualizar());
  }

  Future<void> _actualizar() async {
    if (_actualizando) return;
    _actualizando = true;
    try {
      while (!_liberado && (habilitado && _enPrimerPlano) != _monitoreando) {
        if (habilitado && _enPrimerPlano) {
          _iniciar();
        } else {
          await _detener();
        }
      }
    } finally {
      _actualizando = false;
      if (!_liberado) notifyListeners();
    }
  }

  void _iniciar() {
    _monitoreando = true;
    _noDisponibles.clear();
    if (!kIsWeb &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      _noDisponibles.addAll(tipos);
      return;
    }

    _escuchar(
      TipoSensor.acelerometro,
      accelerometerEventStream(samplingPeriod: _intervalo).map(
        (evento) => LecturaSensor.movimiento(
          TipoSensor.acelerometro,
          evento.x,
          evento.y,
          evento.z,
          evento.timestamp,
        ),
      ),
    );
    _escuchar(
      TipoSensor.giroscopio,
      gyroscopeEventStream(samplingPeriod: _intervalo).map(
        (evento) => LecturaSensor.movimiento(
          TipoSensor.giroscopio,
          evento.x,
          evento.y,
          evento.z,
          evento.timestamp,
        ),
      ),
    );
    _temporizadorDisponibilidad = Timer(const Duration(seconds: 4), () {
      _noDisponibles.addAll(
        tipos.where((tipo) => !_lecturas.containsKey(tipo)),
      );
      notifyListeners();
    });
  }

  void _escuchar(TipoSensor tipo, Stream<LecturaSensor> flujo) {
    _suscripciones.add(
      flujo.listen(
        (lectura) {
          if (_liberado || !_monitoreando) return;
          _noDisponibles.remove(tipo);
          _lecturas[tipo] = lectura;
          notifyListeners();
        },
        onError: (Object error) {
          if (_liberado || !_monitoreando) return;
          _noDisponibles.add(tipo);
          _lecturas.remove(tipo);
          notifyListeners();
        },
        cancelOnError: true,
      ),
    );
  }

  Future<void> _detener() async {
    _monitoreando = false;
    _temporizadorDisponibilidad?.cancel();
    final suscripciones = List.of(_suscripciones);
    _suscripciones.clear();
    await Future.wait(suscripciones.map((suscripcion) => suscripcion.cancel()));
  }

  @override
  void dispose() {
    _liberado = true;
    unawaited(_detener());
    super.dispose();
  }
}
