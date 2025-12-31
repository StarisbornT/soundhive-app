import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/components/rounded_button.dart';
import 'package:soundhive2/screens/non_creator/streaming/streaming.dart';
import 'package:soundhive2/utils/app_colors.dart';

import '../../../lib/dashboard_provider/apiresponseprovider.dart';
import '../../../lib/dashboard_provider/user_provider.dart';
import '../../../model/apiresponse_model.dart';
import '../../../utils/alert_helper.dart';

class PreferenceScreen extends ConsumerStatefulWidget {
  const PreferenceScreen({super.key});

  @override
  _PreferenceScreenState createState() => _PreferenceScreenState();
}

class _PreferenceScreenState extends ConsumerState<PreferenceScreen> {
  void saveData() async {

    try {
      final payload = {
        "interests": selectedInterests,
      };

      final response = await ref.read(apiresponseProvider.notifier).updateInterest(
        context: context,
        payload: payload,
      );


        await ref.read(userProvider.notifier).loadUserProfile();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const Streaming(
            ),
          ),
        );



    } catch (error) {
      String errorMessage = 'An unexpected error occurred';

      print("Raw error: $error");

      if (error is DioException) {
        print("Dio error: ${error.response?.data}");
        print("Status code: ${error.response?.statusCode}");

        if (error.response?.data != null) {
          try {
            final apiResponse = ApiResponseModel.fromJson(error.response?.data);
            errorMessage = apiResponse.message;
          } catch (e) {
            errorMessage = 'Failed to parse error message';
          }
        } else {
          errorMessage = error.message ?? 'Network error occurred';
        }
      }

      showCustomAlert(
        context: context,
        isSuccess: false,
        title: 'Error',
        message: errorMessage,
      );
    }
  }
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
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:  Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("We would love to know more about your taste. ",
                style: TextStyle(color: Colors.white, fontSize: 20)),
            const SizedBox(height: 10),
            const Text("We want to recommend your preferred songs to help you get started.",
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
                  selectedColor: AppColors.PRIMARYCOLOR,
                  backgroundColor: const Color(0xFF0C051F),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            Center(
              child: RoundedButton(
                  title: 'Personalise my experience', onPressed: saveData),
            ),
            const SizedBox(height: 10),

          ],
        ),
      ),
    );
  }
}