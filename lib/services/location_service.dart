import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../models/lectura_sensor.dart';

class ErrorUbicacion implements Exception {
  const ErrorUbicacion(this.mensaje, {this.abrirAjustes});

  final String mensaje;
  final Future<bool> Function()? abrirAjustes;
}

class LocationService {
  const LocationService();

  Future<String> consultarEstado() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return 'Servicios de ubicación desactivados';
      }
      final permiso = await Geolocator.checkPermission();
      return switch (permiso) {
        LocationPermission.whileInUse ||
        LocationPermission.always => 'Disponible',
        LocationPermission.deniedForever => 'Permiso bloqueado en ajustes',
        _ => 'Permiso requerido',
      };
    } catch (_) {
      return 'Ubicación no disponible';
    }
  }

  // El permiso se solicita solo al intentar capturar la ubicación.
  Future<LecturaSensor> capturar() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationServiceDisabledException();
      }
      var permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
      }
      if (permiso == LocationPermission.deniedForever) {
        throw const ErrorUbicacion(
          'Habilita el permiso de ubicación en los ajustes de SensorTrack.',
          abrirAjustes: Geolocator.openAppSettings,
        );
      }
      if (permiso != LocationPermission.always &&
          permiso != LocationPermission.whileInUse) {
        throw const ErrorUbicacion(
          'Se necesita permiso de ubicación para capturar coordenadas.',
        );
      }

      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 18),
        ),
      );
      return LecturaSensor.ubicacion(
        latitud: posicion.latitude,
        longitud: posicion.longitude,
        precision: posicion.accuracy,
        fechaCaptura: posicion.timestamp,
      );
    } on ErrorUbicacion {
      rethrow;
    } on TimeoutException {
      throw const ErrorUbicacion(
        'El GPS tardó demasiado. Intenta de nuevo en un lugar despejado.',
      );
    } on LocationServiceDisabledException {
      throw const ErrorUbicacion(
        'Activa los servicios de ubicación del dispositivo.',
        abrirAjustes: Geolocator.openLocationSettings,
      );
    } catch (_) {
      throw const ErrorUbicacion(
        'No se pudo obtener la ubicación en este dispositivo.',
      );
    }
  }
}
