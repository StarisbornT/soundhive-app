import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/lib/dashboard_provider/creatorProvider.dart';
import 'package:soundhive2/lib/provider.dart';
import '../../../model/creator_model.dart';
import '../screens/auth/login.dart';
import '../screens/non_creator/marketplace/creator.dart';

class CreatorProfileLoader extends ConsumerStatefulWidget {
  final int creatorId;

  const CreatorProfileLoader({super.key, required this.creatorId});

  @override
  ConsumerState<CreatorProfileLoader> createState() =>
      _CreatorProfileLoaderState();
}

class _CreatorProfileLoaderState extends ConsumerState<CreatorProfileLoader> {
  CreatorData? _creator;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchCreator());
  }

  Future<void> _fetchCreator() async {
    try {
      final creator = await ref
          .read(creatorProvider.notifier)
          .getCreatorById(widget.creatorId);
      if (mounted) {
        setState(() {
          _creator = creator;
          _loading = false;
        });
      }
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        _redirectToLogin();
        return;
      }
      if (mounted) {
        setState(() {
          _error = 'Could not load this profile';
          _loading = false;
        });
      }
    }
  }

  void _redirectToLogin() {
    if (!mounted) return;
    final dio = ref.read(dioProvider);
    final storage = ref.read(storageProvider);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => Login(
          dio: dio,
          storage: storage,
          redirectCreatorId: widget.creatorId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _creator == null) {
      return Scaffold(
        body: Center(child: Text(_error ?? 'Something went wrong')),
      );
    }
    return CreatorProfile(creator: _creator!);
  }
}