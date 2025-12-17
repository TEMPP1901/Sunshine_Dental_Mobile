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
import 'providers/attendance_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await Firebase.initializeApp();
  
  // Khởi tạo Notification Service (không block UI)
  NotificationService().initialize().then((_) {
    debugPrint('NotificationService initialized');
  }).catchError((e) {
    debugPrint('Failed to initialize NotificationService: $e');
  });

  // Xử lý lỗi trong framework Flutter
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
    debugPrint('Stack trace: ${details.stack}');
  };

  // Xử lý lỗi ngoài phạm vi Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    debugPrint('Stack trace: $stack');
    return true;
  };

  // Khởi tạo EasyLocalization với loader tùy chỉnh
  await EasyLocalization.ensureInitialized();

  // Lấy ngôn ngữ đã lưu từ SharedPreferences
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

// Loader thực hiện merge nhiều file json ngôn ngữ lại với nhau
class MultiAssetLoader extends AssetLoader {
  const MultiAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    final Map<String, dynamic> merged = {};

    // Danh sách các file ngôn ngữ cho từng màn hình
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
      'leaveRequest',
      'onboarding',
      'splash',
      'web',
    ];

    // Lần lượt đọc từng file và merge vào map chính
    for (final file in files) {
      try {
        final String jsonString = await rootBundle
            .loadString('assets/locales/${locale.languageCode}/$file.json');
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        merged[file] = jsonData;
      } catch (e) {
        // Bỏ qua file không tồn tại
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
        ChangeNotifierProvider(create: (_) => AttendanceProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, _) {
          // Khi đổi ngôn ngữ thì set lại locale cho context
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
              primaryColor: const Color(0xFF1A237E), // Màu xanh navy
              scaffoldBackgroundColor: const Color(0xFFF5F5F7),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1A237E),
                brightness: Brightness.light,
              ).copyWith(
                primary: const Color(0xFF1A237E),
                surface: Colors.white,
                surfaceContainerHighest: const Color(0xFFECEFF1),
                onSurface: const Color(0xFF263238),
                onSurfaceVariant: const Color(0xFF546E7A),
                outline: const Color(0xFFCFD8DC),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                foregroundColor: Color(0xFF263238),
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
              cardColor: Colors.white,
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12), // Bo góc thẻ card
                  side: const BorderSide(color: Color(0xFFECEFF1), width: 1),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCFD8DC)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              primaryColor: const Color(0xFF5C6BC0),
              scaffoldBackgroundColor: const Color(0xFF0F1419), // Cải thiện background
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF5C6BC0),
                brightness: Brightness.dark,
              ).copyWith(
                primary: const Color(0xFF5C6BC0),
                surface: const Color(0xFF1A2332), // Đồng bộ với card color
                surfaceContainerLow: const Color(0xFF1A2332),
                surfaceContainerHighest: const Color(0xFF2A3441),
                onSurface: const Color(0xFFE8EAED), // Cải thiện contrast
                onBackground: const Color(0xFFE8EAED),
                onSurfaceVariant: const Color(0xFFB4B9C4), // Softer variant color
                outline: const Color(0xFF2A3441),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF151B24), // Đồng bộ với hr_hub_page
                foregroundColor: Color(0xFFE8EAED),
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
              cardColor: const Color(0xFF1A2332), // Đồng bộ với hr_hub_page
              cardTheme: CardThemeData(
                color: const Color(0xFF1A2332),
                elevation: 0,
                shadowColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFF2A3441), width: 1),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: const Color(0xFF151A26),
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
