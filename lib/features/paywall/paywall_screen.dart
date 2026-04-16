// ignore_for_file: avoid_print

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import '../analytics/analytics_service.dart';
import '../entitlements/entitlement_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final EntitlementService _entitlements = EntitlementService.instance;
  String _selectedPlan = 'starter';

  @override
  void initState() {
    super.initState();
    _entitlements.addListener(_handleEntitlementChange);
    _entitlements.refresh();
  }

  @override
  void dispose() {
    _entitlements.removeListener(_handleEntitlementChange);
    super.dispose();
  }

  void _handleEntitlementChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _selectPlan(String plan) {
    if (_entitlements.isCheckingOut) {
      return;
    }

    print('PAYWALL PLAN SELECTED: $plan');

    setState(() {
      _selectedPlan = plan;
    });
  }

  Future<void> _confirmPlan() async {
    try {
      print('PAYWALL CTA PRESSED: $_selectedPlan');
      AnalyticsService.track('checkout_started', {'plan': _selectedPlan});
      await _entitlements.startCheckout(_selectedPlan);
      print('PAYWALL CHECKOUT STARTED: $_selectedPlan');
    } catch (_) {
      print('PAYWALL CHECKOUT FAILED: $_selectedPlan');
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Checkout kon niet gestart worden'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  String _buttonLabel() {
    switch (_selectedPlan) {
      case 'pro':
        return 'Start Pro – €5,99 / maand';
      case 'starter':
      default:
        return 'Koop 20 credits – €2,99';
    }
  }

  String _headerSubtitle() {
    final credits = _entitlements.credits;

    if (credits > 0) {
      return 'Nog $credits credits over ⚡';
    }

    return 'Je hebt 0 credits over ⚡';
  }

  String _creditSummary() {
    if (_entitlements.isPro) {
      return 'Je hebt Pro: onbeperkt exporteren.';
    }

    return 'Je hebt ${_entitlements.credits} credits beschikbaar.';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isWide = MediaQuery.of(context).size.width >= 820;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Meer exports nodig?',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge?.copyWith(
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.9,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Text(
                      _headerSubtitle(),
                      textAlign: TextAlign.center,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _CreditsSummary(text: _creditSummary()),
                  const SizedBox(height: AppSpacing.xxl),
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _PlanCard(
                                title: 'Starter',
                                price: '€2,99',
                                subtitle: 'eenmalig',
                                badge: 'Meest gekozen',
                                description:
                                    'Voor snelle exports zonder abonnement.',
                                features: const [
                                  '20 credits totaal',
                                  '1 export = 1 credit',
                                  'Geen maandelijkse kosten',
                                ],
                                selected: _selectedPlan == 'starter',
                                highlighted: true,
                                onTap: () => _selectPlan('starter'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: _PlanCard(
                                title: 'Pro',
                                price: '€5,99',
                                subtitle: 'per maand',
                                description:
                                    'Voor creators die vaak content exporteren.',
                                features: const [
                                  'Onbeperkt exporteren',
                                  'Geen creditlimiet',
                                  'Maandelijks opzegbaar',
                                ],
                                selected: _selectedPlan == 'pro',
                                onTap: () => _selectPlan('pro'),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _PlanCard(
                              title: 'Starter',
                              price: '€2,99',
                              subtitle: 'eenmalig',
                              badge: 'Meest gekozen',
                              description:
                                  'Voor snelle exports zonder abonnement.',
                              features: const [
                                '20 credits totaal',
                                '1 export = 1 credit',
                                'Geen maandelijkse kosten',
                              ],
                              selected: _selectedPlan == 'starter',
                              highlighted: true,
                              onTap: () => _selectPlan('starter'),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _PlanCard(
                              title: 'Pro',
                              price: '€5,99',
                              subtitle: 'per maand',
                              description:
                                  'Voor creators die vaak content exporteren.',
                              features: const [
                                'Onbeperkt exporteren',
                                'Geen creditlimiet',
                                'Maandelijks opzegbaar',
                              ],
                              selected: _selectedPlan == 'pro',
                              onTap: () => _selectPlan('pro'),
                            ),
                          ],
                        ),
                  const SizedBox(height: AppSpacing.xxl),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _entitlements.isCheckingOut
                            ? null
                            : _confirmPlan,
                        child: _entitlements.isCheckingOut
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.textPrimary,
                                ),
                              )
                            : Text(_buttonLabel()),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Veilig betalen via Stripe.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Doorgaan met gratis (beperkt)'),
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

class _CreditsSummary extends StatelessWidget {
  const _CreditsSummary({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary.withValues(alpha: 0.94),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.description,
    required this.features,
    required this.selected,
    required this.onTap,
    this.badge,
    this.highlighted = false,
  });

  final String title;
  final String price;
  final String subtitle;
  final String description;
  final List<String> features;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final borderColor = selected || highlighted
        ? AppColors.accent.withValues(alpha: selected ? 0.56 : 0.34)
        : AppColors.textSecondary.withValues(alpha: 0.10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: highlighted
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.16),
                blurRadius: highlighted ? 34 : 22,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    badge!,
                    style: textTheme.labelMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? AppColors.accent : Colors.transparent,
                      border: Border.all(
                        color: selected
                            ? AppColors.accent
                            : AppColors.textSecondary.withValues(alpha: 0.36),
                      ),
                    ),
                    child: selected
                        ? const Icon(
                            Icons.check,
                            size: 15,
                            color: AppColors.textPrimary,
                          )
                        : null,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    price,
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Text(
                      subtitle,
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                description,
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...features.map(
                (feature) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 7),
                        decoration: BoxDecoration(
                          color: highlighted
                              ? AppColors.accent
                              : AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          feature,
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.92,
                            ),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
