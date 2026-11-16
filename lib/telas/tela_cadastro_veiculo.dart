import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/banco_app.dart';
import '../models/veiculo.dart';
import '../services/brasil_api_service.dart';

class TelaCadastroVeiculo extends StatefulWidget {
  /// Chamado depois que o veículo é salvo com sucesso.
  final VoidCallback aoCadastrar;

  const TelaCadastroVeiculo({super.key, required this.aoCadastrar});

  @override
  State<TelaCadastroVeiculo> createState() => _TelaCadastroVeiculoState();
}

class _TelaCadastroVeiculoState extends State<TelaCadastroVeiculo> {
  final _formKey = GlobalKey<FormState>();
  final _api = BrasilApiService();

  final _anoController = TextEditingController();
  final _cilindradaController = TextEditingController();

  List<MarcaFipe> _marcas = [];
  List<String> _modelos = [];
  MarcaFipe? _marcaSelecionada;
  String? _modeloSelecionado;

  bool _carregandoMarcas = true;
  bool _carregandoModelos = false;
  bool _salvando = false;

  // Falhas ao consultar a API.
  String? _erroMarcas;
  String? _erroModelos;

  // Mensagens de validação dos campos de seleção.
  String? _erroCampoMarca;
  String? _erroCampoModelo;

  @override
  void initState() {
    super.initState();
    _carregarMarcas();
  }

  String _mensagemDeErro(Object erro) {
    if (erro is ApiException) return erro.mensagem;

    return 'Não foi possível carregar os dados.';
  }

  Future<void> _carregarMarcas() async {
    setState(() {
      _carregandoMarcas = true;
      _erroMarcas = null;
    });

    try {
      final marcas = await _api.listarMarcas();

      if (!mounted) return;

      setState(() => _marcas = marcas);
    } catch (erro, stackTrace) {
      debugPrint('Erro ao carregar marcas: $erro');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => _erroMarcas = _mensagemDeErro(erro));
    } finally {
      if (mounted) setState(() => _carregandoMarcas = false);
    }
  }

  Future<void> _carregarModelos(MarcaFipe marca) async {
    setState(() {
      _carregandoModelos = true;
      _erroModelos = null;
      _modelos = [];
    });

    try {
      final modelos = await _api.listarModelos(marca.codigo);

      // Ignora a resposta se o usuário trocou de marca enquanto aguardava.
      if (!mounted || _marcaSelecionada != marca) return;

      setState(() => _modelos = modelos);
    } catch (erro, stackTrace) {
      debugPrint('Erro ao carregar modelos: $erro');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted || _marcaSelecionada != marca) return;

      setState(() => _erroModelos = _mensagemDeErro(erro));
    } finally {
      if (mounted && _marcaSelecionada == marca) {
        setState(() => _carregandoModelos = false);
      }
    }
  }

  void _selecionarMarca(MarcaFipe? marca) {
    if (marca == null || marca == _marcaSelecionada) return;

    setState(() {
      _marcaSelecionada = marca;
      _modeloSelecionado = null;
      _modelos = [];
      _erroCampoMarca = null;
      _erroCampoModelo = null;
    });

    _carregarModelos(marca);
  }

  void _selecionarModelo(String? modelo) {
    if (modelo == null) return;

    setState(() {
      _modeloSelecionado = modelo;
      _erroCampoModelo = null;
    });
  }

  // Aceita "1.6" ou "1,6".
  double? _converterCilindrada(String texto) {
    return double.tryParse(texto.trim().replaceAll(',', '.'));
  }

  String? _validarAno(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Informe o ano.';
    }

    final ano = int.tryParse(texto);
    final anoMaximo = DateTime.now().year + 1;

    if (ano == null || ano < 1900 || ano > anoMaximo) {
      return 'Informe um ano entre 1900 e $anoMaximo.';
    }

    return null;
  }

  String? _validarCilindrada(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Informe a cilindrada.';
    }

    final cilindrada = _converterCilindrada(texto);

    if (cilindrada == null || cilindrada <= 0 || cilindrada > 10) {
      return 'Informe a cilindrada em litros, como 1.6.';
    }

    return null;
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    final formularioValido = _formKey.currentState!.validate();
    final marca = _marcaSelecionada;
    final modelo = _modeloSelecionado;

    setState(() {
      _erroCampoMarca = marca == null ? 'Selecione a marca.' : null;
      _erroCampoModelo = modelo == null ? 'Selecione o modelo.' : null;
    });

    if (!formularioValido || marca == null || modelo == null) return;

    FocusScope.of(context).unfocus();

    final veiculo = Veiculo(
      marca: marca.nome,
      modelo: modelo,
      ano: int.parse(_anoController.text.trim()),
      cilindrada: _converterCilindrada(_cilindradaController.text)!,
    );

    setState(() => _salvando = true);

    try {
      await BancoApp.instancia.inserirVeiculo(veiculo);

      if (!mounted) return;

      widget.aoCadastrar();
    } catch (erro, stackTrace) {
      debugPrint('Erro ao salvar o veículo: $erro');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o veículo.')),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  void dispose() {
    _anoController.dispose();
    _cilindradaController.dispose();
    _api.fechar();

    super.dispose();
  }

  Widget _campoMarca() {
    if (_carregandoMarcas) {
      return const _Carregando(mensagem: 'Carregando marcas...');
    }

    if (_erroMarcas != null) {
      return _ErroComNovaTentativa(
        mensagem: _erroMarcas!,
        aoTentarNovamente: _carregarMarcas,
      );
    }

    return DropdownMenu<MarcaFipe>(
      expandedInsets: EdgeInsets.zero,
      label: const Text('Marca'),
      enableFilter: true,
      requestFocusOnTap: true,
      menuHeight: 300,
      initialSelection: _marcaSelecionada,
      errorText: _erroCampoMarca,
      dropdownMenuEntries: _marcas
          .map((marca) => DropdownMenuEntry<MarcaFipe>(
                value: marca,
                label: marca.nome,
              ))
          .toList(),
      onSelected: _selecionarMarca,
    );
  }

  Widget _campoModelo() {
    final marca = _marcaSelecionada;

    if (marca == null) {
      return DropdownMenu<String>(
        expandedInsets: EdgeInsets.zero,
        label: const Text('Modelo'),
        enabled: false,
        errorText: _erroCampoModelo,
        dropdownMenuEntries: const <DropdownMenuEntry<String>>[],
      );
    }

    if (_carregandoModelos) {
      return const _Carregando(mensagem: 'Carregando modelos...');
    }

    if (_erroModelos != null) {
      return _ErroComNovaTentativa(
        mensagem: _erroModelos!,
        aoTentarNovamente: () => _carregarModelos(marca),
      );
    }

    return DropdownMenu<String>(
      // A chave recria o campo (e limpa o texto) quando a marca muda.
      key: ValueKey(marca.codigo),
      expandedInsets: EdgeInsets.zero,
      label: const Text('Modelo'),
      enableFilter: true,
      requestFocusOnTap: true,
      menuHeight: 300,
      errorText: _erroCampoModelo,
      dropdownMenuEntries: _modelos
          .map((modelo) => DropdownMenuEntry<String>(
                value: modelo,
                label: modelo,
              ))
          .toList(),
      onSelected: _selecionarModelo,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastrar veículo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Informe os dados do veículo.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              _campoMarca(),
              const SizedBox(height: 16),
              _campoModelo(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _anoController,
                decoration: const InputDecoration(
                  labelText: 'Ano',
                  hintText: 'Ex.: 2018',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                validator: _validarAno,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cilindradaController,
                decoration: const InputDecoration(
                  labelText: 'Cilindrada do motor (litros)',
                  hintText: 'Ex.: 1.6',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                validator: _validarCilindrada,
                onFieldSubmitted: (_) => _salvar(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _salvando ? null : _salvar,
                child: _salvando
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Salvar veículo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Carregando extends StatelessWidget {
  final String mensagem;

  const _Carregando({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(mensagem),
        ],
      ),
    );
  }
}

class _ErroComNovaTentativa extends StatelessWidget {
  final String mensagem;
  final VoidCallback aoTentarNovamente;

  const _ErroComNovaTentativa({
    required this.mensagem,
    required this.aoTentarNovamente,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          mensagem,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        TextButton(
          onPressed: aoTentarNovamente,
          child: const Text('Tentar novamente'),
        ),
      ],
    );
  }
}