import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:controle_combustivel/models/abastecimento.dart';
import 'package:controle_combustivel/telas/tela_novo_abastecimento.dart';

Widget _criarTela({List<Abastecimento> existentes = const []}) {
  return MaterialApp(
    home: TelaNovoAbastecimento(veiculoId: 1, abastecimentos: existentes),
  );
}

/// Aumenta a tela de teste para o formulário inteiro ficar visível.
Future<void> _telaGrande(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  // Ordem dos campos: preço (0), quilometragem (1), litros (2), data (3).
  final campos = find.byType(TextFormField);
  final botaoSalvar = find.text('Salvar abastecimento');

  testWidgets('campos vazios mostram as mensagens de erro', (tester) async {
    await _telaGrande(tester);
    await tester.pumpWidget(_criarTela());

    await tester.tap(botaoSalvar);
    await tester.pumpAndSettle();

    expect(find.text('Informe o preço por litro.'), findsOneWidget);
    expect(find.text('Informe a quilometragem.'), findsOneWidget);
    expect(find.text('Informe a quantidade de litros.'), findsOneWidget);
  });

  testWidgets('quilometragem menor que a anterior é recusada', (tester) async {
    await _telaGrande(tester);

    final anterior = Abastecimento(
      id: 1,
      veiculoId: 1,
      combustivel: Combustivel.gasolina,
      precoLitro: 5.8,
      quilometragem: 10000,
      litros: 40,
      dataHora: DateTime(2026, 11, 1, 10, 0),
    );

    await tester.pumpWidget(_criarTela(existentes: [anterior]));

    await tester.enterText(campos.at(0), '5.89');
    await tester.enterText(campos.at(1), '9000');
    await tester.enterText(campos.at(2), '40');

    await tester.tap(botaoSalvar);
    await tester.pumpAndSettle();

    expect(find.textContaining('Deve ser maior que 10000 km'), findsOneWidget);
  });

  testWidgets('o valor total aparece ao digitar preço e litros',
      (tester) async {
    await _telaGrande(tester);
    await tester.pumpWidget(_criarTela());

    expect(find.text('—'), findsOneWidget);

    await tester.enterText(campos.at(0), '5.90');
    await tester.enterText(campos.at(2), '10');
    await tester.pump();

    expect(find.text('R\$ 59,00'), findsOneWidget);
  });
}