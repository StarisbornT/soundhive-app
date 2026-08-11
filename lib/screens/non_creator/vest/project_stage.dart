import 'package:flutter/material.dart';
import 'package:soundhive2/model/investment_model.dart';
import 'package:soundhive2/utils/utils.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Stage 3 — Project: "what's in the works".
///
/// Spec asks for: EP (project), budget (amount to be raised), timeline.
///
/// All fully backed:
///   - project name/type -> investmentName + artistDetails.projectType
///     (SINGLE / EP / ALBUM)
///   - budget             -> artistDetails.fundingTarget
///   - timeline            -> the vest's `duration` (months) plus the real
///     milestone roadmap from `GET /vests/{id}/milestones`
///     (VestMilestone: title, description, status, position, completedAt)
class ProjectStage extends ConsumerWidget {
  final Investment investment;
  const ProjectStage({super.key, required this.investment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistDetails = investment.artistDetails;
    final milestones = [...investment.milestones]..sort((a, b) => a.position.compareTo(b.position));

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The Project',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            investment.investmentName,
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _metricTile(
                  label: 'Project type',
                  value: artistDetails?.projectType.isNotEmpty == true
                      ? artistDetails!.projectType
                      : '—',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  label: 'Stage',
                  value: artistDetails?.projectStage == 'RELEASED' ? 'Released' : 'Pre-release',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricTile(
                  label: 'Budget to raise',
                  value: artistDetails != null
                      ? ref.formatUserCurrency(artistDetails.fundingTarget.toString())
                      : '—',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  label: 'Timeline',
                  value: '${investment.duration} months',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'Roadmap',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Milestones the artist has committed to for this project.',
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
          const SizedBox(height: 12),

          if (milestones.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'No milestones have been set for this project yet.',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            )
          else
            _buildMilestoneTimeline(milestones),
        ],
      ),
    );
  }

  Widget _metricTile({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A102F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneTimeline(List<VestMilestone> milestones) {
    return Column(
      children: List.generate(milestones.length, (index) {
        final m = milestones[index];
        final bool isLast = index == milestones.length - 1;

        Color dotColor;
        IconData? icon;
        if (m.isCompleted) {
          dotColor = Colors.greenAccent;
          icon = Icons.check;
        } else if (m.isInProgress) {
          dotColor = Colors.purpleAccent;
          icon = null;
        } else {
          dotColor = Colors.white24;
          icon = null;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: m.isCompleted ? dotColor : Colors.transparent,
                      border: Border.all(color: dotColor, width: 2),
                    ),
                    child: icon != null
                        ? const Icon(Icons.check, color: Colors.black, size: 14)
                        : null,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.title,
                        style: TextStyle(
                          color: m.isCompleted ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (m.description != null && m.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          m.description!,
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}