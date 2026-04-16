class AppConstants {


  static const bool useMock =
      bool.fromEnvironment('USE_MOCK', defaultValue: false);

  static const String baseUrl = 'https://api.dev.kpi-drive.ru/_api';
  static const String bearerToken = '5c3964b8e3ee4755f2cc0febb851e2f8';
  static const String getIndicatorsPath = '/indicators/get_mo_indicators';
  static const String saveIndicatorFieldPath =
      '/indicators/save_indicator_instance_field';

  static const String periodStart = '2026-04-01';
  static const String periodEnd = '2026-04-30';
  static const String periodKey = 'month';
  static const String authUserId = '40';
}
