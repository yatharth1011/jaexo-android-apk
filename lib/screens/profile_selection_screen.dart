import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../managers/profile_manager.dart';
import '../managers/network_manager.dart';
import '../widgets/pattern_lock.dart';
import 'home_screen.dart';

class ProfileSelectionScreen extends StatefulWidget {
  const ProfileSelectionScreen({super.key});

  @override
  State<ProfileSelectionScreen> createState() => _ProfileSelectionScreenState();
}

class _ProfileSelectionScreenState extends State<ProfileSelectionScreen> {
  bool _creatingNew = false;
  String? _errorMessage;
  List<int>? _firstPattern;
  final TextEditingController _nameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final networkManager = context.watch<NetworkManager>();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'JAEXO ULTIMATE',
                style: theme.textTheme.displayLarge?.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 10),
              Text(
                'NETWORK: ${networkManager.currentSSID ?? "NOT CONNECTED"}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 40),
              if (!_creatingNew) ...[
                Text(
                  'NO PROFILE FOUND',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: networkManager.isConnected
                      ? () => setState(() => _creatingNew = true)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: theme.colorScheme.primary,
                    side: BorderSide(color: theme.colorScheme.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  ),
                  child: Text(
                    'CREATE NEW PROFILE',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                if (!networkManager.isConnected)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Connect to Wi-Fi to continue',
                      style: TextStyle(
                        color: theme.colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ] else ...[
                if (_firstPattern == null) ...[
                  Text(
                    'SET PATTERN LOCK',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Draw a pattern (min 4 dots)',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 30),
                  PatternLock(
                    onPatternComplete: (pattern) {
                      if (pattern.length >= 4) {
                        setState(() {
                          _firstPattern = pattern;
                          _errorMessage = null;
                        });
                      } else {
                        setState(() {
                          _errorMessage = 'Pattern too short (min 4 dots)';
                        });
                      }
                    },
                    errorMessage: _errorMessage,
                  ),
                ] else ...[
                  Text(
                    'CONFIRM PATTERN',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 30),
                  PatternLock(
                    onPatternComplete: (pattern) async {
                      if (_patternsMatch(_firstPattern!, pattern)) {
                        await _createProfile(context, pattern);
                      } else {
                        setState(() {
                          _errorMessage = 'PATTERNS DO NOT MATCH';
                          _firstPattern = null;
                        });
                      }
                    },
                    errorMessage: _errorMessage,
                  ),
                ],
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _creatingNew = false;
                      _firstPattern = null;
                      _errorMessage = null;
                    });
                  },
                  child: Text(
                    'CANCEL',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _patternsMatch(List<int> p1, List<int> p2) {
    if (p1.length != p2.length) return false;
    for (int i = 0; i < p1.length; i++) {
      if (p1[i] != p2[i]) return false;
    }
    return true;
  }

  Future<void> _createProfile(BuildContext context, List<int> pattern) async {
    final networkManager = context.read<NetworkManager>();
    final profileManager = context.read<ProfileManager>();

    await profileManager.createProfile(
      name: 'Default Profile',
      networkSSID: networkManager.currentSSID!,
      networkBSSID: networkManager.currentBSSID!,
      pattern: pattern,
    );

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
