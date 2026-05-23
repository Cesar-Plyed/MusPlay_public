import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/subscription_plan.dart';
import '../../../core/providers/subscription_provider.dart';
import '../../../core/theme/app_theme.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansScreen> createState() => _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Planes', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.surface,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        elevation: 0,
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, sub, _) {
          final plans = sub.availablePlans;
          if (plans.isEmpty) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCurrentPlanBanner(context, sub),
                const SizedBox(height: 24),
                const Text(
                  'Planes disponibles',
                  style: TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...plans.map((plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildPlanCard(context, plan, plan.id == sub.currentPlanId, sub),
                )),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentPlanBanner(BuildContext context, SubscriptionProvider sub) {
    final plan = sub.currentPlan;
    if (plan == null) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: sub.isFree
              ? [AppTheme.surface, AppTheme.surfaceLight]
              : [const Color(0xFF2A1F0A), const Color(0xFF3D2E10)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sub.isFree ? AppTheme.divider : AppTheme.accent,
          width: sub.isFree ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu plan actual',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                plan.name,
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 26, fontWeight: FontWeight.bold),
              ),
              Text(
                plan.price == 0 ? 'GRATIS' : '\$${plan.price.toStringAsFixed(0)}/mes',
                style: TextStyle(
                  color: plan.price == 0 ? Colors.greenAccent : AppTheme.accent,
                  fontSize: 18, fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${plan.maxUploadSongs} subidas · ${plan.maxDownloadSongs} descargas · en tu Google Drive',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, SubscriptionPlan plan, bool isCurrent, SubscriptionProvider sub) {
    final isPremium = plan.id == 'premium';

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? AppTheme.accent : (isPremium ? AppTheme.accent.withOpacity(0.3) : AppTheme.divider),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: isPremium ? [
          BoxShadow(color: AppTheme.accent.withOpacity(0.08), blurRadius: 16, spreadRadius: 2),
        ] : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    if (isPremium) const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                    ),
                    Text(plan.name, style: const TextStyle(
                      color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold,
                    )),
                  ]),
                  const SizedBox(height: 2),
                  Text(plan.description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    plan.price == 0 ? 'Gratis' : '\$${plan.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: plan.price == 0 ? Colors.greenAccent : AppTheme.accent,
                      fontSize: 22, fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (plan.price > 0)
                    const Text('/mes', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  if (isCurrent)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.green.withOpacity(0.5)),
                      ),
                      child: const Text('Activo', style: TextStyle(
                        color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold,
                      )),
                    ),
                ]),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.divider),
            const SizedBox(height: 12),

            // Highlights
            _buildHighlights(plan),
            const SizedBox(height: 16),

            // Features list
            ...plan.features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Icon(Icons.check_circle_rounded,
                  size: 16,
                  color: plan.id == 'premium' ? AppTheme.accent : Colors.greenAccent,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(f, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14))),
              ]),
            )),
            const SizedBox(height: 16),

            // Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: isCurrent
                  ? OutlinedButton(
                      onPressed: null,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.divider),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Plan actual', style: TextStyle(color: AppTheme.textSecondary)),
                    )
                  : ElevatedButton(
                      onPressed: () => _showConfirmDialog(context, plan, sub),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPremium ? AppTheme.accent : AppTheme.surfaceLight,
                        foregroundColor: isPremium ? Colors.black : AppTheme.textPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isPremium ? 'Activar Premium' : 'Cambiar a ${plan.name}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlights(SubscriptionPlan plan) {
    return Row(
      children: [
        _highlight(Icons.upload_rounded, '${plan.maxUploadSongs}', 'Subidas', AppTheme.accent),
        const SizedBox(width: 8),
        _highlight(Icons.download_rounded, '${plan.maxDownloadSongs}', 'Descargas', Colors.blueAccent),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _highlight(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ]),
      ),
    );
  }

  void _showConfirmDialog(BuildContext context, SubscriptionPlan plan, SubscriptionProvider sub) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Cambiar a ${plan.name}',
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (plan.price > 0)
            Text('\$${plan.price.toStringAsFixed(0)}/mes',
                style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 18))
          else
            const Text('Totalmente GRATIS',
                style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          const Text('¿Confirmas el cambio de plan?',
              style: TextStyle(color: AppTheme.textSecondary)),
          if (plan.price > 0) ...[
            const SizedBox(height: 8),
            const Text(
              'Aquí se integrará tu pasarela de pagos.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () { _changePlan(context, plan, sub); Navigator.pop(ctx); },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent, foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _changePlan(BuildContext context, SubscriptionPlan plan, SubscriptionProvider sub) async {
    final messenger = ScaffoldMessenger.of(context);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Usuario no autenticado')));
      return;
    }
    try {
      await sub.changePlan(userId, plan.id);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text('✅ Plan cambiado a ${plan.name}'),
        backgroundColor: Colors.green,
      ));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }
}
