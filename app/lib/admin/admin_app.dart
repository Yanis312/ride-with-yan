import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import '../backend/backend.dart';
import '../backend/remote_config.dart';
import '../config.dart';
import '../data/poll.dart';
import '../data/store_catalog.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/product_art.dart';

/// Panneau d'administration de Yanis, pensé pour son téléphone.
/// On y accède en ajoutant `?admin` à l'adresse web de l'app. Seul son
/// compte (courriel confirmé) peut modifier quoi que ce soit : c'est la base
/// qui le vérifie, pas cet écran.
class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  final _session = AdminSession();
  bool _ready = false;
  bool? _allowed;

  @override
  void initState() {
    super.initState();
    _session.addListener(_check);
    _restoreTheme();
    _session.restore().whenComplete(() {
      if (mounted) setState(() => _ready = true);
    });
  }

  /// Après une connexion, on demande à la base si ce compte est le bon.
  Future<void> _check() async {
    if (!_session.signedIn) {
      setState(() => _allowed = null);
      return;
    }
    bool allowed;
    try {
      allowed = await _session.isAdmin();
    } catch (_) {
      allowed = false;
    }
    if (mounted) setState(() => _allowed = allowed);
  }

  @override
  void dispose() {
    _session.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget home;
    if (!_ready || (_session.signedIn && _allowed == null)) {
      home = const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Brand.gold)),
      );
    } else if (!_session.signedIn) {
      home = _LoginPage(session: _session);
    } else if (_allowed == false) {
      home = _DeniedPage(session: _session);
    } else {
      home = AdminHome(session: _session);
    }

    return ValueListenableBuilder<bool?>(
      valueListenable: _darkMode,
      builder: (context, dark, _) => MaterialApp(
        title: 'Ride with Yan · Admin',
        debugShowCheckedModeBanner: false,
        theme: _adminTheme(Brightness.light),
        darkTheme: _adminTheme(Brightness.dark),
        // Sans choix de Yanis, on suit le réglage du téléphone.
        themeMode: switch (dark) {
          null => ThemeMode.system,
          true => ThemeMode.dark,
          false => ThemeMode.light,
        },
        home: home,
      ),
    );
  }
}

/// Messages de connexion de Supabase, en français.
String _french(String message) => switch (message) {
  'Invalid login credentials' => 'Courriel ou mot de passe incorrect.',
  'Email not confirmed' =>
    'Ouvrez d’abord le courriel de confirmation, puis reconnectez-vous.',
  'User already registered' => 'Ce compte existe déjà : connectez-vous.',
  _ => message,
};

/// Mode sombre choisi par Yanis (null : celui du téléphone), gardé en mémoire.
final _darkMode = ValueNotifier<bool?>(null);
const _darkKey = 'admin_dark_mode';

Future<void> _restoreTheme() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    _darkMode.value = prefs.getBool(_darkKey);
  } catch (_) {
    // Stockage indisponible : on suit le téléphone.
  }
}

Future<void> _toggleTheme(BuildContext context) async {
  final dark = Theme.of(context).brightness != Brightness.dark;
  _darkMode.value = dark;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkKey, dark);
  } catch (_) {
    // Voir _restoreTheme().
  }
}

ThemeData _adminTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: AppFonts.sans,
    scaffoldBackgroundColor: dark
        ? const Color(0xFF0B0B0F)
        : const Color(0xFFF4F3EF),
    colorScheme: ColorScheme.fromSeed(
      seedColor: Brand.gold,
      brightness: brightness,
      // Sur fond clair, l'or vif se lit mal : on prend sa version foncée.
      primary: dark ? Brand.gold : Brand.goldDeep,
      onPrimary: dark ? Brand.ink : Colors.white,
      surface: dark ? const Color(0xFF15161B) : Colors.white,
      onSurface: dark ? Colors.white : Brand.ink,
    ),
    // Les boutons principaux restent or vif, texte noir, dans les deux modes.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Brand.gold,
        foregroundColor: Brand.ink,
      ),
    ),
  );
}

/// Couleurs de texte et de filets qui suivent le mode clair ou sombre.
extension on BuildContext {
  Color get ink => Theme.of(this).colorScheme.onSurface;
  Color get inkMuted => ink.withValues(alpha: 0.62);
  Color get line => ink.withValues(alpha: 0.16);
}

/// Bouton soleil / lune pour changer de mode.
class _ThemeButton extends StatelessWidget {
  const _ThemeButton();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: dark ? 'Mode clair' : 'Mode sombre',
      onPressed: () => _toggleTheme(context),
      icon: Icon(dark ? AppIcons.sun : AppIcons.moon),
    );
  }
}

void _toast(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(color: error ? Colors.white : null),
        ),
        backgroundColor: error ? const Color(0xFFB3261E) : null,
      ),
    );
}

// ---------------------------------------------------------------------------
// Connexion.

class _LoginPage extends StatefulWidget {
  const _LoginPage({required this.session});

  final AdminSession session;

  @override
  State<_LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<_LoginPage> {
  final _email = TextEditingController(text: AppConfig.interacEmail);
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted && done != null) _toast(context, done);
    } on BackendException catch (e) {
      if (mounted) _toast(context, _french(e.message), error: true);
    } catch (_) {
      if (mounted) {
        _toast(
          context,
          'Connexion impossible. Vérifiez le réseau.',
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = _email.text.trim();
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Align(
                    alignment: Alignment.centerRight,
                    child: _ThemeButton(),
                  ),
                  Icon(
                    AppIcons.lockKey,
                    size: 44,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Administration',
                    textAlign: TextAlign.center,
                    style: AppText.display(40, color: context.ink),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ride with Yan',
                    textAlign: TextAlign.center,
                    style: AppText.body(15, color: context.inkMuted),
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Courriel',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _run(
                      () => widget.session.signIn(email, _password.text),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy
                        ? null
                        : () => _run(
                            () => widget.session.signIn(email, _password.text),
                          ),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                    child: Text(_busy ? 'Un instant…' : 'Se connecter'),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            if (_password.text.length < 8) {
                              _toast(
                                context,
                                'Choisissez un mot de passe d’au moins 8 caractères.',
                                error: true,
                              );
                              return;
                            }
                            _run(
                              () =>
                                  widget.session.signUp(email, _password.text),
                              done:
                                  'Compte créé. Ouvrez le courriel de confirmation, '
                                  'puis revenez vous connecter.',
                            );
                          },
                    child: const Text('Première fois ? Créer mon accès'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DeniedPage extends StatelessWidget {
  const _DeniedPage({required this.session});

  final AdminSession session;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.lockKey, size: 48, color: context.inkMuted),
              const SizedBox(height: 14),
              Text(
                'Ce compte n’a pas accès à l’administration.',
                textAlign: TextAlign.center,
                style: AppText.body(17, color: context.ink),
              ),
              const SizedBox(height: 6),
              Text(
                session.email ?? '',
                style: AppText.body(14, color: context.inkMuted),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: session.signOut,
                child: const Text('Changer de compte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Accueil : articles et sondage.

/// Public pour pouvoir être affiché dans les tests.
class AdminHome extends StatefulWidget {
  const AdminHome({super.key, required this.session});

  final AdminSession session;

  @override
  State<AdminHome> createState() => AdminHomeState();
}

class AdminHomeState extends State<AdminHome> {
  late Future<void> _loading = _load();

  Future<void> _load() async {
    await RemoteConfig.instance.refresh();
    await PollStore.instance.load();
    await PollStore.instance.syncFromBackend();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Administration',
            style: AppText.display(26, color: context.ink),
          ),
          actions: [
            const _ThemeButton(),
            IconButton(
              tooltip: 'Recharger',
              onPressed: () => setState(() => _loading = _load()),
              icon: const Icon(AppIcons.refresh),
            ),
            IconButton(
              tooltip: 'Se déconnecter',
              onPressed: widget.session.signOut,
              icon: const Icon(AppIcons.lockKey),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(AppIcons.shoppingBag), text: 'Articles'),
              Tab(icon: Icon(AppIcons.chartBar), text: 'Sondage'),
            ],
          ),
        ),
        body: FutureBuilder<void>(
          future: _loading,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(color: Brand.gold),
              );
            }
            return TabBarView(
              children: [
                _ProductsTab(session: widget.session),
                _PollTab(session: widget.session),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Articles : prix, stock, visibilité.

class _ProductsTab extends StatelessWidget {
  const _ProductsTab({required this.session});

  final AdminSession session;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
      itemCount: baseCatalog.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
            child: Text(
              'Les changements apparaissent sur la tablette au passager suivant.',
              style: AppText.body(13, color: context.inkMuted),
            ),
          );
        }
        return _ProductEditor(
          key: ValueKey(baseCatalog[i - 1].id),
          product: baseCatalog[i - 1],
          session: session,
        );
      },
    );
  }
}

class _ProductEditor extends StatefulWidget {
  const _ProductEditor({
    super.key,
    required this.product,
    required this.session,
  });

  final Product product;
  final AdminSession session;

  @override
  State<_ProductEditor> createState() => _ProductEditorState();
}

class _ProductEditorState extends State<_ProductEditor> {
  late final Product _current;
  late final TextEditingController _price;
  late Map<String, int> _sizes;
  late int _stock;
  late bool _hidden;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final override = RemoteConfig.instance.productOverride(widget.product.id);
    _current = override == null
        ? widget.product
        : widget.product.withOverride(override);
    _hidden = override?['hidden'] == true;
    _price = TextEditingController(text: _format(_current.price));
    _sizes = Map.of(_current.sizes);
    _stock = _current.stock;
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  static String _format(double price) =>
      price == price.roundToDouble() ? '${price.round()}' : price.toString();

  void _touch(VoidCallback change) => setState(() {
    change();
    _dirty = true;
  });

  Future<void> _save() async {
    final price = double.tryParse(_price.text.replaceAll(',', '.'));
    if (price == null || price < 0) {
      _toast(context, 'Prix invalide.', error: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await Backend.upsert('product_overrides', {
        'id': widget.product.id,
        'price': price,
        'sizes': widget.product.hasSizes ? _sizes : null,
        'stock': widget.product.hasSizes ? null : _stock,
        'hidden': _hidden,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, token: await widget.session.token());
      await RemoteConfig.instance.refresh();
      if (!mounted) return;
      setState(() => _dirty = false);
      _toast(context, '${widget.product.name.fr} : enregistré.');
    } catch (e) {
      if (mounted) _toast(context, 'Échec : $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final total = product.hasSizes
        ? _sizes.values.fold(0, (a, b) => a + b)
        : _stock;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: _dirty ? Brand.gold : context.line),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(colors: product.colors),
                  ),
                  child: ProductVisual(product: product, shadow: false),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name.fr,
                        style: AppText.body(
                          16,
                          weight: FontWeight.w700,
                          color: context.ink,
                        ),
                      ),
                      Text(
                        '${product.category.label.fr} · $total en stock',
                        style: AppText.body(13, color: context.inkMuted),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 92,
                  child: TextField(
                    controller: _price,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    textAlign: TextAlign.right,
                    onChanged: (_) => _touch(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Prix',
                      suffixText: r'$',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (product.hasSizes)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final size in _sizes.keys)
                    _Counter(
                      label: size,
                      value: _sizes[size]!,
                      onChanged: (v) => _touch(() => _sizes[size] = v),
                    ),
                ],
              )
            else
              _Counter(
                label: 'Stock',
                value: _stock,
                onChanged: (v) => _touch(() => _stock = v),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                Switch(
                  value: !_hidden,
                  onChanged: (v) => _touch(() => _hidden = !v),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _hidden ? 'Masqué' : 'Visible',
                    style: AppText.body(14, color: context.inkMuted),
                  ),
                ),
                FilledButton(
                  onPressed: _dirty && !_saving ? _save : null,
                  child: Text(_saving ? '…' : 'Enregistrer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Compteur − / + pour une taille ou un stock.
class _Counter extends StatelessWidget {
  const _Counter({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 2, 2, 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.line),
        color: value == 0 ? const Color(0x33B3261E) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppText.body(
              13,
              weight: FontWeight.w600,
              color: context.inkMuted,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value > 0 ? () => onChanged(value - 1) : null,
            icon: const Icon(AppIcons.minus, size: 16),
          ),
          SizedBox(
            width: 22,
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: AppText.body(
                16,
                weight: FontWeight.w700,
                color: context.ink,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: value < 99 ? () => onChanged(value + 1) : null,
            icon: const Icon(AppIcons.plus, size: 16),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sondage : question du jour et résultats.

class _PollTab extends StatefulWidget {
  const _PollTab({required this.session});

  final AdminSession session;

  @override
  State<_PollTab> createState() => _PollTabState();
}

class _PollTabState extends State<_PollTab> {
  final _store = PollStore.instance;
  late String? _forced = _currentForced();

  static String? _currentForced() {
    final value = RemoteConfig.instance.setting('poll_question');
    return pollQuestions.any((q) => q.id == value) ? value as String : null;
  }

  Future<void> _setForced(String? id) async {
    final previous = _forced;
    setState(() => _forced = id);
    try {
      final token = await widget.session.token();
      if (id == null) {
        await Backend.delete('settings', 'key', 'poll_question', token: token);
      } else {
        await Backend.upsert('settings', {
          'key': 'poll_question',
          'value': id,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }, token: token);
      }
      await RemoteConfig.instance.refresh();
      if (mounted) _toast(context, 'Question du jour enregistrée.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _forced = previous);
      _toast(context, 'Échec : $e', error: true);
    }
  }

  Future<void> _reset(PollQuestion q) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remettre à zéro ?'),
        content: Text('Tous les votes de « ${q.question.fr} » seront effacés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    try {
      await Backend.delete(
        'poll_votes',
        'question_id',
        q.id,
        token: await widget.session.token(),
      );
      await _store.syncFromBackend();
      if (mounted) _toast(context, 'Votes effacés.');
    } catch (e) {
      if (mounted) _toast(context, 'Échec : $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 40),
        children: [
          DropdownButtonFormField<String?>(
            initialValue: _forced,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Question du jour',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Automatique (change chaque jour)'),
              ),
              for (final q in pollQuestions)
                DropdownMenuItem(value: q.id, child: Text(q.question.fr)),
            ],
            onChanged: _setForced,
          ),
          const SizedBox(height: 16),
          for (final q in pollQuestions)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            q.question.fr,
                            style: AppText.body(
                              16,
                              weight: FontWeight.w700,
                              color: context.ink,
                            ),
                          ),
                        ),
                        Text(
                          '${_store.total(q)} vote${_store.total(q) > 1 ? 's' : ''}',
                          style: AppText.body(13, color: context.inkMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final o in q.options)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                o.label.fr,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppText.body(
                                  14,
                                  color: context.inkMuted,
                                ),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(99),
                                child: LinearProgressIndicator(
                                  value: _store.share(q, o),
                                  minHeight: 8,
                                  backgroundColor: context.line,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 36,
                              child: Text(
                                '${_store.count(q, o)}',
                                textAlign: TextAlign.right,
                                style: AppText.body(
                                  14,
                                  weight: FontWeight.w700,
                                  color: context.ink,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _store.total(q) == 0
                            ? null
                            : () => _reset(q),
                        child: const Text('Remettre à zéro'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
