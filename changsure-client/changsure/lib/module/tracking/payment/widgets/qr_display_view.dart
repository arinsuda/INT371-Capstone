import 'package:changsure/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../../data/models/payment/payment_model.dart';

class QRDisplayView extends StatelessWidget {
  final CreatePaymentResponse qrData;
  final Duration remaining;
  final String bookingNumber;
  final WebViewController? webViewController;
  final String? technicianName;
  final String? technicianAvatar;

  const QRDisplayView({
    super.key,
    required this.qrData,
    required this.remaining,
    required this.bookingNumber,
    this.webViewController,
    this.technicianName,
    this.technicianAvatar,
  });

  String _formatCountdown(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ระบบกำลังรอการชำระเงิน',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            '฿${qrData.amount.toInt()}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 4),
              Text(
                'ครบกำหนดในอีก ${_formatCountdown(remaining)} นาที',
                style: TextStyle(
                  color: AppColors.colorTertiaryText,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.colorStroke),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.orange.shade50,
                        radius: 16,
                        backgroundImage:
                            technicianAvatar != null &&
                                technicianAvatar!.isNotEmpty
                            ? NetworkImage(technicianAvatar!)
                            : null,
                        child:
                            technicianAvatar == null ||
                                technicianAvatar!.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: Colors.orange,
                                size: 20,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            technicianName ?? 'QR PromptPay',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'QR PromptPay',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'กรุณาสแกนคิวอาร์โค้ดเพื่อชำระเงิน',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: webViewController != null
                        ? IgnorePointer(
                            child: WebViewWidget(
                              controller: webViewController!,
                            ),
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.colorWarning,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_outlined,
                  size: 18,
                  color: Color(0xFFAD6800),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "ท่านสามารถแสดงหน้าจอคิวอาร์โค้ด เพื่อให้ลูกค้าสแกนชำระเงินได้",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFAD6800),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

        ],
      ),
    );
  }
}
