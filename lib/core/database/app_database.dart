import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'connection/connection.dart'
    if (dart.library.html) 'connection/web.dart'
    if (dart.library.io) 'connection/native.dart' as conn;

part 'app_database.g.dart';

class Users extends Table {
  TextColumn get id => text()();
  TextColumn get fullName => text()();
  TextColumn get email => text()();
  TextColumn get passwordHash => text()();
  TextColumn get currencyCode => text().withDefault(const Constant('INR'))();
  TextColumn get themePreference => text().withDefault(const Constant('system'))();
  BoolColumn get biometricEnabled => boolean().withDefault(const Constant(false))();
  BoolColumn get emailVerified => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().nullable()(); // Null for global default categories
  TextColumn get name => text()();
  TextColumn get type => text()(); // 'income' or 'expense'
  TextColumn get icon => text()(); // icon name key
  TextColumn get colorHex => text()(); // theme color
  BoolColumn get isDefault => boolean().withDefault(const Constant(true))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get type => text()(); // 'income' or 'expense'
  IntColumn get amount => integer()(); // minor units (cents/paise)
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get paymentMethod => text().nullable()(); // 'cash', 'card', 'upi', 'bank_transfer'
  TextColumn get note => text().nullable()();
  TextColumn get receiptUrl => text().nullable()();
  DateTimeColumn get transactionDate => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Wallets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get balance => integer().withDefault(const Constant(0))(); // minor units
  TextColumn get currency => text().withLength(min: 3, max: 3).withDefault(const Constant('INR'))();
  TextColumn get colorHex => text().withLength(min: 6, max: 10)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text().customConstraint('NOT NULL REFERENCES users(id) ON DELETE CASCADE')();
  TextColumn get categoryId => text().customConstraint('NOT NULL REFERENCES categories(id) ON DELETE CASCADE')();
  IntColumn get amountLimit => integer()(); // minor units
  TextColumn get period => text().withLength(min: 1, max: 20)(); // 'weekly', 'monthly', 'yearly'
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()(); // 'transaction' or 'category'
  TextColumn get entityId => text()();
  TextColumn get operation => text()(); // 'create', 'update', 'delete'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Users, Categories, Transactions, Wallets, Budgets, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? conn.openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();

        // Create performance indexes for relational constraints
        await m.database.customStatement('CREATE INDEX IF NOT EXISTS tx_user_date_idx ON transactions (user_id, transaction_date);');
        await m.database.customStatement('CREATE INDEX IF NOT EXISTS budget_user_idx ON budgets (user_id);');
        await m.database.customStatement('CREATE INDEX IF NOT EXISTS wallet_user_idx ON wallets (user_id);');
        
        // Insert system default categories
        const uuid = Uuid();

        // 12 Default Expense Categories
        final defaultExpenses = [
          ('Food & Dining', 'restaurant', '0xffFF9F43', 1),
          ('Groceries', 'shopping_basket', '0xff10AC84', 2),
          ('Transport', 'directions_car', '0xff2E86DE', 3),
          ('Shopping', 'shopping_bag', '0xffFF6B6B', 4),
          ('Bills & Utilities', 'receipt', '0xff8395A7', 5),
          ('Rent/Housing', 'home', '0xff54A0FF', 6),
          ('Health & Medical', 'medical_services', '0xffEE5253', 7),
          ('Entertainment', 'movie', '0xffF8C291', 8),
          ('Education', 'school', '0xff0A3D62', 9),
          ('Travel', 'flight', '0xff05C46B', 10),
          ('Personal Care', 'spa', '0xffE056FD', 11),
          ('Other', 'more_horiz', '0xff95A5A6', 12),
        ];

        for (var item in defaultExpenses) {
          await into(categories).insert(
            CategoriesCompanion.insert(
              id: uuid.v4(),
              name: item.$1,
              type: 'expense',
              icon: item.$2,
              colorHex: item.$3,
              isDefault: const Value(true),
              isArchived: const Value(false),
              sortOrder: Value(item.$4),
            ),
          );
        }

        // 6 Default Income Categories
        final defaultIncomes = [
          ('Salary', 'work', '0xff2ECC71', 1),
          ('Freelance/Business', 'monetization_on', '0xff3498DB', 2),
          ('Gift', 'card_giftcard', '0xff9B59B6', 3),
          ('Investment Returns', 'trending_up', '0xffF1C40F', 4),
          ('Refund', 'autorenew', '0xffE67E22', 5),
          ('Other Income', 'attach_money', '0xff7F8C8D', 6),
        ];

        for (var item in defaultIncomes) {
          await into(categories).insert(
            CategoriesCompanion.insert(
              id: uuid.v4(),
              name: item.$1,
              type: 'income',
              icon: item.$2,
              colorHex: item.$3,
              isDefault: const Value(true),
              isArchived: const Value(false),
              sortOrder: Value(item.$4),
            ),
          );
        }
      },
    );
  }
}
