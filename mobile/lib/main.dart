import 'package:flutter/material.dart';
import 'package:camera/camera.dart'; // <-- import camera
import 'pages/home_page.dart';
import 'pages/camera_page.dart'; // ISHI-AI Check
import 'pages/profile_page.dart';
import 'widgets/floating_nav.dart';
import 'pages/about_page.dart';
import 'pages/food_page.dart';
// Ensures Isar native libraries are bundled in release builds.
// import 'package:isar_flutter_libs/isar_flutter_libs.dart' as _;

// Global variable to store cameras
late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras(); // initialize cameras
  runApp(const ISHIApp());
}

class ISHIApp extends StatefulWidget {
  const ISHIApp({super.key});
  @override
  State<ISHIApp> createState() => _ISHIAppState();
}

class _ISHIAppState extends State<ISHIApp> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISHI App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2B5CFF),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF2B5CFF),
        brightness: Brightness.dark,
      ),
      home: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _index,
            children: [
              HomePage(),
              CameraPage(),          // ISHI-AI Check
              _EventsPage(),
              ProfilePage(),         // ← real Profile page (Google OAuth + local storage)
              FoodPage(camera: cameras.first), // ← macro tracking page
              AboutPage(),
              _DonatePage(),
            ],
          ),
        ),
        bottomNavigationBar: FloatingNavBar(
          currentIndex: _index,
          onTap: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}

// Lightweight placeholders (you can expand later)
class _EventsPage extends StatelessWidget {
  const _EventsPage();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Events coming soon'));
}

class _DonatePage extends StatelessWidget {
  const _DonatePage();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Donate link / QR here'));
}