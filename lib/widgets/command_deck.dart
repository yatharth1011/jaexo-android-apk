import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../managers/music_manager.dart';
import '../utils/theme.dart';

class CommandDeck extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onToggle;
  final Function(String) onThemeChange;
  final VoidCallback onResetDay;

  const CommandDeck({
    super.key,
    required this.isOpen,
    required this.onToggle,
    required this.onThemeChange,
    required this.onResetDay,
  });

  @override
  State<CommandDeck> createState() => _CommandDeckState();
}

class _CommandDeckState extends State<CommandDeck> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _controller;
  late Animation<double> _heightFactor;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _heightFactor = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    if (widget.isOpen) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CommandDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen != oldWidget.isOpen) {
      if (widget.isOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final musicManager = context.watch<MusicManager>();

    return AnimatedBuilder(
      animation: _heightFactor,
      builder: (context, child) {
        return ClipRect(
          child: Align(
            heightFactor: _heightFactor.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0A0A).withOpacity(0.95),
          border: Border.all(color: theme.colorScheme.secondary),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeRow(theme),
            const SizedBox(height: 12),
            _buildMusicSearch(theme, musicManager),
            const SizedBox(height: 12),
            _buildMusicControls(theme, musicManager),
            const SizedBox(height: 12),
            _buildActionButtons(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeRow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _themeButton(JaexoTheme.matrix, const Color(0xFF00FF41)),
        _themeButton(JaexoTheme.redline, const Color(0xFFFF0000)),
        _themeButton(JaexoTheme.deepspace, const Color(0xFF00DDFF)),
        _themeButton(JaexoTheme.amber, const Color(0xFFFFBB00)),
        _themeButton(JaexoTheme.ghost, const Color(0xFFE0E0E0)),
      ],
    );
  }

  Widget _themeButton(String theme, Color color) {
    return GestureDetector(
      onTap: () => widget.onThemeChange(theme),
      child: Container(
        width: 15,
        height: 15,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF333333)),
        ),
      ),
    );
  }

  Widget _buildMusicSearch(ThemeData theme, MusicManager musicManager) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            style: theme.textTheme.bodyLarge?.copyWith(fontSize: 12),
            decoration: InputDecoration(
              hintText: 'Search RVX...',
              hintStyle: TextStyle(color: theme.colorScheme.secondary, fontSize: 12),
              filled: true,
              fillColor: const Color(0xFF111111),
              border: const OutlineInputBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            ),
            onSubmitted: (_) => _playMusic(musicManager),
          ),
        ),
        GestureDetector(
          onTap: () => _playMusic(musicManager),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
            ),
            child: const Text(
              'PLAY',
              style: TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => _queueMusic(musicManager),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF444444),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
            child: Text(
              '+Q',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMusicControls(ThemeData theme, MusicManager musicManager) {
    return Row(
      children: [
        if (musicManager.artworkUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              musicManager.artworkUrl!,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.music_note),
            ),
          )
        else
          const Icon(Icons.music_note, size: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                musicManager.currentTitle,
                style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                musicManager.currentArtist,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 10,
                  color: theme.colorScheme.secondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Row(
          children: [
            _iconButton(theme, Icons.skip_previous, () => musicManager.sendMediaControl('prev')),
            _iconButton(theme, Icons.play_pause, () => musicManager.sendMediaControl('playpause')),
            _iconButton(theme, Icons.skip_next, () => musicManager.sendMediaControl('next')),
          ],
        ),
      ],
    );
  }

  Widget _iconButton(ThemeData theme, IconData icon, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(icon, color: theme.colorScheme.primary),
      onPressed: onPressed,
      iconSize: 20,
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: widget.onResetDay,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.colorScheme.error),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: Text(
              'RESET DAY',
              style: TextStyle(
                color: theme.colorScheme.error,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _playMusic(MusicManager musicManager) {
    if (_searchController.text.isNotEmpty) {
      musicManager.playSearch(_searchController.text);
      _searchController.clear();
    }
  }

  void _queueMusic(MusicManager musicManager) {
    if (_searchController.text.isNotEmpty) {
      musicManager.addToQueue(_searchController.text);
      _searchController.clear();
    }
  }
}
