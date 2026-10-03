/// Interrupteurs de diagnostic des performances (temporaire) :
/// ?off=glass,mesh,dock,vignette,glow dans l'URL de l'aperçu web.
abstract final class PerfFlags {
  static final Set<String> _off = (Uri.base.queryParameters['off'] ?? '')
      .split(',')
      .toSet();
  static bool off(String name) => _off.contains(name);
}
