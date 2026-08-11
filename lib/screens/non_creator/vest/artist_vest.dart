import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/model/investment_model.dart';
import 'package:soundhive2/model/user_model.dart';
import 'package:soundhive2/screens/non_creator/vest/vest_details.dart';
import 'overview_stage.dart';
import 'portfolio_stage.dart';
import 'project_stage.dart';
import 'opportunity_stage.dart';

/// Rebuilds the Artist -> Investor journey as five sequential stages so
/// trust is built before any money is discussed:
///
///   Overview -> Portfolio -> Project -> Opportunity -> Invest
///
/// Stages 1-4 live here as an internal PageView. Stage 5 ("Invest") is
/// intentionally NOT reimplemented — it hands off to the existing
/// [VestDetailsScreen], which already owns the amount/payment/confirm
/// steps. This screen's only job is to make sure a user can't reach that
/// screen without having scrolled through the artist's story first.
///
/// Only used for isArtistVest == true. General vests keep going straight
/// to VestDetailsScreen, unchanged, since the "build trust first" premise
/// is specific to artist opportunities.
class ArtistVestFlowScreen extends ConsumerStatefulWidget {
  static const String id = '/artistvestflow';
  final Investment investment;
  final User user;

  const ArtistVestFlowScreen({
    super.key,
    required this.investment,
    required this.user,
  });

  @override
  ConsumerState<ArtistVestFlowScreen> createState() => _ArtistVestFlowScreenState();
}

class _ArtistVestFlowScreenState extends ConsumerState<ArtistVestFlowScreen> {
  final PageController _pageController = PageController();
  int _currentStage = 0;

  static const List<String> _stageLabels = [
    'Overview',
    'Portfolio',
    'Project',
    'Opportunity',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentStage < _stageLabels.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _enterInvestFlow();
    }
  }

  void _goBack() {
    if (_currentStage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _enterInvestFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VestDetailsScreen(
          investment: widget.investment,
          user: widget.user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final artistDetails = widget.investment.artistDetails;

    return Scaffold(
      backgroundColor: const Color(0xFF0C051F),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildStageProgress(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // forward via buttons only
                onPageChanged: (index) => setState(() => _currentStage = index),
                children: [
                  OverviewStage(investment: widget.investment),
                  PortfolioStage(investment: widget.investment),
                  ProjectStage(investment: widget.investment),
                  OpportunityStage(investment: widget.investment),
                ],
              ),
            ),
            _buildBottomBar(artistDetails),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            onPressed: _goBack,
          ),
          Expanded(
            child: Text(
              widget.investment.investmentName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40), // balances the back button so title stays centered
        ],
      ),
    );
  }

  Widget _buildStageProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: List.generate(_stageLabels.length, (index) {
          final bool isActive = index == _currentStage;
          final bool isDone = index < _currentStage;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == _stageLabels.length - 1 ? 0 : 6),
              child: Column(
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: isActive || isDone
                          ? Colors.purpleAccent
                          : Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _stageLabels[index],
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white38,
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBottomBar(ArtistDetails? artistDetails) {
    final bool isLastStage = _currentStage == _stageLabels.length - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0C051F),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _goNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4D3490),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          ),
          child: Text(
            isLastStage ? 'Continue to Invest' : 'Next: ${_stageLabels[_currentStage + 1]}',
            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}