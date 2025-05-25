import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:balaghnyv1/layouts/detail_screen.dart';
import 'package:balaghnyv1/citizen/citizen_comments_page.dart';

class CitizenPollDetailPage extends StatefulWidget {
  final DateTime timestamp;

  const CitizenPollDetailPage({super.key, required this.timestamp});

  @override
  State<CitizenPollDetailPage> createState() => _CitizenPollDetailPageState();
}

class _CitizenPollDetailPageState extends State<CitizenPollDetailPage> {
  bool hasVoted = false;
  bool pollEnded = false;
  bool voteAnonymously = false;
  String? selectedOption;
  Map<String, dynamic>? pollData;
  String? userName;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadPollData();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snapshot =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = snapshot.data();

    if (data != null && mounted) {
      setState(() {
        userName = data['fullName'] ?? 'Anonymous';
      });
    }
  }

  String getPollStatusText() {
    final endDate = (pollData?['endDate'] as Timestamp?)?.toDate();
    if (endDate == null) return '';

    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;

    if (pollEnded) return 'Poll ended.';
    if (difference == 0) return 'Poll ends today.';
    return 'Poll ends in $difference day${difference == 1 ? '' : 's'}.';
  }

  Future<void> _loadPollData() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('polls')
            .where('postedAt', isEqualTo: Timestamp.fromDate(widget.timestamp))
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      final pollVotes = List<Map<String, dynamic>>.from(data['votes'] ?? []);
      final voted = pollVotes.any((v) => v['name'] == userName);
      final now = DateTime.now();
      final ended = (data['endDate'] as Timestamp).toDate().isBefore(now);

      setState(() {
        pollData = data;
        hasVoted = voted;
        pollEnded = ended;
      });
    }
  }
  Widget _buildPollStatusWidget() {
  final endDate = (pollData?['endDate'] as Timestamp?)?.toDate();
  if (endDate == null) return const SizedBox();

  final now = DateTime.now();
  final diff = endDate.difference(now).inDays;

  String text;
  if (pollEnded) {
    text = 'Poll ended.';
  } else if (diff == 0) {
    text = 'Poll ends today.';
  } else {
    text = 'Poll ends in $diff day${diff == 1 ? '' : 's'}.';
  }

  return Row(
    children: [
      const Icon(Icons.access_time, size: 16, color: Color(0xFF4E4B66)),
      const SizedBox(width: 6),
      Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF4E4B66),
          fontFamily: 'Poppins',
        ),
      ),
    ],
  );
}


  Future<void> _submitVote(int optionIndex) async {
    if (pollData == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('polls')
        .doc(pollData!['id']);
    final choice = pollData!['options'][optionIndex];
    final name = voteAnonymously ? 'Anonymous' : userName ?? 'Anonymous';

    await docRef.update({
      'votes': FieldValue.arrayUnion([
        {'name': name, 'choice': choice},
      ]),
      'option${optionIndex + 1}Count': FieldValue.increment(1),
      'totalVotes': FieldValue.increment(1),
    });

    setState(() {
      hasVoted = true;
      selectedOption = choice;
    });
  }

  Widget get pollStatusWidget => Row(
    children: [
      const Icon(Icons.access_time, size: 16, color: Color(0xFF4E4B66)),
      const SizedBox(width: 6),
      Text(
        getPollStatusText(),
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF4E4B66),
          fontFamily: 'Poppins',
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    if (pollData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final option1 = pollData?['options'][0] ?? '';
    final option2 = pollData?['options'][1] ?? '';

    return DetailLayout(
      title: pollData!['title'],
      description: pollData!['details'],
      category: pollData!['category'],
      timestamp: widget.timestamp,
      imageUrl: pollData!['attachment'],
      type: 'poll',
      onCommentsTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CitizenCommentsPage(timestamp: widget.timestamp),
          ),
        );
      },
      bottomSection: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE0E0E0), width: 0.5)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hasVoted && !pollEnded)
              Row(
                children: [
                  Transform.scale(
                    scale: 0.7,
                    child: CupertinoSwitch(
                      value: voteAnonymously,
                      activeTrackColor: const Color(0xFF667080),
                      onChanged:
                          (value) => setState(() => voteAnonymously = value),
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Vote anonymously',
                    style: TextStyle(
                      fontSize: 15,
                      fontFamily: 'Poppins',
                      color: Color(0xFF4E4B66),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            if (!hasVoted && !pollEnded)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _submitVote(0),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BA88),
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        option1,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _submitVote(1),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC30052),
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        option2,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA0A3BD),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    pollEnded ? 'Poll Ended' : 'Vote submitted',
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      extraSection: _buildPollStatusWidget(),
    );
  }
}
