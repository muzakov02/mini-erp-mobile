import 'package:flutter/material.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/di/injector.dart';
import 'core/widgets/config_error_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!AppConfig.isConfigured) {
    runApp(const ConfigErrorApp());
    return;
  }
  setupDependencies();
  runApp(const MiniErpApp());
}
