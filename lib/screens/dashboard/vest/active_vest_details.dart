import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:soundhive2/utils/alert_helper.dart';
import '../../../components/rounded_button.dart';
import '../../../model/active_investment_model.dart';
import 'package:intl/intl.dart';

class ActiveVestDetailsScreen extends ConsumerStatefulWidget {
  final ActiveInvestment investment;
  const ActiveVestDetailsScreen({Key? key, required this.investment}) : super(key: key);

  @override
  ConsumerState<ActiveVestDetailsScreen> createState() => _VestDetailsScreenState();
}

class _VestDetailsScreenState extends ConsumerState<ActiveVestDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget buildInfoCard(String label, String value, {Color? valueColor}) {
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

  Widget buildEarningsCard(String interest, String date) {
    return ListTile(
      title: Text(interest, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
      subtitle: Text(date, style: const TextStyle(color: Colors.white70)),
    );
  }

  Widget buildChart() {
    return AspectRatio(
      aspectRatio: 1.7,
      child: LineChart(
        LineChartData(
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(show: true, leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true))),
          lineBarsData: [
            LineChartBarData(
              spots: [
                FlSpot(0, 100),
                FlSpot(1, 200),
                FlSpot(2, 400),
                FlSpot(3, 600),
                FlSpot(4, 800),
                FlSpot(5, 900),
              ],
              isCurved: true,
              color: Colors.cyanAccent,
              barWidth: 2,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final investment = widget.investment;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: BackButton(color: Colors.white),
        // title: Text(investment.investment.investmentName, style: const TextStyle(color: Colors.white)),
      ),
      body: Column(
        children: [
          // Capital + another card (example)
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.deepPurple,
                  margin: const EdgeInsets.all(12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text("Capital", style: TextStyle(color: Colors.white70)),
                        // Text("₦${investment.amount}",
                        //     style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Roboto',)),
                      ],
                    ),
                  ),
                ),
              ),
              // Add another card here if needed (e.g., Profit)
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
                SingleChildScrollView(
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
                            // buildInfoCard("Project", investment.investment.investmentName),
                            // buildInfoCard("Amount", "₦${investment.amount}"),
                            // buildInfoCard("Maturity date", DateFormat('d MMMM, yyyy').format(DateTime.parse(investment.endDate))),
                            buildInfoCard("Maturity date", DateFormat('d MMMM, yyyy').format(DateFormat('dd-MM-yyyy').parse('15-05-2026'))),
                            // buildInfoCard("Interest", "${investment.}%"),
                            // buildInfoCard("Expected repayment", "₦${investment.expectedRepayment.toStringAsFixed(0)}"),
                            // buildInfoCard("Status", investment.investment.status, valueColor: Colors.green),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text("About Artist", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      //  Text(
                      //   investment.investment.investmentNote,
                      //   style: TextStyle(color: Colors.white70),
                      // ),
                      SizedBox(height: 20,),
                      RoundedButton(
                        title: 'Payout',
                        color: const Color(0xFF4D3490),
                        borderWidth: 0,
                        borderRadius: 25.0,
                        onPressed: () {
                          showCustomAlert(context: context, isSuccess: false, title: 'Error', message: 'Investment not up to maturity date');
                        },
                      )
                    ],
                  ),
                ),

                // Tab 2: Portfolio and earnings
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      buildChart(),
                      const SizedBox(height: 16),
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
                                child: Text("Earnings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ),
                            buildEarningsCard("₦2000", "21 Jan, 2025"),
                            buildEarningsCard("₦2000", "28 Jan, 2025"),
                            // More earnings...
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
