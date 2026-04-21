import 'package:flutter/widgets.dart';
import 'package:money_trace/core/app/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final app = await bootstrapApp();
  runApp(app);
}
