import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tappay/core/theme/app_theme.dart';

/// Primary call-to-action: gradient fill, press-scale, integrated loading state.
class GradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool loading;
  final Gradient gradient;
  final bool glow;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.loading = false,
    this.gradient = AppGradients.brand,
    this.glow = true,
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: AppMotion.fast,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.55,
          duration: AppMotion.fast,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(AppRadius.m),
              boxShadow: widget.glow && enabled ? AppShadows.brandGlow : null,
            ),
            child: Center(
              child: widget.loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                        ],
                        Text(widget.label,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.1)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Standard elevated surface card.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpace.l), this.onTap, this.shadow});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.l),
        border: Border.all(color: AppColors.border),
        boxShadow: shadow ?? AppShadows.card,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(borderRadius: BorderRadius.circular(AppRadius.l), onTap: onTap, child: content);
  }
}

/// Rich amount display with small currency + fraction.
class AmountDisplay extends StatelessWidget {
  final int amount;
  final String currency;
  final double size;
  final Color color;
  const AmountDisplay({super.key, required this.amount, required this.currency, this.size = 40, this.color = AppColors.ink});

  @override
  Widget build(BuildContext context) {
    final p = amountParts(amount, currency);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Text(p.currency, style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.6))),
        ),
        Text(p.whole, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, letterSpacing: -1, color: color)),
        Text('.${p.fraction}', style: TextStyle(fontSize: size * 0.5, fontWeight: FontWeight.w700, color: color.withValues(alpha: 0.55))),
      ],
    );
  }
}

/// Coloured status pill (SUCCESS / PENDING / FAILED / REFUNDED …).
class StatusPill extends StatelessWidget {
  final String status;
  const StatusPill({super.key, required this.status});

  Color get _c => switch (status.toUpperCase()) {
        'SUCCESS' => AppColors.success,
        'FAILED' => AppColors.danger,
        'REFUNDED' => AppColors.inkSoft,
        _ => AppColors.warning,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: _c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.chip)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: _c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(status.toUpperCase(),
              style: TextStyle(color: _c, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        ],
      ),
    );
  }
}

/// Friendly empty / error state.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(AppRadius.l)),
              child: Icon(icon, size: 32, color: AppColors.inkFaint),
            ),
            const SizedBox(height: AppSpace.l),
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.inkSoft, height: 1.4)),
            ],
            if (action != null) ...[const SizedBox(height: AppSpace.xl), action!],
          ],
        ),
      ),
    );
  }
}

/// The TapPay logo mark — a rounded tile with a contactless glyph.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: AppShadows.brandGlow,
      ),
      child: Icon(Icons.contactless_rounded, color: Colors.white, size: size * 0.56),
    );
  }
}

/// Animated success check — scales in with a drawn tick. Used on payment success.
class SuccessCheck extends StatefulWidget {
  final double size;
  final Color color;
  const SuccessCheck({super.key, this.size = 96, this.color = AppColors.success});

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 620))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, _) {
        final pop = Curves.elasticOut.transform(math.min(1, _c.value * 1.4));
        final ring = Curves.easeOut.transform(math.min(1, _c.value * 1.2));
        return Transform.scale(
          scale: pop.clamp(0.0, 1.0),
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle, boxShadow: [
              BoxShadow(color: widget.color.withValues(alpha: 0.35 * ring), blurRadius: 30, spreadRadius: 4 * ring),
            ]),
            child: CustomPaint(painter: _CheckPainter(progress: Curves.easeOut.transform(math.max(0, (_c.value - 0.35) / 0.65)))),
          ),
        );
      },
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  _CheckPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * 0.09
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final a = Offset(size.width * 0.30, size.height * 0.52);
    final b = Offset(size.width * 0.44, size.height * 0.66);
    final c = Offset(size.width * 0.72, size.height * 0.36);

    final path = Path()..moveTo(a.dx, a.dy);
    if (progress <= 0.5) {
      final t = progress / 0.5;
      path.lineTo(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
    } else {
      path.lineTo(b.dx, b.dy);
      final t = (progress - 0.5) / 0.5;
      path.lineTo(b.dx + (c.dx - b.dx) * t, b.dy + (c.dy - b.dy) * t);
    }
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.progress != progress;
}

/// A soft pulsing dot row for "waiting" states.
class WaitingIndicator extends StatelessWidget {
  final String label;
  const WaitingIndicator({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brand)),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AppColors.inkSoft, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

/// Section label used above lists / groups.
class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink, letterSpacing: -0.2)),
        const Spacer(),
        ?trailing,
      ],
    );
  }
}
