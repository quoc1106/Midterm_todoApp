import 'package:flutter/material.dart';
// Riverpod được sử dụng để quản lý state toàn cục cho ứng dụng này
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'frontend/components/app/app_initialization_widget.dart';
import 'package:intl/date_symbol_data_local.dart';

// Cấp độ 3 - FutureProvider Implementation
// Chuyển từ sync initialization sang async initialization với proper loading/error states
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize date formatting (sync operation, can stay here)
  await initializeDateFormatting('en_US', null);

  // Remove Hive initialization - moved to FutureProvider
  // This demonstrates Level 3: Async State Management

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AppInitializationWidget handles all async initialization với FutureProvider
    // Thay thế việc sync initialization trong main()
    return const AppInitializationWidget();
  }
}
