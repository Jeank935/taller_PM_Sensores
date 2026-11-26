import 'package:material_ui/material_ui.dart';

import '../models/lectura_sensor.dart';

typedef GuardarLectura = Future<bool> Function(LecturaSensor lectura);

const colorFondo = Color(0xFF0D1520);
const colorPanel = Color(0xFF172432);
const colorBorde = Color(0xFF2A3B4A);
const verdeMenta = Color(0xFF64E2B5);
const colorTextoSecundario = Color(0xFFB2C3CD);
const ambar = Color(0xFFFFCC83);

String formatearMedicion(double? valor, [int decimales = 2]) =>
    valor?.toStringAsFixed(decimales) ?? '—';

String formatearFechaYHora(BuildContext contexto, DateTime? valor) {
  if (valor == null) return 'Fecha no registrada';
  final local = valor.toLocal();
  final fecha = MaterialLocalizations.of(contexto).formatShortDate(local);
  return '$fecha · ${formatearHora(local)}';
}

String formatearHora(DateTime valor) {
  final local = valor.toLocal();
  return [
    local.hour,
    local.minute,
    local.second,
  ].map((parte) => parte.toString().padLeft(2, '0')).join(':');
}

class ContenidoPagina extends StatelessWidget {
  const ContenidoPagina({
    super.key,
    required this.elementos,
    this.alActualizar,
  });

  final List<Widget> elementos;
  final RefreshCallback? alActualizar;

  @override
  Widget build(BuildContext contexto) {
    final lista = ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      children: elementos,
    );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: alActualizar == null
            ? lista
            : RefreshIndicator(onRefresh: alActualizar!, child: lista),
      ),
    );
  }
}

class EncabezadoPagina extends StatelessWidget {
  const EncabezadoPagina(this.titulo, this.descripcion, {super.key});

  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext contexto) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: Theme.of(contexto).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(descripcion, style: const TextStyle(color: colorTextoSecundario)),
      ],
    ),
  );
}

class Panel extends StatelessWidget {
  const Panel({super.key, required this.contenido});

  final Widget contenido;

  @override
  Widget build(BuildContext contexto) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Material(
      color: colorPanel,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: colorBorde),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: contenido),
    ),
  );
}

class IconoSensor extends StatelessWidget {
  const IconoSensor(this.icono, {super.key});

  final IconData icono;

  @override
  Widget build(BuildContext contexto) => DecoratedBox(
    decoration: BoxDecoration(
      color: verdeMenta.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: const EdgeInsets.all(10),
      child: Icon(icono, color: verdeMenta, size: 22),
    ),
  );
}

class PanelMensaje extends StatelessWidget {
  const PanelMensaje({
    super.key,
    required this.icono,
    required this.titulo,
    this.mensaje,
    this.accion,
  });

  final IconData icono;
  final String titulo;
  final String? mensaje;
  final Widget? accion;

  @override
  Widget build(BuildContext contexto) => Panel(
    contenido: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconoSensor(icono),
        const SizedBox(height: 10),
        Text(
          titulo,
          textAlign: TextAlign.center,
          style: Theme.of(contexto).textTheme.titleMedium,
        ),
        if (mensaje case final texto?) ...[
          const SizedBox(height: 5),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: const TextStyle(color: colorTextoSecundario),
          ),
        ],
        if (accion case final boton?) ...[const SizedBox(height: 12), boton],
      ],
    ),
  );
}

class ValoresLectura extends StatelessWidget {
  const ValoresLectura(this.lectura, {super.key, this.compacto = false});

  final LecturaSensor lectura;
  final bool compacto;

  @override
  Widget build(BuildContext contexto) {
    if (lectura.tipo == TipoSensor.gps) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DatoSensor('Latitud', formatearMedicion(lectura.latitud, 6)),
          DatoSensor('Longitud', formatearMedicion(lectura.longitud, 6)),
          DatoSensor('Precisión', '${formatearMedicion(lectura.precision)} m'),
        ],
      );
    }
    if (compacto) {
      return Text(
        'X ${formatearMedicion(lectura.x)}   Y ${formatearMedicion(lectura.y)}   '
        'Z ${formatearMedicion(lectura.z)} ${lectura.tipo.unidad}',
      );
    }
    return Row(
      children: [
        for (final (etiqueta, valor) in [
          ('X', lectura.x),
          ('Y', lectura.y),
          ('Z', lectura.z),
        ])
          Expanded(
            child: DatoSensor(
              etiqueta,
              formatearMedicion(valor),
              vertical: true,
            ),
          ),
      ],
    );
  }
}

class DatoSensor extends StatelessWidget {
  const DatoSensor(
    this.etiqueta,
    this.valor, {
    super.key,
    this.vertical = false,
  });

  final String etiqueta;
  final String valor;
  final bool vertical;

  @override
  Widget build(BuildContext contexto) {
    final textoValor = Text(
      valor,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
    final textoEtiqueta = Text(
      etiqueta,
      style: const TextStyle(color: colorTextoSecundario),
    );
    if (vertical) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        child: Column(
          children: [textoEtiqueta, const SizedBox(height: 4), textoValor],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: textoEtiqueta),
          const SizedBox(width: 8),
          Flexible(child: textoValor),
        ],
      ),
    );
  }
}
