import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();
  MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Firebase Authentication',
        theme: ThemeData(
          primarySwatch: Colors.green,
        ),
        home: FutureBuilder(
            future: _initialization,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Unexpected Error'));
              } else if (snapshot.hasData) {
                return const MyHomePage(title: 'Firebase Authentication');
              } else {
                return const CircularProgressIndicator();
              }
            }));
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FirebaseAuth auth;
  final String _email = 'emirbgt@hotmail.com';
  final String _password = 'password';
  @override
  void initState() {
    super.initState();
    auth = FirebaseAuth.instance;

    auth.authStateChanges().listen((User? user) {
      if (user == null) {
        debugPrint('User is currently signed out');
      } else {
        debugPrint(
            'User is signed in ${user.email} is verified ? ${user.emailVerified}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
                onPressed: () {
                  createUserEmailandPassword();
                },
                child: const Text('Register with E-mail')),
            const SizedBox(
              width: 10,
            ),
            ElevatedButton(
              onPressed: () {
                loginUserEmailandPassword();
              },
              child: const Text('Login with E-mail'),
            ),
            const SizedBox(
              width: 10,
            ),
            ElevatedButton(
              onPressed: () {
                signOutUser();
              },
              child: const Text('Sign out'),
            ),
            ElevatedButton(
              onPressed: () {
                deleteUser();
              },
              child: const Text('Delete Account'),
            ),
            ElevatedButton(
              onPressed: () {
                changePassword();
              },
              child: const Text('Change Password'),
            ),
            ElevatedButton(
              onPressed: () {
                changeEmail();
              },
              child: const Text('Change Email'),
            ),
          ],
        ),
      ),
    );
  }

  void createUserEmailandPassword() async {
    try {
      var _userCredential = await auth.createUserWithEmailAndPassword(
          email: _email, password: _password);
      var _currentUser = _userCredential.user;

      //mail verification
      if (!_currentUser!.emailVerified) {
        await _currentUser.sendEmailVerification();
      } else {
        debugPrint('E-mail is verified');
      }
      debugPrint(_userCredential.toString());
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void loginUserEmailandPassword() async {
    try {
      var _userCredential = await auth.signInWithEmailAndPassword(
          email: _email, password: _password);
      debugPrint(_userCredential.toString());
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void signOutUser() async {
    await auth.signOut();
  }

  void deleteUser() async {
    if (auth.currentUser != null) {
      await auth.currentUser!.delete();
    } else {
      debugPrint('User is currently signed out');
    }
  }

  void changePassword() async {
    try {
      await auth.currentUser!.updatePassword('password');
      await auth.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        debugPrint('reauthenticate');
        var credential =
            EmailAuthProvider.credential(email: _email, password: _password);
        await auth.currentUser!.reauthenticateWithCredential(credential);
        await auth.currentUser!.updatePassword('password');
        await auth.signOut();
        debugPrint('Password is Updated');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void changeEmail() async {
    try {
      await auth.currentUser!.updateEmail('emir@emir.com');
      await auth.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        debugPrint('reauthenticate');
        var credential =
            EmailAuthProvider.credential(email: _email, password: _password);
        await auth.currentUser!.reauthenticateWithCredential(credential);
        await auth.currentUser!.updateEmail('emir@emir.com');
        await auth.signOut();
        debugPrint('Email is Updated');
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}
