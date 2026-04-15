// Example for a payment success screen in Flutter.
// Place this logic in your real success route/page after Stripe redirects back.

import 'package:flutter/material.dart';

import 'stripe_billing_api_example.dart';

class PaymentSuccessExampleScreen extends StatefulWidget {
  const PaymentSuccessExampleScreen({super.key, required this.billingApi});

  final PixfitBillingApi billingApi;

  @override
  State<PaymentSuccessExampleScreen> createState() =>
      _PaymentSuccessExampleScreenState();
}

class _PaymentSuccessExampleScreenState
    extends State<PaymentSuccessExampleScreen> {
  PixfitBillingStatus? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    try {
      // The webhook is the source of truth. If this loads immediately after
      // redirect and credits are not updated yet, show a retry button or poll
      // once after a short delay in your real screen.
      final status = await widget.billingApi.fetchStatus();

      if (!mounted) {
        return;
      }

      setState(() {
        _status = status;
        _error = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = 'Status kon niet geladen worden';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;

    return Scaffold(
      appBar: AppBar(title: const Text('Betaling gelukt')),
      body: Center(
        child: _error != null
            ? Text(_error ?? '')
            : status == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Credits: ${status.credits}'),
                  Text('Pro actief: ${status.isPro ? 'Ja' : 'Nee'}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refreshStatus,
                    child: const Text('Status opnieuw ophalen'),
                  ),
                ],
              ),
      ),
    );
  }
}
