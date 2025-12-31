import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/screens/auth/create_account.dart';
import 'package:soundhive2/utils/app_colors.dart';
import '../../components/rounded_button.dart';
import '../../utils/utils.dart';
import 'creator_identity.dart';


class IdentityScreen extends StatefulWidget {
  final FlutterSecureStorage storage;
  const IdentityScreen({super.key, required this.storage});
  static String id = 'identity_screen';

  @override
  State<IdentityScreen> createState() => _IdentityScreenState();
}

class _IdentityScreenState extends State<IdentityScreen> {
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
                "What best describes you?",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Creator Option
              GestureDetector(
                onTap: () => _selectIdentity("creator"),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedIdentity == "creator"
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
                              "Creator",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "I want to provide creative services",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: "creator",
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
                onTap: () => _selectIdentity("not_creator"),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: selectedIdentity == "not_creator"
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
                              "Not a creator",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Looking to explore soundhive, hire creatives,\ninvest and stream songs by favourite artists.",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: "not_creator",
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
                  await widget.storage.write(key: 'identity', value: selectedIdentity);
                  await widget.storage.write(key: 'identityUpdate', value: selectedIdentity);
                  print("Selected: $selectedIdentity");
                  if(selectedIdentity == "creator") {
                    Navigator.pushNamed(context, CreatorIdentityScreen.id);
                  }else {
                    Navigator.pushNamed(context, CreateAccount.id);
                  }

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
