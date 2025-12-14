import 'package:changsure/core/theme.dart';
import 'package:flutter/material.dart';

class PaymentCard extends StatelessWidget {
  const PaymentCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "การชำระเงิน",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 4),
          Row(

            children: [
              Image.asset('assets/icons/COD_logo.png', width: 24, height: 24),
              SizedBox(width: 8),
              Text(
                "เก็บเงินปลายทาง",
                style: TextStyle(fontSize: 14, color: AppColors.primaryText),
              ),
              const Spacer(),

              Radio<bool>(
                value: true,
                groupValue: true,
                onChanged: null,
                activeColor: AppColors.colorTertiaryText,
              ),
            ],
          ),
          SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: AppColors.colorTertiaryText,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "ระบบ ChangSure รองรับเฉพาะการชำระแบบชำระเงินปลายทาง (COD) เท่านั้น โปรดชำระผ่าน QR Code ที่ช่างแจ้งให้หลังจากการดำเนินงาน เสร็จสมบูรณ์ และช่างกดปิดงานเรียบร้อยแล้ว",
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.colorTertiaryText,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
