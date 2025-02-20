import 'package:flutter/material.dart';
import 'package:pikanto/output/search_view.dart';
import 'package:pikanto/output/audit_trail.dart';
import 'package:pikanto/resources/settings.dart';
import 'package:pikanto/screens/auth/change_user_password.dart';
import 'package:pikanto/output/user_permissions.dart';

class TabViewScreen extends StatefulWidget {
  const TabViewScreen({super.key});
  @override
  State createState() => _TabViewScreenState();
}

class _TabViewScreenState extends State<TabViewScreen> {
  // List of menu titles
  final List<String> menuTitles = [
    "Search Weight Records",
    if (currentUser['permissions']['canChangeUserPassword']) ...[
      "Change User Password",
      "Audit Trail",
      "User Permissions",
    ]
  ];

  // Current selected menu index
  int selectedMenuIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Menu buttons at the top
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(menuTitles.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _buildMenuButton(index),
                );
              }),
            ),
            const SizedBox(height: 20), // Spacing between menu and content
            // Display different content based on the selected menu
            Expanded(
              child: _buildSelectedView(),
            ),
          ],
        ),
      ),
    );
  }

  // Function to build each menu button
  Widget _buildMenuButton(int index) {
    bool isSelected = selectedMenuIndex == index;

    return isSelected
        ? TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.grey[200], // Blends with background
              foregroundColor: Colors.black, // Text color
            ),
            onPressed: () {},
            child: Text(menuTitles[index]),
          )
        : ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black, // Dark color when not selected
            ),
            onPressed: () {
              setState(() {
                selectedMenuIndex = index; // Update selected index
              });
            },
            child: Text(menuTitles[index],
                style: TextStyle(color: Theme.of(context).primaryColor)),
          );
  }

  // Function to build the view based on selected menu
  Widget _buildSelectedView() {
    switch (selectedMenuIndex) {
      case 0:
        return const Center(child: SearchView());
      case 1:
        return const Center(child: ChangeUserPassword());
      case 2:
        return const Center(child: AuditTrailWidget());
      case 3:
        return const Center(child: PermissionsWidget());
      default:
        return Container();
    }
  }
}
