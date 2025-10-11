import 'package:flutter/material.dart';
import 'screens/image_processing/image_processor.dart';

void main() {
  runApp(const PixelatorApp());
}

class PixelatorApp extends StatelessWidget {
  const PixelatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Pixelator',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _views = [
    ImageProcessor(),
    Text("something"),
    // ImageProcessor(),

  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _views[_currentIndex],
      appBar: AppBar(
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Text("Art Menu", style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.brush),
              title: const Text("Create Art"),
              onTap: () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context); // close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.collections),
              title: const Text("Saved Art"),
              onTap: () {
                setState(() => _currentIndex = 1);
                Navigator.pop(context); // close drawer
              },
            ),
          ],
        ),
      ),
    );
  }
}