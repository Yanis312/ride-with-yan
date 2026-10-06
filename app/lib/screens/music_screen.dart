import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../config.dart';
import '../data/bilingual.dart';
import '../data/music.dart';
import '../l10n/app_localizations.dart';
import '../navigation/sections.dart';
import '../session/session_controller.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/mesh_background.dart';
import '../widgets/section_scaffold.dart';

/// Coin musique : le lecteur officiel YouTube intégré (gratuit, légal),
/// la chanson de Yanis en vedette, et une sélection par ambiance.
/// Le son sort de la tablette (ou des haut-parleurs de la voiture en Bluetooth).
class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key, this.autoPlayFavorite = false});

  /// Lance directement la chanson de Yanis (bouton "Fais-moi écouter").
  final bool autoPlayFavorite;

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen> {
  late final YoutubePlayerController _player = YoutubePlayerController(
    params: const YoutubePlayerParams(
      showFullscreenButton: false,
      strictRelatedVideos: true,
      playsInline: true,
    ),
  );
  late final StreamSubscription<YoutubePlayerValue> _sub;

  Track _current = yanFavorite;
  bool _playing = false;
  bool _wasEnded = false;
  int _volume = AppConfig.maxMusicVolume;
  Bi? _mood;

  @override
  void initState() {
    super.initState();
    _sub = _player.listen((v) {
      final playing = v.playerState == PlayerState.playing;
      if (playing != _playing && mounted) {
        setState(() => _playing = playing);
        SessionScope.of(context).setMediaPlaying(playing);
        // Le plafond de volume vaut aussi pour la toute première lecture.
        if (playing) _player.setVolume(_volume);
      }
      // Morceau terminé : on enchaîne sur le suivant de la sélection.
      final ended = v.playerState == PlayerState.ended;
      if (ended && !_wasEnded && mounted) _step(1);
      _wasEnded = ended;
    });
    if (widget.autoPlayFavorite) {
      _play(yanFavorite);
    } else {
      _player.cueVideoById(videoId: _current.videoId);
    }
  }

  SessionController? _session;

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

  List<Track> get _visible => _mood == null
      ? playlist
      : playlist.where((t) => t.mood.fr == _mood!.fr).toList();

  Future<void> _play(Track track) async {
    setState(() => _current = track);
    await _player.loadVideoById(videoId: track.videoId);
    if (!mounted) return;
    await _player.setVolume(_volume);
  }

  void _toggle() => _playing ? _player.pauseVideo() : _player.playVideo();

  void _step(int delta) {
    final list = _visible;
    final i = list.indexOf(_current);
    // En Dart, % renvoie toujours un reste positif : -1 % n == n - 1.
    _play(list[(i + delta) % list.length]);
  }

  void _changeVolume(int delta) {
    setState(
      () => _volume = (_volume + delta).clamp(0, AppConfig.maxMusicVolume),
    );
    _player.setVolume(_volume);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 900;

    final player = _PlayerPanel(
      controller: _player,
      track: _current,
      playing: _playing,
      volume: _volume,
      onToggle: _toggle,
      onPrevious: () => _step(-1),
      onNext: () => _step(1),
      onVolume: _changeVolume,
    );
    final side = _Side(
      current: _current,
      playing: _playing,
      tracks: _visible,
      mood: _mood,
      onMood: (m) => setState(() => _mood = m),
      onPlay: _play,
    );

    return SectionScaffold(
      scene: Scene.music,
      section: Section.music,
      title: l10n.musicTitle,
      child: compact
          ? ListView(
              children: [
                player,
                const SizedBox(height: 24),
                SizedBox(height: 640, child: side),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 7, child: SingleChildScrollView(child: player)),
                const SizedBox(width: 32),
                Expanded(flex: 5, child: side),
              ],
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Lecteur et commandes.

class _PlayerPanel extends StatelessWidget {
  const _PlayerPanel({
    required this.controller,
    required this.track,
    required this.playing,
    required this.volume,
    required this.onToggle,
    required this.onPrevious,
    required this.onNext,
    required this.onVolume,
  });

  final YoutubePlayerController controller;
  final Track track;
  final bool playing;
  final int volume;
  final VoidCallback onToggle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onVolume;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Brand.gold.withValues(alpha: playing ? 0.4 : 0.15),
                blurRadius: 70,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: YoutubePlayer(controller: controller, aspectRatio: 16 / 9),
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            if (playing)
              const _Equalizer()
            else
              Icon(AppIcons.music, color: p.accentText, size: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.musicNowPlaying.toUpperCase(),
                    style: AppText.eyebrow(p.accentText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.display(34, color: p.text),
                  ),
                  Text(
                    track.artist,
                    style: AppText.body(16, color: p.textMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            LiquidIconButton(
              icon: AppIcons.previous,
              size: 52,
              onTap: onPrevious,
            ),
            const SizedBox(width: 12),
            Pressable(
              onTap: onToggle,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Brand.goldSoft, Brand.gold],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Brand.gold.withValues(alpha: 0.5),
                      blurRadius: 30,
                    ),
                  ],
                ),
                child: Icon(
                  playing ? AppIcons.pause : AppIcons.play,
                  color: Brand.ink,
                  size: 30,
                ),
              ),
            ),
            const SizedBox(width: 12),
            LiquidIconButton(icon: AppIcons.next, size: 52, onTap: onNext),
            const Spacer(),
            _VolumeControl(volume: volume, onChange: onVolume),
          ],
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            l10n.musicMaxHint,
            style: AppText.body(12, color: p.textMuted),
          ),
        ),
      ],
    );
  }
}

class _VolumeControl extends StatelessWidget {
  const _VolumeControl({required this.volume, required this.onChange});

  final int volume;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const steps = 7;
    final level = (volume / AppConfig.maxMusicVolume * steps).round();

    return LiquidPill(
      padding: const EdgeInsets.all(6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RoundTap(icon: AppIcons.volumeDown, onTap: () => onChange(-10)),
          const SizedBox(width: 8),
          for (var i = 0; i < steps; i++)
            AnimatedContainer(
              duration: AppMotion.fast,
              width: 6,
              height: 10.0 + i * 3,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: i < level ? Brand.gold : p.hairline,
              ),
            ),
          const SizedBox(width: 8),
          _RoundTap(icon: AppIcons.volumeUp, onTap: () => onChange(10)),
        ],
      ),
    );
  }
}

class _RoundTap extends StatelessWidget {
  const _RoundTap({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.palette.hairline,
        ),
        child: Icon(icon, size: 20, color: context.palette.text),
      ),
    );
  }
}

/// Petites barres qui dansent pendant la lecture.
class _Equalizer extends StatelessWidget {
  const _Equalizer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 26,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 0; i < 4; i++)
            Container(
                  width: 4,
                  height: 26,
                  decoration: BoxDecoration(
                    color: Brand.gold,
                    borderRadius: BorderRadius.circular(2),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleY(
                  begin: 0.25,
                  end: 1,
                  alignment: Alignment.bottomCenter,
                  duration: (380 + i * 130).ms,
                  curve: Curves.easeInOutSine,
                ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Le choix de Yan et la sélection.

class _Side extends StatelessWidget {
  const _Side({
    required this.current,
    required this.playing,
    required this.tracks,
    required this.mood,
    required this.onMood,
    required this.onPlay,
  });

  final Track current;
  final bool playing;
  final List<Track> tracks;
  final Bi? mood;
  final ValueChanged<Bi?> onMood;
  final ValueChanged<Track> onPlay;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final l10n = AppLocalizations.of(context);
    final moods = <Bi>{for (final t in playlist.skip(1)) t.mood}.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FavoriteCard(
          onPlay: () => onPlay(yanFavorite),
          active: current == yanFavorite && playing,
        ),
        const SizedBox(height: 22),
        Text(
          l10n.musicPlaylistTitle,
          style: AppText.display(28, color: p.text),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _MoodChip(
                label: Localizations.localeOf(context).languageCode == 'en'
                    ? 'All'
                    : 'Tout',
                selected: mood == null,
                onTap: () => onMood(null),
              ),
              for (final m in moods)
                _MoodChip(
                  label: m.of(context),
                  selected: mood?.fr == m.fr,
                  onTap: () => onMood(m),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: tracks.length,
            itemBuilder: (context, i) => _TrackRow(
              track: tracks[i],
              active: tracks[i] == current,
              playing: playing,
              onTap: () => onPlay(tracks[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _FavoriteCard extends StatelessWidget {
  const _FavoriteCard({required this.onPlay, required this.active});

  final VoidCallback onPlay;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget vinyl = Container(
      width: 92,
      height: 92,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            Color(0xFF0B0B0F),
            Color(0xFF2A2D36),
            Color(0xFF0B0B0F),
            Color(0xFF23262E),
            Color(0xFF0B0B0F),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(colors: [Brand.goldSoft, Brand.gold]),
        ),
      ),
    );
    if (active) {
      vinyl = vinyl
          .animate(onPlay: (c) => c.repeat())
          .rotate(duration: 2400.ms);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF2B3A67), Color(0xFF0B0E18)],
        ),
        border: Border.all(color: Brand.gold.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          vinyl,
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(AppIcons.heart, size: 16, color: Brand.gold),
                    const SizedBox(width: 6),
                    Text(
                      l10n.musicYanPick.toUpperCase(),
                      style: AppText.eyebrow(Brand.goldSoft),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  yanFavorite.title,
                  style: AppText.display(28, color: Colors.white),
                ),
                Text(
                  '${yanFavorite.artist}  ·  ${l10n.musicYanPickHint}',
                  style: AppText.body(13, color: Colors.white70),
                ),
                const SizedBox(height: 12),
                PillButton(
                  label: l10n.musicPlayIt,
                  onTap: onPlay,
                  trailing: const Icon(AppIcons.play),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Pressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.spring,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: selected
                ? const LinearGradient(colors: [Brand.goldSoft, Brand.gold])
                : null,
            color: selected ? null : p.glass,
            border: selected ? null : Border.all(color: p.hairline),
          ),
          child: Text(
            label,
            style: AppText.body(
              15,
              weight: FontWeight.w600,
              color: selected ? Brand.ink : p.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _TrackRow extends StatelessWidget {
  const _TrackRow({
    required this.track,
    required this.active,
    required this.playing,
    required this.onTap,
  });

  final Track track;
  final bool active;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Pressable(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.medium,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: active ? Brand.gold.withValues(alpha: 0.14) : p.glass,
          border: Border.all(color: active ? Brand.gold : p.hairline),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 76,
                height: 48,
                child: Image.network(
                  track.thumbnail,
                  fit: BoxFit.cover,
                  // Sans réseau (ou sans accès à l'image), une vignette neutre.
                  errorBuilder: (_, _, _) => ColoredBox(
                    color: p.hairline,
                    child: Icon(AppIcons.music, color: p.textMuted, size: 20),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(
                      15,
                      weight: FontWeight.w600,
                      color: p.text,
                    ),
                  ),
                  Text(
                    track.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(13, color: p.textMuted),
                  ),
                ],
              ),
            ),
            if (active && playing)
              const _Equalizer()
            else
              Icon(AppIcons.play, size: 18, color: p.textMuted),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}
