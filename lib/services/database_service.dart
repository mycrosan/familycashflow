import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/member.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/recurring_transaction.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'fluxo_familiar.db';
  static const int _databaseVersion = 1;

  // Tabelas
  static const String _tableUsers = 'users';
  static const String _tableMembers = 'members';
  static const String _tableCategories = 'categorias';
  static const String _tableTransactions = 'lancamentos';
  static const String _tableRecurringTransactions = 'recorrencias';
  static const String _tableSyncLog = 'sync_log';

  // Singleton
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabela de usuários
    await db.execute('''
      CREATE TABLE $_tableUsers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        profile_picture TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Tabela de membros
    await db.execute('''
      CREATE TABLE $_tableMembers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        relation TEXT NOT NULL,
        profile_picture TEXT,
        user_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_tableUsers (id)
      )
    ''');

    // Tabela de categorias
    await db.execute('''
      CREATE TABLE $_tableCategories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL,
        icone TEXT,
        cor TEXT,
        user_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_tableUsers (id)
      )
    ''');

    // Tabela de transações
    await db.execute('''
      CREATE TABLE $_tableTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valor REAL NOT NULL,
        data TEXT NOT NULL,
        categoria TEXT NOT NULL,
        responsavel_id INTEGER NOT NULL,
        observacoes TEXT,
        receipt_image TEXT,
        recorrencia_id INTEGER,
        sync_status TEXT NOT NULL DEFAULT 'synced',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (responsavel_id) REFERENCES $_tableMembers (id),
        FOREIGN KEY (recorrencia_id) REFERENCES $_tableRecurringTransactions (id)
      )
    ''');

    // Tabela de transações recorrentes
    await db.execute('''
      CREATE TABLE $_tableRecurringTransactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        frequency TEXT NOT NULL,
        category TEXT NOT NULL,
        value REAL NOT NULL,
        associated_member_id INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        max_occurrences INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        notes TEXT,
        user_id INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (associated_member_id) REFERENCES $_tableMembers (id),
        FOREIGN KEY (user_id) REFERENCES $_tableUsers (id)
      )
    ''');

    // Tabela de log de sincronização
    await db.execute('''
      CREATE TABLE $_tableSyncLog (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id INTEGER NOT NULL,
        action TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending',
        created_at TEXT NOT NULL,
        synced_at TEXT
      )
    ''');

    // Índices para melhor performance
    await db.execute('CREATE INDEX idx_transactions_date ON $_tableTransactions (data)');
    await db.execute('CREATE INDEX idx_transactions_category ON $_tableTransactions (categoria)');
    await db.execute('CREATE INDEX idx_transactions_member ON $_tableTransactions (responsavel_id)');
    await db.execute('CREATE INDEX idx_transactions_sync ON $_tableTransactions (sync_status)');
    await db.execute('CREATE INDEX idx_sync_log_status ON $_tableSyncLog (sync_status)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Implementar migrações futuras aqui
  }

  // === USERS ===

  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(_tableUsers, user.toJson());
  }

  Future<List<User>> getUsers() async {
    final db = await database;
    final maps = await db.query(_tableUsers, orderBy: 'name ASC');
    return maps.map((map) => User.fromJson(map)).toList();
  }

  Future<User?> getUser(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      _tableUsers,
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    final db = await database;
    return await db.update(
      _tableUsers,
      user.toJson(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete(
      _tableUsers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === MEMBERS ===

  Future<int> insertMember(Member member) async {
    final db = await database;
    return await db.insert(_tableMembers, member.toJson());
  }

  Future<List<Member>> getMembers() async {
    final db = await database;
    final maps = await db.query(_tableMembers, orderBy: 'name ASC');
    return maps.map((map) => Member.fromJson(map)).toList();
  }

  Future<Member?> getMember(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableMembers,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Member.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateMember(Member member) async {
    final db = await database;
    return await db.update(
      _tableMembers,
      member.toJson(),
      where: 'id = ?',
      whereArgs: [member.id],
    );
  }

  Future<int> deleteMember(int id) async {
    final db = await database;
    return await db.delete(
      _tableMembers,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === CATEGORIES ===

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert(_tableCategories, category.toJson());
  }

  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query(_tableCategories, orderBy: 'nome ASC');
    return maps.map((map) => Category.fromJson(map)).toList();
  }

  Future<List<Category>> getCategoriesByType(String type) async {
    final db = await database;
    final maps = await db.query(
      _tableCategories,
      where: 'tipo = ?',
      whereArgs: [type],
      orderBy: 'nome ASC',
    );
    return maps.map((map) => Category.fromJson(map)).toList();
  }

  Future<Category?> getCategory(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableCategories,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return Category.fromJson(maps.first);
    }
    return null;
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      _tableCategories,
      category.toJson(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete(
      _tableCategories,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === TRANSACTIONS ===

  Future<int> insertTransaction(Transaction transaction) async {
    final db = await database;
    final data = transaction.toJson();
    
    return await db.insert(_tableTransactions, data);
  }

  Future<List<Transaction>> getTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    int? memberId,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (startDate != null) {
      whereClause += 'data >= ?';
      whereArgs.add(startDate.toIso8601String());
    }
    
    if (endDate != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'data <= ?';
      whereArgs.add(endDate.toIso8601String());
    }
    
    if (category != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'categoria = ?';
      whereArgs.add(category);
    }
    
    if (memberId != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'responsavel_id = ?';
      whereArgs.add(memberId);
    }

    final maps = await db.query(
      _tableTransactions,
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'data DESC',
    );

    // Converter para objetos Transaction com relacionamentos
    final transactions = <Transaction>[];
    for (final map in maps) {
      final member = await getMember(map['responsavel_id'] as int);
      if (member != null) {
        final transaction = Transaction.fromJson({
          ...map,
          'responsavel': member.toJson(),
        });
        transactions.add(transaction);
      }
    }

    return transactions;
  }

  Future<Transaction?> getTransaction(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final map = maps.first;
      final member = await getMember(map['responsavel_id'] as int);
      if (member != null) {
        return Transaction.fromJson({
          ...map,
          'responsavel': member.toJson(),
        });
      }
    }
    return null;
  }

  Future<int> updateTransaction(Transaction transaction) async {
    final db = await database;
    final data = transaction.toJson();
    
    return await db.update(
      _tableTransactions,
      data,
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete(
      _tableTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === RECURRING TRANSACTIONS ===

  Future<int> insertRecurringTransaction(RecurringTransaction recurringTransaction) async {
    final db = await database;
    final data = recurringTransaction.toJson();
    data['associated_member_id'] = recurringTransaction.associatedMember.id;
    
    return await db.insert(_tableRecurringTransactions, data);
  }

  Future<List<RecurringTransaction>> getRecurringTransactions() async {
    final db = await database;
    final maps = await db.query(
      _tableRecurringTransactions,
      where: 'is_active = 1',
      orderBy: 'start_date ASC',
    );

    final recurringTransactions = <RecurringTransaction>[];
    for (final map in maps) {
      final member = await getMember(map['associated_member_id'] as int);
      if (member != null) {
        final recurringTransaction = RecurringTransaction.fromJson({
          ...map,
          'associated_member': member.toJson(),
        });
        recurringTransactions.add(recurringTransaction);
      }
    }

    return recurringTransactions;
  }

  Future<int> updateRecurringTransaction(RecurringTransaction recurringTransaction) async {
    final db = await database;
    final data = recurringTransaction.toJson();
    data['associated_member_id'] = recurringTransaction.associatedMember.id;
    
    return await db.update(
      _tableRecurringTransactions,
      data,
      where: 'id = ?',
      whereArgs: [recurringTransaction.id],
    );
  }

  Future<int> deleteRecurringTransaction(int id) async {
    final db = await database;
    return await db.delete(
      _tableRecurringTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<RecurringTransaction?> getRecurringTransaction(int id) async {
    final db = await database;
    final maps = await db.query(
      _tableRecurringTransactions,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final map = maps.first;
      final member = await getMember(map['associated_member_id'] as int);
      if (member != null) {
        return RecurringTransaction.fromJson({
          ...map,
          'associated_member': member.toJson(),
        });
      }
    }
    return null;
  }

  // === SYNC LOG ===

  Future<void> logSyncAction(String tableName, int recordId, String action) async {
    final db = await database;
    await db.insert(_tableSyncLog, {
      'table_name': tableName,
      'record_id': recordId,
      'action': action,
      'sync_status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncActions() async {
    final db = await database;
    return await db.query(
      _tableSyncLog,
      where: 'sync_status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
  }

  Future<void> markSyncActionAsSynced(int id) async {
    final db = await database;
    await db.update(
      _tableSyncLog,
      {
        'sync_status': 'synced',
        'synced_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === UTILITIES ===

  Future<void> clearDatabase() async {
    final db = await database;
    await db.delete(_tableSyncLog);
    await db.delete(_tableTransactions);
    await db.delete(_tableRecurringTransactions);
    await db.delete(_tableCategories);
    await db.delete(_tableMembers);
    await db.delete(_tableUsers);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
