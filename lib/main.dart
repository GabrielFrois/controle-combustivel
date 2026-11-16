import 'package:flutter/material.dart';

import 'database/banco_app.dart';
import 'models/veiculo.dart';
import 'telas/tela_cadastro_veiculo.dart';
import 'telas/tela_dashboard.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const ControleCombustivelApp());
}

class ControleCombustivelApp extends StatelessWidget {
  const ControleCombustivelApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Controle de combustível',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const TelaRaiz(),
    );
  }
}

/// Lê o veículo salvo e decide qual tela mostrar:
/// sem veículo -> cadastro; com veículo -> dashboard.
class TelaRaiz extends StatefulWidget {
  const TelaRaiz({super.key});

  @override
  State<TelaRaiz> createState() => _TelaRaizState();
}

class _TelaRaizState extends State<TelaRaiz> {
  Veiculo? _veiculo;
  bool _carregando = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregarVeiculo();
  }

  Future<void> _carregarVeiculo() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });

    try {
      final veiculo = await BancoApp.instancia.obterVeiculo();

      if (!mounted) return;

      setState(() => _veiculo = veiculo);
    } catch (erro, stackTrace) {
      debugPrint('Erro ao carregar o veículo: $erro');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() => _erro = 'Não foi possível carregar os dados.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_carregando) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_erro != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_erro!),
              TextButton(
                onPressed: _carregarVeiculo,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final veiculo = _veiculo;

    if (veiculo == null) {
      return TelaCadastroVeiculo(aoCadastrar: _carregarVeiculo);
    }

    return TelaDashboard(veiculo: veiculo, aoExcluir: _carregarVeiculo);
  }
}