import 'package:money_trace/core/settings/app_settings_repository.dart';
import 'package:money_trace/data/demo/memory_app_settings_repository.dart';

Future<AppSettingsRepository> createAppSettingsRepository() async {
  return MemoryAppSettingsRepository();
}
