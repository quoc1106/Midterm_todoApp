import 'package:flutter/material.dart';
// Riverpod được sử dụng để quản lý state toàn cục cho ứng dụng này
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/todo/screens/todo_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/todo_model.dart';
import 'models/section_model.dart';
import 'models/project_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_US', null);

  // Khởi tạo Hive và đăng ký adapter cho Todo, Section, Project
  await Hive.initFlutter();
  Hive.registerAdapter(TodoAdapter());
  Hive.registerAdapter(SectionModelAdapter());
  // Đăng ký adapter cho ProjectModel
  Hive.registerAdapter(ProjectModelAdapter());
  await Hive.openBox<Todo>('todos');
  await Hive.openBox<SectionModel>('sections');
  await Hive.openBox<ProjectModel>('projects');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App with Riverpod',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TodoScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
