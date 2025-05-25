import 'dart:io';

import 'package:balaghnyv1/models/ad.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';
import 'advertiser_thank_you_page.dart';

class AdvertiserConfirmEmailPage extends StatefulWidget {
  final String title;
  final String details;
  final Region region;
  final AdCategory category;
  final File? pickedFile;
  final String? locationUrl;

  const AdvertiserConfirmEmailPage({
    super.key,
    required this.title,
    required this.details,
    required this.region,
    required this.category,
    this.pickedFile,
    this.locationUrl,
  });

  @override
  State<AdvertiserConfirmEmailPage> createState() =>
      _AdvertiserConfirmEmailPageState();
}

class _AdvertiserConfirmEmailPageState
    extends State<AdvertiserConfirmEmailPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool isLoading = false;

  Future<void> _handleConfirmAndPublish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      // Send confirmation email
      final email = _emailController.text.trim();
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'sendConfirmationEmail',
      );
      final result = await callable.call(<String, dynamic>{'email': email});

      if (result.data['success'] != true) {
        _showError('Failed to send confirmation email.');
        return;
      }

      // Upload file to Firebase Storage
      String? fileUrl;
      if (widget.pickedFile != null && widget.pickedFile!.existsSync()) {
        final fileName = const Uuid().v4();
        final ref = FirebaseStorage.instance.ref().child('ads/$fileName');
        await ref.putFile(widget.pickedFile!);
        fileUrl = await ref.getDownloadURL();
      }

      // Save ad to Firestore
      await FirebaseFirestore.instance.collection('ads').add({
        'title': widget.title,
        'details': widget.details,
        'region': widget.region.toString().split('.').last,
        'category': widget.category.toString().split('.').last,
        'status': 'pending',
        'postedAt': Timestamp.now(),
        'attachment': fileUrl,
        'contactEmail': email,
        'locationUrl': widget.locationUrl ?? '', //Save location link
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdvertiserThankYouPage()),
        );
      }
    } catch (e) {
      _showError('Something went wrong: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // This is used to check if the email field is filled
  bool isEmailFilled = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      setState(() {
        isEmailFilled = _emailController.text.trim().isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    print("Error: $message"); // <-- This prints the real error
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: const Text(
          'Confirm Email',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // dismiss keyboard
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Almost there!',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 35,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF4A825),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Please enter your email so we can contact you about the status of your advertisement.',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email*',
                          hintText: 'name@example.com',
                          hintStyle: const TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          } else if (!RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          ).hasMatch(value)) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed:
                      (isEmailFilled && !isLoading)
                          ? _handleConfirmAndPublish
                          : null,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1877F2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child:
                      isLoading
                          ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : const Text(
                            'Confirm & Publish',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
