import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Marca de veículo retornada pela BrasilAPI - tabela FIPE.
class MarcaFipe {
  final String nome;

  /// Código usado para consultar os modelos da marca.
  final String codigo;

  const MarcaFipe({required this.nome, required this.codigo});
}

/// Erro com mensagem pronta para ser exibida ao usuário.
class ApiException implements Exception {
  final String mensagem;

  const ApiException(this.mensagem);

  @override
  String toString() => mensagem;
}

class BrasilApiService {
  static const String _base = 'https://brasilapi.com.br/api/fipe';

  // Apenas carros: o cadastro trabalha com um tipo de veículo.
  static const String _tipoVeiculo = 'carros';

  static const Duration _limiteEspera = Duration(seconds: 15);

  final http.Client _cliente;

  BrasilApiService({http.Client? cliente}) : _cliente = cliente ?? http.Client();

  /// GET /api/fipe/marcas/v1/carros -> [{"nome": "...", "valor": "..."}]
  Future<List<MarcaFipe>> listarMarcas() async {
    final dados = await _buscarLista('$_base/marcas/v1/$_tipoVeiculo');

    final marcas = dados.map((item) {
      final mapa = item as Map<String, dynamic>;

      return MarcaFipe(
        nome: mapa['nome'] as String,
        codigo: mapa['valor'].toString(),
      );
    }).toList();

    marcas.sort(
      (a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()),
    );

    return marcas;
  }

  /// GET /api/fipe/veiculos/v1/carros/{codigoMarca} -> [{"modelo": "..."}]
  Future<List<String>> listarModelos(String codigoMarca) async {
    final dados = await _buscarLista(
      '$_base/veiculos/v1/$_tipoVeiculo/$codigoMarca',
    );

    // O toSet remove nomes repetidos.
    final modelos = dados
        .map((item) => (item as Map<String, dynamic>)['modelo'] as String)
        .toSet()
        .toList();

    modelos.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return modelos;
  }

  Future<List<dynamic>> _buscarLista(String url) async {
    final http.Response resposta;

    try {
      resposta = await _cliente.get(Uri.parse(url)).timeout(_limiteEspera);
    } on TimeoutException {
      throw const ApiException('Tempo esgotado. Verifique sua conexão.');
    } catch (_) {
      throw const ApiException(
        'Não foi possível conectar. Verifique sua conexão.',
      );
    }

    if (resposta.statusCode != 200) {
      throw ApiException(
        'Serviço indisponível no momento (código ${resposta.statusCode}).',
      );
    }

    // bodyBytes + utf8 garante a acentuação correta.
    final corpo = jsonDecode(utf8.decode(resposta.bodyBytes));

    if (corpo is! List) {
      throw const ApiException('Resposta inesperada do serviço.');
    }

    return corpo;
  }

  void fechar() => _cliente.close();
}