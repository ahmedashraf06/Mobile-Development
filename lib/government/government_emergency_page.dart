import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../layouts/layout.dart';

class GovernmentEmergencyPage extends StatefulWidget {
  const GovernmentEmergencyPage({super.key});

  @override
  State<GovernmentEmergencyPage> createState() =>
      _GovernmentEmergencyPageState();
}

Widget customAddButton({required VoidCallback onTap}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Icon(
          Icons.add_circle_outline,
          size: 28,
          color: Colors.black,
          weight: 700,
        ),
      ),
    ),
  );
}

class _GovernmentEmergencyPageState extends State<GovernmentEmergencyPage> {
  final TextEditingController serviceController = TextEditingController();
  final TextEditingController numberController = TextEditingController();

  void _showAddEmergencyBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Emergency Type',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: serviceController,
                  decoration: _inputDecoration('e.g. Water'),
                ),

                const SizedBox(height: 16),
                const Text(
                  'Emergency Number',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: numberController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('e.g. 125'),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _addEmergencyNumber,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Add Emergency Number',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontFamily: 'Poppins',
        color: Color(0xFFA0A3BD), // Light grey color
      ),
      filled: true,
      fillColor: Color(0xFFF1F6F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _addEmergencyNumber() async {
    final service = serviceController.text.trim();
    final number = numberController.text.trim();

    if (service.isNotEmpty && number.isNotEmpty) {
      await FirebaseFirestore.instance.collection('emergencyNumbers').add({
        'service': service,
        'number': number,
        'timestamp': FieldValue.serverTimestamp(),
      });
      serviceController.clear();
      numberController.clear();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: 'Emergency Numbers',
      showNotificationAndFilter: false,
      actions: [customAddButton(onTap: _showAddEmergencyBottomSheet)],
      onAdd: _showAddEmergencyBottomSheet,
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('emergencyNumbers')
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No emergency numbers yet',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            );
          }
         

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return EmergencyCard(
                serviceName: data['service'] ?? '',
                phoneNumber: data['number'] ?? '',
              );
            },
          );
        },
      ),
    );
  }
}

class EmergencyCard extends StatelessWidget {
  final String serviceName;
  final String phoneNumber;

  const EmergencyCard({
    super.key,
    required this.serviceName,
    required this.phoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            serviceName,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 20),
              const SizedBox(width: 6),
              Text(
                phoneNumber,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
