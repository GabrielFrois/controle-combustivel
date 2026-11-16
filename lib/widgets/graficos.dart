import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/abastecimento.dart';
import '../utils/formatadores.dart';

const TextStyle _estiloEixo = TextStyle(fontSize: 10);
const TextStyle _estiloDica = TextStyle(color: Colors.white, fontSize: 12);

/// Intervalo entre rótulos do eixo X, para as datas não se sobreporem.
int _passoRotulos(int quantidade) => math.max(1, (quantidade / 5).ceil());

/// Rótulo (data curta) do eixo X. O valor do eixo é o índice do abastecimento.
Widget _rotuloData(double valor, List<Abastecimento> abastecimentos) {
  final indice = valor.toInt();
  final passo = _passoRotulos(abastecimentos.length);

  if (valor != indice.toDouble() ||
      indice < 0 ||
      indice >= abastecimentos.length ||
      indice % passo != 0) {
    return const SizedBox.shrink();
  }

  return Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Text(
      formatarDataCurta(abastecimentos[indice].dataHora),
      style: _estiloEixo,
    ),
  );
}

FlTitlesData _titulos({
  required List<Abastecimento> abastecimentos,
  required String Function(double) formatarEixo,
}) {
  return FlTitlesData(
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        interval: 1,
        getTitlesWidget: (valor, meta) => _rotuloData(valor, abastecimentos),
      ),
    ),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 48,
        getTitlesWidget: (valor, meta) {
          return Text(formatarEixo(valor), style: _estiloEixo);
        },
      ),
    ),
  );
}

/// Cartão com título e área de altura fixa para o gráfico.
class _CartaoGrafico extends StatelessWidget {
  final String titulo;
  final Widget grafico;

  const _CartaoGrafico({required this.titulo, required this.grafico});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 24, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(height: 220, child: grafico),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de linha. [valores] tem um item por abastecimento; os nulos
/// (como o abastecimento de referência) ficam fora da linha.
class GraficoLinha extends StatelessWidget {
  final String titulo;
  final List<Abastecimento> abastecimentos;
  final List<double?> valores;
  final String Function(double) formatarEixo;
  final String Function(double) formatarValor;
  final Color? cor;

  const GraficoLinha({
    super.key,
    required this.titulo,
    required this.abastecimentos,
    required this.valores,
    required this.formatarEixo,
    required this.formatarValor,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    final pontos = <FlSpot>[];

    for (var i = 0; i < valores.length; i++) {
      final valor = valores[i];

      if (valor != null) pontos.add(FlSpot(i.toDouble(), valor));
    }

    if (pontos.isEmpty) return const SizedBox.shrink();

    final menor = pontos.map((p) => p.y).reduce(math.min);
    final maior = pontos.map((p) => p.y).reduce(math.max);

    // Folga acima e abaixo
    final folga = maior == menor
        ? math.max(maior * 0.1, 0.5)
        : (maior - menor) * 0.2;

    return _CartaoGrafico(
      titulo: titulo,
      grafico: LineChart(
        LineChartData(
          minX: pontos.first.x - 1,
          maxX: pontos.last.x + 1,
          minY: math.max(0, menor - folga),
          maxY: maior + folga,
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: _titulos(
            abastecimentos: abastecimentos,
            formatarEixo: formatarEixo,
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (pontosToque) {
                return pontosToque.map((ponto) {
                  final abastecimento = abastecimentos[ponto.x.toInt()];

                  return LineTooltipItem(
                    '${formatarDataHora(abastecimento.dataHora)}\n'
                    '${abastecimento.combustivel.rotulo}: '
                    '${formatarValor(ponto.y)}',
                    _estiloDica,
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: pontos,
              isCurved: false,
              color: cor ?? Theme.of(context).colorScheme.primary,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gráfico de barras com um valor por abastecimento.
class GraficoBarras extends StatelessWidget {
  final String titulo;
  final List<Abastecimento> abastecimentos;
  final List<double> valores;
  final String Function(double) formatarEixo;
  final String Function(double) formatarValor;
  final Color? cor;

  const GraficoBarras({
    super.key,
    required this.titulo,
    required this.abastecimentos,
    required this.valores,
    required this.formatarEixo,
    required this.formatarValor,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    if (valores.isEmpty) return const SizedBox.shrink();

    final maior = valores.reduce(math.max);
    final corBarra = cor ?? Theme.of(context).colorScheme.primary;

    return _CartaoGrafico(
      titulo: titulo,
      grafico: BarChart(
        BarChartData(
          minY: 0,
          maxY: maior * 1.2,
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: _titulos(
            abastecimentos: abastecimentos,
            formatarEixo: formatarEixo,
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (grupo, indiceGrupo, haste, indiceHaste) {
                final abastecimento = abastecimentos[grupo.x];

                return BarTooltipItem(
                  '${formatarDataHora(abastecimento.dataHora)}\n'
                  '${abastecimento.combustivel.rotulo}: '
                  '${formatarValor(haste.toY)}',
                  _estiloDica,
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < valores.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: valores[i],
                    width: valores.length > 15 ? 6 : 14,
                    color: corBarra,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}