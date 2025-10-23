import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/theme.dart';
import '../../services/kyc_service.dart';

class KYCSubmissionScreen extends StatefulWidget {
	const KYCSubmissionScreen({Key? key}) : super(key: key);

  @override
  State<KYCSubmissionScreen> createState() => _KYCSubmissionScreenState();
}

class _KYCSubmissionScreenState extends State<KYCSubmissionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;
  String? _idCardUrl;
  String? _profilePhotoUrl;
  File? _idCardFile;
  File? _profilePhotoFile;

  @override
  void dispose() {
    _idNumberController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitKYC() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_idCardUrl == null || _profilePhotoUrl == null) {
      _showError('Please upload both ID card and profile photo');
      return;
    }

    setState(() => _isLoading = true);

    final result = await KYCService.submitKYC(
      idCardUrl: _idCardUrl!,
      idCardNumber: _idNumberController.text.trim(),
      profilePhotoUrl: _profilePhotoUrl!,
      address: _addressController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      Navigator.pop(context, true);
      _showSuccess('KYC submitted successfully');
    } else {
      _showError(result['message'] ?? 'Submission failed');
    }
  }

  Future<void> _uploadIDCard() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _idCardFile = File(image.path);
          _idCardUrl = image.path;
        });
        _showSuccess('ID card selected');
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  Future<void> _uploadProfilePhoto() async {
    try {
      // Show dialog to choose between camera and gallery
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Select Photo Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Camera'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          );
        },
      );

      if (source != null) {
        final XFile? image = await _picker.pickImage(
          source: source,
          maxWidth: 1080,
          maxHeight: 1080,
          imageQuality: 85,
        );

        if (image != null) {
          setState(() {
            _profilePhotoFile = File(image.path);
            _profilePhotoUrl = image.path;
          });
          _showSuccess('Profile photo selected');
        }
      }
    } catch (e) {
      _showError('Failed to pick image: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.errorColor),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.secondaryColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete KYC'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verify Your Identity',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'To ensure secure transactions, we need to verify your identity',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // ID Card Upload
              _buildUploadCard(
                title: 'Upload ID Card',
                description: 'Ghana Card, Passport, or Driver\'s License',
                icon: Icons.badge_outlined,
                isUploaded: _idCardUrl != null,
                imageFile: _idCardFile,
                onTap: _uploadIDCard,
              ),
              const SizedBox(height: 16),

              // ID Number
              TextFormField(
                controller: _idNumberController,
                decoration: const InputDecoration(
                  labelText: 'ID Card Number',
                  hintText: 'GHA-XXXXXXXXX-X',
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your ID number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Profile Photo Upload
              _buildUploadCard(
                title: 'Upload Profile Photo',
                description: 'Clear photo of your face',
                icon: Icons.person_outline,
                isUploaded: _profilePhotoUrl != null,
                imageFile: _profilePhotoFile,
                onTap: _uploadProfilePhoto,
              ),
              const SizedBox(height: 16),

              // Address
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Residential Address',
                  hintText: 'Enter your full address',
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.security, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your documents are encrypted and stored securely',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitKYC,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Submit for Verification'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isUploaded,
    File? imageFile,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUploaded
              ? AppTheme.secondaryColor.withOpacity(0.1)
              : Colors.white,
          border: Border.all(
            color: isUploaded ? AppTheme.secondaryColor : AppTheme.borderColor,
            width: isUploaded ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isUploaded
                        ? AppTheme.secondaryColor
                        : AppTheme.borderColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isUploaded ? Icons.check : icon,
                    color: isUploaded ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isUploaded
                              ? AppTheme.secondaryColor
                              : AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isUploaded ? Icons.edit : Icons.upload_file,
                  color: isUploaded ? AppTheme.secondaryColor : AppTheme.textSecondary,
                ),
              ],
            ),
            if (imageFile != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  imageFile,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
