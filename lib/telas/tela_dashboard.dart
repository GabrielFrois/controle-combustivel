import 'package:flutter/material.dart';

import '../database/banco_app.dart';
import '../models/abastecimento.dart';
import '../models/veiculo.dart';
import '../utils/formatadores.dart';
import '../utils/indicadores.dart';
import '../widgets/graficos.dart';
import 'tela_novo_abastecimento.dart';

class TelaDashboard extends StatefulWidget {
  final Veiculo veiculo;

  // Chamado depois que o veículo e seus abastecimentos são excluído.
  final VoidCallback aoExcluir;

  const TelaDashboard({
    super.key,
    required this.veiculo,
    required this.aoExcluir,
  });

  @override
  State<TelaDashboard> createState() => _TelaDashboardState();
}

class _TelaDashboardState extends State<TelaDashboard> {
  // Em ordem cronológica
  List<Abastecimento> _abastecimentos = [];
  List<Indicador> _indicadores = [];
  bool _carregando = true;
  bool _excluindo = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarAbastecimentos();
  }

  Future<void> _carregarAbastecimentos() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final lista = await BancoApp.instancia.listarAbastecimentos(
        widget.veiculo.id!,
      );

      if (!mounted) return;

      setState(() {
        _abastecimentos = lista;
        _indicadores = calcularIndicadores(lista);
      });
    } catch (erro, stackTrace) {
      debugPrint('Erro ao carregar os abastecimentos: $erro');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => _erro = 'Não foi possível carregar os abastecimentos.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _abrirNovoAbastecimento() async {
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => TelaNovoAbastecimento(
          veiculoId: widget.veiculo.id!,
          abastecimentos: _abastecimentos,
        ),
      ),
    );

    if (!mounted) return;

    if (salvou == true) {
      await _carregarAbastecimentos();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Abastecimento registrado.')),
      );
    }
  }

  Future<void> _confirmarExclusao() async {
    if (_excluindo) return;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Excluir veículo?'),
          content: const Text(
            'O veículo e todos os abastecimentos registrados serão '
            'apagados. Essa ação não pode ser desfeita.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (confirmou != true) return;
    if (!mounted) return;

    setState(() => _excluindo = true);

    try {
      await BancoApp.instancia.excluirVeiculo(widget.veiculo.id!);

      if (!mounted) return;

      widget.aoExcluir();
    } catch (erro, stackTrace) {
      debugPrint('Erro ao excluir o veículo: $erro');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir o veículo.')),
      );
    } finally {
      if (mounted) setState(() => _excluindo = false);
    }
  }

  Widget _cartaoVeiculo() {
    final veiculo = widget.veiculo;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${veiculo.marca} ${veiculo.modelo}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Ano: ${veiculo.ano}'),
            Text('Cilindrada: ${veiculo.cilindrada.toStringAsFixed(1)} L'),
          ],
        ),
      ),
    );
  }

  Widget _cartaoResumo(String rotulo, String valor) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(rotulo, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  valor,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resumo() {
    final resumo = calcularResumo(_indicadores);
    final consumoMedio = resumo.consumoMedio;
    final custoMedio = resumo.custoMedioPorKm;

    return Row(
      children: [
        _cartaoResumo('Gasto total', formatarMoeda(resumo.gastoTotal)),
        _cartaoResumo(
          'Consumo médio',
          consumoMedio == null ? '—' : '${formatarNumero(consumoMedio)} km/L',
        ),
        _cartaoResumo(
          'Custo médio',
          custoMedio == null ? '—' : '${formatarMoeda(custoMedio)}/km',
        ),
      ],
    );
  }

  List<Widget> _graficos() {
    final graficos = <Widget>[
      GraficoBarras(
        titulo: 'Valor de cada abastecimento (R\$)',
        abastecimentos: _abastecimentos,
        valores: _abastecimentos.map((a) => a.valorTotal).toList(),
        formatarEixo: (valor) => formatarNumero(valor, casas: 0),
        formatarValor: formatarMoeda,
      ),
      const SizedBox(height: 16),
    ];

    // Consumo e custo por km só existem a partir do segundo abastecimento.
    if (_abastecimentos.length < 2) {
      graficos.add(
        const Text(
          'Registre pelo menos dois abastecimentos para ver o consumo '
          '(km/L) e o custo por km (R\$/km).',
        ),
      );

      return graficos;
    }

    graficos.addAll([
      GraficoLinha(
        titulo: 'Consumo (km/L)',
        abastecimentos: _abastecimentos,
        valores: _indicadores.map((i) => i.consumo).toList(),
        formatarEixo: (valor) => formatarNumero(valor, casas: 1),
        formatarValor: (valor) => '${formatarNumero(valor)} km/L',
      ),
      const SizedBox(height: 16),
      GraficoLinha(
        titulo: 'Custo por quilômetro (R\$/km)',
        abastecimentos: _abastecimentos,
        valores: _indicadores.map((i) => i.custoPorKm).toList(),
        formatarEixo: formatarNumero,
        formatarValor: (valor) => '${formatarMoeda(valor)}/km',
        cor: Theme.of(context).colorScheme.tertiary,
      ),
    ]);

    return graficos;
  }

  String _linhaIndicadores(Indicador indicador) {
    final distancia = indicador.distancia;
    final consumo = indicador.consumo;
    final custo = indicador.custoPorKm;

    if (distancia == null || consumo == null || custo == null) {
      return 'Referência inicial (sem km/L e R\$/km)';
    }

    return '${formatarNumero(distancia, casas: 0)} km rodados · '
        '${formatarNumero(consumo)} km/L · '
        '${formatarMoeda(custo)}/km';
  }

  Widget _cartaoAbastecimento(Indicador indicador) {
    final abastecimento = indicador.abastecimento;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(child: Icon(Icons.local_gas_station)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        abastecimento.combustivel.rotulo,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        formatarMoeda(abastecimento.valorTotal),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                  Text(formatarDataHora(abastecimento.dataHora)),
                  Text(
                    '${formatarNumero(abastecimento.litros)} L × '
                    '${formatarPrecoLitro(abastecimento.precoLitro)} · '
                    '${abastecimento.quilometragem} km',
                  ),
                  Text(_linhaIndicadores(indicador)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _conteudoAbastecimentos() {
    if (_carregando) {
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }

    if (_erro != null) {
      return [
        Text(_erro!),
        TextButton(
          onPressed: _carregarAbastecimentos,
          child: const Text('Tentar novamente'),
        ),
      ];
    }

    if (_abastecimentos.isEmpty) {
      return const [Text('Nenhum abastecimento registrado.')];
    }

    final titulo = Theme.of(context).textTheme.titleMedium;

    return [
      Text('Resumo', style: titulo),
      const SizedBox(height: 8),
      _resumo(),
      const SizedBox(height: 16),
      Text('Gráficos', style: titulo),
      const SizedBox(height: 8),
      ..._graficos(),
      const SizedBox(height: 16),
      Text('Abastecimentos', style: titulo),
      const SizedBox(height: 8),
      // Do mais recente para o mais antigo.
      ..._indicadores.reversed.map(_cartaoAbastecimento),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Controle de combustível'),
        actions: [
          IconButton(
            tooltip: 'Excluir veículo',
            icon: const Icon(Icons.delete_outline),
            onPressed: _excluindo ? null : _confirmarExclusao,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        // Desabilitado até a lista carregar: a validação da quilometragem depende dos abastecimentos já registrados.
        onPressed: _carregando || _erro != null
            ? null
            : _abrirNovoAbastecimento,
        icon: const Icon(Icons.add),
        label: const Text('Abastecimento'),
      ),
      body: ListView(
        // Espaço extra no fim para o botão não cobrir o último item.
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          _cartaoVeiculo(),
          const SizedBox(height: 16),
          ..._conteudoAbastecimentos(),
        ],
      ),
    );
  }
}