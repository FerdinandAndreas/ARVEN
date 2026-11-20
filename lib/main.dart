import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/device_provider.dart';
import 'screens/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }
  runApp(const ArvenSmartFarmingApp());
}

class ArvenSmartFarmingApp extends StatelessWidget {
  const ArvenSmartFarmingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DeviceProvider()),
      ],
      child: MaterialApp(
        title: 'ARVEN',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: AppColors.primary,
            onPrimary: Colors.white,
            secondary: AppColors.accent,
            onSecondary: Colors.white,
            surface: AppColors.surfaceWhite,
            onSurface: AppColors.textPrimary,
            error: AppColors.danger,
            onError: Colors.white,
          ),
          scaffoldBackgroundColor: AppColors.background,
          textTheme: GoogleFonts.plusJakartaSansTextTheme(
            Theme.of(context).textTheme,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            titleTextStyle: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          cardTheme: CardThemeData(
            color: AppColors.surfaceWhite,
            elevation: 0,
            margin: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}
