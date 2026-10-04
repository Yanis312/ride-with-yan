import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../config.dart';
import '../data/bilingual.dart';
import '../data/videos.dart';
import '../l10n/app_localizations.dart';
import '../session/session_controller.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/mesh_background.dart';
import '../widgets/section_scaffold.dart';

/// Divertissement : vidéos courtes par thème, dans le lecteur officiel
/// YouTube intégré. Le volume reste plafonné pour ne pas gêner la conduite.
class EntertainmentScreen extends StatefulWidget {
  const EntertainmentScreen({super.key});

  @override
  State<EntertainmentScreen> createState() => _EntertainmentScreenState();
}

class _EntertainmentScreenState extends State<EntertainmentScreen> {
  late final YoutubePlayerController _player = YoutubePlayerController(
    params: const YoutubePlayerParams(
      showFullscreenButton: false,
      strictRelatedVideos: true,
      playsInline: true,
    ),
  );
  late final StreamSubscription<YoutubePlayerValue> _sub;
  SessionController? _session;

  int _category = 0;
  Video _current = videoCategories.first.videos.first;
  bool _playing = false;
  int _volume = AppConfig.maxMusicVolume;

  List<Video> get _videos => videoCategories[_category].videos;

  @override
  void initState() {
    super.initState();
    _sub = _player.listen((v) {
      final playing = v.playerState == PlayerState.playing;
      if (playing != _playing && mounted) {
        setState(() => _playing = playing);
        _session?.setMediaPlaying(playing);
      }
      // Vidéo terminée : on enchaîne sur la suivante du même thème.
      if (v.playerState == PlayerState.ended) _next();
    });
    _player.cueVideoById(videoId: _current.id);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _session = SessionScope.of(context);
  }

  @override
  void dispose() {
    _session?.setMediaPlaying(false);
    _sub.cancel();
    _player.close();
    super.dispose();
  }

  Future<void> _play(Video video) async {
    setState(() => _current = video);
    await _player.loadVideoById(videoId: video.id);
    await _player.setVolume(_volume);
  }

  void _next() {
    final i = _videos.indexOf(_current);
    _play(_videos[(i + 1) % _videos.length]);
  }

  void _toggle() => _playing ? _player.pauseVideo() : _player.playVideo();

  void _changeVolume(int delta) {
    setState(
      () => _volume = (_volume + delta).clamp(0, AppConfig.maxMusicVolume),
    );
    _player.setVolume(_volume);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = context.palette;
    final compact = MediaQuery.sizeOf(context).width < 900;

    final player = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE5533D)
                    .withValues(alpha: _playing ? 0.45 : 0.18),
                blurRadius: 70,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: YoutubePlayer(controller: _player, aspectRatio: 16 / 9),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _current.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(30, color: p.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_current.channel}  ·  ${_current.minutes} min',
                    style: AppText.body(15, color: p.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            LiquidIconButton(
              icon: AppIcons.volumeDown,
              size: 48,
              onTap: () => _changeVolume(-10),
            ),
            const SizedBox(width: 8),
            LiquidIconButton(
              icon: AppIcons.volumeUp,
              size: 48,
              onTap: () => _changeVolume(10),
            ),
            const SizedBox(width: 12),
            PillButton(
              label: _playing
                  ? const Bi('Pause', 'Pause').of(context)
                  : const Bi('Lecture', 'Play').of(context),
              onTap: _toggle,
              trailing: Icon(_playing ? AppIcons.pause : AppIcons.play),
            ),
            const SizedBox(width: 8),
            LiquidIconButton(icon: AppIcons.next, size: 48, onTap: _next),
          ],
        ),
      ],
    );

    final side = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: videoCategories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) => _Chip(
              label: videoCategories[i].label.of(context),
              icon: videoCategories[i].icon,
              selected: i == _category,
              onTap: () => setState(() => _category = i),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView.builder(
            key: ValueKey(_category),
            shrinkWrap: compact,
            physics: compact ? const NeverScrollableScrollPhysics() : null,
            itemCount: _videos.length,
            itemBuilder: (context, i) =>
                _VideoRow(
                      video: _videos[i],
                      active: _videos[i].id == _current.id,
                      playing: _playing,
                      onTap: () => _play(_videos[i]),
                    )
                    .animate()
                    .fadeIn(delay: (50 * i).ms, duration: 450.ms)
                    .slideX(begin: 0.06, delay: (50 * i).ms),
          ),
        ),
      ],
    );

    return SectionScaffold(
      scene: Scene.cinema,
      title: l10n.sectionEntertainment,
      child: compact
          ? ListView(
              children: [
                player,
                const SizedBox(height: 24),
                SizedBox(height: 120.0 + 96 * _videos.length, child: side),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 7, child: SingleChildScrollView(child: player)),
                const SizedBox(width: 28),
                Expanded(flex: 5, child: side),
              ],
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = selected ? Brand.ink : p.text;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        curve: AppMotion.spring,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: selected ? Brand.gold : p.glass,
          border: Border.all(color: selected ? Brand.gold : p.hairline),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppText.body(15, weight: FontWeight.w600, color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoRow extends StatelessWidget {
  const _VideoRow({
    required this.video,
    required this.active,
    required this.playing,
    required this.onTap,
  });

  final Video video;
  final bool active;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: active ? Brand.gold.withValues(alpha: 0.16) : p.glass,
            border: Border.all(color: active ? Brand.gold : p.hairline),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 124,
                  height: 70,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        video.thumbnail,
                        fit: BoxFit.cover,
                        // Sans réseau, une vignette neutre.
                        errorBuilder: (_, _, _) => ColoredBox(
                          color: p.hairline,
                          child: Icon(AppIcons.filmSlate, color: p.textMuted),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          margin: const EdgeInsets.all(5),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${video.minutes} min',
                            style: AppText.body(
                              11,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(
                        15,
                        weight: FontWeight.w600,
                        color: p.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      video.channel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.body(13, color: p.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                active && playing ? AppIcons.pause : AppIcons.play,
                color: active ? p.accentText : p.textMuted,
                size: 22,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
