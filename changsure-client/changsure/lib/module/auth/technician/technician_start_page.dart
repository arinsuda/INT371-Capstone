import 'package:changsure/core/button/primary_button.dart';
import 'package:changsure/module/auth/setup_address.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../data/models/master_data_models.dart';
import '../../../data/models/users/users_model.dart';
import '../../../state/master_data_provider.dart';
import '../../../state/user_provider.dart';

class TechnicianStartPage extends ConsumerStatefulWidget {
  final String email;

  const TechnicianStartPage({super.key, required this.email});

  @override
  ConsumerState<TechnicianStartPage> createState() =>
      _TechnicianRegisterPageState();
}

class _TechnicianRegisterPageState extends ConsumerState<TechnicianStartPage> {
  void _showTermsDialog(DocumentTermResponse doc, UserModel user) {
    bool acceptTerms = false;
    bool acceptPrivacy = false;
    bool showScrollButton = true;

    final ScrollController scrollController = ScrollController();

    final termsConsent = doc.content.consents.firstWhere(
      (e) => e.key == "accept_terms",
    );

    final privacyConsent = doc.content.consents.firstWhere(
      (e) => e.key == "accept_privacy",
    );
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
                                "อัปเดตล่าสุด ${doc.updatedAt.day}/${doc.updatedAt.month}/${doc.updatedAt.year}",
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
                                  Text(
                                    doc.content.body,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      height: 1.6,
                                    ),
                                  ),
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
                                          Expanded(
                                            child: Text(termsConsent.label),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: 50,
                                          right: 8,
                                        ),
                                        child: Text(
                                          termsConsent.description,
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
                                          Expanded(
                                            child: Text(privacyConsent.label),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left: 50,
                                          right: 8,
                                        ),
                                        child: Text(
                                          privacyConsent.description,
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
                                        ? () async {
                                            final consents = <String>[];

                                            if (acceptTerms) {
                                              consents.add(termsConsent.key);
                                            }

                                            if (acceptPrivacy) {
                                              consents.add(privacyConsent.key);
                                            }
                                            try {
                                              final request =
                                                  DocumentAcceptanceRequest(
                                                    userId: user.id,
                                                    role: "technician",
                                                    consents: consents,
                                                  );

                                              final result = await ref.read(
                                                documentAcceptanceProvider(
                                                  request,
                                                ).future,
                                              );

                                              print(result);

                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => SetupAddress(
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
                                            } catch (e, st) {
                                              debugPrint(
                                                "❌ ACCEPT DOCUMENT ERROR: $e",
                                              );
                                              debugPrint("❌ STACKTRACE: $st");

                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    "ยอมรับเงื่อนไขไม่สำเร็จ: $e",
                                                  ),
                                                ),
                                              );
                                            }
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
    final user = ref.read(userProvider);
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
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: PrimaryButton(
                      text: "เริ่มลงทะเบียน",
                      onPressed: () async {
                        print("🔥 CLICK REGISTER");
                        try {
                          final doc = await ref.read(documentProvider.future);

                          if (user == null) return;
                          _showTermsDialog(doc, user);
                        } catch (e, st) {
                          print("❌ Document Error: $e");
                          print("❌ StackTrace: $st");

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("โหลดข้อกำหนดไม่สำเร็จ"),
                            ),
                          );
                        }
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
