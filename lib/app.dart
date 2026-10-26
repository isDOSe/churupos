import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'features/converter/presentation/converter_screen.dart';

class ChuruposApp extends StatelessWidget {
  const ChuruposApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Churupos',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const ConverterScreen(),
    );
  }
}
