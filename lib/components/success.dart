import 'package:flutter/material.dart';
import 'package:soundhive2/components/rounded_button.dart';

class Success extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? navigation;
  final String? image;
  final VoidCallback? onButtonPressed;

  const Success({
    required this.title,
    required this.subtitle,
    this.navigation,
    this.image,
    super.key,
    this.onButtonPressed
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: const Color(0xFF0C051F),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              if(image != null)
              Image.asset(image ?? 'images/success_profile.png'),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 23,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.all(10),
                child: RoundedButton(
                  title: 'Continue',
                  color: Color(0xFF4D3490),
                  borderRadius: 100,
                  borderWidth: 0,
                  onPressed: () {
                    if (navigation != null && navigation!.isNotEmpty) {
                      Navigator.pushNamed(context, navigation!);
                    } else if(onButtonPressed != null) {
                      onButtonPressed!();
                      }else {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
