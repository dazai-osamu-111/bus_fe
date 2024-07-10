import 'package:bus_management/screens/deposit_screen.dart';
import 'package:bus_management/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  try {
    await dotenv.load(fileName: ".env");
    runApp(const MyApp());
  } catch (e) {
    print(e);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final GoRouter _router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
        ),
        // Bạn có thể thêm nhiều tuyến đường khác ở đây
        GoRoute(
          path: '/momo_callback',
          builder: (context, state) {
            final orderId = state
                .queryParams['orderId']; // Ensure queryParams is used correctly
            return DepositScreen(orderId: orderId);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
