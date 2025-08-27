import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:soundhive2/components/success.dart';
import 'package:soundhive2/screens/dashboard/dashboard.dart';

import '../../services/loader_service.dart';
import '../../utils/alert_helper.dart';
import '../creator/creator_dashboard.dart';
import '../onboarding/just_curious.dart';

class UpdateProfile1 extends StatefulWidget {
  static String id = 'update_profile';
  final FlutterSecureStorage storage;
  final Dio dio;
  const UpdateProfile1({super.key, required this.storage, required this.dio});


  @override
  State<UpdateProfile1> createState() => _UpdateProfileState();
}

class _UpdateProfileState extends State<UpdateProfile1> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController dobController = TextEditingController(); // Date of Birth Controller
  final TextEditingController phoneController = TextEditingController();
  List<String> selectedInterests = []; // Added to track interests
  String pin = '';
  String? identity;

  Future<void> loadData() async {
    String? storedIdentity = await widget.storage.read(key: 'role');
    print("🔍 Loaded identity in UpdateProfile: $storedIdentity");

    setState(() {
      identity = storedIdentity;
    });
  }


  @override
  void initState() {
    super.initState();
    loadData();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }



  Future<void> createProfile() async {
    try {
      LoaderService.showLoader(context);
      Map<String, dynamic> payload = {
        "first_name": firstNameController.text,
        "last_name": lastNameController.text,
        "dob": dobController.text,
        "phone_number": phoneController.text,
      };
      final options = Options(headers: {'Accept': 'application/json'});
      final response = await widget.dio.post(
          '/update/profile',
          data: jsonEncode(payload),
          options: options
      );
      print(response);
      if (response.statusCode == 200) {
        LoaderService.hideLoader(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const Success(
                image: 'images/success_profile.png',
                title: 'Account created successfully',
                subtitle: '',
              ),
            ),
          );
          _nextPage();

      }
      else {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Email OTP not verified',
        );
      }
    }
    catch(error) {
      LoaderService.hideLoader(context);
      if (error is DioError) {
        String errorMessage = "Login Failed, Please check input";

        if (error.response != null && error.response!.data != null) {
          Map<String, dynamic> responseData = error.response!.data;
          if (responseData.containsKey('message')) {
            errorMessage = responseData['message'];
          } else if (responseData.containsKey('errors')) {
            Map<String, dynamic> errors = responseData['errors'];
            List<String> errorMessages = [];
            errors.forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                errorMessages.addAll(value.map((error) => "$key: $error"));
              }
            });
            errorMessage = errorMessages.join("\n");
          }
        }
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: errorMessage,
        );
        return;
      }
    }
  }

  Future<void> createPin() async {
    try {
      LoaderService.showLoader(context);
      Map<String, dynamic> payload = {
        "pin": pin,
      };
      final options = Options(headers: {'Accept': 'application/json'});
      final response = await widget.dio.post(
          '/create/pin',
          data: jsonEncode(payload),
          options: options
      );
      print(response);
      if (response.statusCode == 200) {
        LoaderService.hideLoader(context);
        if(identity?.toLowerCase() == "creator") {
          Navigator.pushNamed(context, CreatorDashboard.id);
        }else {
          Navigator.pushNamed(context, JustCurious.id);
        }

      }
      else {
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: 'Email OTP not verified',
        );
      }
    }
    catch(error) {
      LoaderService.hideLoader(context);
      if (error is DioError) {
        String errorMessage = "Login Failed, Please check input";

        if (error.response != null && error.response!.data != null) {
          Map<String, dynamic> responseData = error.response!.data;
          if (responseData.containsKey('message')) {
            errorMessage = responseData['message'];
          } else if (responseData.containsKey('errors')) {
            Map<String, dynamic> errors = responseData['errors'];
            List<String> errorMessages = [];
            errors.forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                errorMessages.addAll(value.map((error) => "$key: $error"));
              }
            });
            errorMessage = errorMessages.join("\n");
          }
        }
        showCustomAlert(
          context: context,
          isSuccess: false,
          title: 'Error',
          message: errorMessage,
        );
        return;
      }
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    dobController.dispose();
    phoneController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("Update $identity");
    return Scaffold(
      backgroundColor: const Color(0xFF0C051F),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 50.0), // Adjust as needed
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('images/logo.png', height: 30),
                    const SizedBox(width: 8),
                    const Text(
                      'Soundhive',
                      style: TextStyle(
                        fontFamily: 'Nohemi',
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Divider(color: Color(0xFF2C2C2C),),

              ],
            ),
          ),
          Expanded( // Ensures PageView takes the remaining space
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                UserDetailsStep(
                  onNext: () {
                    createProfile();
                  },
                  firstNameController: firstNameController,
                  lastNameController: lastNameController,
                  dobController: dobController,
                  phoneController: phoneController,
                ),
                // InterestsStep(
                //     onNext: _nextPage,
                //     onBack: _previousPage,
                //   onInterestsUpdated: (interests) => setState(() => selectedInterests = interests),
                // ),
                PinSetupStep(
                    onBack: _previousPage,
                  onPinUpdated: (newPin) => setState(() => pin = newPin),
                  onSubmit: createPin,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

// Step 1: User Details Form
class UserDetailsStep extends StatelessWidget {
  final VoidCallback onNext;
  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController dobController;
  final TextEditingController phoneController;

  const UserDetailsStep({
    super.key,
    required this.onNext,
    required this.firstNameController,
    required this.lastNameController,
    required this.dobController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Can you tell us more about yourself?",
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            const SizedBox(height: 10),
            const Text(
              "We want to know more about you",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            _buildTextField('First Name', 'Enter your First Name', firstNameController, context),
            const SizedBox(height: 10),
            _buildTextField('Last Name', 'Enter your Last Name', lastNameController, context),
            const SizedBox(height: 10),
            _buildTextField('Date Of Birth', 'Enter your Date of Birth', dobController, context, isDate: true),
            const SizedBox(height: 10),
            _buildTextField('Phone Number', 'Enter your Phone Number', phoneController, context, isPhone: true),
            const SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5B3C98),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, TextEditingController controller,  BuildContext context, {bool isDate = false, bool isPhone = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: isDate,
          keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
          inputFormatters: isPhone ? [FilteringTextInputFormatter.digitsOnly] : [],
          onTap: isDate
              ? () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
            );
            if (pickedDate != null) {
              controller.text = "${pickedDate.toLocal()}".split(' ')[0];
            }
          }
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white10,
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: isDate ? const Icon(Icons.calendar_today, color: Colors.white54) : null,
          ),
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}

// Step 2: Select Interests
class InterestsStep extends StatefulWidget {
  final VoidCallback onNext;
  final VoidCallback onBack;
  final ValueChanged<List<String>> onInterestsUpdated;

  const InterestsStep({
    super.key,
    required this.onNext,
    required this.onBack,
    required this.onInterestsUpdated,
  });

  @override
  _InterestsStepState createState() => _InterestsStepState();
}

class _InterestsStepState extends State<InterestsStep> {
  List<String> interests = [
    "Gospel", "Metal", "Rock", "Hip-Pop", "Reggae",
    "Country", "Classical", "Jazz", "Blues"
  ];
  List<String> selectedInterests = [];

  void toggleInterest(String interest) {
    setState(() {
      selectedInterests.contains(interest)
          ? selectedInterests.remove(interest)
          : selectedInterests.add(interest);
      widget.onInterestsUpdated(selectedInterests);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: widget.onBack,
            child: const Text("Back", style: TextStyle(color: Colors.grey)),
          ),
          const Text("One last thing... What are your interests?",
              style: TextStyle(color: Colors.white, fontSize: 20)),
          const SizedBox(height: 10),
          const Text("Pick at least one",
              style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 8,
            children: interests.map((interest) {
              bool isSelected = selectedInterests.contains(interest);
              return ChoiceChip(
                label: Text(interest),
                selected: isSelected,
                onSelected: (_) => toggleInterest(interest),
                selectedColor: Colors.purple,
                backgroundColor: Color(0xFF0C051F),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey,
                ),
              );
            }).toList(),
          ),
          const Spacer(),
          Center(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: widget.onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5B3C98),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Create account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

        ],
      ),
    );
  }
}

// Step 3: Create PIN
class PinSetupStep extends StatefulWidget {
  final VoidCallback onBack;
  final ValueChanged<String> onPinUpdated;
  final VoidCallback onSubmit;

  const PinSetupStep({
    super.key,
    required this.onBack,
    required this.onPinUpdated,
    required this.onSubmit,
  });

  @override
  _PinSetupStepState createState() => _PinSetupStepState();
}

class _PinSetupStepState extends State<PinSetupStep> {
  String pin = "";

  void _onKeyPressed(String value) {
    setState(() {
      if (value == "X" && pin.isNotEmpty) {
        pin = pin.substring(0, pin.length - 1);
      } else if (pin.length < 4) {
        pin += value;
      }
      widget.onPinUpdated(pin); // Notify parent of PIN changes
      if (pin.length == 4) {
        widget.onSubmit();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C051F),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 50, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "Create Authenticator PIN",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Create a 4-digit PIN to login into the app as well as confirming transactions.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Container(
              width: 155,
              padding: EdgeInsets.all(7.0),
              decoration: BoxDecoration(
                color: Color(0xFF1A191E),
                borderRadius: BorderRadius.circular(10)
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < pin.length ? Colors.white : Colors.grey.shade800,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 40),
            NumericKeyboard(onKeyPressed: _onKeyPressed),
            const SizedBox(height: 20),
            TextButton(
              onPressed: widget.onBack,
              child: const Text("Back", style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      )
    );
  }
}

// Dummy Numeric Keyboard (You can implement it properly)
class NumericKeyboard extends StatelessWidget {
  final Function(String) onKeyPressed;

  const NumericKeyboard({super.key, required this.onKeyPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          for (var row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['0', 'X']
          ])
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((number) {
                return GestureDetector(
                  onTap: () => onKeyPressed(number),
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF1A191E),
                    ),
                    alignment: Alignment.center,
                    child: number == "X"
                        ? const Icon(Icons.backspace, color: Colors.white, size: 24)
                        : Text(
                      number,
                      style: const TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
