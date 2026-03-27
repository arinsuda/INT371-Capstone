import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/models/booking/booking_model.dart';

class InputPriceView extends StatefulWidget {
  final Booking booking;
  final bool isLoading;
  final Function(double) onConfirm;

  const InputPriceView({
    super.key,
    required this.booking,
    required this.onConfirm,
    this.isLoading = false,
  });

  @override
  State<InputPriceView> createState() => _InputPriceViewState();
}

class _InputPriceViewState extends State<InputPriceView> {
  late TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final initialPrice = widget.booking.pricingType == 'FIXED'
        ? widget.booking.quotedPriceFixed?.toStringAsFixed(0) ?? ''
        : '';
    _controller = TextEditingController(text: initialPrice);
  }

  void _validateAndConfirm() {
    final text = _controller.text;
    if (text.isEmpty) {
      setState(() => _errorMessage = 'กรุณาระบุจำนวนเงิน');
      return;
    }

    final price = double.tryParse(text);
    if (price == null) {
      setState(() => _errorMessage = 'รูปแบบตัวเลขไม่ถูกต้อง');
      return;
    }

    if (widget.booking.pricingType == 'RANGE') {
      final min = widget.booking.quotedPriceMin ?? 0;
      final max = widget.booking.quotedPriceMax ?? double.infinity;

      if (price < min || price > max) {
        setState(
          () => _errorMessage =
              'ราคาต้องอยู่ระหว่าง ฿${min.toInt()} - ${max.toInt()}',
        );
        return;
      }
    }

    setState(() => _errorMessage = null);
    widget.onConfirm(price);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'กรุณากำหนดค่าบริการของคุณ',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'ระบุจำนวนเงินที่คุณต้องการ โดยช่างสามารถประเมินงานได้อย่างเหมาะสม',
            style: TextStyle(color: AppColors.colorTertiaryText, fontSize: 16),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.colorStroke),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "ราคาที่เลือกต้องไม่ต่ำกว่าราคาขั้นต่ำ และไม่เกินราคาสูงสุดของบริการ",
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
                Center(
                  child: SizedBox(
                    width: 200,
                    child: TextField(
                      controller: _controller,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            '${widget.booking.quotedPriceMin} - ${widget.booking.quotedPriceMax}',
                        hintStyle: TextStyle(color: AppColors.primaryBorder),
                        errorText: _errorMessage,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: _errorMessage != null
                                ? AppColors.colorError
                                : AppColors.primaryBorderHover,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    onPressed: widget.isLoading ? null : _validateAndConfirm,
                    padding: EdgeInsetsGeometry.symmetric(vertical: 8),
                    borderRadius: 12,
                    text: widget.isLoading ? '' : 'ยืนยัน',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
