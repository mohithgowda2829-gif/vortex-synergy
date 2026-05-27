import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/resource_api.dart';
import '../../config/app_feedback.dart';
import '../../config/app_config.dart';
import '../../config/app_formatters.dart';
import '../../models/paged_resource_result.dart';
import '../../models/resource_item.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_title.dart';
import '../../widgets/status_chip.dart';
import 'resource_details_screen.dart';

class BrowseResourcesScreen extends StatefulWidget {
  const BrowseResourcesScreen({super.key});

  @override
  State<BrowseResourcesScreen> createState() => _BrowseResourcesScreenState();
}

class _BrowseResourcesScreenState extends State<BrowseResourcesScreen> {
  final TextEditingController _queryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();

  String? _resourceType;
  String _sort = 'EXPIRY';
  static const int _pageSize = 12;
  int _page = 0;
  late Future<PagedResourceResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _queryController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<PagedResourceResult> _load() {
    final AuthProvider auth = context.read<AuthProvider>();
    return ResourceApi(auth.apiClient).list(
      auth.token!,
      query: _queryController.text.trim().isEmpty ? null : _queryController.text.trim(),
      resourceType: _resourceType,
      city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      area: _areaController.text.trim().isEmpty ? null : _areaController.text.trim(),
      latitude: double.tryParse(_latitudeController.text.trim()),
      longitude: double.tryParse(_longitudeController.text.trim()),
      sort: _sort,
      page: _page,
      size: _pageSize,
    );
  }

  void _applyFilters() {
    final bool latitudeFilled = _latitudeController.text.trim().isNotEmpty;
    final bool longitudeFilled = _longitudeController.text.trim().isNotEmpty;
    if (latitudeFilled != longitudeFilled) {
      AppFeedback.showError(context, 'Enter both latitude and longitude for nearest sorting.');
      return;
    }
    if (_sort == 'NEAREST' && latitudeFilled && longitudeFilled) {
      final double? latitude = double.tryParse(_latitudeController.text.trim());
      final double? longitude = double.tryParse(_longitudeController.text.trim());
      if (latitude == null || longitude == null) {
        AppFeedback.showError(context, 'Enter valid latitude and longitude values.');
        return;
      }
    }
    setState(() {
      _page = 0;
      _future = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'Browse Resources',
      onLogout: () => auth.logout(),
      child: RefreshIndicator(
        onRefresh: () async => setState(() => _future = _load()),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: <Widget>[
          Card(
            color: const Color(0xFFEFF7EC),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Icon(Icons.info_outline),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Only verified food and medically approved medicine appear here. Pull to refresh after new listings are approved.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: <Widget>[
                  const SectionTitle(
                    title: 'Find Resources',
                    subtitle: 'Search by listing title, medicine name, location, and urgency.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _queryController,
                    decoration: const InputDecoration(labelText: 'Search title or resource name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _resourceType,
                    decoration: const InputDecoration(labelText: 'Resource type'),
                    items: const <DropdownMenuItem<String?>>[
                      DropdownMenuItem<String?>(value: null, child: Text('All')),
                      DropdownMenuItem<String?>(value: 'FOOD', child: Text('Food')),
                      DropdownMenuItem<String?>(value: 'MEDICINE', child: Text('Medicine')),
                    ],
                    onChanged: (String? value) => setState(() => _resourceType = value),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final bool stacked = constraints.maxWidth < 520;
                      final Widget cityField = TextField(
                        controller: _cityController,
                        decoration: const InputDecoration(labelText: 'City'),
                      );
                      final Widget areaField = TextField(
                        controller: _areaController,
                        decoration: const InputDecoration(labelText: 'Area'),
                      );
                      if (stacked) {
                        return Column(
                          children: <Widget>[
                            cityField,
                            const SizedBox(height: 12),
                            areaField,
                          ],
                        );
                      }
                      return Row(
                        children: <Widget>[
                          Expanded(child: cityField),
                          const SizedBox(width: 12),
                          Expanded(child: areaField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      final bool stacked = constraints.maxWidth < 520;
                      final Widget latitudeField = TextField(
                        controller: _latitudeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(labelText: 'Latitude'),
                      );
                      final Widget longitudeField = TextField(
                        controller: _longitudeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                        decoration: const InputDecoration(labelText: 'Longitude'),
                      );
                      if (stacked) {
                        return Column(
                          children: <Widget>[
                            latitudeField,
                            const SizedBox(height: 12),
                            longitudeField,
                          ],
                        );
                      }
                      return Row(
                        children: <Widget>[
                          Expanded(child: latitudeField),
                          const SizedBox(width: 12),
                          Expanded(child: longitudeField),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _sort,
                    decoration: const InputDecoration(labelText: 'Sort by'),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: 'EXPIRY', child: Text('Earliest expiry')),
                      DropdownMenuItem(value: 'LOCATION', child: Text('Location grouping')),
                      DropdownMenuItem(value: 'NEAREST', child: Text('Nearest coordinates')),
                      DropdownMenuItem(value: 'PRIORITY', child: Text('Highest priority')),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() => _sort = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<PagedResourceResult>(
            future: _future,
            builder: (BuildContext context, AsyncSnapshot<PagedResourceResult> snapshot) {
              if (snapshot.hasError) {
                return EmptyStateCard(
                  title: 'Unable to load resources',
                  message: AppFeedback.messageFromError(snapshot.error!),
                  icon: Icons.cloud_off_outlined,
                  action: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _applyFilters,
                      child: const Text('Retry'),
                    ),
                  ),
                );
              }
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final PagedResourceResult result = snapshot.data!;
              final List<ResourceItem> resources = result.items;
              if (resources.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: EmptyStateCard(
                    title: 'No matching resources found',
                    message:
                        'Try clearing some filters, refreshing, or waiting for medical approval on new medicine listings.',
                    icon: Icons.search_off_rounded,
                  ),
                );
              }
              return Column(
                children: <Widget>[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'Showing ${resources.length} resource(s) on page ${result.page + 1} of ${result.totalPages == 0 ? 1 : result.totalPages}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            '${result.totalElements} total',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...resources.map((ResourceItem resource) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: resource.primaryPhotoUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    AppConfig.resolveUrl(resource.primaryPhotoUrl!),
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
                                      return const CircleAvatar(
                                        child: Icon(Icons.broken_image_outlined),
                                      );
                                    },
                                  ),
                                )
                              : const CircleAvatar(child: Icon(Icons.fastfood_outlined)),
                          title: Text(resource.title),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: <Widget>[
                                    StatusChip(
                                      label: resource.resourceType,
                                      status: resource.resourceType,
                                    ),
                                    StatusChip(
                                      label: resource.requiresReceiverDelivery ? 'Receiver delivery' : 'Self pickup',
                                      status: resource.requiresReceiverDelivery ? 'PENDING' : 'APPROVED',
                                    ),
                                    if (resource.resourceType == 'MEDICINE')
                                      StatusChip(
                                        label: formatStatus(resource.medicalVerificationStatus),
                                        status: resource.medicalVerificationStatus,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${resource.city}, ${resource.area}\n'
                                  '${resource.availableQuantity} ${resource.unit}'
                                  '${resource.distanceKm != null ? '\n${resource.distanceKm} km away' : ''}',
                                ),
                              ],
                            ),
                          ),
                          trailing: Text(
                            resource.resourceType == 'FOOD'
                                ? formatDateTime(resource.expiresAt)
                                : formatDate(resource.medicineExpiryDate),
                            textAlign: TextAlign.right,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => ResourceDetailsScreen(resource: resource),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  }),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: result.first
                              ? null
                              : () {
                                  setState(() {
                                    _page = (_page - 1).clamp(0, _page);
                                    _future = _load();
                                  });
                                },
                          child: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: result.last
                              ? null
                              : () {
                                  setState(() {
                                    _page += 1;
                                    _future = _load();
                                  });
                                },
                          child: const Text('Next'),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}
