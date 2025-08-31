import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:soundhive2/model/get_active_vest_model.dart';
import 'package:soundhive2/utils/alert_helper.dart';
import 'package:soundhive2/utils/utils.dart';
import '../../../components/rounded_button.dart';
import '../../../lib/dashboard_provider/get_investment_statistics.dart';
import '../../../model/active_investment_model.dart';
import 'package:intl/intl.dart';

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
            // Investment name
            Text(
              investment.vest!.investmentName,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),

            // Capital card
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: const Color(0xFF4D3490),
                    margin: const EdgeInsets.all(12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text("Capital", style: TextStyle(color: Colors.white70)),
                          Text(
                            Utils.formatCurrency(investment.amount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
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

            // Tabs
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: "About this vest"),
                Tab(text: "Portfolio and earnings"),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white60,
              indicatorColor: Colors.white,
            ),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: About this vest
                  _buildAboutTab(investment, statisticsState),

                  // Tab 2: Portfolio and earnings
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _buildInfoCard("Project", investment.vest!.investmentName),
                _buildInfoCard("Amount", Utils.formatCurrency(investment.amount)),
                _buildInfoCard("Maturity date", investment.maturityDate),
                _buildInfoCard("Interest", "${investment.vest?.roi}%"),
                _buildInfoCard("Expected repayment", Utils.formatCurrency(investment.expectedRepayment)),
                _buildInfoCard("Status", investment.vest!.status, valueColor: Colors.green),

                // Additional statistics from API
                statisticsState.when(
                  data: (stats) => Column(
                    children: [
                      _buildInfoCard("ROI so far", Utils.formatCurrency(stats.data.performanceMetrics.roiSoFar)),
                      _buildInfoCard("Current value", Utils.formatCurrency(stats.data.performanceMetrics.currentValue)),
                      _buildInfoCard("Progress", "${stats.data.performanceMetrics.progressPercentage.toStringAsFixed(1)}%"),
                      _buildInfoCard("Time to maturity", stats.data.timeMetrics.timeToMaturityHuman),
                    ],
                  ),
                  loading: () => const CircularProgressIndicator(),
                  error: (error, stack) => _buildInfoCard("Status", "Error loading stats"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              "About Investment",
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            investment.vest!.description,
            style: const TextStyle(color: Colors.white70),
          ),
          
        ],
      ),
    );
  }

  Widget _buildPortfolioTab(ActiveVest investment, AsyncValue<InvestmentStatisticsModel> statisticsState) {
    return statisticsState.when(
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Performance summary cards
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    "ROI So Far",
                    Utils.formatCurrency(stats.data.performanceMetrics.roiSoFar),
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    "Current Value",
                    Utils.formatCurrency(stats.data.performanceMetrics.currentValue),
                    Colors.cyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    "Progress",
                    "${stats.data.performanceMetrics.progressPercentage.toStringAsFixed(1)}%",
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    "Time Left",
                    stats.data.timeMetrics.timeToMaturityHuman,
                    stats.data.timeMetrics.timeToMaturityDays > 30
                        ? Colors.blue
                        : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // The custom graph container
            Container(
              height: 250,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(10),
              ),
              child: _VestChart(
                investmentData: stats.data,
                initialAmount: double.parse(investment.amount),
              ),
            ),
            const SizedBox(height: 20),

            // The Earnings list section
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Performance Summary",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  _buildEarningsRow("Total Invested", Utils.formatCurrency(stats.data.investmentDetails.investedAmount)),
                  const Divider(color: Colors.white24),
                  _buildEarningsRow("ROI Earned", Utils.formatCurrency(stats.data.performanceMetrics.roiSoFar), isGreen: true),
                  _buildEarningsRow("Expected Total ROI", Utils.formatCurrency(stats.data.performanceMetrics.totalExpectedRoi)),
                  _buildEarningsRow("Current Value", Utils.formatCurrency(stats.data.performanceMetrics.currentValue), isGreen: true),
                  _buildEarningsRow("Days Invested", "${stats.data.performanceMetrics.daysSinceInvestment} days"),
                  _buildEarningsRow("Total Duration", "${stats.data.performanceMetrics.totalInvestmentDays} days"),
                ],
              ),
            )
          ],
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text(
          "Error loading statistics: $error",
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, Color valueColor) {
    return Card(
      color: Colors.grey.shade800,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: TextStyle(color: valueColor ?? Colors.white)),
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
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: TextStyle(
              color: isGreen ? Colors.greenAccent : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _VestChart extends StatelessWidget {
  final InvestmentData investmentData;
  final double initialAmount;

  const _VestChart({
    super.key,
    required this.investmentData,
    required this.initialAmount,
  });

  @override
  Widget build(BuildContext context) {
    // Generate chart data based on investment progress
    final spots = _generateChartData();

    return AspectRatio(
      aspectRatio: 1.70,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: LineChart(
          _mainData(spots),
        ),
      ),
    );
  }

  List<FlSpot> _generateChartData() {
    final totalDays = investmentData.performanceMetrics.totalInvestmentDays;
    final currentDays = investmentData.performanceMetrics.daysSinceInvestment;
    final initial = initialAmount;
    final finalValue = investmentData.investmentDetails.expectedRepayment;

    // Generate points for the chart
    final spots = <FlSpot>[];

    // Start at day 0 with initial amount
    spots.add(FlSpot(0, initial));

    // Add intermediate points based on progress
    if (totalDays > 0 && currentDays > 0) {
      final progress = currentDays / totalDays;
      final currentValue = initial + (investmentData.performanceMetrics.roiSoFar);

      // Add current progress point
      spots.add(FlSpot(progress * 10, currentValue));

      // Add a few more points for the curve
      for (double i = 0.2; i < 1.0; i += 0.2) {
        if (i < progress) {
          final value = initial + (finalValue - initial) * i;
          spots.add(FlSpot(i * 10, value));
        }
      }
    }

    // Add final point
    spots.add(FlSpot(10, finalValue));

    return spots;
  }

  LineChartData _mainData(List<FlSpot> spots) {
    final maxY = investmentData.investmentDetails.expectedRepayment * 1.1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 5,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            getTitlesWidget: (value, meta) {
              if (value % (maxY / 5) == 0) {
                return Text(
                  Utils.formatCurrency(value),
                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                );
              }
              return Container();
            },
          ),
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
          color: Colors.cyan,
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                Colors.cyan.withOpacity(0.3),
                Colors.purple.withOpacity(0.3),
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
        ),
      ],
    );
  }
}
