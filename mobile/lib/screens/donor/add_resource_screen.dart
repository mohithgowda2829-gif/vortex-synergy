import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/resource_api.dart';
import '../../api/upload_api.dart';
import '../../config/app_feedback.dart';
import '../../models/resource_item.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/photo_gallery.dart';

class AddResourceScreen extends StatefulWidget {
  const AddResourceScreen({super.key, this.resource});

  final ResourceItem? resource;

  @override
  State<AddResourceScreen> createState() => _AddResourceScreenState();
}

class _AddResourceScreenState extends State<AddResourceScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _locationNoteController = TextEditingController();
  final TextEditingController _foodTypeController = TextEditingController();
  final TextEditingController _medicineNameController = TextEditingController();
  final TextEditingController _batchNumberController = TextEditingController();
  final TextEditingController _medicineCategoryController = TextEditingController();

  String _resourceType = 'FOOD';
  String _medicineSealStatus = 'SEALED';
  String _medicineAccessType = 'OTC';
  bool _prescriptionRequired = false;
  bool _requiresReceiverDelivery = false;
  bool _submitting = false;
  bool _uploadingPhotos = false;
  DateTime? _preparedTime;
  DateTime? _expiryTime;
  DateTime? _medicineExpiryDate;
  final List<String> _photoUrls = <String>[];

  bool get _isEditing => widget.resource != null;

  @override
  void initState() {
    super.initState();
    final ResourceItem? resource = widget.resource;
    if (resource == null) {
      return;
    }

    _resourceType = resource.resourceType;
    _titleController.text = resource.title;
    _descriptionController.text = resource.description ?? '';
    _quantityController.text = resource.quantity.toString();
    _unitController.text = resource.unit;
    _cityController.text = resource.city;
    _areaController.text = resource.area;
    _latitudeController.text = resource.latitude?.toString() ?? '';
    _longitudeController.text = resource.longitude?.toString() ?? '';
    _locationNoteController.text = resource.locationNote ?? '';
    _foodTypeController.text = resource.foodType ?? '';
    _medicineNameController.text = resource.medicineName ?? '';
    _batchNumberController.text = resource.batchNumber ?? '';
    _medicineCategoryController.text = resource.medicineCategory ?? '';
    _medicineSealStatus = resource.medicineSealStatus ?? 'SEALED';
    _medicineAccessType = resource.medicineAccessType ?? 'OTC';
    _prescriptionRequired = resource.prescriptionRequired ?? false;
    _requiresReceiverDelivery = resource.requiresReceiverDelivery;
    _preparedTime = resource.preparedTime;
    _expiryTime = resource.expiresAt;
    _medicineExpiryDate = resource.medicineExpiryDate;
    _photoUrls.addAll(resource.photoUrls);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _locationNoteController.dispose();
    _foodTypeController.dispose();
    _medicineNameController.dispose();
    _batchNumberController.dispose();
    _medicineCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFood = _resourceType == 'FOOD';

    return AppScaffold(
      title: _isEditing ? 'Edit Resource' : 'Add Resource',
      child: SingleChildScrollView(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    initialValue: _resourceType,
                    decoration: const InputDecoration(labelText: 'Resource type'),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: 'FOOD', child: Text('Food')),
                      DropdownMenuItem(value: 'MEDICINE', child: Text('Medicine')),
                    ],
                    onChanged: _isEditing
                        ? null
                        : (String? value) {
                            if (value != null) {
                              setState(() => _resourceType = value);
                            }
                          },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Quantity'),
                          validator: _validateQuantity,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _unitController,
                          decoration: InputDecoration(
                            labelText: isFood ? 'Unit (meal, pack)' : 'Unit (kit, bottle)',
                          ),
                          validator: _required,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: _cityController,
                          decoration: const InputDecoration(labelText: 'City'),
                          validator: _required,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _areaController,
                          decoration: const InputDecoration(labelText: 'Area'),
                          validator: _required,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: _latitudeController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: const InputDecoration(labelText: 'Latitude (optional)'),
                          validator: _validateCoordinate,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _longitudeController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                          decoration: const InputDecoration(labelText: 'Longitude (optional)'),
                          validator: _validateCoordinate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _locationNoteController,
                    decoration: const InputDecoration(labelText: 'Location note'),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Resource Photos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 10),
                  PhotoGallery(photoUrls: _photoUrls, height: 140),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _uploadingPhotos ? null : _pickAndUploadPhotos,
                      icon: const Icon(Icons.add_a_photo_outlined),
                      label: Text(_uploadingPhotos ? 'Uploading...' : 'Add Photos'),
                    ),
                  ),
                  if (_photoUrls.isNotEmpty)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => setState(_photoUrls.clear),
                        child: const Text('Remove all photos'),
                      ),
                    ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _requiresReceiverDelivery,
                    title: const Text('Require receiver-managed delivery'),
                    subtitle: const Text(
                      'Leave this off when the receiver will come and collect the resource directly.',
                    ),
                    onChanged: (bool value) => setState(() => _requiresReceiverDelivery = value),
                  ),
                  const SizedBox(height: 14),
                  if (isFood) ...<Widget>[
                    TextFormField(
                      controller: _foodTypeController,
                      decoration: const InputDecoration(labelText: 'Food type'),
                    ),
                    const SizedBox(height: 14),
                    _DateButton(
                      label: 'Prepared time',
                      value: _preparedTime,
                      onPressed: () => _pickDateTime((DateTime value) {
                        _preparedTime = value;
                      }),
                    ),
                    const SizedBox(height: 12),
                    _DateButton(
                      label: 'Expiry time (optional)',
                      value: _expiryTime,
                      onPressed: () => _pickDateTime((DateTime value) {
                        _expiryTime = value;
                      }),
                    ),
                  ] else ...<Widget>[
                    TextFormField(
                      controller: _medicineNameController,
                      decoration: const InputDecoration(labelText: 'Medicine name'),
                      validator: _required,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _batchNumberController,
                      decoration: const InputDecoration(labelText: 'Batch number'),
                      validator: _required,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _medicineCategoryController,
                      decoration: const InputDecoration(labelText: 'Medicine category'),
                      validator: _required,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _medicineSealStatus,
                      decoration: const InputDecoration(labelText: 'Seal status'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(value: 'SEALED', child: Text('Sealed')),
                        DropdownMenuItem(value: 'OPENED', child: Text('Opened')),
                      ],
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() => _medicineSealStatus = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _medicineAccessType,
                      decoration: const InputDecoration(labelText: 'OTC or restricted'),
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(value: 'OTC', child: Text('OTC')),
                        DropdownMenuItem(value: 'RESTRICTED', child: Text('Restricted')),
                      ],
                      onChanged: (String? value) {
                        if (value != null) {
                          setState(() => _medicineAccessType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      value: _prescriptionRequired,
                      title: const Text('Prescription required'),
                      onChanged: (bool value) => setState(() => _prescriptionRequired = value),
                    ),
                    const SizedBox(height: 14),
                    _DateButton(
                      label: 'Medicine expiry date',
                      value: _medicineExpiryDate,
                      isDateOnly: true,
                      onPressed: () => _pickDate((DateTime value) {
                        _medicineExpiryDate = value;
                      }),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(_submitting ? 'Saving...' : (_isEditing ? 'Save Changes' : 'Create Resource')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final bool latitudeFilled = _latitudeController.text.trim().isNotEmpty;
    final bool longitudeFilled = _longitudeController.text.trim().isNotEmpty;
    if (latitudeFilled != longitudeFilled) {
      AppFeedback.showError(context, 'Enter both latitude and longitude, or leave both blank.');
      return;
    }
    if (_resourceType == 'FOOD' && _preparedTime == null) {
      AppFeedback.showError(context, 'Select the food prepared time before creating the resource.');
      return;
    }
    if (_resourceType == 'MEDICINE' && _medicineExpiryDate == null) {
      AppFeedback.showError(context, 'Select the medicine expiry date before creating the resource.');
      return;
    }
    if (_preparedTime != null && _expiryTime != null && !_expiryTime!.isAfter(_preparedTime!)) {
      AppFeedback.showError(context, 'Food expiry time must be after the prepared time.');
      return;
    }
    setState(() => _submitting = true);

    final AuthProvider auth = context.read<AuthProvider>();
    final ResourceApi api = ResourceApi(auth.apiClient);
    try {
      final Map<String, dynamic> body = <String, dynamic>{
        'resourceType': _resourceType,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'quantity': int.tryParse(_quantityController.text.trim()) ?? 0,
        'unit': _unitController.text.trim(),
        'city': _cityController.text.trim(),
        'area': _areaController.text.trim(),
        'latitude': double.tryParse(_latitudeController.text.trim()),
        'longitude': double.tryParse(_longitudeController.text.trim()),
        'locationNote': _locationNoteController.text.trim(),
        'requiresReceiverDelivery': _requiresReceiverDelivery,
        'photoUrls': _photoUrls,
        if (_resourceType == 'FOOD') ...<String, dynamic>{
          'foodType': _foodTypeController.text.trim(),
          'preparedTime': _preparedTime?.toIso8601String(),
          if (_expiryTime != null) 'expiryTime': _expiryTime!.toIso8601String(),
        } else ...<String, dynamic>{
          'medicineName': _medicineNameController.text.trim(),
          'batchNumber': _batchNumberController.text.trim(),
          'medicineCategory': _medicineCategoryController.text.trim(),
          'medicineSealStatus': _medicineSealStatus,
          'medicineAccessType': _medicineAccessType,
          'prescriptionRequired': _prescriptionRequired,
          'medicineExpiryDate': _medicineExpiryDate == null ? null : _formatDateOnly(_medicineExpiryDate!),
        },
      };

      final ResourceItem created = _isEditing
          ? await api.update(auth.token!, widget.resource!.id, body)
          : await api.create(auth.token!, body);
      if (!mounted) return;
      AppFeedback.showSuccess(context, _buildSuccessMessage(created));
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickAndUploadPhotos() async {
    final AuthProvider auth = context.read<AuthProvider>();
    setState(() => _uploadingPhotos = true);

    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.image,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final UploadApi uploadApi = UploadApi();
      final List<String> uploadedUrls = <String>[];
      for (final PlatformFile file in result.files) {
        uploadedUrls.add(await uploadApi.uploadResourcePhoto(auth.token!, file));
      }

      if (!mounted) return;
      setState(() => _photoUrls.addAll(uploadedUrls));
      AppFeedback.showSuccess(context, '${uploadedUrls.length} photo(s) uploaded');
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    } finally {
      if (mounted) {
        setState(() => _uploadingPhotos = false);
      }
    }
  }

  String? _required(String? value) {
    return (value == null || value.trim().isEmpty) ? 'This field is required' : null;
  }

  String? _validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Quantity is required';
    }
    final int? quantity = int.tryParse(value.trim());
    if (quantity == null) {
      return 'Quantity must be a whole number';
    }
    if (quantity < 1) {
      return 'Quantity must be greater than 0';
    }
    return null;
  }

  String? _validateCoordinate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return double.tryParse(value.trim()) == null ? 'Enter a valid number' : null;
  }

  String _formatDateOnly(DateTime value) {
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  String _buildSuccessMessage(ResourceItem resource) {
    if (_isEditing) {
      if (resource.resourceType == 'MEDICINE') {
        return 'Resource updated. Medicine listings return to review before they become public again.';
      }
      return 'Resource updated successfully.';
    }
    if (resource.resourceType == 'MEDICINE' && resource.medicalVerificationStatus != 'APPROVED') {
      return 'Medicine created successfully. It will appear to receivers after doctor/pharmacist approval.';
    }
    return 'Resource created successfully and is now visible to receivers.';
  }

  Future<void> _pickDateTime(ValueChanged<DateTime> onPicked) async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
      initialDate: now,
    );
    if (date == null || !mounted) return;
    final TimeOfDay? time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() {
      onPicked(DateTime(date.year, date.month, date.day, time.hour, time.minute));
    });
  }

  Future<void> _pickDate(ValueChanged<DateTime> onPicked) async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 730)),
      initialDate: now,
    );
    if (date == null) return;
    setState(() => onPicked(date));
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.value,
    required this.onPressed,
    this.isDateOnly = false,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onPressed;
  final bool isDateOnly;

  @override
  Widget build(BuildContext context) {
    final String text = value == null
        ? 'Select'
        : isDateOnly
            ? '${value!.day}/${value!.month}/${value!.year}'
            : '${value!.day}/${value!.month}/${value!.year} ${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}';
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.calendar_month_outlined),
      label: Align(
        alignment: Alignment.centerLeft,
        child: Text('$label: $text'),
      ),
    );
  }
}
