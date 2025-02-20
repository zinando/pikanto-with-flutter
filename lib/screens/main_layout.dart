import "package:flutter/material.dart";
import "package:pikanto/resources/settings.dart";
import "home_screen.dart";
import "data_screens/product_screen.dart";
import "data_screens/haulier_screen.dart";
import 'data_screens/customer_screen.dart';
import 'data_screens/user_screen.dart';
import 'data_screens/weight_records_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_screens/profile_screen.dart';
import 'data_screens/settings_screen.dart';
import 'data_screens/tabview.dart';
import 'package:provider/provider.dart';
import 'package:pikanto/helpers/my_functions.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final GlobalKey<_MainLayoutState> mainLayoutKey =
      GlobalKey<_MainLayoutState>();
  int selectedScreenIndex = 0;
  String _caption = 'Loading...'; // Initial caption text
  List<IconData> gridButtonIcons = [
    Icons.person,
    Icons.settings,
    Icons.menu,
  ];
  Color iconColor = themeData[settingsData['appTheme']].colorScheme.tertiary;
  Color icon2Color = themeData[settingsData['appTheme']].colorScheme.tertiary;
  Color icon3Color = themeData[settingsData['appTheme']].colorScheme.tertiary;

  List<String> gridButtonLabels = [
    "Profile",
    "Settings",
    "Menu",
  ];

  List<Widget> screenList = [
    const HomeScreen(),
    const DataHistory(),
    const UserScreen(),
    const ProductListWidget(),
    const HauliersPage(),
    const CustomerScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Load the last recorded weight from SharedPreferences
    _loadCaption();
    // listen to the last recorded weight notifier
    lastRecordedWeightNotifier.addListener(_updateCaption);
  }

  // Function to load data from SharedPreferences
  Future<void> _loadCaption() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedWeight = prefs.getString('lastRecordedWeight');

    // Set the retrieved value to _caption, if null assign a default value
    setState(() {
      _caption = savedWeight ?? 'None';
    });
  }

  void actionGridButtonsTap(int index) {
    if (index + 6 < 9) {
      setState(() {
        selectedScreenIndex = index + 6;
      });
    }
  }

  void changeSelectedScreenIndex(int index) {
    if (index == 1 && currentUser['permissions']['canViewWeightRecord']) {
      selectedScreenIndex = index;
    } else if (index == 2 && currentUser['permissions']['canViewUser']) {
      selectedScreenIndex = index;
    } else if (index == 3 && currentUser['permissions']['canViewProduct']) {
      selectedScreenIndex = index;
    } else if (index == 4 && currentUser['permissions']['canViewHaulier']) {
      selectedScreenIndex = index;
    } else if (index == 5 && currentUser['permissions']['canViewCustomer']) {
      selectedScreenIndex = index;
    } else if (index == 0) {
      selectedScreenIndex = index;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _updateCaption() {
    setState(() {
      _caption = lastRecordedWeightNotifier.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get device scaling factor and screen size
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    //double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    const refWidth = 1368.0;
    const refHeight = 841.5;

    bool smallWidth = screenWidth < (900 * (refWidth / screenWidth));
    bool smallHeight = screenHeight <= (700 * (refHeight / screenHeight));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        automaticallyImplyLeading: false,
        toolbarHeight: screenHeight * 0.14, // Make toolbar height responsive
        title: Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 10, 0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(2, 10, 2, 20),
                color: Theme.of(context).colorScheme.primary,
                width: screenWidth * 0.18, // Responsive width
                child: Card(
                  elevation: 20.0,
                  child: AspectRatio(
                    aspectRatio: 17 / 7,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: Image.asset(settingsData['appLogoAlt']),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Card(
                      margin: const EdgeInsets.all(16),
                      elevation: 10.0,
                      child: Center(
                        child: Container(
                          alignment: Alignment.center,
                          width: constraints.maxWidth,
                          height: screenHeight *
                              0.1, // Adjust height based on screen size
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Last Measured Weight:",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.tertiary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16 *
                                      (screenWidth /
                                          screenHeight), // Responsive text size
                                ),
                              ),
                              SizedBox(width: 40.0 * (screenWidth / refWidth)),
                              Text(
                                _caption.toString(),
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16 *
                                      (screenWidth /
                                          screenHeight), // Responsive text size
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: Row(
        children: [
          Container(
            padding: const EdgeInsetsDirectional.all(8.0),
            width: screenWidth * 0.2, // Responsive side menu width
            color: Theme.of(context).colorScheme.primary,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: screenList.length,
                    itemBuilder: (context, index) {
                      return MenuButton(
                        index: index,
                        onPressed: () => changeSelectedScreenIndex(index),
                      );
                    },
                  ),
                ),
                //if (!smallHeight)
                Container(
                  alignment: Alignment.center,
                  color: Theme.of(context).colorScheme.onPrimary,
                  width: screenWidth *
                      0.2, // Responsive grid button container width
                  height: screenHeight * 0.08, // Adjusted for different screens
                  child: smallHeight || smallWidth
                      ? _buildGridButtonsAlt()
                      : _buildGridButtons(),
                )
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Center(
                child: selectedScreenIndex == 6
                    ? const ProfilePage()
                    : selectedScreenIndex == 7
                        ? const SettingsScreen()
                        : selectedScreenIndex == 8
                            ? const TabViewScreen()
                            : screenList[selectedScreenIndex],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridButtons() {
    //double screenWidth = MediaQuery.of(context).size.width;
    //double screenHeight = MediaQuery.of(context).size.height;
    //double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: gridButtonIcons.length, // Number of items per row
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.2, // Aspect ratio of each item
      ),
      itemCount: gridButtonIcons.length,
      itemBuilder: (context, index) {
        return GridMenuButton(
          index: index,
          menuIcons: gridButtonIcons,
          menuIconsLabel: gridButtonLabels,
          onPressed: () {
            actionGridButtonsTap(index);
          },
        );
      },
    );
  }

  Widget _buildGridButtonsAlt() {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    //double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    double availableHeight = screenHeight * 0.08;
    double availableWidth = (screenWidth * 0.2) / 3;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        MouseRegion(
          onEnter: (_) {
            setState(() {
              iconColor = Theme.of(context).colorScheme.primary;
            });
          },
          onExit: (_) {
            setState(() {
              iconColor = Theme.of(context).colorScheme.tertiary;
            });
          },
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () => actionGridButtonsTap(0),
            child: Icon(
              Icons.person,
              color: iconColor,
              size: 22 * (availableWidth / availableHeight),
            ),
          ),
        ),
        MouseRegion(
          onEnter: (_) {
            setState(() {
              icon2Color = Theme.of(context).colorScheme.primary;
            });
          },
          onExit: (_) {
            setState(() {
              icon2Color = Theme.of(context).colorScheme.tertiary;
            });
          },
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () => actionGridButtonsTap(1),
            child: Icon(
              Icons.settings,
              color: icon2Color,
              size: 22 * (availableWidth / availableHeight),
            ),
          ),
        ),
        MouseRegion(
          onEnter: (_) {
            setState(() {
              icon3Color = Theme.of(context).colorScheme.primary;
            });
          },
          onExit: (_) {
            setState(() {
              icon3Color = Theme.of(context).colorScheme.tertiary;
            });
          },
          cursor: SystemMouseCursors.click,
          child: InkWell(
            onTap: () => actionGridButtonsTap(2),
            child: Icon(
              Icons.menu,
              color: icon3Color,
              size: 22 * (availableWidth / availableHeight),
            ),
          ),
        ),
      ],
    );
  }
}

// Create menu buttons using the Card widget
class MenuButton extends StatefulWidget {
  final int index;
  //final GlobalKey<_MainLayoutState> mainLayoutKey;
  final VoidCallback? onPressed; // Optional callback function

  const MenuButton({super.key, required this.index, required this.onPressed});

  @override
  State createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  List<String> menuILabels = [
    "Home",
    "Data History",
    "User Records",
    "Product Records",
    "Haulier Records",
    "Customer Records",
  ];

  List<IconData> menuIcons = [
    Icons.home,
    Icons.history,
    Icons.person,
    Icons.insert_emoticon,
    Icons.emoji_transportation,
    Icons.group,
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200), // Duration of the animation
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weightRecordsProvider = context.watch<WeightRecordsProvider>();
    int itemsToBeApproved = MyFunctions.countItemsToBeApproved(
        weightRecordsProvider.weightRecordsList);
    bool smallScreen = MediaQuery.of(context).size.width < 800;
    return MouseRegion(
      onEnter: (_) => _controller.forward(), // Start the animation on hover
      onExit: (_) =>
          _controller.reverse(), // Revert the animation when not hovering
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          shadowColor: Theme.of(context).primaryColorDark,
          color: Theme.of(context).colorScheme.tertiary,
          margin: const EdgeInsets.all(8.0),
          elevation: 10.0, // Adjust elevation as needed
          child: InkWell(
            onTap: widget.onPressed, // Handle button press
            child: Container(
              width: MediaQuery.of(context).size.width *
                  0.2, // 20% of screen width
              height: (MediaQuery.of(context).size.height * 0.58) /
                  menuILabels.length,
              alignment: Alignment.center, // Center the content
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      menuIcons[widget.index],
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      size: 40.0,
                    ),
                    if (!smallScreen) const SizedBox(width: 16),
                    if (!smallScreen)
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.2 - 100,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              menuILabels[widget.index],
                              softWrap: true,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // circular shape
                            widget.index == 1 && itemsToBeApproved > 0
                                ? Container(
                                    width: 20, // Diameter of the circle
                                    height: 20,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                      // border: Border.all(
                                      //     color: Colors.black, width: 2),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$itemsToBeApproved',
                                        style: TextStyle(
                                          fontSize: 11, // Size of the number
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Create 3 grid menu buttons using the Card widget
class GridMenuButton extends StatefulWidget {
  final int index;
  final List<IconData> menuIcons;
  final List<String> menuIconsLabel;
  final VoidCallback onPressed;

  const GridMenuButton({
    super.key,
    required this.index,
    required this.menuIcons,
    required this.menuIconsLabel,
    required this.onPressed,
  });

  @override
  State createState() => _GridMenuButtonState();
}

class _GridMenuButtonState extends State<GridMenuButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200), // Duration of the animation
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    //double devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    return MouseRegion(
      onEnter: (_) => _controller.forward(), // Start the animation on hover
      onExit: (_) =>
          _controller.reverse(), // Revert the animation when not hovering
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          shadowColor: Theme.of(context).colorScheme.primary,
          color: Theme.of(context).colorScheme.tertiary,
          //margin: const EdgeInsets.all(8.0),
          elevation: 10.0, // Adjust elevation as needed
          child: InkWell(
            onTap: widget.onPressed, // Handle button press
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Column(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Icon(
                          widget.menuIcons[widget.index],
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          size: (screenWidth * 0.05) /
                              widget.menuIcons.length, // Adjust icon size
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 4.0,
                    ),
                    Expanded(
                        //height: 20.0,
                        child: Text(widget.menuIconsLabel[widget.index],
                            style: TextStyle(
                                fontSize: 6.0 * (screenWidth / screenHeight))))
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
