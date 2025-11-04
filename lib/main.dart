import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_page.dart';
import 'feed_page.dart';

//import 'feed_page.dart'; // will be used later when feed is ready

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: 'AIzaSyBuZOQ5t9qZ47DLd1IvwB9Ix-YvExdS59Y',
      authDomain: 'task-6742f.firebaseapp.com',
      databaseURL: 'https://task-6742f-default-rtdb.firebaseio.com',
      projectId: 'task-6742f',
      storageBucket: 'task-6742f.appspot.com',
      messagingSenderId: '843211975001',
      appId: '1:843211975001:web:1b3b04aa4c35a7c68d4448',
      measurementId: 'G-2K961435ZR',
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Realtime Posts (test)',
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snap.data;
        if (user == null) return const AuthPage();

        // Logged in → temporarily show placeholder until feed is done
        return FeedPage();
      },
    );
  }
}

class PlaceholderHome extends StatelessWidget {
  const PlaceholderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Logged in')),
      body: const Center(
        child: Text(
          'Logged in — profile flow active.',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
