import 'package:flutter/widgets.dart';

import '../theme/app_icons.dart';
import 'bilingual.dart';

/// Vidéo du coin divertissement : lecteur officiel YouTube intégré.
/// Uniquement des chaînes officielles, et chaque identifiant a été vérifié
/// avec l'oEmbed de YouTube (intégration autorisée).
@immutable
class Video {
  const Video(this.id, this.title, this.channel, this.minutes);

  final String id;
  final String title;
  final String channel;
  final int minutes;

  String get thumbnail => 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
}

@immutable
class VideoCategory {
  const VideoCategory(this.label, this.icon, this.videos);

  final Bi label;
  final IconData icon;
  final List<Video> videos;
}

const videoCategories = [
  VideoCategory(Bi('Humour', 'Comedy'), AppIcons.maskHappy, [
    Video('bTmjZy1oaGQ', 'Best Pranks Of All Time', 'Just For Laughs Gags', 15),
    Video('jv5RtGHKLWg', 'Top 10 Pranks of 2019', 'Just For Laughs Gags', 15),
    Video('MHn8SnqLb68', 'Top 10 Pranks of 2020', 'Just For Laughs Gags', 16),
    Video(
      'TSD9HtBW-9E',
      'Hilarious Prank Reactions',
      'Just For Laughs Gags',
      25,
    ),
  ]),
  VideoCategory(Bi('Montréal', 'Montréal'), AppIcons.buildings, [
    Video('zkGwMz2Dfos', 'Montréal vue du ciel, en 4K', 'Drone Snap', 5),
    Video('Jv-D5FqYsP4', 'Summer in Montreal From The Sky', 'lofi.aerials', 19),
    Video('yErZIYP1cwk', 'Montréal en 4K par drone', 'Exploropia', 10),
    Video('oZv9XCF-TvQ', 'Old Montreal Walking Tour', 'walks and city', 20),
  ]),
  VideoCategory(Bi('Nature', 'Nature'), AppIcons.pawPrint, [
    Video('l9GMrP-2-Wc', 'Fox Dives Head First Into Snow', 'BBC Earth', 4),
    Video('yYt_psQXvEM', 'Crab vs Eel vs Octopus', 'BBC Earth', 6),
    Video(
      '4PwDFddpo4c',
      'Emperor Penguin Chicks Jump Off a Cliff',
      'National Geographic',
      5,
    ),
    Video(
      'hkBhJxZupeE',
      '7 Minutes of The Cutest Baby Animals',
      'Nat Geo Animals',
      7,
    ),
    Video('7bOptq-NPJQ', 'Alps & Dolomites', 'Nature Relaxation Films', 5),
    Video(
      '7EMynhUaHso',
      'Breathtaking Moments from Planet Earth',
      'BBC Earth',
      27,
    ),
  ]),
  VideoCategory(Bi('Sport', 'Sports'), AppIcons.soccerBall, [
    Video('tTK90W_2Yh8', 'The Best Ever World Cup Goals', 'FIFA', 6),
    Video('QtSMXXJq11Q', 'The Very Best Goals From Qatar 2022', 'FIFA', 10),
    Video('Vw34wMAqWzc', 'Top 10 Goals, World Cup 2018', 'FIFA', 5),
    Video(
      'btWIF0LignA',
      '10 Of The Greatest Olympic Moments Ever',
      'Olympic Games',
      6,
    ),
    Video(
      'q4Mujt1wer4',
      'Moments That Left Us Speechless, Paris 2024',
      'Olympic Games',
      12,
    ),
    Video(
      'fbqHK8i-HdA',
      'The Most Insane Ski Run Ever Imagined',
      'Red Bull Snow',
      10,
    ),
    Video('Hz2F_S3Tl0Y', 'I Jumped From Space', 'Red Bull', 4),
  ]),
  VideoCategory(Bi('Science', 'Science'), AppIcons.flask, [
    Video('yDAAlojz8NU', 'The Scariest Place in The Universe', 'Kurzgesagt', 9),
    Video(
      'FgnjdW-x7mQ',
      'The Last Thing To Ever Happen In The Universe',
      'Kurzgesagt',
      11,
    ),
    Video('VD6xJq8NguY', 'There Is Life Hiding Inside Earth', 'Kurzgesagt', 11),
    Video(
      '9IiYOTzJ2uw',
      'I Built a Roller Coaster In My Lab',
      'Mark Rober',
      19,
    ),
    Video(
      'jjpjjcMeujM',
      'Ronaldo vs My Unbeatable Goalie Robot',
      'Mark Rober',
      27,
    ),
  ]),
  VideoCategory(Bi('Animation', 'Animation'), AppIcons.smiley, [
    Video('1an6_gb03zQ', 'Fruit & Nut (court métrage)', 'Pixar', 7),
    Video('g_GyKWx0j30', 'The Quest', 'Simon’s Cat', 9),
    Video('qWsqc2I2Wco', 'CatGPT Goes Wrong', 'Simon’s Cat', 4),
    Video('4ijbLe-UBe8', 'Cosy Autumn', 'Simon’s Cat', 11),
    Video('8FerpJvtRFs', 'Classic Cat Cartoons', 'Simon’s Cat', 30),
  ]),
  VideoCategory(Bi('Voyage', 'Travel'), AppIcons.airplane, [
    Video('iiGYuQEacMk', 'Japan, Land of Effortless Beauty', 'Benn TK', 4),
    Video('kaHzh89au3o', 'Japan 4K, Hidden Beauty', 'ORRIS', 6),
    Video('_DJb5HjeDkQ', 'Megacities in 4K', 'Explore The World 4K', 30),
  ]),
];
