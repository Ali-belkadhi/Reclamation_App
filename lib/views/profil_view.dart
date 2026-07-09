import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme/app_theme.dart';

class ProfilView extends StatelessWidget {
  final User user;
  final VoidCallback onLogout;
  final Color primaryColor;

  const ProfilView({
    super.key,
    required this.user,
    required this.onLogout,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: primaryColor.withAlpha(20),
                  child: Text(
                    user.prenom.isNotEmpty
                        ? '${user.prenom[0]}${user.nom[0]}'.toUpperCase()
                        : user.nom.substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border.withAlpha(140)),
            ),
            child: Column(
              children: [
                _buildProfileDetailRow(
                  Icons.email_outlined,
                  'Adresse e-mail',
                  user.email,
                ),
                const Divider(color: AppColors.border, height: 24),
                _buildProfileDetailRow(
                  Icons.phone_iphone_outlined,
                  'Téléphone',
                  user.telephone ?? 'Non spécifié',
                ),
                const Divider(color: AppColors.border, height: 24),
                _buildProfileDetailRow(
                  Icons.badge_outlined,
                  'CIN',
                  user.cin ?? 'Non spécifié',
                ),
                const Divider(color: AppColors.border, height: 24),
                _buildProfileDetailRow(
                  Icons.account_balance_outlined,
                  'Agence',
                  user.agence?.nom ?? 'Non spécifiée',
                ),
                if (user.equipe != null) ...[
                  const Divider(color: AppColors.border, height: 24),
                  _buildProfileDetailRow(
                    Icons.groups_outlined,
                    'ID équipe',
                    user.equipe!.nom.toString(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {
                debugPrint('Déconnexion cliquée...');
                onLogout();
              },
              icon: const Icon(
                Icons.logout_rounded,
                color: AppColors.primaryRed,
              ),
              label: const Text(
                'SE DÉCONNECTER',
                style: TextStyle(
                  color: AppColors.primaryRed,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryRed, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.textLight, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textLight,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
