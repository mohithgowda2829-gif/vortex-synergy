import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/report_api.dart';
import '../../config/app_feedback.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/empty_state_card.dart';
import '../../widgets/section_title.dart';
import '../../widgets/status_chip.dart';

class ReportCenterScreen extends StatefulWidget {
  const ReportCenterScreen({super.key, required this.title});

  final String title;

  @override
  State<ReportCenterScreen> createState() => _ReportCenterScreenState();
}

class _ReportCenterScreenState extends State<ReportCenterScreen> {
  String? _selectedReport;
  String? _csvContent;
  bool _loading = false;
  bool _showRawCsv = false;

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: widget.title,
      onLogout: () => auth.logout(),
      child: ListView(
        children: <Widget>[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: const SectionTitle(
                title: 'Operational Reports',
                subtitle: 'Preview exportable CSV reports in table form before downloading or sharing them.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _ReportButton(
                label: 'Donations',
                selected: _selectedReport == 'donations',
                onTap: () => _load('donations'),
              ),
              _ReportButton(
                label: 'Claims',
                selected: _selectedReport == 'claims',
                onTap: () => _load('claims'),
              ),
              _ReportButton(
                label: 'Expiry',
                selected: _selectedReport == 'expiry',
                onTap: () => _load('expiry'),
              ),
              _ReportButton(
                label: 'Medicine',
                selected: _selectedReport == 'medicine',
                onTap: () => _load('medicine'),
              ),
              _ReportButton(
                label: 'Delivery',
                selected: _selectedReport == 'delivery',
                onTap: () => _load('delivery'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_loading) const LinearProgressIndicator(),
          if (_selectedReport != null) ...<Widget>[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${_selectedReport![0].toUpperCase()}${_selectedReport!.substring(1)} Report Preview',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    StatusChip(label: 'CSV', status: 'APPROVED'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _csvContent == null
                  ? const EmptyStateCard(
                      title: 'Select a report',
                      message: 'Choose one of the report categories above to preview structured CSV data.',
                      icon: Icons.table_chart_outlined,
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _CsvTablePreview(csvContent: _csvContent!),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => setState(() => _showRawCsv = !_showRawCsv),
                            child: Text(_showRawCsv ? 'Hide Raw CSV' : 'Show Raw CSV'),
                          ),
                        ),
                        if (_showRawCsv)
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxHeight: 260),
                            child: SingleChildScrollView(
                              child: SelectableText(
                                _csvContent!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _load(String type) async {
    setState(() {
      _selectedReport = type;
      _loading = true;
      _showRawCsv = false;
    });

    final AuthProvider auth = context.read<AuthProvider>();
    final ReportApi api = ReportApi(auth.apiClient);
    try {
      String csv;
      switch (type) {
        case 'donations':
          csv = await api.donationsCsv(auth.token!);
        case 'claims':
          csv = await api.claimsCsv(auth.token!);
        case 'expiry':
          csv = await api.expiryCsv(auth.token!);
        case 'medicine':
          csv = await api.medicineCsv(auth.token!);
        case 'delivery':
          csv = await api.deliveryCsv(auth.token!);
        default:
          csv = '';
      }
      if (!mounted) return;
      setState(() => _csvContent = csv);
    } catch (error) {
      if (!mounted) return;
      AppFeedback.showError(context, error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _CsvTablePreview extends StatelessWidget {
  const _CsvTablePreview({required this.csvContent});

  final String csvContent;

  @override
  Widget build(BuildContext context) {
    final List<List<String>> rows = _parseCsv(csvContent);
    if (rows.isEmpty) {
      return const EmptyStateCard(
        title: 'No rows available',
        message: 'This report is currently empty for the selected filters and stored data.',
        icon: Icons.inbox_outlined,
      );
    }

    final List<String> headers = rows.first;
    final List<List<String>> dataRows = rows.length > 1 ? rows.sublist(1) : <List<String>>[];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 24,
          columns: headers
              .map((String header) => DataColumn(label: Text(header.replaceAll('_', ' ').toUpperCase())))
              .toList(),
          rows: dataRows
              .map(
                (List<String> row) => DataRow(
                  cells: headers.asMap().entries.map((MapEntry<int, String> entry) {
                    final String value = entry.key < row.length ? row[entry.key] : '';
                    return DataCell(Text(value.isEmpty ? '-' : value));
                  }).toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  List<List<String>> _parseCsv(String csv) {
    final List<List<String>> rows = <List<String>>[];
    final List<String> currentRow = <String>[];
    final StringBuffer currentCell = StringBuffer();
    bool inQuotes = false;

    for (int index = 0; index < csv.length; index++) {
      final String character = csv[index];
      final String? nextCharacter = index + 1 < csv.length ? csv[index + 1] : null;

      if (character == '"') {
        if (inQuotes && nextCharacter == '"') {
          currentCell.write('"');
          index++;
        } else {
          inQuotes = !inQuotes;
        }
        continue;
      }

      if (character == ',' && !inQuotes) {
        currentRow.add(currentCell.toString());
        currentCell.clear();
        continue;
      }

      if ((character == '\n' || character == '\r') && !inQuotes) {
        if (character == '\r' && nextCharacter == '\n') {
          index++;
        }
        currentRow.add(currentCell.toString());
        currentCell.clear();
        if (currentRow.any((String cell) => cell.isNotEmpty)) {
          rows.add(List<String>.from(currentRow));
        }
        currentRow.clear();
        continue;
      }

      currentCell.write(character);
    }

    if (currentCell.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentCell.toString());
      if (currentRow.any((String cell) => cell.isNotEmpty)) {
        rows.add(List<String>.from(currentRow));
      }
    }

    return rows;
  }
}

class _ReportButton extends StatelessWidget {
  const _ReportButton({required this.label, required this.onTap, required this.selected});

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return selected
        ? ElevatedButton(onPressed: onTap, child: Text(label))
        : OutlinedButton(onPressed: onTap, child: Text(label));
  }
}
