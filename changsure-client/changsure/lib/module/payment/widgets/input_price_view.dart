import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/models/booking/booking_model.dart';

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
    final isFixed = widget.booking.pricingType == 'FIXED';

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'กรุณากำหนดค่าบริการของคุณ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'ระบุจำนวนเงินที่คุณต้องการ โดยช่างสามารถประเมินงานได้อย่างเหมาะสม',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF91D5FF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF1890FF),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isFixed
                              ? 'ราคาคงที่: ฿${widget.booking.quotedPriceFixed?.toInt()}'
                              : 'ราคาที่เลือกต้องอยู่ระหว่าง ฿${widget.booking.quotedPriceMin?.toInt()} - ${widget.booking.quotedPriceMax?.toInt()}',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _controller,
                  readOnly: isFixed,
                  keyboardType: TextInputType.number,

                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'ระบุราคา',

                    errorText: _errorMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: _errorMessage != null
                            ? Colors.red
                            : Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.isLoading ? null : _validateAndConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF003DAB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'ยืนยัน',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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
}
