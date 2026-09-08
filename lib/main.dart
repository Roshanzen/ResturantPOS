import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:restaurant_pos/app/bootstrap.dart';
import 'package:restaurant_pos/app/environment.dart';
import 'package:restaurant_pos/app/router.dart';
import 'package:restaurant_pos/features/auth/auth_controller.dart';
import 'package:restaurant_pos/providers/pos_provider.dart';
import 'package:restaurant_pos/theme/pos_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.initialize();
  runApp(const RestaurantPOSApp());
}

class RestaurantPOSApp extends StatelessWidget {
  const RestaurantPOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(
            value: AppBootstrap.authController),
        ChangeNotifierProvider<POSProvider>.value(
            value: AppBootstrap.posProvider),
      ],
      child: MaterialApp(
        title: AppEnvironment.current.appName,
        debugShowCheckedModeBanner: false,
        theme: PosTheme.darkTheme,
        initialRoute: '/',
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
