import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../services/supabase_service.dart';
import '../widgets/componentes.dart';
import 'home.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.servicioSupabase});

  final SupabaseService servicioSupabase;

  @override
  State<SplashPage> createState() => _EstadoSplashPage();
}

class _EstadoSplashPage extends State<SplashPage> {
  Timer? _temporizador;
  bool _lista = false;

  @override
  void initState() {
    super.initState();
    _temporizador = Timer(const Duration(milliseconds: 850), () {
      setState(() => _lista = true);
    });
  }

  @override
  void dispose() {
    _temporizador?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext contexto) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 200),
    child: _lista
        ? HomePage(servicioSupabase: widget.servicioSupabase)
        : Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sensors_rounded, size: 72, color: azul),
                  const SizedBox(height: 12),
                  Text(
                    'SensorTrack',
                    style: Theme.of(contexto).textTheme.displaySmall,
                  ),
                ],
              ),
            ),
          ),
  );
}
