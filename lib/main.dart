import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'pages/preset_grid_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlarmAutomatoApp());
}

class AlarmAutomatoApp extends StatelessWidget {
  const AlarmAutomatoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        textTheme: GoogleFonts.notoSansJpTextTheme(),
      ),
      home: const PresetGridPage(),
    );
  }
}
