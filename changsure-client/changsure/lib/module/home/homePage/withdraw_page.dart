import 'package:changsure/core/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../../../state/user_provider.dart';

class WithdrawPage extends ConsumerStatefulWidget {
  const WithdrawPage({super.key});

  @override
  ConsumerState<WithdrawPage> createState() => _WithdrawPageState();
}

class _WithdrawPageState extends ConsumerState<WithdrawPage> {
  int? selectedAmount = 2000;
  final TextEditingController amountController = TextEditingController();

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
  }

  @override
  void initState() {
    super.initState();
    amountController.text = _formatNumber(selectedAmount!);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    final tech = user?.technicianProfile;
    final walletAsync = ref.watch(walletSummaryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🔵 BLUE HEADER
          Container(
            height: 250,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF001F9F),
                  AppColors.primary,
                  Color(0xFFB7CFFF),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // 🧾 CONTENT
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Header(
                    header: "ถอนเงิน",
                    color: Colors.white,
                    iconColor: Colors.white,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 30),

                // ⚪ WHITE SECTION
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 24,
                      right: 24,
                      top: 50,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 25,
                                backgroundImage:
                                    (tech?.avatarUrl != null &&
                                        tech!.avatarUrl!.isNotEmpty)
                                    ? NetworkImage(
                                        tech.avatarUrl!,
                                      ) // ✅ ใช้ NetworkImage
                                    : const AssetImage(
                                            'assets/image/Technician.png',
                                          )
                                          as ImageProvider, // ✅ fallback เป็น asset
                              ),
                              SizedBox(width: 10),
                              Text(
                                tech!.fullName,
                                style: TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          walletAsync.when(
                            data: (wallet) {
                              return Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppColors.colorStroke),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "ยอดเงินที่ถอนออกได้ (-5%)",
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "฿ ${_formatNumber(wallet.withdrawableBalance.toInt())}",
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            loading: () => Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              child: const Center(child: CircularProgressIndicator()),
                            ),
                            error: (e, _) => Text("Error: $e"),
                          ),
                          SizedBox(height: 36),
                          Text(
                            "ระบุจำนวนเงิน",
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 20,
                            ),
                          ),
                          SizedBox(height: 16),

                          // 💰 จำนวนเงินด้านบน
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: amountController,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly, // ✅ อนุญาตเฉพาะตัวเลข
                                  ],
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (value) {
                                    final number = int.tryParse(value.replaceAll(',', ''));
                                    if (number == null) return;

                                    final formatted = _formatNumber(number);

                                    amountController.value = TextEditingValue(
                                      text: formatted,
                                      selection: TextSelection.collapsed(offset: formatted.length),
                                    );

                                    setState(() {
                                      selectedAmount = null;
                                    });
                                  },
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                "บาท",
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),


                          Divider(color: AppColors.colorStroke),

                          SizedBox(height: 20),

                          // 💳 ปุ่มเลือกจำนวนเงิน
                          Row(
                            children: [
                              _amountButton(500),
                              SizedBox(width: 12),
                              _amountButton(1000),
                              SizedBox(width: 12),
                              _amountButton(2000),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountButton(int amount) {
    final isSelected = selectedAmount == amount;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedAmount = amount;
            amountController.text = _formatNumber(amount); // 👈 sync input
          });
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Color(0xFF3071C7) : Color(0xFFF2F2F2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              "${_formatNumber(amount)} บาท",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
