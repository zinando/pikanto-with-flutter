import 'package:flutter/material.dart';
import 'package:pikanto/resources/settings.dart';
import 'package:pikanto/screens/auth/change_password.dart';
import 'package:pikanto/screens/auth/login.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Profile Data',
                  style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              // add a button to log out: it will navigate to the login screen
              ElevatedButton(
                onPressed: () {
                  // stop the user specific listening
                  SocketManager().stopListening(
                      'notification_response_${currentUser["userId"]}');
                  // Navigate to the login screen after initialization
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                      builder: (context) => const AuthenticationScreen()));
                },
                child: const Text('Log Out'),
              ),
            ],
          ),
          const SizedBox(height: 30.0),
          Row(
            children: [
              const Icon(Icons.person, size: 24.0),
              const SizedBox(width: 16.0),
              Text(currentUser['fullName'].toString(),
                  style: const TextStyle(fontSize: 16.0, color: Colors.black)),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.email, size: 24.0),
              const SizedBox(width: 16.0),
              Text(currentUser['email'].toString(),
                  style: const TextStyle(fontSize: 16.0, color: Colors.black)),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.admin_panel_settings, size: 24.0),
              const SizedBox(width: 16.0),
              Text(currentUser['adminType'].toString(),
                  style: const TextStyle(fontSize: 16.0, color: Colors.black)),
            ],
          ),
          const SizedBox(height: 26.0),
          const Text('Change Password',
              style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          const SizedBox(height: 16.0),
          SizedBox(
              width: MediaQuery.of(context).size.width * 0.5,
              child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: const ChangePasswordScreen())),
        ],
      ),
    );
  }
}
