import 'package:material_ui/material_ui.dart';

import '../models/lectura_sensor.dart';
import '../widgets/componentes.dart';

class PaginaDetalles extends StatelessWidget {
  const PaginaDetalles({super.key, required this.lectura});

  final LecturaSensor lectura;

  @override
  Widget build(BuildContext contexto) => Scaffold(
    appBar: AppBar(title: const Text('Detalle de medición')),
    body: SafeArea(
      child: ContenidoPagina(
        elementos: [
          EncabezadoPagina(
            lectura.tipo.etiqueta,
            formatearFechaYHora(contexto, lectura.fechaCaptura),
          ),
          Panel(contenido: ValoresLectura(lectura, compacto: true)),
          SelectableText(
            'ID ${lectura.id}',
            style: const TextStyle(color: colorTextoSecundario),
          ),
        ],
      ),
    ),
  );
}
