import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lab_mid/pages/home_page.dart';
import 'package:lab_mid/pages/signup_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false; // State variable to track loading state
  bool _rememberMe = false; // State variable to track "Remember Me" checkbox

  Future<bool> _authenticateUser(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
              email: _emailController.text, password: _passwordController.text);

      // Reset the text fields after successful authentication
      _emailController.clear();
      _passwordController.clear();

      return true; // User authentication successful
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred. Please try again later.';

      // Customize error messages based on the error code
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided for that user.';
      }

      // Show the error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );

      return false; // User authentication failed
    } catch (error) {
      // Show a generic error message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred. Please try again later.'),
        ),
      );

      // Print detailed error message to the console for debugging
      print("Error signing in with email: $error");

      return false; // User authentication failed
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId:
            '876196456698-55olnpnoig1d0epi2pb09na98lebosa8.apps.googleusercontent.com',
      );

      final GoogleSignInAccount? googleSignInAccount =
          await googleSignIn.signIn();

      if (googleSignInAccount != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleSignInAccount.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        await FirebaseAuth.instance.signInWithCredential(credential);

        // Navigate to the home screen after successful sign-in
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
      }
    } catch (error) {
      // Handle Google sign-in errors
      String errorMessage = 'An error occurred. Please try again later.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
        ),
      );

      if (kDebugMode) {
        print("Error signing in with Google: $error");
      }
    } finally {
      // Set loading state to false
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Resource?> signInWithFacebook() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final LoginResult result = await FacebookAuth.instance.login();
      switch (result.status) {
        case LoginStatus.success:
          final AuthCredential facebookCredential =
              FacebookAuthProvider.credential(result.accessToken!.token);
          final userCredential = await FirebaseAuth.instance
              .signInWithCredential(facebookCredential);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ),
          );
          return Resource(status: Status.Success);
        case LoginStatus.cancelled:
          return Resource(status: Status.Cancelled);
        case LoginStatus.failed:
          return Resource(status: Status.Error);
        default:
          return null;
      }
    } on FirebaseAuthException {
      rethrow;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.1),
              Center(
                child: Image.asset(
                  'lib/assets/cignifi.jpeg',
                  width: 200,
                ),
              ),
              Text(
                'Login to your Account',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  hintText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value!;
                          });
                        },
                      ),
                      Text(
                        'Remember Me',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () async {
                              final isAuthenticated =
                                  await _authenticateUser(context);

                              if (isAuthenticated) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HomePage(),
                                  ),
                                );
                              }
                            },
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : const Text('Sign in'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Or sign in with',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: _isLoading ? null : _signInWithGoogle,
                    child: Container(
                      width: 80,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.google,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  InkWell(
                    onTap: _isLoading ? null : signInWithFacebook,
                    child: Container(
                      width: 80,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.facebook,
                          size: 40, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: 20),
                  InkWell(
                    onTap: () {},
                    child: Container(
                      width: 80,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(FontAwesomeIcons.twitter,
                          size: 40, color: Colors.blue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: () {
                  // Navigate to the sign-up page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpPage(),
                    ),
                  );
                },
                child: Text(
                  "Don't have an account? Sign up",
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Colors.blue,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class Resource {
  final Status? status;

  Resource({this.status});
}

// ignore: constant_identifier_names
enum Status { Success, Cancelled, Error }
