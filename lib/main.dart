import 'package:material_ui/material_ui.dart';

import 'pages/splash.dart';
import 'services/supabase_service.dart';
import 'widgets/componentes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final servicioSupabase = await SupabaseService.inicializar();
  runApp(AplicacionSensorTrack(servicioSupabase: servicioSupabase));
}

class AplicacionSensorTrack extends StatelessWidget {
  const AplicacionSensorTrack({super.key, required this.servicioSupabase});

  final SupabaseService servicioSupabase;

  @override
  Widget build(BuildContext contexto) {
    final colores = ColorScheme.fromSeed(
      seedColor: azul,
      brightness: Brightness.dark,
      primary: azul,
      onPrimary: colorFondo,
      primaryContainer: azulOscuro,
      onPrimaryContainer: colorTexto,
      secondary: verde,
      onSecondary: colorFondo,
      secondaryContainer: azulOscuro,
      onSecondaryContainer: colorTexto,
      tertiary: naranja,
      onTertiary: colorFondo,
      error: const Color(0xFFFF585D),
      onError: colorFondo,
      surface: colorFondo,
      onSurface: colorTexto,
      onSurfaceVariant: colorTextoSecundario,
      surfaceContainer: colorPanel,
      surfaceContainerHigh: colorPanel,
      outline: colorTextoSecundario,
      outlineVariant: colorBorde,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SensorTrack',
      locale: const Locale('es', 'EC'),
      supportedLocales: const [Locale('es', 'EC')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(
        colorScheme: colores,
        scaffoldBackgroundColor: colorFondo,
        appBarTheme: const AppBarTheme(backgroundColor: colorFondo),
        navigationBarTheme: const NavigationBarThemeData(
          backgroundColor: colorPanel,
          indicatorColor: azulOscuro,
          height: 72,
        ),
      ),
      home: SplashPage(servicioSupabase: servicioSupabase),
    );
  }
}
