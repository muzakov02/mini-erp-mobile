import 'package:flutter/material.dart';

class ConfigErrorApp extends StatelessWidget {
  const ConfigErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mini ERP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal),
      home: Scaffold(
        appBar: AppBar(title: const Text('Mini ERP')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_suggest, size: 48),
                SizedBox(height: 12),
                Text(
                  "Server manzili berilmagan. Ilovani API_BASE_URL bilan ishga tushiring:",
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                SelectableText(
                  '--dart-define=API_BASE_URL=http://192.168.1.10:3000/api',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
