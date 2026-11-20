import 'package:flutter_test/flutter_test.dart';
import 'package:controle_combustivel/models/abastecimento.dart';
import 'package:controle_combustivel/utils/formatadores.dart';
import 'package:controle_combustivel/utils/indicadores.dart';

Abastecimento _abastecimento({
  required int km,
  required double litros,
  required double preco,
  int dia = 1,
  Combustivel combustivel = Combustivel.gasolina,
}) {
  return Abastecimento(
    veiculoId: 1,
    combustivel: combustivel,
    precoLitro: preco,
    quilometragem: km,
    litros: litros,
    dataHora: DateTime(2026, 11, dia, 10, 0),
  );
}

void main() {
  group('Abastecimento', () {
    test('valorTotal é o preço por litro vezes os litros', () {
      final abastecimento = _abastecimento(km: 10000, litros: 40, preco: 5.8);

      expect(abastecimento.valorTotal, closeTo(232.0, 0.001));
    });

    test('toMap e fromMap preservam os dados', () {
      final original = Abastecimento(
        id: 1,
        veiculoId: 1,
        combustivel: Combustivel.etanol,
        precoLitro: 4.2,
        quilometragem: 10880,
        litros: 39,
        dataHora: DateTime(2026, 11, 13, 18, 30),
      );

      final copia = Abastecimento.fromMap(original.toMap());

      expect(copia.combustivel, Combustivel.etanol);
      expect(copia.precoLitro, 4.2);
      expect(copia.quilometragem, 10880);
      expect(copia.litros, 39);
      expect(copia.dataHora.isAtSameMomentAs(original.dataHora), isTrue);
    });
  });

  group('calcularIndicadores', () {
    test('o primeiro abastecimento é só referência', () {
      final indicadores = calcularIndicadores([
        _abastecimento(km: 10000, litros: 40, preco: 5.8),
      ]);

      expect(indicadores.first.distancia, isNull);
      expect(indicadores.first.consumo, isNull);
      expect(indicadores.first.custoPorKm, isNull);
    });

    test('calcula distância, km/L e R\$/km a partir do segundo', () {
      final indicadores = calcularIndicadores([
        _abastecimento(km: 10000, litros: 40, preco: 5.8, dia: 1),
        _abastecimento(km: 10450, litros: 38, preco: 5.9, dia: 5),
      ]);

      final segundo = indicadores[1];

      expect(segundo.distancia, 450);
      expect(segundo.consumo, closeTo(450 / 38, 0.0001));
      expect(segundo.custoPorKm, closeTo((38 * 5.9) / 450, 0.0001));
    });

    test('distância zero ou negativa não gera indicadores', () {
      final indicadores = calcularIndicadores([
        _abastecimento(km: 10000, litros: 40, preco: 5.8, dia: 1),
        _abastecimento(km: 10000, litros: 38, preco: 5.9, dia: 5),
      ]);

      expect(indicadores[1].consumo, isNull);
      expect(indicadores[1].custoPorKm, isNull);
    });
  });

  group('calcularResumo', () {
    test('usa médias ponderadas e ignora o abastecimento de referência', () {
      final indicadores = calcularIndicadores([
        _abastecimento(km: 10000, litros: 40, preco: 5.8, dia: 1),
        _abastecimento(km: 10450, litros: 38, preco: 5.9, dia: 5),
        _abastecimento(km: 10880, litros: 39, preco: 4.2, dia: 10),
      ]);

      final resumo = calcularResumo(indicadores);

      // 40 * 5,8 + 38 * 5,9 + 39 * 4,2
      expect(resumo.gastoTotal, closeTo(620.0, 0.001));
      // (450 + 430) km / (38 + 39) L
      expect(resumo.consumoMedio, closeTo(880 / 77, 0.001));
      // (224,2 + 163,8) / 880 km
      expect(resumo.custoMedioPorKm, closeTo(388 / 880, 0.001));
    });

    test('com um único abastecimento não há médias', () {
      final resumo = calcularResumo(
        calcularIndicadores([
          _abastecimento(km: 10000, litros: 40, preco: 5.8),
        ]),
      );

      expect(resumo.consumoMedio, isNull);
      expect(resumo.custoMedioPorKm, isNull);
    });
  });

  group('formatadores', () {
    test('formatam moeda, número e preço por litro', () {
      expect(formatarMoeda(5.9), 'R\$ 5,90');
      expect(formatarNumero(11.8421), '11,84');
      expect(formatarPrecoLitro(5.899), 'R\$ 5,899');
    });

    test('formatam data e horário', () {
      final data = DateTime(2026, 11, 13, 18, 30);

      expect(formatarDataHora(data), '13/11/2026 18:30');
      expect(formatarDataCurta(data), '13/11');
    });
  });
}