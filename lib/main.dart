import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/themes/app_theme.dart';
import 'presentation/routes/app_router.dart';
import 'core/services/keycloak_service.dart';
import 'core/services/device_service.dart';
import 'core/services/service_locator.dart';
import 'core/services/token_management_service.dart';
import 'core/services/startup_validation_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize ServiceLocator with all dynamic services
  final serviceLocator = ServiceLocator();
  await serviceLocator.initialize();

  // Validate initial setup
  final isValid = await StartupValidationService.validateInitialSetup();
  if (isValid) {
    // Start token monitoring for auto-refresh
    StartupValidationService.startTokenMonitoring();
  }

  // Get services from ServiceLocator (with dynamic headers)
  final keycloakService = serviceLocator.keycloakService;
  final apiService = serviceLocator.apiService;
  final tokenManagementService = serviceLocator.tokenManagementService;
  final deviceService = DeviceService(apiService);

  runApp(
    MyApp(
      keycloakService: keycloakService,
      tokenManagementService: tokenManagementService,
      deviceService: deviceService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final KeycloakService keycloakService;
  final TokenManagementService tokenManagementService;
  final DeviceService deviceService;

  const MyApp({
    super.key,
    required this.keycloakService,
    required this.tokenManagementService,
    required this.deviceService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: keycloakService),
        ChangeNotifierProvider.value(value: tokenManagementService),
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
