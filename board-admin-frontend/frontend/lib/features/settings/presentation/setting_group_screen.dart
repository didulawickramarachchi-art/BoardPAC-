import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loading.dart';
import '../model/setting_definition.dart';
import '../model/setting_model.dart';
import '../model/setting_request.dart';
import '../provider/setting_provider.dart';

class SettingGroupScreen extends ConsumerStatefulWidget {
  final String group;
  const SettingGroupScreen({super.key, required this.group});
  @override
  ConsumerState<SettingGroupScreen> createState() => _SettingGroupScreenState();
}

class _SettingGroupScreenState extends ConsumerState<SettingGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _values = {};
  final Map<String, TextEditingController> _controllers = {};
  bool _initialized = false;
  bool _saving = false;

  List<SettingDefinition> get _definitions =>
      settingDefinitions[widget.group] ?? const [];
  String get _title => widget.group
      .replaceAll('_', ' ')
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');

  void _initialize(List<SettingModel> items) {
    if (_initialized) return;
    final stored = {
      for (final item in items) item.settingKey: item.settingValue,
    };
    for (final definition in _definitions) {
      final value = stored[definition.key] ?? definition.defaultValue;
      _values[definition.key] = value;
      if (definition.control == SettingControl.number ||
          definition.control == SettingControl.text) {
        _controllers[definition.key] = TextEditingController(text: value);
      }
    }
    _initialized = true;
  }

  bool _isTrue(String key) => _values[key]?.toLowerCase() == 'true';
  bool _isEnabled(SettingDefinition d) =>
      d.enabledBy == null || _isTrue(d.enabledBy!);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    try {
      for (final entry in _controllers.entries) {
        _values[entry.key] = entry.value.text.trim();
      }
      await ref.read(settingGroupProvider(widget.group).notifier).saveAll([
        for (final d in _definitions)
          SettingRequest(
            settingGroup: widget.group,
            settingKey: d.key,
            settingValue: _values[d.key] ?? d.defaultValue,
            description: d.label,
          ),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save settings: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingGroupProvider(widget.group));
    return Scaffold(
      appBar: AppBar(title: Text('$_title Settings')),
      body: settings.when(
        loading: () => const AppLoading(),
        error: (error, _) => _ErrorView(
          error: error,
          onRetry: () =>
              ref.read(settingGroupProvider(widget.group).notifier).load(),
        ),
        data: (items) {
          _initialize(items);
          if (_definitions.isEmpty) {
            return const Center(child: Text('No settings configured.'));
          }
          return Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                    children: [
                      Text(
                        'Configure how $_title features behave across the web portal and member devices.',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 18),
                      ..._buildSections(),
                    ],
                  ),
                ),
                _SaveBar(saving: _saving, onSave: _save),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildSections() {
    final sections = <String>[];
    for (final d in _definitions) {
      if (!sections.contains(d.section)) sections.add(d.section);
    }
    return [
      for (final section in sections) ...[
        _SectionCard(
          title: section,
          children: _definitions
              .where((d) => d.section == section)
              .map(_buildSetting)
              .toList(),
        ),
        const SizedBox(height: 16),
      ],
    ];
  }

  Widget _buildSetting(SettingDefinition d) {
    final enabled = _isEnabled(d);
    late final Widget control;
    switch (d.control) {
      case SettingControl.toggle:
        control = Switch.adaptive(
          value: _isTrue(d.key),
          onChanged: enabled
              ? (v) => setState(() => _values[d.key] = '$v')
              : null,
        );
      case SettingControl.number:
        control = SizedBox(
          width: 230,
          child: TextFormField(
            controller: _controllers[d.key],
            enabled: enabled,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              isDense: true,
              suffixText: d.suffix,
              helperText: d.helper,
            ),
            validator: (value) {
              final number = int.tryParse(value ?? '');
              if (number == null || number < 0) return 'Enter a valid number';
              if (d.max != null && number > d.max!) {
                return 'Maximum is ${d.max}';
              }
              return null;
            },
          ),
        );
      case SettingControl.text:
        final long = d.key == 'printing_disclaimer';
        control = SizedBox(
          width: 380,
          child: TextFormField(
            controller: _controllers[d.key],
            enabled: enabled,
            minLines: long ? 3 : 1,
            maxLines: long ? 5 : 1,
            decoration: const InputDecoration(isDense: true),
            validator: (value) =>
                (value ?? '').trim().isEmpty ? 'This field is required' : null,
          ),
        );
      case SettingControl.select:
        control = SizedBox(
          width: 280,
          child: DropdownButtonFormField<String>(
            initialValue: d.options.contains(_values[d.key])
                ? _values[d.key]
                : d.defaultValue,
            decoration: const InputDecoration(isDense: true),
            items: d.options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: enabled
                ? (v) => setState(() => _values[d.key] = v ?? '')
                : null,
          ),
        );
      case SettingControl.multiSelect:
        final selected = (_values[d.key] ?? '')
            .split(',')
            .where((v) => v.isNotEmpty)
            .toSet();
        control = Wrap(
          spacing: 8,
          runSpacing: 6,
          children: d.options
              .map(
                (option) => FilterChip(
                  label: Text(option),
                  selected: selected.contains(option),
                  onSelected: enabled
                      ? (checked) => setState(() {
                          checked
                              ? selected.add(option)
                              : selected.remove(option);
                          _values[d.key] = selected.join(',');
                        })
                      : null,
                ),
              )
              .toList(),
        );
    }
    return Opacity(
      opacity: enabled ? 1 : .48,
      child: Padding(
        padding: EdgeInsets.fromLTRB(d.indented ? 24 : 0, 12, 0, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final label = Text(
              d.label,
              style: TextStyle(
                color: AppColors.text,
                fontWeight: d.indented ? FontWeight.w500 : FontWeight.w600,
                height: 1.35,
              ),
            );
            if (constraints.maxWidth < 680 ||
                d.control == SettingControl.multiSelect) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [label, const SizedBox(height: 10), control],
              );
            }
            return Row(
              children: [
                Expanded(child: label),
                const SizedBox(width: 24),
                control,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.devices_rounded,
                color: AppColors.navy,
                size: 20,
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            children[i],
          ],
        ],
      ),
    ),
  );
}

class _SaveBar extends StatelessWidget {
  final bool saving;
  final VoidCallback onSave;
  const _SaveBar({required this.saving, required this.onSave});
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    elevation: 10,
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: saving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(saving ? 'Saving…' : 'Save settings'),
          ),
        ),
      ),
    ),
  );
}

class _ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 44,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text('Could not load settings\n$error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
