import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../models/lectura_sensor.dart';
import 'componentes.dart';

class GraficoSensor extends StatelessWidget {
  const GraficoSensor({super.key, required this.tipo, required this.lecturas});

  final TipoSensor tipo;
  final List<LecturaSensor> lecturas;

  @override
  Widget build(BuildContext contexto) {
    final esGps = tipo == TipoSensor.gps;
    final etiquetas = esGps ? ['Precisión (m)'] : ['X', 'Y', 'Z'];
    const colores = [azul, verde, naranja];
    final series = [
      for (var eje = 0; eje < etiquetas.length; eje++)
        [
          for (final (indice, lectura) in lecturas.indexed)
            switch (esGps
                ? lectura.precision
                : [lectura.x, lectura.y, lectura.z][eje]) {
              final valor? when valor.isFinite => FlSpot(
                indice.toDouble(),
                valor,
              ),
              _ => FlSpot.nullSpot,
            },
        ],
    ];
    final valores = series
        .expand((puntos) => puntos)
        .where((punto) => !punto.isNull())
        .map((punto) => punto.y)
        .toList();
    if (valores.isEmpty) {
      return const Text(
        'Las mediciones todavía no tienen valores para graficar.',
      );
    }
    final minimo = valores.reduce(math.min);
    final maximo = valores.reduce(math.max);
    final margen = math.max((maximo - minimo) * 0.12, 0.1);
    final ultimoIndice = lecturas.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Últimas ${lecturas.length} ${lecturas.length == 1 ? 'captura' : 'capturas'} · ${tipo.unidad}',
          style: const TextStyle(color: colorTextoSecundario),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 6,
          children: [
            for (final (indice, etiqueta) in etiquetas.indexed)
              Text(
                etiqueta,
                style: TextStyle(
                  color: colores[indice],
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 205,
          child: LineChart(
            LineChartData(
              minX: 0,
              maxX: math.max(1, ultimoIndice).toDouble(),
              minY: minimo - margen,
              maxY: maximo + margen,
              clipData: const FlClipData.all(),
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: colorBorde),
              ),
              titlesData: const FlTitlesData(
                rightTitles: AxisTitles(),
                topTitles: AxisTitles(),
                bottomTitles: AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 46),
                ),
              ),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => colorFondo,
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (puntosMarcados) => [
                    for (final (indice, puntoMarcado) in puntosMarcados.indexed)
                      LineTooltipItem(
                        '${indice == 0 ? '${formatearFechaYHora(contexto, lecturas[puntoMarcado.x.toInt()].fechaCaptura)}\n' : ''}'
                        '${etiquetas[puntoMarcado.barIndex]} ${formatearMedicion(puntoMarcado.y)}',
                        TextStyle(color: colores[puntoMarcado.barIndex]),
                      ),
                  ],
                ),
              ),
              lineBarsData: [
                for (final (indice, puntos) in series.indexed)
                  LineChartBarData(
                    spots: puntos,
                    color: colores[indice],
                    barWidth: 2,
                    dotData: FlDotData(show: lecturas.length <= 12),
                  ),
              ],
            ),
          ),
        ),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: 12,
          runSpacing: 4,
          children: [
            Text(
              formatearFechaYHora(contexto, lecturas.first.fechaCaptura),
              style: const TextStyle(color: colorTextoSecundario),
            ),
            if (ultimoIndice > 0)
              Text(
                formatearFechaYHora(contexto, lecturas.last.fechaCaptura),
                style: const TextStyle(color: colorTextoSecundario),
              ),
          ],
        ),
      ],
    );
  }
}
