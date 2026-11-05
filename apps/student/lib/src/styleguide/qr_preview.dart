import 'package:busin_ui/busin_ui.dart';
import 'package:flutter/material.dart';

import '../qr/boarding_ticket.dart';

/// Debug builds only: the boarding ticket with a made-up code, to look at without an approved subscription
/// (`--route /styleguide/qr`).
class QrPreviewScreen extends StatelessWidget {
  const QrPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = BusinL10n.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(BusinSpace.x5),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: BoardingTicket(
                code: 'busin1.00000000-0000-0000-0000-000000000000.58000000.AbCdEfGhIjKlMnOpQrStUvWxYz012345',
                name: 'Nnamu Radiance Kinga',
                matricule: 'ICT2026-0001',
                size: 280,
                liveLabel: l10n.qrLive,
                imageLabel: l10n.qrImageLabel,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
