import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/announcement.dart';

class CreateAnnouncementPage extends StatefulWidget {
  final String? announcementId;
  final Map<String, dynamic>? initialData;

  const CreateAnnouncementPage({
    super.key,
    this.announcementId,
    this.initialData,
  });

  @override
  State<CreateAnnouncementPage> createState() => _CreateAnnouncementPageState();
}

class _CreateAnnouncementPageState extends State<CreateAnnouncementPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  Region? selectedRegion;
  Category? selectedCategory;
  File? pickedFile;
  bool isLoading = false;
  String? existingAttachmentUrl;
  bool? isExistingImage;

  @override
  void initState() {
    super.initState();
    if (widget.initialData?['attachment'] != null &&
        widget.initialData!['attachment'].toString().isNotEmpty) {
      existingAttachmentUrl = widget.initialData!['attachment'];
      isExistingImage = widget.initialData!['isImage'] ?? true;
    }

    if (widget.initialData != null) {
      titleController.text = widget.initialData!['title'] ?? '';
      detailsController.text = widget.initialData!['details'] ?? '';
      selectedCategory = Category.values.firstWhere(
        (e) => e.toString().split('.').last == widget.initialData!['category'],
        orElse: () => Category.values.first,
      );
      selectedRegion = Region.values.firstWhere(
        (e) => e.toString().split('.').last == widget.initialData!['region'],
        orElse: () => Region.values.first,
      );
    }

    titleController.addListener(() => setState(() {}));
    detailsController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    titleController.dispose();
    detailsController.dispose();
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

  Future<void> _submitAnnouncement() async {
    setState(() => isLoading = true);
    try {
      String? fileUrl = widget.initialData?['attachment'];

      if (pickedFile != null && pickedFile!.existsSync()) {
        final fileName = DateTime.now().millisecondsSinceEpoch.toString();
        final ref = FirebaseStorage.instance.ref().child(
          'announcements/$fileName',
        );
        await ref.putFile(pickedFile!);
        fileUrl = await ref.getDownloadURL();
      }

      final updatedData = {
        'title': titleController.text.trim(),
        'details': detailsController.text.trim(),
        'region': selectedRegion.toString().split('.').last,
        'category': selectedCategory.toString().split('.').last,
        'attachment': fileUrl,
        'postedAt': Timestamp.now(),
      };
      final isImage = pickedFile != null && isImageFile(pickedFile!.path);
      if (widget.announcementId != null) {
        final docRef = FirebaseFirestore.instance
            .collection('announcements')
            .doc(widget.announcementId);
        await docRef.update(updatedData);

        // 🔔 TODO: Send notification to users that title was changed
      } else {
        await FirebaseFirestore.instance.collection('announcements').add({
          ...updatedData,
          'postedAt': Timestamp.now(),
          'isImage': isImage,
        });
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _showFileSourceDialog() async {
    showCupertinoModalPopup(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
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
                    setState(() {
                      pickedFile = File(pickedImage.path);
                      existingAttachmentUrl = null;
                      isExistingImage = null;
                    });
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

  @override
  Widget build(BuildContext context) {
    final isPublishEnabled =
        titleController.text.isNotEmpty &&
        detailsController.text.isNotEmpty &&
        selectedRegion != null &&
        selectedCategory != null;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Create Announcement',
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
                        (existingAttachmentUrl != null)
                            ? (isExistingImage == true)
                                ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    existingAttachmentUrl!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                )
                                : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.insert_drive_file,
                                      size: 32,
                                      color: Color(0xFF4E4B66),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      existingAttachmentUrl!
                                          .split('/')
                                          .last
                                          .split('%2F')
                                          .last,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 14,
                                        color: Color(0xFF4E4B66),
                                      ),
                                    ),
                                  ],
                                )
                            : pickedFile != null
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
              TextField(
                controller: titleController,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Color(0xFF050505),
                ),
                decoration: const InputDecoration(
                  hintText: 'Add Title',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFFA0A3BD),
                    fontSize: 20,
                  ),
                  border: InputBorder.none,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFE0E0E0)),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF1877F2)),
                  ),
                ),
              ),
              TextField(
                controller: detailsController,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xFF4E4B66),
                ),
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add Details',
                  hintStyle: TextStyle(
                    fontFamily: 'Poppins',
                    color: Color(0xFFA0A3BD),
                  ),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Choose Category',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap:
                    () => _showCupertinoEnumPicker<Category>(
                      values: Category.values,
                      currentValue: selectedCategory,
                      onSelected:
                          (value) => setState(() => selectedCategory = value),
                      label: 'Select Category',
                    ),
                child: _buildCupertinoField(
                  label:
                      selectedCategory != null
                          ? selectedCategory
                              .toString()
                              .split('.')
                              .last
                              .replaceAllMapped(
                                RegExp(r'([a-z])([A-Z])'),
                                (m) => '${m[1]} ${m[2]}',
                              )
                              .capitalize()
                          : 'Select Category',
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Choose Region',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 14),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap:
                    () => _showCupertinoEnumPicker<Region>(
                      values: Region.values,
                      currentValue: selectedRegion,
                      onSelected:
                          (value) => setState(() => selectedRegion = value),
                      label: 'Select Region',
                    ),
                child: _buildCupertinoField(
                  label:
                      selectedRegion != null
                          ? selectedRegion
                              .toString()
                              .split('.')
                              .last
                              .replaceAllMapped(
                                RegExp(r'([a-z])([A-Z])'),
                                (m) => '${m[1]} ${m[2]}',
                              )
                              .capitalize()
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed:
                (isPublishEnabled && !isLoading) ? _submitAnnouncement : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isLoading
                      ? const Color(0xFFEEF1F4) // light gray while loading
                      : (isPublishEnabled
                          ? const Color(0xFF1877F2) // blue if enabled
                          : const Color(0xFFEEF1F4)), // gray if disabled
              foregroundColor:
                  isLoading
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
                isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(
                      widget.announcementId != null ? 'Edit' : 'Publish',
                      style: const TextStyle(
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

  Widget dropdownBox<T>({
    required T? selectedValue,
    required List<T> items,
    required String hintText,
    required void Function(T?) onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(left: 16, right: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: selectedValue,
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEFEFEF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_drop_down,
              color: Colors.black,
              size: 20,
            ),
          ),
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            color: Colors.black,
          ),
          hint: Text(
            hintText,
            style: const TextStyle(
              fontFamily: 'Poppins',
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          items:
              items.map((item) {
                final label =
                    item
                        .toString()
                        .split('.')
                        .last
                        .replaceAllMapped(
                          RegExp(r'([a-z])([A-Z])'),
                          (match) => '${match[1]} ${match[2]}',
                        )
                        .capitalize();
                return DropdownMenuItem<T>(value: item, child: Text(label));
              }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _showCupertinoEnumPicker<T>({
    required List<T> values,
    required T? currentValue,
    required void Function(T) onSelected,
    required String label,
  }) {
    final FixedExtentScrollController scrollController =
        FixedExtentScrollController(
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
                  padding: const EdgeInsets.only(right: 16, top: 12),
                  alignment: Alignment.centerRight,
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
                    onSelectedItemChanged: (index) => onSelected(values[index]),
                    children:
                        values.map((value) {
                          final text =
                              value
                                  .toString()
                                  .split('.')
                                  .last
                                  .replaceAllMapped(
                                    RegExp(r'([a-z])([A-Z])'),
                                    (m) => '${m[1]} ${m[2]}',
                                  )
                                  .capitalize();
                          return Center(child: Text(text));
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
    );
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
}
