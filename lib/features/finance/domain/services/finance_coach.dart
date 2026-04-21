import 'package:money_trace/features/finance/domain/models/finance_advice.dart';
import 'package:money_trace/features/finance/domain/models/finance_snapshot.dart';

abstract interface class FinanceCoach {
  List<FinanceAdvice> buildAdvice(FinanceSnapshot snapshot);
}
