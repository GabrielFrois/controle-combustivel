import '../models/abastecimento.dart';

/// Indicadores de um abastecimento em relação ao anterior.
/// O primeiro abastecimento é só referência: os três campos ficam nulos.
class Indicador {
  final Abastecimento abastecimento;

  /// Quilometragem atual menos a do abastecimento anterior.
  final double? distancia;

  /// Distância percorrida dividida pelos litros do abastecimento atual.
  final double? consumo;

  /// Valor total do abastecimento atual dividido pela distância percorrida.
  final double? custoPorKm;

  const Indicador({
    required this.abastecimento,
    this.distancia,
    this.consumo,
    this.custoPorKm,
  });
}

/// Calcula os indicadores seguindo a regra do enunciado: todos os registros completam o tanque.
List<Indicador> calcularIndicadores(List<Abastecimento> abastecimentos) {
  final resultado = <Indicador>[];

  for (var i = 0; i < abastecimentos.length; i++) {
    final atual = abastecimentos[i];

    // O primeiro serve de referência inicial.
    if (i == 0) {
      resultado.add(Indicador(abastecimento: atual));
      continue;
    }

    final anterior = abastecimentos[i - 1];
    final distancia = (atual.quilometragem - anterior.quilometragem).toDouble();

    // Proteção contra divisão por zero ou distância negativa.
    if (distancia <= 0) {
      resultado.add(Indicador(abastecimento: atual));
      continue;
    }

    resultado.add(
      Indicador(
        abastecimento: atual,
        distancia: distancia,
        consumo: distancia / atual.litros,
        custoPorKm: atual.valorTotal / distancia,
      ),
    );
  }

  return resultado;
}

class ResumoGastos {
  final double gastoTotal;

  /// Distância total / litros totais, ignorando o abastecimento de referência.
  final double? consumoMedio;

  /// Gasto / distância total, ignorando o abastecimento de referência.
  final double? custoMedioPorKm;

  const ResumoGastos({
    required this.gastoTotal,
    this.consumoMedio,
    this.custoMedioPorKm,
  });
}

ResumoGastos calcularResumo(List<Indicador> indicadores) {
  var gastoTotal = 0.0;
  var distanciaTotal = 0.0;
  var litrosComIndicador = 0.0;
  var gastoComIndicador = 0.0;

  for (final indicador in indicadores) {
    final abastecimento = indicador.abastecimento;
    final distancia = indicador.distancia;

    gastoTotal += abastecimento.valorTotal;

    if (distancia != null) {
      distanciaTotal += distancia;
      litrosComIndicador += abastecimento.litros;
      gastoComIndicador += abastecimento.valorTotal;
    }
  }

  return ResumoGastos(
    gastoTotal: gastoTotal,
    consumoMedio:
        distanciaTotal > 0 ? distanciaTotal / litrosComIndicador : null,
    custoMedioPorKm:
        distanciaTotal > 0 ? gastoComIndicador / distanciaTotal : null,
  );
}