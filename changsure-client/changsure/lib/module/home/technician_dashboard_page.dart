import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/core/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../data/models/technician/dashboard_model.dart';
import '../../state/user_provider.dart';
import 'homePage/widgets/notification_badge_button.dart';
import 'homePage/withdraw_page.dart';

class TechnicianDashboardPage extends ConsumerStatefulWidget {
  const TechnicianDashboardPage({super.key});

  @override
  ConsumerState<TechnicianDashboardPage> createState() =>
      _TechnicianDashboardPageState();
}

class _TechnicianDashboardPageState
    extends ConsumerState<TechnicianDashboardPage> {


  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletSummaryProvider);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 🔵 BLUE HEADER
          Container(
            height: 400,
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
                _buildHeader(),
                const SizedBox(height: 20),
                _buildBalance(walletAsync),
                const SizedBox(height: 30),

                // ⚪ WHITE SECTION
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
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
                          // const SizedBox(height: 24),
                          // _buildWalletHeader(),
                          // const SizedBox(height: 16),
                          // _buildWalletCards(walletAsync),
                          const SizedBox(height: 24),
                          _buildStatsHeader(),
                          const SizedBox(height: 12),
                          _buildStatsGrid(walletAsync),
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

  // ================= HEADER =================

  Widget _buildHeader() {
    final user = ref.watch(userProvider);

    final tech = user?.technicianProfile;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage:
            (tech?.avatarUrl != null && tech!.avatarUrl!.isNotEmpty)
                ? NetworkImage(tech.avatarUrl!) // ✅ ใช้ NetworkImage
                : const AssetImage('assets/image/Technician.png')
            as ImageProvider, // ✅ fallback เป็น asset
          ),
          const SizedBox(width: 10),
          Text(
            tech!.fullName,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const Spacer(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: NotificationBadgeButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildBalance(AsyncValue<WalletSummary> walletAsync) {
    return walletAsync.when(
      data: (wallet) {
        return Column(
          children: [
            Text(
              "ยอดเงินที่ถอนออกได้ (-5%)",
              style: TextStyle(color: AppColors.colorSecondaryText),
            ),
            SizedBox(height: 8),
            Text(
              "฿ ${wallet.withdrawableBalance}",
              style: TextStyle(
                color: AppColors.colorSecondaryText,
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),

            IntrinsicWidth(
              child: PrimaryButton(
                text: "ถอนเงิน",
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => WithdrawPage()));
                },
                borderRadius: 14,
                padding: EdgeInsetsGeometry.symmetric(vertical: 6, horizontal: 32),
              ),
            ),

          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text("Error: $e"),
    );
  }

  // ================= WALLET =================

  Widget _buildWalletHeader() {
    return Row(
      children: [
        const Icon(Icons.account_balance_wallet_outlined),
        const SizedBox(width: 8),
        const Text(
          "กระเป๋าเงินของฉัน",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Spacer(),
        IntrinsicWidth(
          child: PrimaryButton(
            text: "ถอนเงิน",
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => WithdrawPage()));
            },
            borderRadius: 14,
            padding: EdgeInsetsGeometry.symmetric(vertical: 6, horizontal: 32),
          ),
        ),
      ],
    );
  }

  Widget _buildWalletCards(AsyncValue<WalletSummary> walletAsync) {
    return walletAsync.when(
      data: (wallet) {
        return Row(
          children: [
            Expanded(
              child: _walletCard(
                title: "ยอดเงินคงเหลือปัจจุบัน",
                amount: "฿ ${wallet.balance}",
                color1: const Color(0xFF0D47A1),
                color2: const Color(0xFF1565C0),
                backgroundImage: "assets/image/service_card1.png",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _walletCard(
                title: "รายได้สะสมทั้งหมด",
                amount: "฿ ${wallet.totalEarned}",
                color1: const Color(0xFF1565C0),
                color2: const Color(0xFF1E88E5),
                backgroundImage: "assets/image/service_card2.png",
              ),
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text("Error: $e"),
    );
  }

  Widget _walletCard({
    required String title,
    required String amount,
    required Color color1,
    required Color color2,
    String? backgroundImage, // 👈 เพิ่มตรงนี้
  }) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),

        // 🖼️ ใส่รูป background
        image: backgroundImage != null
            ? DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
        )
            : null,

        // 🎨 gradient overlay (ยังใช้ได้)
        gradient: LinearGradient(
          colors: [color1.withOpacity(0.8), color2.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ================= STATS =================

  Widget _buildStatsHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SvgPicture.asset("assets/icons/stat_chart.svg", width: 24),
        SizedBox(width: 4),
        Text(
          "สถิติการทำงาน",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(AsyncValue<WalletSummary> walletAsync) {
    return walletAsync.when(
      data: (wallet) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;

            int crossAxisCount = 2;
            double spacing = 12;

            // คำนวณความกว้างต่อ item
            final itemWidth =
                (width - (spacing * (crossAxisCount - 1))) / crossAxisCount;

            // กำหนดความสูงที่อยากได้ (ปรับได้)
            final itemHeight = 100;

            final aspectRatio = itemWidth / itemHeight;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: aspectRatio,
          children: [
            _statCard(
              "จำนวนงานทั้งหมด",
              "${wallet.totalJobs} งาน",
              Icon(Icons.receipt_long_rounded,
                  color: Color(0xFF5590D4), size: 18),
              Color(0xFF5590D4),
            ),
            _statCard(
              "งานที่สำเร็จ",
              "${wallet.completedJobs} งาน",
              SvgPicture.asset(
                "assets/icons/calendar_check.svg",
                width: 18,
                height: 18,
              ),
              Color(0xFF52C14A),
            ),
            _statCard(
              "งานที่ถูกยกเลิก",
              "${wallet.cancelledJobs} งาน",
              Icon(Icons.close, color: Color(0xFFF5222D), size: 18),
              Color(0xFFF5222D),
            ),
            _statCard(
              "ค่า Rating เฉลี่ย",
              "${wallet.averageRating} /5",
              Icon(Icons.star_outline, color: Color(0xFFFAAD14), size: 18),
              Color(0xFFFAAD14),
            ),
          ],
        );
      },);
            },

      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text("Error: $e"),
    );
  }

  Widget _statCard(String title,
      String value,
      Widget icon, // 👈 เปลี่ยนตรงนี้
      Color color,) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: icon, // 👈 ใช้ตรง ๆ เลย
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 12, color: color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
