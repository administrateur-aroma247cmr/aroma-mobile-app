import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  AppConfig._();

  static String get apiBaseUrl {
    final fromEnv = dotenv.maybeGet('API_BASE_URL')?.trim();
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return fromEnv.replaceAll(RegExp(r'/+$'), '');
    }
    return 'https://aroma-jpc-crm-api.aroma-digitalisation.cloud';
  }
}
