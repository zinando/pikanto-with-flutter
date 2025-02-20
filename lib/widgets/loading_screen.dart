import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ScreenAnimator extends StatelessWidget {
  const ScreenAnimator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // display a text
        const SizedBox(height: 50.0),
        Text(
          'processing your request...',
          style: TextStyle(
            fontSize: 24.0,
            fontWeight: FontWeight.w100,
            color: Theme.of(context).colorScheme.tertiary,
          ),
        ),
        LoadingAnimationWidget.fourRotatingDots(
          color: Theme.of(context).colorScheme.primary,
          size: 50.0,
        ),
      ],
    );
  }
}

// Create a loading screen that will serve as a splash screen
class LoadingAnimator extends StatelessWidget {
  const LoadingAnimator({super.key});

  @override
  Widget build(BuildContext context) {
    return LoadingAnimationWidget.fourRotatingDots(
      color: Theme.of(context).colorScheme.primary,
      size: 50.0,
    );
  }
}

class BottomLoader extends StatelessWidget {
  const BottomLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // display a text
            const Text(
              'processing your request...',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w100,
              ),
            ),
            const SizedBox(height: 20.0),
            LoadingAnimationWidget.dotsTriangle(
              color: Theme.of(context).colorScheme.primary,
              size: 50.0,
            ),
          ],
        ),
      ),
    );
  }
}

class LinearLoader extends StatelessWidget {
  const LinearLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // display a text
            const Text(
              'processing, please wait...',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.w100,
              ),
            ),
            const SizedBox(height: 20.0),
            LinearProgressIndicator(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
