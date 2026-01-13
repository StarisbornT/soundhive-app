import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/screens/auth/create_account.dart';
import 'package:soundhive2/utils/app_colors.dart';

import '../../components/rounded_button.dart';
import '../../utils/utils.dart';

class CreatorIdentityScreen extends StatefulWidget {
  final FlutterSecureStorage storage;
  const CreatorIdentityScreen({super.key, required this.storage});
  static String id = 'creator_identity';

  @override
  State<CreatorIdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<CreatorIdentityScreen> {
  String? selectedIdentity;
  String? selectedIdentityUpdate;

  void _selectIdentity(String identity) {
    setState(() {
      selectedIdentity = identity;
      selectedIdentityUpdate = identity;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo
              Utils.logo(),
              const SizedBox(height: 40),
              const Text(
                "Do you provide your creative services as an individual or a Business?",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Creator Option
              GestureDetector(
                onTap: () => _selectIdentity("individual"),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedIdentity == "individual"
                          ? Color(0xFF2C2C2C)
                          : Colors.white24,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Individual",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "I work as a solo creative",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: "individual",
                        groupValue: selectedIdentity,
                        onChanged: (value) => _selectIdentity(value!),
                        activeColor: AppColors.WHITECOLOR,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Not a Creator Option
              GestureDetector(
                onTap: () => _selectIdentity("business"),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedIdentity == "business"
                          ? const Color(0xFF2C2C2C)
                          : Colors.white24,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Business",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "I have a business that provides creative services.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: "business",
                        groupValue: selectedIdentity,
                        onChanged: (value) => _selectIdentity(value!),
                        activeColor: AppColors.WHITECOLOR,
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),
              RoundedButton(
                title: 'Contiue',
                onPressed: selectedIdentity != null ? () async {
                  await widget.storage.write(key: 'creator_identity', value: selectedIdentity);
                  print("Selected: $selectedIdentity");
                  Navigator.pushNamed(context, CreateAccount.id);
                } : null,
                color: selectedIdentity != null ? AppColors.PRIMARYCOLOR : AppColors.INACTIVEBUTTONCOLOR,
                borderWidth: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
