enum Combustivel {
  etanol('Etanol'),
  gasolina('Gasolina'),
  diesel('Diesel');

  final String rotulo;

  const Combustivel(this.rotulo);
}

class Abastecimento {
  final int? id;
  final int veiculoId;
  final Combustivel combustivel;

  /// Preço por litro em reais.
  final double precoLitro;

  /// Quilometragem do veículo no momento do abastecimento.
  final int quilometragem;

  final double litros;
  final DateTime dataHora;

  const Abastecimento({
    this.id,
    required this.veiculoId,
    required this.combustivel,
    required this.precoLitro,
    required this.quilometragem,
    required this.litros,
    required this.dataHora,
  });

  /// Valor total do abastecimento
  double get valorTotal => precoLitro * litros;

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'veiculo_id': veiculoId,
      'combustivel': combustivel.name,
      'preco_litro': precoLitro,
      'quilometragem': quilometragem,
      'litros': litros,
      'data_hora': dataHora.toUtc().toIso8601String(),
    };
  }

  factory Abastecimento.fromMap(Map<String, Object?> mapa) {
    return Abastecimento(
      id: mapa['id'] as int,
      veiculoId: mapa['veiculo_id'] as int,
      combustivel: Combustivel.values.byName(mapa['combustivel'] as String),
      precoLitro: (mapa['preco_litro'] as num).toDouble(),
      quilometragem: mapa['quilometragem'] as int,
      litros: (mapa['litros'] as num).toDouble(),
      dataHora: DateTime.parse(mapa['data_hora'] as String).toLocal(),
    );
  }
}