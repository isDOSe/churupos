import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      locale: const Locale('es', 'VE'),
      supportedLocales: const [Locale('es', 'VE'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const ConverterScreen(),
    );
  }
}
