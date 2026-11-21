import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// The receipt's loyalty QR on screen: for cafés without a printer, or a lost receipt.
/// The customer scans it with their phone to earn the points.
Future<void> showLoyaltyQr(BuildContext context, {required String url, required String receiptNumber}) =>
    showDialog<void>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: Text('Points fidélité · Ticket $receiptNumber'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Le client scanne ce code avec son téléphone.'),
                const SizedBox(height: 16),
                Container(
                  key: const Key('loyalty-qr'),
                  color: Colors.white, // dark on white, whatever the theme: phones read it better
                  padding: const EdgeInsets.all(12),
                  child: QrImageView(data: url, size: 260, errorCorrectionLevel: QrErrorCorrectLevel.M),
                ),
              ],
            ),
            actions: [FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Fermer'))],
          ),
    );
