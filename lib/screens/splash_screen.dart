import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../managers/profile_manager.dart';
import '../managers/network_manager.dart';
import 'profile_selection_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final profileManager = context.read<ProfileManager>();
    await profileManager.init();

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    if (profileManager.currentProfile == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileSelectionScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'JAEXO ULTIMATE',
                style: theme.textTheme.displayLarge?.copyWith(
                  fontSize: 36,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 40),
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
