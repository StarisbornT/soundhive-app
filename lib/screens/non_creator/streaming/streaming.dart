import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../utils/app_colors.dart';

class Streaming extends ConsumerStatefulWidget {
  const Streaming({super.key});

  @override
  _StreamingState createState() => _StreamingState();
}

class _StreamingState extends ConsumerState<Streaming> {
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