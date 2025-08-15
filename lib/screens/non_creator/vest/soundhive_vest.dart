import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_colors.dart';

class SoundhiveVest extends ConsumerStatefulWidget {
  const SoundhiveVest({super.key});

  @override
  _SoundhiveVestState createState() => _SoundhiveVestState();
}

class _SoundhiveVestState extends ConsumerState<SoundhiveVest> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.BACKGROUNDCOLOR,
      body: Center(
        child: Text(
          'Coming Soon',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}