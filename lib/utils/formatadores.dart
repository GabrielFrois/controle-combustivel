/// Formata um número com vírgula decimal
String formatarNumero(double valor, {int casas = 2}) {
  return valor.toStringAsFixed(casas).replaceAll('.', ',');
}

/// Formata um valor em reais com duas casas
String formatarMoeda(double valor) {
  return 'R\$ ${formatarNumero(valor)}';
}

/// Preço por litro com três casas, como nas bombas
String formatarPrecoLitro(double valor) {
  return 'R\$ ${formatarNumero(valor, casas: 3)}';
}

String _doisDigitos(int numero) => numero.toString().padLeft(2, '0');

/// Formata data e horário
String formatarDataHora(DateTime data) {
  final dia = _doisDigitos(data.day);
  final mes = _doisDigitos(data.month);
  final hora = _doisDigitos(data.hour);
  final minuto = _doisDigitos(data.minute);

  return '$dia/$mes/${data.year} $hora:$minuto';
}

/// Data curta para os eixos dos gráficos
String formatarDataCurta(DateTime data) {
  return '${_doisDigitos(data.day)}/${_doisDigitos(data.month)}';
}