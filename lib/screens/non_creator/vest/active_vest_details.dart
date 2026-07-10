import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:soundhive2/model/get_active_vest_model.dart';
import 'package:soundhive2/utils/utils.dart';
import 'package:soundhive2/lib/dashboard_provider/get_investment_statistics.dart';
import '../../../model/investment_statistics_model.dart';

class ActiveVestDetailsScreen extends ConsumerStatefulWidget {
  final ActiveVest investment;
  const ActiveVestDetailsScreen({super.key, required this.investment});

  @override
  ConsumerState<ActiveVestDetailsScreen> createState() => _VestDetailsScreenState();
}

class _VestDetailsScreenState extends ConsumerState<ActiveVestDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(getInvestmentStatisticsProvider.notifier).getBreakDown(widget.investment.id);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final investment = widget.investment;
    final statisticsState = ref.watch(getInvestmentStatisticsProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              investment.vest?.investmentName ?? "Investment View",
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: const Color(0xFF4D3490),
                    margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text("Capital Invested", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            ref.formatUserCurrency(investment.amount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Roboto',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "About this Vest"),
                Tab(text: "Portfolio & Earnings"),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.purpleAccent,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAboutTab(investment, statisticsState),
                  _buildPortfolioTab(investment, statisticsState),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutTab(ActiveVest investment, AsyncValue<InvestmentStatisticsModel> statisticsState) {
    final vestNode = investment.vest;
    final bool isArtist = vestNode?.artistDetails != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildInfoCard("Project Title", vestNode?.investmentName ?? ''),
                _buildInfoCard("Principal", ref.formatUserCurrency(investment.amount)),
                _buildInfoCard("Maturity Timeline", investment.maturityDate),
                _buildInfoCard("Contract ROI", "${vestNode?.roi}%"),
                _buildInfoCard("Expected Payout", ref.formatUserCurrency(investment.expectedRepayment)),

                if (isArtist) ...[
                  _buildInfoCard("Project Stage", vestNode!.artistDetails!.projectStage, valueColor: Colors.purpleAccent),
                  _buildInfoCard("Investor Revenue Split", "${vestNode.artistDetails!.revenueSplitInvestor.toStringAsFixed(0)}%"),
                ],

                _buildInfoCard("Status", vestNode?.status ?? 'ACTIVE', valueColor: Colors.green),

                statisticsState.when(
                  data: (stats) => Column(
                    children: [
                      const Divider(color: Colors.white10),
                      _buildInfoCard("ROI Accrued So Far", ref.formatUserCurrency(stats.data.performanceMetrics.roiSoFar.toString())),
                      _buildInfoCard("Current Assets Value", ref.formatUserCurrency(stats.data.performanceMetrics.currentValue.toString())),
                      _buildInfoCard("Time to Maturity", stats.data.timeMetrics.timeToMaturityHuman),
                    ],
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "Description Blueprint",
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            vestNode?.description ?? "No details disclosed.",
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioTab(ActiveVest investment, AsyncValue<InvestmentStatisticsModel> statisticsState) {
    return statisticsState.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(child: _buildMetricCard("ROI So Far", ref.formatUserCurrency(stats.data.performanceMetrics.roiSoFar.toString()), Colors.greenAccent)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard("Current Value", ref.formatUserCurrency(stats.data.performanceMetrics.currentValue.toString()), Colors.cyanAccent)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildMetricCard("Progress Yield", "${stats.data.performanceMetrics.progressPercentage.toStringAsFixed(1)}%", Colors.purpleAccent)),
                const SizedBox(width: 8),
                Expanded(child: _buildMetricCard("Remaining", stats.data.timeMetrics.timeToMaturityHuman, Colors.orangeAccent)),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              height: 220,
              padding: const EdgeInsets.only(right: 16, top: 16),
              decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(10)),
              child: _VestChart(
                investmentData: stats.data,
                initialAmount: double.tryParse(investment.amount) ?? 0.0,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Performance Summary Ledger", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  _buildEarningsRow("Total Asset Investment", ref.formatUserCurrency(stats.data.investmentDetails.investedAmount.toString())),
                  const Divider(color: Colors.white10, height: 1),
                  _buildEarningsRow("ROI Earned", ref.formatUserCurrency(stats.data.performanceMetrics.roiSoFar.toString()), isGreen: true),
                  _buildEarningsRow("Total Maturity Target Return", ref.formatUserCurrency(stats.data.investmentDetails.expectedRepayment.toString())),
                  _buildEarningsRow("Days Active", "${stats.data.performanceMetrics.daysSinceInvestment} Days"),
                ],
              ),
            )
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text("Error metrics execution: $error", style: const TextStyle(color: Colors.white))),
    );
  }

  Widget _buildMetricCard(String title, String value, Color valueColor) {
    return Card(
      color: Colors.grey.shade900,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(color: valueColor, fontSize: 15, fontWeight: FontWeight.bold, fontFamily: 'Roboto'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: TextStyle(color: valueColor ?? Colors.white, fontSize: 13, fontFamily: 'Roboto')),
        ],
      ),
    );
  }

  Widget _buildEarningsRow(String label, String value, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(
            value,
            style: TextStyle(color: isGreen ? Colors.greenAccent : Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Roboto', fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _VestChart extends StatelessWidget {
  final InvestmentData investmentData;
  final double initialAmount;

  const _VestChart({required this.investmentData, required this.initialAmount});

  @override
  Widget build(BuildContext context) {
    final spots = _generateChartData();
    return LineChart(_mainData(spots));
  }

  List<FlSpot> _generateChartData() {
    final totalDays = investmentData.performanceMetrics.totalInvestmentDays;
    final currentDays = investmentData.performanceMetrics.daysSinceInvestment;
    final finalValue = investmentData.investmentDetails.expectedRepayment;

    final spots = <FlSpot>[];
    spots.add(FlSpot(0, initialAmount));

    if (totalDays > 0 && currentDays > 0) {
      final progress = currentDays / totalDays;
      final currentValue = initialAmount + (investmentData.performanceMetrics.roiSoFar);
      spots.add(FlSpot(progress * 10, currentValue));
    }
    spots.add(FlSpot(10, finalValue));
    return spots;
  }

  LineChartData _mainData(List<FlSpot> spots) {
    final maxY = investmentData.investmentDetails.expectedRepayment * 1.15;
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (value) => const FlLine(color: Colors.white10, strokeWidth: 1),
      ),
      titlesData: const FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false) // Handled implicitly via cards to save design layout width
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 10,
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.purpleAccent,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: true),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [Colors.purple.withOpacity(0.2), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}