import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/themes/app_theme.dart';
import 'presentation/routes/app_router.dart';
import 'core/services/keycloak_service.dart';
import 'core/services/api_service.dart';
import 'core/services/device_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final keycloakService = KeycloakService();
  await keycloakService.initialize();

  final apiService = ApiService(keycloakService);
  final deviceService = DeviceService(apiService);

  runApp(MyApp(keycloakService: keycloakService, deviceService: deviceService));
}

class MyApp extends StatelessWidget {
  final KeycloakService keycloakService;
  final DeviceService deviceService;

  const MyApp({
    super.key,
    required this.keycloakService,
    required this.deviceService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: keycloakService),
        Provider.value(value: deviceService),
      ],
      child: MaterialApp.router(
        title: 'MDMS Clone',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.getRouter(keycloakService),
      ),
    );
  }
}
