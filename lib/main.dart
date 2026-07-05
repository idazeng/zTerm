import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'constants/constants.dart';
import 'models/models.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'utils/theme.dart';
import 'theme/app_page_route.dart';

/// 应用入口
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化共享偏好设置
  await SharedPreferences.getInstance();
  
  runApp(
    const ProviderScope(
      child: ZsshxApp(),
    ),
  );
}

/// 应用根组件
class ZsshxApp extends ConsumerWidget {
  const ZsshxApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    
    // 根据设置确定主题模式
    ThemeMode themeMode;
    switch (settings.themeMode) {
      case AppThemeMode.light:
        themeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        themeMode = ThemeMode.dark;
        break;
      default:
        themeMode = ThemeMode.system;
    }
    
    return MaterialApp(
      title: 'zTerm',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(settings.themeColorIndex),
      darkTheme: AppTheme.getDarkTheme(settings.themeColorIndex),
      themeMode: themeMode,
      // 使用系统默认字体
      builder: (context, child) {
        return DefaultTextStyle(
          style: Theme.of(context).textTheme.bodyMedium!,
          child: child!,
        );
      },
      onGenerateRoute: (settings) {
        return AppPageRoute(page: settings.arguments as Widget, settings: settings);
      },
      home: const HomeScreen(),
    );
  }
}
