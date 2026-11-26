import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/lectura_sensor.dart';

class SupabaseService {
  SupabaseService(this._cliente, {required this.errorConfiguracion});

  static Future<SupabaseService> inicializar() async {
    const url = String.fromEnvironment('SUPABASE_URL');
    const clavePublica = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    if (url.isEmpty || clavePublica.isEmpty) {
      return SupabaseService(
        null,
        errorConfiguracion: 'Faltan la URL y la clave pública de Supabase.',
      );
    }

    try {
      final instancia = await Supabase.initialize(
        url: url,
        publishableKey: clavePublica,
      );
      return SupabaseService(instancia.client, errorConfiguracion: null);
    } catch (_) {
      return SupabaseService(
        null,
        errorConfiguracion:
            'No se pudo inicializar Supabase. Revisa la configuración.',
      );
    }
  }

  static const tamanoPaginaHistorial = 25;
  static const _tabla = 'sensor_readings';
  static const _columnas =
      'id,sensor_type,x,y,z,latitude,longitude,accuracy,recorded_at';
  static const _tiempoLimite = Duration(seconds: 15);

  final SupabaseClient? _cliente;
  final String? errorConfiguracion;
  Future<void>? _inicioSesion;

  Future<void> comprobarConexion() async {
    final cliente = await _obtenerClienteAutenticado();
    await cliente.from(_tabla).select('id').limit(1).timeout(_tiempoLimite);
  }

  Future<void> guardarLectura(LecturaSensor lectura) async {
    final cliente = await _obtenerClienteAutenticado();
    await cliente
        .from(_tabla)
        .upsert(
          lectura.aJson(),
          onConflict: 'id',
          ignoreDuplicates: true,
          defaultToNull: false,
        )
        .timeout(_tiempoLimite);
  }

  Future<List<LecturaSensor>> consultarHistorial({
    int desplazamiento = 0,
  }) async {
    final cliente = await _obtenerClienteAutenticado();
    final filas = await cliente
        .from(_tabla)
        .select(_columnas)
        .order('recorded_at', ascending: false)
        .order('id', ascending: false)
        .range(desplazamiento, desplazamiento + tamanoPaginaHistorial - 1)
        .timeout(_tiempoLimite);
    return filas.map(LecturaSensor.desdeJson).toList();
  }

  Future<ResumenSensores> consultarEstadisticas() async {
    final cliente = await _obtenerClienteAutenticado();
    final resumen = await cliente
        .rpc('sensor_statistics')
        .timeout(_tiempoLimite);
    return ResumenSensores.desdeJson(resumen as Map<String, dynamic>);
  }

  Future<List<LecturaSensor>> consultarEvolucion(TipoSensor tipo) async {
    final cliente = await _obtenerClienteAutenticado();
    final filas = await cliente
        .from(_tabla)
        .select(_columnas)
        .eq('sensor_type', tipo.valor)
        .not('recorded_at', 'is', null)
        .order('recorded_at', ascending: false)
        .order('id', ascending: false)
        .limit(30)
        .timeout(_tiempoLimite);
    return filas.reversed.map(LecturaSensor.desdeJson).toList();
  }

  Future<SupabaseClient> _obtenerClienteAutenticado() async {
    final cliente = _cliente;
    if (cliente == null) {
      throw StateError(errorConfiguracion ?? 'Supabase sin configurar.');
    }
    final sesion = cliente.auth.currentSession;
    if (sesion == null || sesion.isExpired) {
      await (_inicioSesion ??= _abrirSesion(cliente));
    }
    return cliente;
  }

  Future<void> _abrirSesion(SupabaseClient cliente) async {
    try {
      if (cliente.auth.currentSession == null) {
        await cliente.auth.signInAnonymously().timeout(_tiempoLimite);
      } else {
        await cliente.auth.refreshSession().timeout(_tiempoLimite);
      }
    } finally {
      _inicioSesion = null;
    }
  }

  String mensajeDeError(Object error) {
    if (errorConfiguracion case final mensaje?) return mensaje;
    if (error is TimeoutException) {
      return 'Supabase tardó demasiado en responder. Intenta nuevamente.';
    }
    if (error is AuthException) {
      if (error.code == 'anonymous_provider_disabled') {
        return 'Activa los inicios de sesión anónimos en Supabase.';
      }
      return 'No se pudo iniciar la sesión de Supabase. ${error.message}';
    }
    if (error is PostgrestException) {
      return switch (error.code) {
        '42501' =>
          'Revisa los permisos y las políticas RLS de sensor_readings.',
        'PGRST202' || 'PGRST205' || '42P01' || '42883' =>
          'Falta instalar la tabla o la función de estadísticas en Supabase.',
        _ => 'Supabase rechazó la operación. ${error.message}',
      };
    }
    return 'No se pudo completar la operación. Comprueba tu conexión y reintenta.';
  }
}
