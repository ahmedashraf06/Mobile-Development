import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../layouts/layout.dart';

class CitizenEmergencyPage extends StatelessWidget {
  const CitizenEmergencyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Layout(
      title: 'Emergency Numbers',
      child: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('emergencyNumbers')
                .orderBy('service')
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No emergency numbers found.',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final name = data['service'] ?? 'Unknown';
              final phone = data['number'] ?? '---';

              return EmergencyCard(serviceName: name, phoneNumber: phone);
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
