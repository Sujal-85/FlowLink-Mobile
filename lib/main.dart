import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flowlink_mobile/ui/app_theme.dart';
import 'package:flowlink_mobile/ui/main_tabs_screen.dart';
import 'package:flowlink_mobile/ui/splash_screen.dart';
import 'package:flowlink_mobile/ui/onboarding_screen.dart';
import 'package:flowlink_mobile/ui/onboarding_screen2.dart';
import 'package:flowlink_mobile/ui/onboarding_screen3.dart';
import 'package:flowlink_mobile/ui/login_screen.dart';
import 'package:flowlink_mobile/ui/signup_screen.dart';
import 'package:flowlink_mobile/ui/welcome_screen.dart';
import 'package:flowlink_mobile/ui/congratulations_screen.dart';
import 'package:flowlink_mobile/ui/location_select_screen.dart';
import 'package:flowlink_mobile/ui/location_intro_screen.dart';
import 'package:flowlink_mobile/ui/phone_input_screen.dart';
import 'package:flowlink_mobile/ui/personal_details_screen.dart';
import 'package:flowlink_mobile/services/cart_service.dart';
import 'package:flowlink_mobile/services/purchase_history_service.dart';
import 'package:flowlink_mobile/services/theme_service.dart';
import 'package:flowlink_mobile/services/orders_service.dart';
import 'package:flowlink_mobile/ui/orders_list_screen.dart';
import 'package:flowlink_mobile/services/favorites_service.dart';
import 'package:flowlink_mobile/services/auth_service.dart';
import 'package:flowlink_mobile/widgets/loader_navigator_observer.dart';
import 'package:flowlink_mobile/services/db_service.dart';
import 'package:flowlink_mobile/services/content_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CartService.instance.init();
  await PurchaseHistoryService.instance.init();
  await ThemeService.instance.init();
  await DbService.instance.init();
  await ContentService.instance.init();
  await OrdersService.instance.init();
  await FavoritesService.instance.init();
  await AuthService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeService.instance.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'FlowLink',
          theme: buildTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: mode,
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.stylus,
            },
          ),
          navigatorObservers: [LoaderNavigatorObserver()],
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            final scale = (mq.size.width / 375.0).clamp(0.9, 1.15);
            final themedChild = MediaQuery(
              data: mq.copyWith(textScaler: TextScaler.linear(scale)),
              child: child ?? const SizedBox.shrink(),
            );
            return themedChild;
          },
          home: const SplashScreen(),
          routes: {
            '/home': (_) => const MainTabsScreen(),
            '/orders': (_) => const OrdersListScreen(),
            '/login': (_) => LoginScreen(),
            '/signup': (_) => SignupScreen(),
            '/welcome': (_) => const WelcomeScreen(),
            '/congrats': (_) => const CongratulationsScreen(),
            '/phone': (_) => const PhoneInputScreen(),
            '/onboarding': (_) => OnboardingScreen(),
            '/onboarding2': (_) => OnboardingScreen2(),
            '/onboarding3': (_) => OnboardingScreen3(),
            '/splash': (_) => SplashScreen(),
            '/select-location': (_) => const LocationIntroScreen(),
            '/personal-details': (_) => const PersonalDetailsScreen(),
            // Existing map picker moved under a dedicated route
            '/select-location/map': (_) => const LocationSelectScreen(),
          },
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
