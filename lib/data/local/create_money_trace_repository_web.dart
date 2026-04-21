import 'package:money_trace/data/demo/demo_money_trace_repository.dart';
import 'package:money_trace/features/finance/domain/repositories/money_trace_repository.dart';

Future<MoneyTraceRepository> createMoneyTraceRepository() async {
  return DemoMoneyTraceRepository();
}
