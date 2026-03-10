import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/module/auth/setup_address.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../state/master_data_provider.dart';

class TechnicianStartPage extends ConsumerStatefulWidget {
  final String email;

  const TechnicianStartPage({super.key, required this.email});

  @override
  ConsumerState<TechnicianStartPage> createState() =>
      _TechnicianRegisterPageState();
}

class _TechnicianRegisterPageState extends ConsumerState<TechnicianStartPage> {
  void _showTermsDialog() {
    bool acceptTerms = false;
    bool acceptPrivacy = false;
    bool showScrollButton = true;

    final ScrollController scrollController = ScrollController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!scrollController.hasListeners) {
                scrollController.addListener(() {
                  final isBottom =
                      scrollController.offset >=
                      scrollController.position.maxScrollExtent - 20;

                  if (showScrollButton == isBottom) {
                    setState(() {
                      showScrollButton = !isBottom;
                    });
                  }
                });
              }
            });

            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              insetPadding: EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.60,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.primaryText,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 50, 24, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          /// header + close
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "ข้อกำหนดและเงื่อนไขการใช้บริการ",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "ChangSure – ช่างชัวร์",
                                style: TextStyle(fontSize: 14),
                              ),
                              Text(
                                "อัปเดตล่าสุด 21 ธ.ค. 25",
                                style: TextStyle(
                                  color: AppColors.colorTertiaryText,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          /// content scroll
                          Expanded(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("""
1. ผู้สมัครต้องมีอายุไม่ต่ำกว่า 18 ปี
ผู้สมัครจะต้องมีอายุครบตามเกณฑ์ที่กำหนดและสามารถปฏิบัติงานได้ตามมาตรฐานของระบบ

2. การให้ข้อมูลที่ถูกต้อง
ผู้สมัครต้องให้ข้อมูลที่ถูกต้องครบถ้วน เช่น ชื่อ ที่อยู่ เบอร์โทรศัพท์ และข้อมูลการติดต่ออื่น ๆ

3. การรักษามาตรฐานการให้บริการ
ช่างที่เข้าร่วมระบบต้องปฏิบัติงานอย่างมืออาชีพ มีความสุภาพ และให้บริการอย่างมีคุณภาพแก่ลูกค้า

4. ความรับผิดชอบต่ออุปกรณ์และทรัพย์สิน
ผู้ให้บริการต้องดูแลอุปกรณ์ของลูกค้าอย่างเหมาะสม

5. การปฏิบัติตามกฎหมาย
ผู้ให้บริการต้องปฏิบัติตามกฎหมายที่เกี่ยวข้อง

6. การระงับบัญชี
ระบบมีสิทธิ์ระงับบัญชีผู้ใช้งานหากพบว่ามีการละเมิดข้อกำหนด

----------------------------------------------------

Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.

Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
Lorem ipsum dolor sit amet, consectetur adipiscing elit.
""", style: TextStyle(fontSize: 14, height: 1.6)),
                                  const SizedBox(height: 24),

                                  /// checkbox terms
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: acceptTerms,
                                            checkColor: Colors.white,
                                            fillColor:
                                                MaterialStateProperty.resolveWith<
                                                  Color
                                                >((states) {
                                                  if (states.contains(
                                                    MaterialState.selected,
                                                  )) {
                                                    return const Color(
                                                      0xFF3071C7,
                                                    );
                                                  }
                                                  return Colors.white;
                                                }),
                                            side: const BorderSide(
                                              color: AppColors.primaryBorder,
                                              width: 1.5,
                                            ),
                                            onChanged: (v) {
                                              setState(() {
                                                acceptTerms = v ?? false;
                                              });
                                            },
                                          ),
                                          const Expanded(
                                            child: Text(
                                              "ยอมรับเงื่อนไขการใช้บริการ",
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(
                                          left: 50,
                                          right: 8,
                                        ),
                                        child: Text(
                                          "ฉันได้อ่านและยอมรับข้อกำหนดและเงื่อนไขการใช้บริการของแอปช่างชัวร์แล้ว "
                                          "รวมถึงกฎการใช้งานแพลตฟอร์มการจองบริการ การชำระเงิน "
                                          "นโยบายการยกเลิกและมาตรการกรณีฝ่าฝืนข้อกำหนด "
                                          "เช่นการนัดหมายหรือชำระเงินนอกระบบ",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.colorTertiaryText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 12),

                                  /// checkbox privacy
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            value: acceptPrivacy,
                                            checkColor: Colors.white,
                                            fillColor:
                                                MaterialStateProperty.resolveWith<
                                                  Color
                                                >((states) {
                                                  if (states.contains(
                                                    MaterialState.selected,
                                                  )) {
                                                    return const Color(
                                                      0xFF3071C7,
                                                    );
                                                  }
                                                  return Colors.white;
                                                }),
                                            side: const BorderSide(
                                              color: AppColors.primaryBorder,
                                              width: 1.5,
                                            ),
                                            onChanged: (v) {
                                              setState(() {
                                                acceptPrivacy = v ?? false;
                                              });
                                            },
                                          ),
                                          const Expanded(
                                            child: Text(
                                              "อนุญาตให้ใช้ข้อมูลส่วนบุคคล",
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Padding(
                                        padding: EdgeInsets.only(
                                          left: 50,
                                          right: 8,
                                        ),
                                        child: Text(
                                          "ฉันยินยอมให้แอปช่างชัวร์เก็บรวบรวม ใช้และประมวลผลข้อมูลส่วนบุคคลของฉัน",
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: AppColors.colorTertiaryText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 40),

                                  /// primary button
                                  PrimaryButton(
                                    text: "ยืนยัน",
                                    onPressed: (acceptTerms && acceptPrivacy)
                                        ? () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    SetupAddress(
                                                      onSave: (data) async {
                                                        final result = await ref
                                                            .read(
                                                              addressProvider
                                                                  .notifier,
                                                            )
                                                            .createTechnicianAddress(
                                                              data,
                                                            );
                                                        return result;
                                                      },
                                                    ),
                                              ),
                                            );
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// ปุ่ม scroll ลงล่างสุด
                    if (showScrollButton)
                      Positioned(
                        right: 16,
                        bottom: 50,
                        child: GestureDetector(
                          onTap: () {
                            scrollController.animateTo(
                              scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                            );
                          },
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_downward,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003EB3),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            /// วงกลมสีขาวด้านล่าง
            Positioned(
              bottom: -850,
              left: -100,
              right: -100,
              child: Container(
                height: 2000,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),

            /// Content หลัก
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "ลงทะเบียนเป็นช่าง",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "ง่ายนิดเดียว เริ่มเลย !",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Image.asset(
                    "assets/image/Logo_ChangSure_Transparents.PNG",
                    width: 300,
                  ),
                  const SizedBox(height: 32),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: PrimaryButton(
                      text: "เริ่มลงทะเบียน",
                      onPressed: () {
                        _showTermsDialog();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
