import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../database/banco_app.dart';
import '../models/abastecimento.dart';
import '../utils/formatadores.dart';

class TelaNovoAbastecimento extends StatefulWidget {
  final int veiculoId;

  // Abastecimentos já registrados, em ordem cronológica. Usados para validar a 
  // quilometragem em relação ao abastecimento anterior e ao seguinte.
  final List<Abastecimento> abastecimentos;

  const TelaNovoAbastecimento({
    super.key,
    required this.veiculoId,
    required this.abastecimentos,
  });

  @override
  State<TelaNovoAbastecimento> createState() => _TelaNovoAbastecimentoState();
}

class _TelaNovoAbastecimentoState extends State<TelaNovoAbastecimento> {
  final _formKey = GlobalKey<FormState>();

  final _precoController = TextEditingController();
  final _quilometragemController = TextEditingController();
  final _litrosController = TextEditingController();
  final _dataHoraController = TextEditingController();

  Combustivel _combustivel = Combustivel.gasolina;
  DateTime? _dataHora;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();

    // Começa com a data e o horário atuais.
    final agora = DateTime.now();
    _dataHora = agora;
    _dataHoraController.text = formatarDataHora(agora);
  }

  // Aceita "5.89" ou "5,89".
  double? _converter(String texto) {
    return double.tryParse(texto.trim().replaceAll(',', '.'));
  }

  /// Valor total em tempo real: preço por litro x litros.
  double? get _valorTotalPrevisto {
    final preco = _converter(_precoController.text);
    final litros = _converter(_litrosController.text);

    if (preco == null || litros == null) return null;

    return preco * litros;
  }

  Future<void> _selecionarDataHora() async {
    final atual = _dataHora ?? DateTime.now();

    final data = await showDatePicker(
      context: context,
      initialDate: atual,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (data == null || !mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(atual),
    );

    if (hora == null || !mounted) return;

    final selecionada = DateTime(
      data.year,
      data.month,
      data.day,
      hora.hour,
      hora.minute,
    );

    setState(() {
      _dataHora = selecionada;
      _dataHoraController.text = formatarDataHora(selecionada);
    });
  }

  String? _validarPreco(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Informe o preço por litro.';
    }

    final preco = _converter(texto);

    if (preco == null || preco <= 0 || preco > 100) {
      return 'Informe um preço válido, como 5.89.';
    }

    return null;
  }

  String? _validarLitros(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Informe a quantidade de litros.';
    }

    final litros = _converter(texto);

    if (litros == null || litros <= 0 || litros > 1000) {
      return 'Informe uma quantidade válida, como 40.5.';
    }

    return null;
  }

  String? _validarQuilometragem(String? valor) {
    final texto = valor?.trim() ?? '';

    if (texto.isEmpty) {
      return 'Informe a quilometragem.';
    }

    final quilometragem = int.tryParse(texto);

    if (quilometragem == null) {
      return 'Informe uma quilometragem válida.';
    }

    final dataHora = _dataHora;

    // A data é validada em seu próprio campo.
    if (dataHora == null) return null;

    // A lista está em ordem cronológica: procura os vizinhos da data escolhida para manter a quilometragem sempre crescente.
    Abastecimento? anterior;
    Abastecimento? seguinte;

    for (final abastecimento in widget.abastecimentos) {
      if (abastecimento.dataHora.isAfter(dataHora)) {
        seguinte ??= abastecimento;
      } else {
        anterior = abastecimento;
      }
    }

    if (anterior != null && quilometragem <= anterior.quilometragem) {
      return 'Deve ser maior que ${anterior.quilometragem} km, '
          'do abastecimento anterior.';
    }

    if (seguinte != null && quilometragem >= seguinte.quilometragem) {
      return 'Deve ser menor que ${seguinte.quilometragem} km, '
          'do abastecimento seguinte.';
    }

    return null;
  }

  String? _validarDataHora() {
    final dataHora = _dataHora;

    if (dataHora == null) {
      return 'Selecione a data e o horário.';
    }

    if (dataHora.isAfter(DateTime.now())) {
      return 'A data e o horário não podem estar no futuro.';
    }

    return null;
  }

  Future<void> _salvar() async {
    if (_salvando) return;

    final formularioValido = _formKey.currentState!.validate();

    if (!formularioValido) return;

    FocusScope.of(context).unfocus();

    final abastecimento = Abastecimento(
      veiculoId: widget.veiculoId,
      combustivel: _combustivel,
      precoLitro: _converter(_precoController.text)!,
      quilometragem: int.parse(_quilometragemController.text.trim()),
      litros: _converter(_litrosController.text)!,
      dataHora: _dataHora!,
    );

    setState(() => _salvando = true);

    try {
      await BancoApp.instancia.inserirAbastecimento(abastecimento);

      if (!mounted) return;

      // Devolve true para o dashboard recarregar a lista.
      Navigator.pop(context, true);
    } catch (erro, stackTrace) {
      debugPrint('Erro ao salvar o abastecimento: $erro');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível salvar o abastecimento.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  void dispose() {
    _precoController.dispose();
    _quilometragemController.dispose();
    _litrosController.dispose();
    _dataHoraController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final valorTotal = _valorTotalPrevisto;

    return Scaffold(
      appBar: AppBar(title: const Text('Novo abastecimento')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Tipo de combustível'),
              const SizedBox(height: 8),
              SegmentedButton<Combustivel>(
                segments: Combustivel.values
                    .map((combustivel) => ButtonSegment<Combustivel>(
                          value: combustivel,
                          label: Text(combustivel.rotulo),
                        ))
                    .toList(),
                selected: {_combustivel},
                onSelectionChanged: (selecao) {
                  setState(() => _combustivel = selecao.first);
                },
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _precoController,
                decoration: const InputDecoration(
                  labelText: 'Preço por litro (R\$)',
                  hintText: 'Ex.: 5.89',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                validator: _validarPreco,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quilometragemController,
                decoration: const InputDecoration(
                  labelText: 'Quilometragem (km)',
                  hintText: 'Ex.: 45230',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _validarQuilometragem,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _litrosController,
                decoration: const InputDecoration(
                  labelText: 'Litros abastecidos',
                  hintText: 'Ex.: 40.5',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                validator: _validarLitros,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dataHoraController,
                decoration: const InputDecoration(
                  labelText: 'Data e horário',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_month),
                ),
                readOnly: true,
                onTap: _selecionarDataHora,
                validator: (_) => _validarDataHora(),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Valor total'),
                      Text(
                        valorTotal == null ? '—' : formatarMoeda(valorTotal),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
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
                    : const Text('Salvar abastecimento'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}