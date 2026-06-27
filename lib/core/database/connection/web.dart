import 'package:drift/drift.dart';
// ignore: deprecated_member_use
import 'package:drift/web.dart';

QueryExecutor openConnection() {
  // ignore: deprecated_member_use
  return WebDatabase('pocket_ledger', logStatements: true);
}
