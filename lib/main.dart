import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/router.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set up error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };
  
  // Handle errors outside of Flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };
  
  // Initialize EasyLocalization with custom asset loader
  await EasyLocalization.ensureInitialized();
  
  // Load saved language preference
  final prefs = await SharedPreferences.getInstance();
  final languageCode = prefs.getString('language') ?? 'en';
  final savedLocale = Locale(languageCode);
  
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/locales',
      fallbackLocale: const Locale('en'),
      startLocale: savedLocale,
      assetLoader: const MultiAssetLoader(),
      child: const MyApp(),
    ),
  );
}

/// Custom asset loader to merge multiple JSON files
class MultiAssetLoader extends AssetLoader {
  const MultiAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final Map<String, dynamic> merged = {};

    // List of all screen translation files
    final files = [
      'common',
      'login',
      'signup',
      'home',
      'about',
      'service',
      'contact',
      'account',
      'attendance',
      'profile',
      'onboarding',
      'splash',
      'web',
    ];

    // Load each file and merge into the main map
    for (final file in files) {
      try {
        final String jsonString = await rootBundle
            .loadString('assets/locales/${locale.languageCode}/$file.json');
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        merged[file] = jsonData;
      } catch (e) {
        // File might not exist, skip it
        continue;
      }
    }

    return merged;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, _) {
          // Update locale when language changes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && context.locale != languageProvider.locale) {
              context.setLocale(languageProvider.locale);
            }
          });

          return MaterialApp.router(
            title: 'Sunshine Dental Care',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: languageProvider.locale,
            routerConfig: appRouter,
            theme: ThemeData(
              primaryColor: const Color(0xFF3366FF),
              scaffoldBackgroundColor: Colors.grey[50],
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF3366FF),
                brightness: Brightness.light,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF0D1B3E),
                elevation: 0,
              ),
              cardColor: Colors.white,
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              primaryColor: const Color(0xFF3366FF),
              scaffoldBackgroundColor: const Color(0xFF0F0F0F),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF3366FF),
                brightness: Brightness.dark,
              ).copyWith(
                surface: const Color(0xFF1C1C1C),
                surfaceContainerHighest: const Color(0xFF2A2A2A),
                onSurface: Colors.white,
                onSurfaceVariant: Colors.white70,
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1C1C1C),
                foregroundColor: Colors.white,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
              cardColor: const Color(0xFF1C1C1C),
              cardTheme: CardThemeData(
                color: const Color(0xFF1C1C1C),
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF1C1C1C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF3366FF), width: 2),
                ),
              ),
              useMaterial3: true,
            ),
            themeMode: themeProvider.themeMode,
          );
        },
      ),
    );
  }
}

