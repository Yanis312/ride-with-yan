import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// QR code à scanner avec le téléphone du passager. Sans [data], affiche
/// un emplacement "à configurer" (voir lib/config.dart).
class QrCard extends StatelessWidget {
  const QrCard({
    super.key,
    required this.data,
    required this.icon,
    required this.label,
    this.color = Brand.ink,
    this.size = 180,
  });

  final String? data;
  final IconData icon;
  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ready = data != null && data!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: SizedBox.square(
            dimension: size,
            child: ready
                ? QrImageView(
                    data: data!,
                    padding: EdgeInsets.zero,
                    backgroundColor: Colors.white,
                    eyeStyle: QrEyeStyle(
                      eyeShape: QrEyeShape.circle,
                      color: color,
                    ),
                    dataModuleStyle: QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.circle,
                      color: color,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: size * 0.3,
                          color: color.withValues(alpha: 0.35),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          l10n.toConfigure,
                          style: AppText.body(
                            14,
                            weight: FontWeight.w600,
                            color: Brand.ink.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: context.palette.text),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppText.body(
                16,
                weight: FontWeight.w600,
                color: context.palette.text,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
