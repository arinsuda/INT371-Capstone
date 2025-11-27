import 'package:changsure/module/auth/login.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:changsure/core/theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/footer/footerBar.dart';
import '../state/bottomBarState.dart';

import '../api/api_client.dart';
import '../repositories/auth_repository.dart';
import '../config/app_config.dart';
import '../state/auth_state.dart';

import '../repositories/profile_repository.dart';
import '../state/profile_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient(AppConfig.baseUrl);
  final authRepo = AuthRepository(apiClient);
  final profileRepo = ProfileRepository(apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BottomBarState()),

        Provider<AuthRepository>.value(value: authRepo),
        Provider<ProfileRepository>.value(value: profileRepo),

        ChangeNotifierProvider<AuthState>(
          create: (_) => AuthState()..loadToken(),
        ),

        ChangeNotifierProvider<ProfileState>(
          create: (_) => ProfileState(profileRepo)..loadProfile(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Changsure App',
      theme: ThemeData(
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
      ),
      home: Consumer<AuthState>(
        builder: (context, auth, child) {
          if (!auth.isLoggedIn) {
            final authRepo = Provider.of<AuthRepository>(
              context,
              listen: false,
            );
            return LoginScreen(authRepo: authRepo);
          }

          return const FooterBarTemplate();
        },
      ),
    );
  }
}
