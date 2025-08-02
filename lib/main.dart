import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'presentation/themes/app_theme.dart';
import 'presentation/routes/app_router.dart';
import 'core/services/keycloak_service.dart';
import 'core/services/device_service.dart';
import 'core/services/device_group_service.dart';
import 'core/services/site_service.dart';
import 'core/services/season_service.dart';
import 'core/services/special_day_service.dart';
import 'core/services/service_locator.dart';
import 'core/services/token_management_service.dart';
import 'core/services/time_band_service.dart';
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
  final timeBandService = serviceLocator.timeBandService;
  final deviceService = DeviceService(apiService);
  final deviceGroupService = DeviceGroupService(apiService);
  final siteService = SiteService(apiService);
  final seasonService = SeasonService(apiService);
  final specialDayService = SpecialDayService(apiService);

  runApp(
    MyApp(
      serviceLocator: serviceLocator,
      keycloakService: keycloakService,
      tokenManagementService: tokenManagementService,
      timeBandService: timeBandService,
      deviceService: deviceService,
      deviceGroupService: deviceGroupService,
      siteService: siteService,
      seasonService: seasonService,
      specialDayService: specialDayService,
    ),
  );
}

class MyApp extends StatelessWidget {
  final ServiceLocator serviceLocator;
  final KeycloakService keycloakService;
  final TokenManagementService tokenManagementService;
  final TimeBandService timeBandService;
  final DeviceService deviceService;
  final DeviceGroupService deviceGroupService;
  final SiteService siteService;
  final SeasonService seasonService;
  final SpecialDayService specialDayService;

  const MyApp({
    super.key,
    required this.serviceLocator,
    required this.keycloakService,
    required this.tokenManagementService,
    required this.timeBandService,
    required this.deviceService,
    required this.deviceGroupService,
    required this.siteService,
    required this.seasonService,
    required this.specialDayService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: serviceLocator),
        ChangeNotifierProvider.value(value: keycloakService),
        ChangeNotifierProvider.value(value: tokenManagementService),
        Provider.value(value: timeBandService),
        Provider.value(value: deviceService),
        Provider.value(value: deviceGroupService),
        Provider.value(value: siteService),
        Provider.value(value: seasonService),
        Provider.value(value: specialDayService),
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
