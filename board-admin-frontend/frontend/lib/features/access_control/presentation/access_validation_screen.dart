import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/role_access.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_status_chip.dart';
import '../../auth/provider/auth_provider.dart';
import '../../users/model/user_model.dart';
import '../../users/provider/user_provider.dart';
import '../provider/access_provider.dart';

String _userLabel(UserModel user) {
  final displayName = user.displayName?.trim();
  if (displayName != null && displayName.isNotEmpty) {
    return displayName == user.username
        ? displayName
        : '$displayName (${user.username})';
  }

  final fullName = '${user.firstName} ${user.lastName}'.trim();
  return fullName.isNotEmpty ? '$fullName (${user.username})' : user.username;
}

class AccessValidationScreen extends ConsumerStatefulWidget {
  const AccessValidationScreen({super.key});

  @override
  ConsumerState<AccessValidationScreen> createState() =>
      _AccessValidationScreenState();
}

class _AccessValidationScreenState
    extends ConsumerState<AccessValidationScreen> {
  int? selectedUserId;
  ({int userId, String channel})? submittedArgs;
  String channel = 'WEB';

  static const Color navy = Color(0xFF14275B);
  static const Color bgColor = Color(0xFFF6F7FC);
  static const Color cardColor = Colors.white;
  static const Color iconBg = Color(0xFFE9ECF3);
  static const Color arrowBg = Color(0xFFFFF1D8);
  static const Color subTextColor = Color(0xFF6E7FA8);

  void _validate() {
    final userId = selectedUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a user.')),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      submittedArgs = (userId: userId, channel: channel);
    });
  }

  @override
  Widget build(BuildContext context) {
    final access = RoleAccess(ref.watch(authProvider).role ?? 'MEMBER');

    if (!access.isAdmin) {
      return const Scaffold(
        backgroundColor: bgColor,
        body: Center(
          child: Text('You do not have access to access validation.'),
        ),
      );
    }

    final usersAsync = ref.watch(userListProvider);

    final asyncData = submittedArgs == null
        ? null
        : ref.watch(accessValidationProvider(submittedArgs!));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: navy,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Access Validation',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  usersAsync.when(
                    data: (users) => DropdownButtonFormField<int>(
                      initialValue: users.any(
                        (user) => user.id == selectedUserId,
                      )
                          ? selectedUserId
                          : null,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Select User',
                        prefixIcon: const Icon(
                          Icons.person_search_rounded,
                          color: navy,
                        ),
                        filled: true,
                        fillColor: iconBg.withOpacity(0.55),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: navy,
                            width: 1.4,
                          ),
                        ),
                      ),
                      hint: const Text('Choose a user'),
                      items: users
                          .map(
                            (user) => DropdownMenuItem<int>(
                              value: user.id,
                              child: Text(
                                _userLabel(user),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedUserId = value;
                          submittedArgs = null;
                        });
                      },
                    ),
                    loading: () => const SizedBox(
                      height: 56,
                      child: Center(child: LinearProgressIndicator()),
                    ),
                    error: (error, _) => _UserLoadError(
                      onRetry: () => ref.invalidate(userListProvider),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: channel,
                    decoration: InputDecoration(
                      labelText: 'Requested Channel',
                      prefixIcon: const Icon(
                        Icons.devices_rounded,
                        color: navy,
                      ),
                      filled: true,
                      fillColor: iconBg.withOpacity(0.55),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: navy, width: 1.4),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'WEB', child: Text('WEB')),
                      DropdownMenuItem(value: 'DEVICE', child: Text('DEVICE')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          channel = value;
                          submittedArgs = null;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: navy,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _validate,
                      icon: const Icon(Icons.verified_user_rounded),
                      label: const Text(
                        'Validate Access',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (asyncData == null)
              const _ValidationPrompt()
            else
              asyncData.when(
              data: (item) {
                final allowed = item.allowed;

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: allowed
                                  ? const Color(0xFFE8F7EE)
                                  : const Color(0xFFFFECEC),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              allowed
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              color: allowed
                                  ? const Color(0xFF168A45)
                                  : const Color(0xFFD64545),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.username,
                                  style: const TextStyle(
                                    color: navy,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  allowed
                                      ? 'User access is allowed'
                                      : 'User access is denied',
                                  style: const TextStyle(
                                    color: subTextColor,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AppStatusChip(label: allowed ? 'ALLOWED' : 'DENIED'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoTile(
                        icon: Icons.wifi_tethering_rounded,
                        title: 'Requested Channel',
                        value: item.requestedChannel,
                      ),
                      const SizedBox(height: 12),
                      _InfoTile(
                        icon: Icons.info_outline_rounded,
                        title: 'Reason',
                        value: item.reason,
                      ),
                    ],
                  ),
                );
              },
              error: (e, _) => Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  'Failed to validate access:\n$e',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 40),
                child: AppLoading(),
              ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UserLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _UserLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Could not load users.',
              style: TextStyle(
                color: Color(0xFFD64545),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ValidationPrompt extends StatelessWidget {
  const _ValidationPrompt();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF14275B)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Select a user and channel, then validate access.',
              style: TextStyle(
                color: Color(0xFF6E7FA8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  static const Color navy = Color(0xFF14275B);
  static const Color iconBg = Color(0xFFE9ECF3);
  static const Color subTextColor = Color(0xFF6E7FA8);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: iconBg.withOpacity(0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: navy, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: subTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
