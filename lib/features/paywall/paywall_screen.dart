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
    AnalyticsService.track('paywall_viewed');
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
    setState(() {
      _selectedPlan = plan;
    });
  }

  Future<void> _confirmPlan() async {
    print("CHECKOUT CLICKED - plan: $_selectedPlan");

    if (_selectedPlan == 'free') {
      Navigator.pop(context);
      return;
    }

    try {
      print("STARTING CHECKOUT API CALL");

      AnalyticsService.track('checkout_started', {'plan': _selectedPlan});

      await _entitlements.startCheckout(_selectedPlan);

      print("CHECKOUT API CALL DONE");
    } catch (_) {
      print("CHECKOUT FAILED");

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

  String _confirmButtonLabel() {
    switch (_selectedPlan) {
      case 'free':
        return 'Ga door met Free';
      case 'starter':
        return 'Koop Starter';
      case 'pro':
        return 'Start Pro abonnement';
      default:
        return 'Kies dit plan';
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: AppColors.textSecondary.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Text(
                    'Unlock smoother exports',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Maak je content perfect passend',
                  style: textTheme.headlineLarge?.copyWith(fontSize: 34),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  _entitlements.isPro
                      ? 'Je Pro abonnement is actief'
                      : 'Kies een plan dat bij je past',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _EntitlementSummary(entitlements: _entitlements),
                const SizedBox(height: AppSpacing.xxl),
                _PlanCard(
                  title: 'Free',
                  price: 'Gratis',
                  features: const [
                    'Gebruik je beschikbare credits',
                    'basis functionaliteit',
                  ],
                  selected: _selectedPlan == 'free',
                  onTap: () => _selectPlan('free'),
                ),
                const SizedBox(height: AppSpacing.lg),
                _PlanCard(
                  title: 'Starter',
                  price: 'EUR 2.99 eenmalig',
                  features: const [
                    '20 exports totaal',
                    'geen watermerk',
                    'eenmalige aankoop',
                  ],
                  selected: _selectedPlan == 'starter',
                  onTap: () => _selectPlan('starter'),
                ),
                const SizedBox(height: AppSpacing.lg),
                _PlanCard(
                  title: 'Pro',
                  price: 'EUR 5.99 / maand',
                  features: const [
                    'Unlimited exports',
                    'alle features',
                    'toekomstige video support',
                    'maandelijks abonnement',
                  ],
                  badge: 'Meest gekozen',
                  highlighted: true,
                  selected: _selectedPlan == 'pro',
                  onTap: () => _selectPlan('pro'),
                ),
                const SizedBox(height: AppSpacing.xxl),
                SizedBox(
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
                        : Text(_confirmButtonLabel()),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(
                    'Annuleer wanneer je wilt',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

class _EntitlementSummary extends StatelessWidget {
  const _EntitlementSummary({required this.entitlements});

  final EntitlementService entitlements;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final status = entitlements.isPro
        ? 'Current plan: Pro'
        : 'Current plan: ${entitlements.displayPlanLabel} · Credits: ${entitlements.credits}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.56),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.10),
        ),
      ),
      child: Text(
        status,
        style: textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary.withValues(alpha: 0.92),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.price,
    required this.features,
    required this.selected,
    required this.onTap,
    this.badge,
    this.highlighted = false,
  });

  final String title;
  final String price;
  final List<String> features;
  final bool selected;
  final VoidCallback onTap;
  final String? badge;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: highlighted ? const Color(0xFF202033) : AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? AppColors.accent
                  : highlighted
                  ? AppColors.accent.withValues(alpha: 0.45)
                  : AppColors.textSecondary.withValues(alpha: 0.10),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: highlighted
                    ? AppColors.accent.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.18),
                blurRadius: highlighted ? 30 : 22,
                spreadRadius: highlighted ? 2 : 0,
                offset: const Offset(0, 12),
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
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge ?? '',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                price,
                style: textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                title == 'Free'
                    ? 'Voor rustig gebruik en basis exports'
                    : title == 'Starter'
                    ? 'Meer ruimte zonder abonnement'
                    : 'Alles open voor creators die veel posten',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              for (final feature in features) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      height: 6,
                      width: 6,
                      decoration: BoxDecoration(
                        color: highlighted
                            ? AppColors.accent
                            : AppColors.textSecondary.withValues(alpha: 0.75),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        feature,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
