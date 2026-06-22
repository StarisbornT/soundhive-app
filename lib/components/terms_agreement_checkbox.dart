import 'package:flutter/material.dart';
import 'package:soundhive2/screens/dashboard/verification_webview.dart';
import 'package:soundhive2/utils/app_colors.dart';

class LegalUrls {
  static const termsAndPrivacy =
      'https://thecre8hiveapp.com/page/privacy-policy/';
}

class TermsAgreementCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const TermsAgreementCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  void _openTerms(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const VerificationWebView(
          url: LegalUrls.termsAndPrivacy,
          title: 'Terms & Conditions',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const linkStyle = TextStyle(
      color: AppColors.PRIMARYCOLOR,
      fontSize: 13,
      decoration: TextDecoration.underline,
      height: 1.4,
    );
    const bodyStyle = TextStyle(
      color: Colors.white70,
      fontSize: 13,
      height: 1.4,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: value,
            onChanged: (checked) => onChanged(checked ?? false),
            activeColor: AppColors.PRIMARYCOLOR,
            side: const BorderSide(color: Colors.white54),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('I agree to the ', style: bodyStyle),
                GestureDetector(
                  onTap: () => _openTerms(context),
                  child: const Text('Terms & Conditions', style: linkStyle),
                ),
                const Text(' and ', style: bodyStyle),
                GestureDetector(
                  onTap: () => _openTerms(context),
                  child: const Text('Privacy Policy', style: linkStyle),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
