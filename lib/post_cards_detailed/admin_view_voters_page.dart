import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class ViewVotersPage extends StatelessWidget {
  final DateTime timestamp;

  const ViewVotersPage({super.key, required this.timestamp});

  Future<Map<String, dynamic>?> _fetchPollData() async {
    final start = Timestamp.fromDate(
      timestamp.subtract(const Duration(seconds: 1)),
    );
    final end = Timestamp.fromDate(timestamp.add(const Duration(seconds: 1)));

    final snapshot =
        await FirebaseFirestore.instance
            .collection('polls')
            .where('postedAt', isGreaterThanOrEqualTo: start)
            .where('postedAt', isLessThanOrEqualTo: end)
            .limit(1)
            .get();

    if (snapshot.docs.isEmpty) return null;
    return snapshot.docs.first.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Poll results',
          
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: const BackButton(),
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchPollData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('Poll not found or no data.'));
          }

          final data = snapshot.data!;
          final option1 = data['option1Count'] ?? 0;
          final option2 = data['option2Count'] ?? 0;
          final votes = List<Map<String, dynamic>>.from(data['votes'] ?? []);
          final total = option1 + option2;
          final options = List<String>.from(
            data['options'] ?? ['Option 1', 'Option 2'],
          );
          final option1Label = options.isNotEmpty ? options[0] : 'Option 1';
          final option2Label = options.length > 1 ? options[1] : 'Option 2';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Donut Chart
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: SizedBox(
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              color: const Color(0xFF00BA88),
                              value: option1.toDouble(),
                              title: '$option1Label\n$option1',
                              radius: 100,
                              titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              color: const Color(0xFFC30052),
                              value: option2.toDouble(),
                              title: '$option2Label\n$option2',
                              radius: 100,
                              titleStyle: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                          centerSpaceRadius: 48,
                          sectionsSpace: 0,
                          pieTouchData: PieTouchData(enabled: false),
                        ),
                      ),
                      Text(
                        '$total',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text(
                  'Voters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        // Table Header
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFCBCBCB)),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: const [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(left: 16),
                                  child: Text(
                                    'Citizen',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'Voted',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Table Rows
                        ...votes.map((vote) {
                          final name = vote['name'] ?? 'Anonymous';
                          final choice = vote['choice'] ?? '-';

                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: const BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Color(0xFFE0E0E0)),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    choice,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
