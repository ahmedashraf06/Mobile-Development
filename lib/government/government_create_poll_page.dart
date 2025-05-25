import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/poll.dart';

class CreatePollPage extends StatefulWidget {
  const CreatePollPage({super.key});

  @override
  State<CreatePollPage> createState() => _CreatePollPageState();
}

class _CreatePollPageState extends State<CreatePollPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  final TextEditingController option1Controller = TextEditingController();
  final TextEditingController option2Controller = TextEditingController();
  Region? selectedRegion;
  Category? selectedCategory;
  DateTime? selectedEndDate;
  File? pickedFile;
  bool isPublishing = false;

  @override
  void dispose() {
    titleController.dispose();
    detailsController.dispose();
    option1Controller.dispose();
    option2Controller.dispose();
    super.dispose();
  }

  bool isImageFile(String path) {
    final ext = path.toLowerCase();
    return ext.endsWith('.png') ||
        ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.gif') ||
        ext.endsWith('.webp');
  }

  Widget _buildCupertinoField({required String label}) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 14,
                color:
                    (label == 'Select Category' || label == 'Select Region')
                        ? Colors.grey
                        : Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Icon(Icons.arrow_drop_down, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  Future<void> _showFileSourceDialog() async {
    showCupertinoModalPopup(
      context: context,
      builder:
          (context) => CupertinoActionSheet(
            title: const Text('Select Attachment Source'),
            actions: [
              CupertinoActionSheetAction(
                child: const Text('Choose from Photos'),
                onPressed: () async {
                  Navigator.pop(context);
                  final pickedImage = await ImagePicker().pickImage(
                    source: ImageSource.gallery,
                  );
                  if (pickedImage != null) {
                    setState(() => pickedFile = File(pickedImage.path));
                  }
                },
              ),
              CupertinoActionSheetAction(
                child: const Text('Choose a File'),
                onPressed: () async {
                  Navigator.pop(context);
                  final result = await FilePicker.platform.pickFiles();
                  if (result != null && result.files.single.path != null) {
                    setState(
                      () => pickedFile = File(result.files.single.path!),
                    );
                  }
                },
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
          ),
    );
  }

  /*Future<void> _showFileSourceDialog() async {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: const Text(
        'Select Attachment Source',
        style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from Photos'),
            onTap: () async {
              Navigator.pop(context);
              final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
              if (pickedImage != null) {
                setState(() => pickedFile = File(pickedImage.path));
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: const Text('Choose a File'),
            onTap: () async {
              Navigator.pop(context);
              final result = await FilePicker.platform.pickFiles();
              if (result != null && result.files.single.path != null) {
                setState(() => pickedFile = File(result.files.single.path!));
              }
            },
          ),
        ],
      ),
    ),
  );
}

*/ //this works for both android and ios while the other one works only for ios

  Future<void> _publishPoll() async {
    setState(() => isPublishing = true);
    try {
      String? fileUrl;
      if (pickedFile != null && pickedFile!.existsSync()) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = FirebaseStorage.instance.ref().child('polls/$fileName');
        await ref.putFile(pickedFile!);
        fileUrl = await ref.getDownloadURL();
      }

      final docRef = FirebaseFirestore.instance.collection('polls').doc();
      await docRef.set({
        'id': docRef.id,
        'title': titleController.text.trim(),
        'details': detailsController.text.trim(),
        'postedAt': Timestamp.now(),
        'endDate': Timestamp.fromDate(selectedEndDate!),
        'region': selectedRegion!.name,
        'category': selectedCategory!.name,
        'options': [
          option1Controller.text.trim(),
          option2Controller.text.trim(),
        ],
        'attachment': fileUrl,
        'votes': [], // will hold { name: ..., choice: ... }
        'option1Count': 0,
        'option2Count': 0,
        'totalVotes': 0,
        'status': 'active',
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error publishing poll: $e');
    } finally {
      if (mounted) setState(() => isPublishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPublishEnabled =
        titleController.text.isNotEmpty &&
        detailsController.text.isNotEmpty &&
        option1Controller.text.isNotEmpty &&
        option2Controller.text.isNotEmpty &&
        selectedEndDate != null &&
        selectedRegion != null &&
        selectedCategory != null &&
        !isPublishing;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create Poll',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _showFileSourceDialog,
                child: DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(12),
                  dashPattern: const [8, 6],
                  strokeWidth: 1.5,
                  color: const Color(0xFF4E4B66),
                  child: Container(
                    height: 160,
                    width: double.infinity,
                    color: const Color(0xFFF5F6FA),
                    child:
                        pickedFile != null
                            ? isImageFile(pickedFile!.path)
                                ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        pickedFile!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            size: 20,
                                          ),
                                          onPressed:
                                              () => setState(
                                                () => pickedFile = null,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                                : Center(
                                  child: Text(
                                    pickedFile!.path.split('/').last,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      color: Color(0xFF4E4B66),
                                    ),
                                  ),
                                )
                            : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.upload,
                                  size: 32,
                                  color: Color(0xFF4E4B66),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Add Photo or File',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4E4B66),
                                  ),
                                ),
                              ],
                            ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildTextField(
                titleController,
                'Add Title',
                fontSize: 20,
                bold: true,
              ),
              _buildTextField(detailsController, 'Add Details', maxLines: 3),
              _buildTextField(option1Controller, 'Option 1'),
              _buildTextField(option2Controller, 'Option 2'),
              const SizedBox(height: 16),
              _buildDatePicker(),
              const SizedBox(height: 16),
              GestureDetector(
                onTap:
                    () => _showCupertinoEnumPicker<Category>(
                      values: Category.values,
                      currentValue: selectedCategory,
                      onSelected:
                          (value) => setState(() => selectedCategory = value),
                      label: 'Category',
                    ),
                child: _buildCupertinoField(
                  label:
                      selectedCategory != null
                          ? StringExtension(
                            selectedCategory.toString().split('.').last,
                          ).capitalize()
                          : 'Select Category',
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap:
                    () => _showCupertinoEnumPicker<Region>(
                      values: Region.values,
                      currentValue: selectedRegion,
                      onSelected:
                          (value) => setState(() => selectedRegion = value),
                      label: 'Region',
                    ),
                child: _buildCupertinoField(
                  label:
                      selectedRegion != null
                          ? StringExtension(
                            selectedRegion.toString().split('.').last,
                          ).capitalize()
                          : 'Select Region',
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x19000000),
              offset: Offset(0, -2),
              blurRadius: 6,
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: isPublishEnabled ? _publishPoll : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isPublishing
                      ? const Color(0xFFEEF1F4)
                      : (isPublishEnabled
                          ? const Color(0xFF1877F2)
                          : const Color(0xFFEEF1F4)),
              foregroundColor:
                  isPublishing
                      ? const Color(0xFF667080)
                      : (isPublishEnabled
                          ? Colors.white
                          : const Color(0xFF667080)),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child:
                isPublishing
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Text(
                      'Publish',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    double fontSize = 16,
    bool bold = false,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        fontFamily: 'Poppins',
        fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
        fontSize: fontSize,
        color: const Color(0xFF050505),
      ),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
          fontFamily: 'Poppins',
          color: Color(0xFFA0A3BD),
        ),
        border: InputBorder.none,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF1877F2)),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'End Date',
          style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => selectedEndDate = picked);
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedEndDate != null
                      ? '${selectedEndDate!.day.toString().padLeft(2, '0')}-${selectedEndDate!.month.toString().padLeft(2, '0')}-${selectedEndDate!.year}'
                      : 'Select End Date',
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: Color(0xFF4E4B66),
                  ),
                ),
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Color(0xFF4E4B66),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCupertinoEnumPicker<T>({
    required List<T> values,
    required T? currentValue,
    required void Function(T) onSelected,
    required String label,
  }) {
    final scrollController = FixedExtentScrollController(
      initialItem: currentValue != null ? values.indexOf(currentValue) : 0,
    );

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => Container(
            height: 300,
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16, top: 12),
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: scrollController,
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      onSelected(values[index]);
                    },
                    children:
                        values.map((value) {
                          final text =
                              StringExtension(
                                value
                                    .toString()
                                    .split('.')
                                    .last
                                    .replaceAllMapped(
                                      RegExp(r'([a-z])([A-Z])'),
                                      (m) => '${m[1]} ${m[2]}',
                                    ),
                              ).capitalize();
                          return Center(child: Text(text));
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

extension StringExtension on String {
  String capitalize() =>
      isEmpty ? '' : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
}
