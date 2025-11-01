import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 await Firebase.initializeApp(
  options: FirebaseOptions(
    apiKey: 'AIzaSyBuZQ0St9qZ47LDd1vwB9Ix-YvExdS59Y',
    authDomain: 'task-6742f.firebaseapp.com',
    databaseURL: 'https://task-6742f-default-rtdb.firebaseio.com',
    projectId: 'task-6742f',
    storageBucket: 'task-6742f.appspot.com',
    messagingSenderId: '843211975001',
    appId: '1:843211975001:web:1b3b04aa4c35a7c68d4448',
    measurementId: 'G-2K961435ZR',
  ),
);
 // uses the firebase config you put in web/index.html
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Realtime Posts (test)',
      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _status = 'Checking Firebase...';

  @override
  void initState() {
    super.initState();
    // quick smoke test: check that Firebase.initializeApp completed and update UI
    Future.microtask(() {
      setState(() => _status = 'Firebase initialized — ready.');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Realtime Posts — Smoke Test')),
      body: Center(child: Text(_status)),
    );
  }
}
