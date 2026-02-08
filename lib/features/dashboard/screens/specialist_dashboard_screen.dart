import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../../../core/user_model.dart';

import '../../../services/pdf_service.dart';
import '../../../services/blockchain_service.dart';
import 'package:open_file/open_file.dart';
import '../../professional/screens/demo_call_screen.dart';

class SpecialistDashboardScreen extends StatelessWidget {
  final UserData specialist;
  const SpecialistDashboardScreen({super.key, required this.specialist});

  Future<void> _generateAndOpenPlan(BuildContext context, String name, String type) async {
    // Simulated patient data for PDF
    final patient = UserData(
      name: name,
      email: '${name.toLowerCase().replaceAll(' ', '.')}@example.com',
      age: type == 'Senior Citizen' ? 65 : 28,
      gender: 'Male',
      category: type,
      weight: 72,
      height: 175,
    );

    final exercises = type == 'Working Professional' 
      ? ['Cobra Stretch', 'Desk Neck Stretches', 'Lower Back Rotations']
      : ['Mountain Pose', 'Cat-Cow Stretch', 'Gentle Neck Rolls'];

    final file = await PdfService.generateHealthPlan(patient, 'Yoga', exercises);
    
    // Anchor to Blockchain
    final record = {
      'patient': name,
      'type': 'Health Plan',
      'timestamp': DateTime.now().toIso8601String(),
    };
    final recordHash = BlockchainService.generateRecordHash(record);
    final txHash = await BlockchainService.anchorToBlockchain(recordHash);

    if (context.mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Plan Anchored on Solana! Tx: ${txHash.substring(0, 10)}...'),
          action: SnackBarAction(label: 'View', onPressed: () {}),
        ),
      );
    }

    await OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Specialist Portal', style: GoogleFonts.outfit(fontSize: 14, color: AppColors.textLight)),
            Text(specialist.name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
          ],
        ),
        actions: [
          if (specialist.isAbhaVerified)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Chip(
                avatar: const Icon(Icons.verified_rounded, color: Colors.white, size: 16),
                label: const Text('ABHA Verified', style: TextStyle(color: Colors.white, fontSize: 10)),
                backgroundColor: AppColors.secondary,
                padding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatGrid(context),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Patients', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                TextButton(onPressed: () {}, child: const Text('View All')),
              ],
            ),
            const SizedBox(height: 16),
            _buildConsultationCard(context, 'Rudraksh Zodage', 'Working Professional', '09:00 AM', 'Weight Loss'),
            _buildConsultationCard(context, 'Sneha Kapoor', 'Housewife', '12:15 PM', 'Diet Planning'),
            const SizedBox(height: 32),
            Text('Health Shared reports', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildReportCard(context, 'Blood_Report_Rudraksh.pdf', 'Just now'),
            _buildReportCard(context, 'MRI_Sneha.jpg', '2 hours ago'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatItem(context, 'Total Patients', '128', Icons.people_outline, Colors.blue),
        _buildStatItem(context, 'Pending Reports', '5', Icons.description_outlined, Colors.orange),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening $label...')));
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildConsultationCard(BuildContext context, String name, String type, String time, String reason) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: AppColors.primary.withOpacity(0.1), child: Text(name[0])),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('$type • $reason', style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                  ],
                ),
              ),
              Text(time, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _generateAndOpenPlan(context, name, type),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                  label: const Text('Generate PDF Plan', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showSessionOptions(context),
                  icon: const Icon(Icons.videocam_rounded, size: 16),
                  label: const Text('Start/Join Call', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSessionOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Video Consultation', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _createNewSession(context);
              },
              icon: const Icon(Icons.add_call),
              label: const Text('Create New Session'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/join-session');
              },
              icon: const Icon(Icons.keyboard_alt_outlined),
              label: const Text('Join with Code'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }

  void _createNewSession(BuildContext context) {
    // Generate a random 6-digit code
    final String code = (100000 + DateTime.now().millisecondsSinceEpoch % 900000).toString();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Session Created'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this code with your patient:'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(code, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.copy, color: AppColors.primary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: code));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!')));
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DemoCallScreen(channelId: code)),
              );
            },
            child: const Text('Start Call'),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context, String title, String time) {
    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Opening $title...')));
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 14))),
            Text(time, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
