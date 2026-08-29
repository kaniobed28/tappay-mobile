import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:tappay/core/network/api_error.dart';
import 'package:tappay/core/theme/app_theme.dart';
import 'package:tappay/core/widgets/ui.dart';
import 'package:tappay/features/users/data/users_api.dart';

/// Asks for the payer's mobile-money number and saves it to their profile.
///
/// Mobile money charges a phone rather than a card, so a payer who signed in with
/// Google has nothing on file the provider can bill. Rather than dead-ending the
/// payment, we collect the number at the moment it is needed.
///
/// Returns true once the number is saved.
Future<bool> askForMobileNumber(BuildContext context) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (_) => Padding(
      // Keeps the field above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: const _MobileNumberForm(),
    ),
  );
  return saved ?? false;
}

class _MobileNumberForm extends StatefulWidget {
  const _MobileNumberForm();

  @override
  State<_MobileNumberForm> createState() => _MobileNumberFormState();
}

class _MobileNumberFormState extends State<_MobileNumberForm> {
  final _controller = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final number = _controller.text.trim();
    if (number.isEmpty) {
      setState(() => _error = 'Enter your mobile money number');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final api = context.read<UsersApi>();
    final navigator = Navigator.of(context);
    try {
      await api.updateProfile(phone: number);
      if (mounted) navigator.pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = apiErrorMessage(e);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          const Text(
            'Your mobile money number',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.ink),
          ),
          const SizedBox(height: AppSpace.s),
          const Text(
            'The payment prompt is sent to this number. You only need to add it once.',
            style: TextStyle(color: AppColors.inkSoft, height: 1.4),
          ),
          const SizedBox(height: AppSpace.xl),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
            decoration: const InputDecoration(
              labelText: 'Mobile number',
              hintText: '024 123 4567',
              prefixIcon: Icon(Icons.smartphone_rounded),
            ),
            onSubmitted: (_) => _save(),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpace.m),
            Row(children: [
              const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.danger),
              const SizedBox(width: 6),
              Expanded(
                child: Text(_error!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ),
            ]),
          ],
          const SizedBox(height: AppSpace.xl),
          GradientButton(label: 'Save and continue', loading: _saving, onPressed: _save),
        ],
      ),
    );
  }
}
