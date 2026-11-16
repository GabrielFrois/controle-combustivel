import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/abastecimento.dart';
import '../models/veiculo.dart';

class BancoApp {
  BancoApp._();

  static final BancoApp instancia = BancoApp._();

  Future<Database>? _abertura;

  /// Abre o banco na primeira chamada e reaproveita nas seguintes.
  Future<Database> get banco => _abertura ??= _abrir();

  Future<Database> _abrir() async {
    final pasta = await getDatabasesPath();

    return openDatabase(
      p.join(pasta, 'controle_combustivel.db'),
      version: 1,
      // O SQLite não aplica chaves estrangeiras por padrão.
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      // Executa apenas na primeira criação do banco.
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE veiculo (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            marca TEXT NOT NULL,
            modelo TEXT NOT NULL,
            ano INTEGER NOT NULL,
            cilindrada REAL NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE abastecimento (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            veiculo_id INTEGER NOT NULL,
            combustivel TEXT NOT NULL,
            preco_litro REAL NOT NULL,
            quilometragem INTEGER NOT NULL,
            litros REAL NOT NULL,
            data_hora TEXT NOT NULL,
            FOREIGN KEY (veiculo_id) REFERENCES veiculo (id)
              ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  // Veículo

  /// Retorna o veículo cadastrado ou null quando não há nenhum.
  Future<Veiculo?> obterVeiculo() async {
    final db = await banco;
    final registros = await db.query('veiculo', limit: 1);

    if (registros.isEmpty) return null;

    return Veiculo.fromMap(registros.first);
  }

  /// Cadastra o veículo. Só é permitido um por vez.
  Future<int> inserirVeiculo(Veiculo veiculo) async {
    final db = await banco;

    return db.transaction((txn) async {
      final existentes = await txn.query('veiculo', limit: 1);

      if (existentes.isNotEmpty) {
        throw StateError('Já existe um veículo cadastrado.');
      }

      return txn.insert('veiculo', veiculo.toMap());
    });
  }

  /// Exclui o veículo e todos os abastecimentos associados a ele.
  Future<void> excluirVeiculo(int veiculoId) async {
    final db = await banco;

    await db.transaction((txn) async {
      await txn.delete(
        'abastecimento',
        where: 'veiculo_id = ?',
        whereArgs: [veiculoId],
      );
      await txn.delete('veiculo', where: 'id = ?', whereArgs: [veiculoId]);
    });
  }

  // Abastecimento

  Future<int> inserirAbastecimento(Abastecimento abastecimento) async {
    final db = await banco;

    return db.insert('abastecimento', abastecimento.toMap());
  }

  /// Lista os abastecimentos do veículo em ordem cronológica (do mais antigo para o mais recente).
  Future<List<Abastecimento>> listarAbastecimentos(int veiculoId) async {
    final db = await banco;
    final registros = await db.query(
      'abastecimento',
      where: 'veiculo_id = ?',
      whereArgs: [veiculoId],
      orderBy: 'data_hora ASC, id ASC',
    );

    return registros.map(Abastecimento.fromMap).toList();
  }
}