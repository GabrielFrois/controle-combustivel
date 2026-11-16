class Veiculo {
  final int? id;
  final String marca;
  final String modelo;
  final int ano;

  /// Cilindrada do motor em litros
  final double cilindrada;

  const Veiculo({
    this.id,
    required this.marca,
    required this.modelo,
    required this.ano,
    required this.cilindrada,
  });

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'marca': marca,
      'modelo': modelo,
      'ano': ano,
      'cilindrada': cilindrada,
    };
  }

  factory Veiculo.fromMap(Map<String, Object?> mapa) {
    return Veiculo(
      id: mapa['id'] as int,
      marca: mapa['marca'] as String,
      modelo: mapa['modelo'] as String,
      ano: mapa['ano'] as int,
      cilindrada: (mapa['cilindrada'] as num).toDouble(),
    );
  }
}