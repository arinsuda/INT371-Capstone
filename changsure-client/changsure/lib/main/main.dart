import 'dart:developer';

import 'package:changsure/models/technicians/technician_activity.dart';
import 'package:changsure/services/technician_activity_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'package:changsure/module/auth/login.dart';
import 'package:changsure/core/theme.dart';
import 'package:changsure/core/footer/footer_bar.dart';
import 'package:changsure/config/app_config.dart';

import 'package:changsure/api/api_client.dart';
import 'package:changsure/services/auth_service.dart';
import 'package:changsure/services/profile_service.dart';
import 'package:changsure/services/province_service.dart';
import 'package:changsure/services/technician_address_service.dart';
import 'package:changsure/services/customer_address_service.dart';
import 'package:changsure/services/service_category_service.dart';
import 'package:changsure/services/service_service.dart';
import 'package:changsure/services/technician_activity_service.dart';

import 'package:changsure/state/auth_state.dart';
import 'package:changsure/state/profile_state.dart';
import 'package:changsure/state/province_state.dart';
import 'package:changsure/state/technician_address_state.dart';
import 'package:changsure/state/bottom_bar_state.dart';
import 'package:changsure/state/customer_address_state.dart';
import 'package:changsure/state/category_state.dart';
import 'package:changsure/state/service_state.dart';
import 'package:changsure/state/ativity_state.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MultiProvider(providers: _buildProviders(), child: const MyApp()));
}

List<SingleChildWidget> _buildProviders() {
  final apiClient = ApiClient(AppConfig.baseUrl, navigatorKey: navigatorKey);
  final authService = AuthService(apiClient);
  final profileService = ProfileService(apiClient);
  final provinceService = ProvinceService(apiClient);
  final techAddressService = TechnicianAddressService(apiClient);
  final customerAddressService = CustomerAddressService(apiClient);
  final serviceCategoryService = ServiceCategoryService(apiClient);
  final serviceService = ServiceApi(apiClient);
  final techActivityService = TechnicianWorkService(apiClient);

  return [
    Provider<AuthService>.value(value: authService),
    Provider<ProfileService>.value(value: profileService),
    Provider<ProvinceService>.value(value: provinceService),
    Provider<TechnicianAddressService>.value(value: techAddressService),
    Provider<CustomerAddressService>.value(value: customerAddressService),
    Provider<ServiceCategoryService>.value(value: serviceCategoryService),
    Provider<ServiceApi>.value(value: serviceService),
    Provider<TechnicianWorkService>.value(value: techActivityService),

    ChangeNotifierProvider(create: (_) => BottomBarState()),
    ChangeNotifierProvider(create: (_) => AuthState()..loadToken()),
    ChangeNotifierProvider(create: (_) => ProvinceState(provinceService)),

    ChangeNotifierProxyProvider<AuthState, ProfileState>(
      create: (ctx) =>
          ProfileState(ctx.read<ProfileService>(), ctx.read<AuthState>())
            ..loadProfile(),
      update: (ctx, auth, previous) =>
          previous ?? ProfileState(ctx.read<ProfileService>(), auth),
    ),

    ChangeNotifierProvider(
      create: (ctx) =>
          TechnicianAddressState(ctx.read<TechnicianAddressService>()),
    ),

    ChangeNotifierProvider(
      create: (ctx) => CustomerAddressState(ctx.read<CustomerAddressService>()),
    ),

    ChangeNotifierProvider(
      create: (ctx) => ServiceCategoryState(ctx.read<ServiceCategoryService>()),
    ),

    ChangeNotifierProvider(
      create: (ctx) => ServiceState(api: ctx.read<ServiceApi>()),
    ),

    ChangeNotifierProvider(
      create: (ctx) => TechnicianWorkState(ctx.read<TechnicianWorkService>()),
    ),
  ];
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Changsure App',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: AppRoutes.initial,
      routes: _buildRoutes(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      scaffoldBackgroundColor: Colors.white,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      useMaterial3: true,
      textTheme: GoogleFonts.notoSansThaiTextTheme(),
      appBarTheme: AppBarTheme(
        titleTextStyle: GoogleFonts.notoSansThai(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      AppRoutes.initial: (context) =>
          const AuthGuard(child: FooterBarTemplate()),
      AppRoutes.login: (context) =>
          LoginScreen(authRepo: context.read<AuthService>()),
      AppRoutes.home: (context) => const FooterBarTemplate(),
    };
  }
}

abstract class AppRoutes {
  static const String initial = '/';
  static const String login = '/login';
  static const String home = '/home';
}

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthState>(
      builder: (context, authState, _) {
        if (!authState.isLoggedIn) {
          return LoginScreen(authRepo: context.read<AuthService>());
        }
        return child;
      },
    );
  }
}
