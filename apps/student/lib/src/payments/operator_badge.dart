import 'package:busin_core/busin_core.dart';
import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';

import 'payment_text.dart';

/// The operator a number belongs to, in its own colours. A text mark for now: the operators' official acceptance marks
/// replace it here, in one place, once BusIn has them (ADR 0029). These are the operators' brand colours, not BusIn's, so
/// they are the only colours in the app not read from the theme.
class OperatorBadge extends StatelessWidget {
  const OperatorBadge({super.key, required this.operator, this.compact = false});

  final MobileMoneyOperator operator;
  final bool compact;

  static const _brand = {
    MobileMoneyOperator.mtn: (bg: Color(0xFFFFCC00), fg: Color(0xFF000000), short: 'MTN MoMo'),
    MobileMoneyOperator.orange: (bg: Color(0xFFFF7900), fg: Color(0xFF000000), short: 'Orange Money'),
  };

  @override
  Widget build(BuildContext context) {
    final brand = _brand[operator]!;
    return Semantics(
      label: operatorName(operator),
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(color: brand.bg, borderRadius: BorderRadius.circular(BusinRadius.sm)),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? BusinSpace.x2 : BusinSpace.x3, vertical: compact ? 2 : BusinSpace.x1),
            child: Text(
              brand.short,
              style: (compact ? Theme.of(context).textTheme.labelSmall : Theme.of(context).textTheme.labelMedium)?.copyWith(
                color: brand.fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
