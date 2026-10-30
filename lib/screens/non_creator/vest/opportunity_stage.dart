import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soundhive2/model/investment_model.dart';
import 'package:soundhive2/utils/utils.dart';

/// Stage 4 — Opportunity: the funding numbers themselves.
///
/// Spec asks for: funding target, progress bar, minimum investment,
/// revenue split, forecasting, risk rating. All backed by real fields:
///   - funding target / progress -> artistDetails.fundingTarget,
///     .totalRaised, .fundingProgressPercentage (backend-computed)
///   - minimum investment         -> investment.minimumAmount
///   - investor / artist return    -> revenueSplitInvestor / revenueSplitArtist,
///     labelled "(In Perpetuity after Payback)" when returnTimeline says so
///   - payback period              -> artistDetails.paybackPeriodMonths
///   - forecasting                 -> targetRoiMin / targetRoiMax ("500%")
///   - risk rating                  -> artistDetails.riskLevel (LOW/MEDIUM/HIGH),
///     with investment.riskAssessment as the free-text explanation
///
/// All amounts are Naira (Utils.formatNaira), independent of wallet currency.
class OpportunityStage extends ConsumerWidget {
  final Investment investment;
  const OpportunityStage({super.key, required this.investment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artistDetails = investment.artistDetails;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'The Opportunity',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "Here's exactly what backing this project looks like.",
            style: TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(height: 20),

          if (artistDetails != null) _buildFundingProgress(ref, artistDetails),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _metricTile(
                  label: 'Minimum investment',
                  value: Utils.formatNaira(investment.minimumAmountValue),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  label: 'Forecasted return',
                  value: artistDetails != null
                      ? artistDetails.forecastedReturnLabel
                      : '—',
                ),
              ),
            ],
          ),
          if (artistDetails?.hasPaybackPeriod ?? false) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _metricTile(
                    label: 'Payback Period',
                    value: artistDetails!.paybackLabel,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ],
          const SizedBox(height: 10),

          if (artistDetails != null) _buildRevenueSplit(artistDetails),
          const SizedBox(height: 10),

          if (artistDetails != null) _buildRiskCard(artistDetails, investment.riskAssessment),

          if (artistDetails?.revenueStreamTags.isNotEmpty == true) ...[
            const SizedBox(height: 20),
            const Text(
              'Revenue streams',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: artistDetails!.revenueStreamTags.map((tag) => _buildTagChip(tag)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFundingProgress(WidgetRef ref, ArtistDetails artistDetails) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A102F),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Raised: ${Utils.formatNaira(artistDetails.totalRaised)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Target: ${Utils.formatNaira(artistDetails.fundingTarget)}',
                  style: const TextStyle(color: Colors.purpleAccent, fontSize: 12),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: artistDetails.fundingProgress,
              backgroundColor: Colors.white10,
              color: Colors.purpleAccent,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${artistDetails.fundingProgressPercentage.toStringAsFixed(0)}% funded',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueSplit(ArtistDetails artistDetails) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
            child: _splitMetric(
              'Investor Return',
              '${artistDetails.revenueSplitInvestor.toStringAsFixed(0)}%',
              note: artistDetails.isPerpetual
                  ? (artistDetails.hasPaybackPeriod
                      ? '(In Perpetuity after Payback)'
                      : '(In Perpetuity)')
                  : null,
            ),
          ),
          Container(width: 1, height: 36, color: Colors.white10),
          Expanded(
            child: _splitMetric('Artist Return', '${artistDetails.revenueSplitArtist.toStringAsFixed(0)}%'),
          ),
        ],
      ),
    );
  }

  Widget _splitMetric(String label, String value, {String? note}) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.purpleAccent, fontSize: 16, fontWeight: FontWeight.bold)),
        if (note != null) ...[
          const SizedBox(height: 2),
          Text(
            note,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
        ],
      ],
    );
  }

  Widget _buildRiskCard(ArtistDetails artistDetails, String riskAssessment) {
    Color riskColor;
    switch (artistDetails.riskLevel.toUpperCase()) {
      case 'LOW':
        riskColor = Colors.greenAccent;
        break;
      case 'MEDIUM':
        riskColor = Colors.orangeAccent;
        break;
      default:
        riskColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A102F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: riskColor.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, color: riskColor, size: 16),
              const SizedBox(width: 8),
              Text(
                '${artistDetails.riskLevel.toUpperCase()} RISK',
                style: TextStyle(color: riskColor, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (riskAssessment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              riskAssessment,
              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        tag.replaceAll('_', ' '),
        style: const TextStyle(color: Colors.white70, fontSize: 11),
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
}