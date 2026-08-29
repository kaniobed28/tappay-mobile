import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tappay/features/merchants/data/merchant_models.dart';
import 'package:tappay/core/network/api_error.dart';
import 'package:tappay/features/merchants/data/merchants_api.dart';
import 'package:tappay/features/sessions/data/sessions_api.dart';
import 'package:tappay/core/theme/app_theme.dart';
import 'package:tappay/core/widgets/ui.dart';
import 'package:tappay/features/sessions/presentation/collect_screen.dart';

/// Merchant entry point: ensure a merchant profile exists, then collect an amount.
class ReceiveScreen extends StatefulWidget {
  const ReceiveScreen({super.key});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  MerchantModel? _merchant;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _merchant = await context.read<MerchantsApi>().myMerchant();
      _error = null;
    } catch (e) {
      _error = apiErrorMessage(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive payment')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? EmptyState(
                  icon: Icons.wifi_off_rounded,
                  title: 'Something went wrong',
                  subtitle: _error,
                  action: OutlinedButton(onPressed: _load, child: const Text('Retry')),
                )
              : _merchant == null
                  ? _MerchantSetup(onDone: (m) => setState(() => _merchant = m))
                  : _AmountForm(merchant: _merchant!),
    );
  }
}

class _MerchantSetup extends StatefulWidget {
  final void Function(MerchantModel) onDone;
  const _MerchantSetup({required this.onDone});

  @override
  State<_MerchantSetup> createState() => _MerchantSetupState();
}

class _MerchantSetupState extends State<_MerchantSetup> {
  final _name = TextEditingController();
  bool _busy = false;
  String? _error;

  Future<void> _save() async {
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Enter a business name');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final m = await context.read<MerchantsApi>().registerMerchant(_name.text.trim());
      widget.onDone(m);
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(gradient: AppGradients.mint, borderRadius: BorderRadius.circular(AppRadius.m)),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 18),
          const Text('Set up your business', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -0.4)),
          const SizedBox(height: 4),
          const Text('This name is shown to customers when they pay you.', style: TextStyle(color: AppColors.inkSoft, height: 1.4)),
          const SizedBox(height: 22),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Business name', prefixIcon: Icon(Icons.badge_outlined)),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          GradientButton(label: 'Continue', gradient: AppGradients.mint, loading: _busy, onPressed: _save),
        ],
      ),
    );
  }
}

class _AmountForm extends StatefulWidget {
  final MerchantModel merchant;
  const _AmountForm({required this.merchant});

  @override
  State<_AmountForm> createState() => _AmountFormState();
}

class _AmountFormState extends State<_AmountForm> {
  String _amount = '0';
  final _note = TextEditingController();
  bool _busy = false;
  String? _error;

  void _tap(String key) {
    setState(() {
      _error = null;
      if (key == '⌫') {
        _amount = _amount.length <= 1 ? '0' : _amount.substring(0, _amount.length - 1);
      } else if (key == '.') {
        if (!_amount.contains('.')) _amount = '$_amount.';
      } else {
        if (_amount == '0') {
          _amount = key;
        } else if (_amount.contains('.') && _amount.split('.')[1].length >= 2) {
          return; // max 2 decimals
        } else {
          _amount = '$_amount$key';
        }
      }
    });
  }

  int get _minor => ((double.tryParse(_amount) ?? 0) * 100).round();

  Future<void> _start() async {
    if (_minor <= 0) {
      setState(() => _error = 'Enter an amount');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final session = await context.read<SessionsApi>().createSession(amount: _minor, description: _note.text.trim());
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => CollectScreen(session: session)));
    } catch (e) {
      setState(() => _error = apiErrorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fill the screen on a tall (phone) viewport, but scroll instead of
    // overflowing when the viewport is short (web/landscape/split-screen).
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 24),
                      Text(widget.merchant.businessName,
                          style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(widget.merchant.currency,
                                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.inkFaint)),
                          ),
                          Text(_amount,
                              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w800, color: AppColors.ink, letterSpacing: -1.5)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_error != null)
                        Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13))
                      else
                        SizedBox(
                          width: 240,
                          child: TextField(
                            controller: _note,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: 'Add a note (optional)',
                              filled: false,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                _Keypad(onKey: _tap),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: GradientButton(
                    label: 'Request payment',
                    gradient: AppGradients.mint,
                    icon: Icons.contactless_rounded,
                    loading: _busy,
                    onPressed: _start,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  final void Function(String) onKey;
  const _Keypad({required this.onKey});

  @override
  Widget build(BuildContext context) {
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.9,
        children: keys
            .map((k) => InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.m),
                  onTap: () => onKey(k),
                  child: Center(
                    child: k == '⌫'
                        ? const Icon(Icons.backspace_outlined, color: AppColors.ink, size: 22)
                        : Text(k, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
