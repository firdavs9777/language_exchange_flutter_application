import 'package:bananatalk_app/service/authentication.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Login extends ConsumerStatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends ConsumerState<Login> {
  late TextEditingController _phoneNumberController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _phoneNumberController = TextEditingController(text: '+');
    _passwordController = TextEditingController();
    // ref.watch(authStatesProvider);
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: Text('Hisobga Kirish'),
      ),
      backgroundColor: Theme.of(context).colorScheme.onSecondary,
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Text(
                'Login',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                  fontSize: 18,
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _phoneNumberController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelText: 'Email',
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                labelText: 'Password',
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            SizedBox(height: 24.0),
            SizedBox(
              width: 200.0,
              child: ElevatedButton(
                onPressed: () async {
                  final String phoneNumber = _phoneNumberController.text;
                  final String password = _passwordController.text;
                  Authentication.login(phoneNumber, password);
                  // final check = await authService.login(phoneNumber, password);

                  // if (check != null) {7
                  //
                  //   print(test);
                  //   print('test');
                  // }
                  // if (check != null) {
                  //   // Navigate to the home screen upon successful login.
                  //   Navigator.of(context).push(MaterialPageRoute(
                  //       builder: (ctx) => const TabsScreen()));
                  // } else {
                  //   // Display an error message if login fails.
                  //   ScaffoldMessenger.of(context)
                  //       .showSnackBar(SnackBar(content: Text('Login failed')));
                  // }
                  // Implement your logic here
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 12.0,
                  ),
                ),
                child: Text(
                  'Kirish',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {
                    // Implement your forgot password logic here
                  },
                  child: Text('Forgot password?'),
                ),
                TextButton(
                  onPressed: () {
                    //   Navigator.of(context)
                    //       .push(MaterialPageRoute(builder: (ctx) => Register()));
                    //
                  },
                  child: Text('Register'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
