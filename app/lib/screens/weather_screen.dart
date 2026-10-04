import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../data/bilingual.dart';
import '../data/weather.dart';
import '../l10n/app_localizations.dart';
import '../navigation/sections.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';
import '../widgets/mesh_background.dart';
import '../widgets/section_scaffold.dart';

/// Météo en direct : conditions actuelles, prochaines heures et 6 jours,
/// pour Montréal et quelques destinations courantes.
class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Place _place = places.first;
  late Future<Weather> _weather = WeatherService.fetch(_place);

  void _select(Place place) => setState(() {
    _place = place;
    _weather = WeatherService.fetch(place);
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final compact = MediaQuery.sizeOf(context).width < 900;

    return SectionScaffold(
      scene: Scene.profile,
      title: l10n.sectionWeather,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: places.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => _PlaceChip(
                label: places[i].name.of(context),
                selected: places[i] == _place,
                onTap: () => _select(places[i]),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: FutureBuilder<Weather>(
              future: _weather,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _Offline(onRetry: () => _select(_place));
                }
                final weather = snapshot.data;
                if (snapshot.connectionState != ConnectionState.done ||
                    weather == null) {
                  return const Center(
                    child: CircularProgressIndicator(color: Brand.gold),
                  );
                }
                final now = _NowCard(weather: weather, place: _place);
                final forecast = _Forecast(weather: weather);
                return compact
                    ? ListView(
                        children: [
                          SizedBox(height: 400, child: now),
                          const SizedBox(height: 18),
                          SizedBox(height: 620, child: forecast),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 5, child: now),
                          const SizedBox(width: 24),
                          Expanded(flex: 7, child: forecast),
                        ],
                      ).animate().fadeIn(
                        duration: AppMotion.medium,
                        curve: AppMotion.spring,
                      );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _degrees(double value) => '${value.round()}°';

class _PlaceChip extends StatelessWidget {
  const _PlaceChip({
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
            Icon(AppIcons.mapPin, size: 16, color: fg),
            const SizedBox(width: 6),
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

/// Pas de réseau : on le dit simplement, avec un bouton pour réessayer.
class _Offline extends StatelessWidget {
  const _Offline({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.wifiSlash, size: 56, color: p.textMuted),
          const SizedBox(height: 14),
          Text(
            const Bi(
              'Météo indisponible pour le moment.',
              'Weather is unavailable right now.',
            ).of(context),
            style: AppText.body(17, color: p.textMuted),
          ),
          const SizedBox(height: 18),
          PillButton(
            label: const Bi('Réessayer', 'Try again').of(context),
            filled: false,
            onTap: onRetry,
            trailing: const Icon(AppIcons.refresh),
          ),
        ],
      ),
    );
  }
}

/// Conditions actuelles : grande température sur un ciel aux couleurs du temps.
class _NowCard extends StatelessWidget {
  const _NowCard({required this.weather, required this.place});

  final Weather weather;
  final Place place;

  List<Color> get _sky {
    if (!weather.isDay) return const [Color(0xFF1B2A55), Color(0xFF070B1C)];
    return switch (weather.code) {
      0 || 1 => const [Color(0xFF3AA6FF), Color(0xFF0B4FA8)],
      2 || 3 || 45 || 48 => const [Color(0xFF7E93AD), Color(0xFF34475E)],
      71 ||
      73 ||
      75 ||
      77 ||
      85 ||
      86 => const [Color(0xFFA9C4DE), Color(0xFF4B6A8C)],
      _ => const [Color(0xFF50698A), Color(0xFF1C2A40)],
    };
  }

  @override
  Widget build(BuildContext context) {
    final (label, icon) = describeWeather(weather.code, isDay: weather.isDay);
    final rain = weather.rainSoon;

    Widget fact(IconData icon, String value, String name) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.white70),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppText.body(
              18,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(name, style: AppText.body(12, color: Colors.white70)),
        ],
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _sky,
          ),
        ),
        child: Stack(
          children: [
            // Grande icône en filigrane dans le coin.
            Positioned(
              right: -40,
              top: -30,
              child: Icon(
                icon,
                size: 260,
                color: Colors.white.withValues(alpha: 0.14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name.of(context).toUpperCase(),
                    style: AppText.eyebrow(Colors.white),
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weather.temperature.round()}',
                          style: AppText.display(
                            150,
                            color: Colors.white,
                          ).copyWith(height: 0.95),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 18),
                          child: Text(
                            '°C',
                            style: AppText.display(44, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(icon, size: 26, color: Colors.white),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          label.of(context),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.display(30, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      fact(
                        AppIcons.thermometer,
                        _degrees(weather.feelsLike),
                        const Bi('Ressenti', 'Feels like').of(context),
                      ),
                      fact(
                        AppIcons.wind,
                        '${weather.wind.round()} km/h',
                        const Bi('Vent', 'Wind').of(context),
                      ),
                      fact(
                        AppIcons.dropHalf,
                        '${weather.humidity} %',
                        const Bi('Humidité', 'Humidity').of(context),
                      ),
                    ],
                  ),
                  if (rain >= 50) ...[
                    const SizedBox(height: 18),
                    // Il va pleuvoir : le parapluie de la boutique tombe bien.
                    Pressable(
                      onTap: () => openSection(context, Section.store),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFE08A), Brand.gold],
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              AppIcons.umbrella,
                              size: 22,
                              color: Brand.ink,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                Bi(
                                  '$rain % de risque de pluie. Un parapluie est en vente à bord.',
                                  '$rain% chance of rain. An umbrella is for sale on board.',
                                ).of(context),
                                style: AppText.body(
                                  14,
                                  weight: FontWeight.w600,
                                  color: Brand.ink,
                                ),
                              ),
                            ),
                            const Icon(
                              AppIcons.arrowRight,
                              size: 18,
                              color: Brand.ink,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Forecast extends StatelessWidget {
  const _Forecast({required this.weather});

  final Weather weather;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final locale = Localizations.localeOf(context).languageCode;
    // Échelle commune aux barres min–max de la semaine.
    final low = weather.days.map((d) => d.min).reduce((a, b) => a < b ? a : b);
    final high = weather.days.map((d) => d.max).reduce((a, b) => a > b ? a : b);
    final span = (high - low).abs() < 1 ? 1.0 : high - low;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BezelCard(
          radius: 30,
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                const Bi('PROCHAINES HEURES', 'NEXT HOURS').of(context),
                style: AppText.eyebrow(p.accentText),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 104,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: weather.hours.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final h = weather.hours[i];
                    final night = h.time.hour < 6 || h.time.hour >= 20;
                    final (_, icon) = describeWeather(h.code, isDay: !night);
                    return Container(
                      width: 68,
                      decoration: BoxDecoration(
                        color: i == 0
                            ? Brand.gold.withValues(alpha: 0.18)
                            : p.glass,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: i == 0 ? Brand.gold : p.hairline,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            i == 0
                                ? const Bi('Maint.', 'Now').of(context)
                                : DateFormat.j(locale).format(h.time),
                            style: AppText.body(12, color: p.textMuted),
                          ),
                          const SizedBox(height: 6),
                          Icon(icon, size: 24, color: p.text),
                          const SizedBox(height: 6),
                          Text(
                            _degrees(h.temperature),
                            style: AppText.body(
                              16,
                              weight: FontWeight.w700,
                              color: p.text,
                            ),
                          ),
                          if (h.rainChance >= 30)
                            Text(
                              '${h.rainChance} %',
                              style: AppText.body(
                                10,
                                weight: FontWeight.w600,
                                color: const Color(0xFF3AA6FF),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: BezelCard(
            radius: 30,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  const Bi('CETTE SEMAINE', 'THIS WEEK').of(context),
                  style: AppText.eyebrow(p.accentText),
                ),
                const SizedBox(height: 6),
                for (final (i, d) in weather.days.indexed)
                  Expanded(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 96,
                          child: Text(
                            i == 0
                                ? const Bi('Aujourd’hui', 'Today').of(context)
                                : toBeginningOfSentenceCase(
                                    DateFormat.EEEE(locale).format(d.date),
                                  ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body(
                              15,
                              weight: FontWeight.w500,
                              color: p.text,
                            ),
                          ),
                        ),
                        Icon(
                          describeWeather(d.code).$2,
                          size: 22,
                          color: p.text,
                        ),
                        SizedBox(
                          width: 46,
                          child: Text(
                            d.rainChance >= 30 ? '${d.rainChance} %' : '',
                            textAlign: TextAlign.center,
                            style: AppText.body(
                              11,
                              weight: FontWeight.w600,
                              color: const Color(0xFF3AA6FF),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 34,
                          child: Text(
                            _degrees(d.min),
                            textAlign: TextAlign.right,
                            style: AppText.body(15, color: p.textMuted),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Barre min–max, placée sur l'échelle de la semaine.
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, c) => Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: p.hairline,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                                Positioned(
                                  left: c.maxWidth * (d.min - low) / span,
                                  width: (c.maxWidth * (d.max - d.min) / span)
                                      .clamp(8.0, c.maxWidth),
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(99),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF3AA6FF), Brand.gold],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 34,
                          child: Text(
                            _degrees(d.max),
                            style: AppText.body(
                              15,
                              weight: FontWeight.w700,
                              color: p.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Text(
                  const Bi(
                    'Données : Open-Meteo',
                    'Data: Open-Meteo',
                  ).of(context),
                  style: AppText.body(10, color: p.textMuted),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
