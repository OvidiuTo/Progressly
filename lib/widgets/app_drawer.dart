import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/styles.dart';
import '../providers/route_provider.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  bool _notificationsEnabled = false;

  @override
  Widget build(BuildContext context) {
    final currentRoute = RouteProvider.instance.currentRoute;
    final authService = AuthService();

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 180,
              child: DrawerHeader(
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.person,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: FutureBuilder<String?>(
                        future: authService.getUsername(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  snapshot.data!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                FutureBuilder<String?>(
                                  future: authService.getUserEmail(),
                                  builder: (context, emailSnapshot) {
                                    if (emailSnapshot.hasData) {
                                      return Text(
                                        emailSnapshot.data!,
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.8),
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ],
                            );
                          }
                          return FutureBuilder<String?>(
                            future: authService.getUserEmail(),
                            builder: (context, emailSnapshot) {
                              if (emailSnapshot.hasData) {
                                return Text(
                                  emailSnapshot.data!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(
                        Icons.home,
                        color: AppColors.textPrimary,
                      ),
                      title: Text(
                        'Home',
                        style: TextStyle(
                          color: currentRoute == '/home'
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/home');
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.person,
                        color: AppColors.textPrimary,
                      ),
                      title: Text(
                        'Profile',
                        style: TextStyle(
                          color: currentRoute == '/profile'
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/profile');
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.bar_chart,
                        color: AppColors.textPrimary,
                      ),
                      title: Text(
                        'Statistics',
                        style: TextStyle(
                          color: currentRoute == '/statistics'
                              ? AppColors.primary
                              : AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/statistics');
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                    ),
                    ListTile(
                      leading: Icon(
                        _notificationsEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: AppColors.textPrimary,
                      ),
                      title: const Text(
                        'Notifications',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Switch(
                        value: _notificationsEnabled,
                        onChanged: (value) {
                          setState(() {
                            _notificationsEnabled = value;
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.logout,
                color: AppColors.error,
              ),
              title: const Text(
                'Log Out',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () async {
                await AuthService().signOut();
                if (context.mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 8,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
