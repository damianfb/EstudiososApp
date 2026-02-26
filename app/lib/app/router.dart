import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Proveedor global del router de la aplicación.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      // TODO: Reemplazar por rutas reales a medida que se implementen las features.
      // Ejemplo:
      // GoRoute(path: '/', builder: (context, state) => const LoginScreen()),
      // GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(
        path: '/',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('EstudiososApp')),
        ),
      ),
    ],
  );
});
