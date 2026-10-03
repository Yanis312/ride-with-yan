import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'road_logo.dart';

/// Le Y transformé en métal liquide (shader de Paper, voir shaders/NOTICE.md).
/// [gold] teinte le chrome en or pour coller à la marque.
/// Tant que le shader ou le masque ne sont pas prêts, le logo classique s'affiche.
class LiquidMetalLogo extends StatefulWidget {
  const LiquidMetalLogo({super.key, required this.size, this.gold = true});

  final double size;
  final bool gold;

  @override
  State<LiquidMetalLogo> createState() => _LiquidMetalLogoState();
}

class _LiquidMetalLogoState extends State<LiquidMetalLogo>
    with SingleTickerProviderStateMixin {
  static Future<(ui.FragmentProgram, ui.Image)?>? _resources;

  late final Ticker _ticker = createTicker(_onTick);
  final _time = ValueNotifier<double>(0);
  Duration _last = Duration.zero;
  ui.FragmentShader? _shader;
  ui.Image? _mask;

  static Future<(ui.FragmentProgram, ui.Image)?> _load() async {
    try {
      final program = await ui.FragmentProgram.fromAsset(
        'shaders/liquid_metal.frag',
      );
      final bytes = await rootBundle.load('assets/images/y_mask.png');
      final codec = await ui.instantiateImageCodec(bytes.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      return (program, frame.image);
    } catch (e) {
      debugPrint('Logo métal liquide indisponible : $e');
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _resources ??= _load();
    _resources!.then((r) {
      if (!mounted || r == null) return;
      setState(() {
        _shader = r.$1.fragmentShader();
        _mask = r.$2;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.disableAnimationsOf(context);
    if (reduce && _ticker.isActive) _ticker.stop();
    if (!reduce && !_ticker.isActive) _ticker.start();
  }

  void _onTick(Duration elapsed) {
    // 30 images/s suffisent pour le métal liquide (voir MeshBackground).
    if ((elapsed - _last).inMilliseconds < 33) return;
    // Même cadence que la démo de Paper : temps en millisecondes x vitesse.
    _time.value += (elapsed - _last).inMilliseconds * 0.3;
    _last = elapsed;
  }

  @override
  void dispose() {
    _ticker.dispose();
    _time.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shader = _shader;
    final mask = _mask;
    if (shader == null || mask == null) {
      return RoadLogo(size: widget.size, showTile: false, glow: 0.6);
    }

    Widget metal = CustomPaint(
      size: Size.square(widget.size),
      painter: _LiquidPainter(shader, mask, _time),
    );
    if (widget.gold) {
      // Le chrome devient de l'or : les blancs virent au doré, les noirs restent profonds.
      metal = ColorFiltered(
        // dart format off
        colorFilter: const ColorFilter.matrix([
          1.05, 0.10, 0.00, 0, 0.02,
          0.00, 0.82, 0.04, 0, 0.00,
          0.00, 0.00, 0.30, 0, 0.00,
          0.00, 0.00, 0.00, 1, 0.00,
        ]),
        // dart format on
        child: metal,
      );
    }
    return RepaintBoundary(
      child: SizedBox.square(dimension: widget.size, child: metal),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  _LiquidPainter(this.shader, this.mask, this.time) : super(repaint: time);

  final ui.FragmentShader shader;
  final ui.Image mask;
  final ValueNotifier<double> time;

  @override
  void paint(Canvas canvas, Size size) {
    var i = 0;
    shader
      ..setFloat(i++, size.width)
      ..setFloat(i++, size.height)
      ..setFloat(i++, time.value) // u_time
      ..setFloat(i++, 1) // u_ratio
      ..setFloat(i++, 1) // u_img_ratio
      ..setFloat(i++, 2) // u_patternScale
      ..setFloat(i++, 0.015) // u_refraction
      ..setFloat(i++, 0.4) // u_edge
      ..setFloat(i++, 0.005) // u_patternBlur
      ..setFloat(i++, 0.07) // u_liquid
      ..setImageSampler(0, mask);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_LiquidPainter old) =>
      old.shader != shader || old.mask != mask;
}
