import 'package:flutter/material.dart';
import '../../services/call_state_service.dart';
import '../../design_system/tokens/design_tokens.dart';

class CallerIdSetupScreen extends StatefulWidget {
  const CallerIdSetupScreen({super.key});

  @override
  State<CallerIdSetupScreen> createState() => _CallerIdSetupScreenState();
}

class _CallerIdSetupScreenState extends State<CallerIdSetupScreen> {
  bool _isChecking = true;
  bool _isRoleHeld = false;
  bool _isRequesting = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    setState(() => _isChecking = true);
    final isHeld = await CallStateService.instance.isCallScreeningRoleHeld();
    setState(() {
      _isRoleHeld = isHeld;
      _isChecking = false;
    });
  }

  Future<void> _requestRole() async {
    setState(() => _isRequesting = true);
    final granted = await CallStateService.instance.requestCallScreeningRole();
    setState(() => _isRequesting = false);

    if (granted) {
      setState(() => _isRoleHeld = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Call screening enabled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Call screening permission denied'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caller ID Protection Setup'),
      ),
      body: _isChecking
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _isRoleHeld
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isRoleHeld
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isRoleHeld ? Icons.check_circle : Icons.warning,
                          color: _isRoleHeld ? Colors.green : Colors.orange,
                          size: 48,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isRoleHeld
                                    ? 'Protection Active'
                                    : 'Setup Required',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isRoleHeld
                                    ? 'Caller ID protection is enabled'
                                    : 'Enable call screening to see caller risk',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Feature Explanation
                  const Text(
                    'How It Works',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildFeatureItem(
                    icon: Icons.phone_in_talk,
                    title: 'Real-Time Caller ID',
                    description:
                        'See caller phone numbers and risk scores before you answer',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    icon: Icons.shield,
                    title: 'Scam Detection',
                    description:
                        'Automatically cross-reference callers against 10,000+ reported scam numbers',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    icon: Icons.offline_bolt,
                    title: 'Works Offline',
                    description:
                        'Local database provides instant protection without internet',
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem(
                    icon: Icons.verified_user,
                    title: 'Carrier Verification',
                    description:
                        'STIR/SHAKEN verification detects caller ID spoofing',
                  ),

                  const SizedBox(height: 32),

                  // Privacy Note
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.privacy_tip, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Phone numbers are encrypted before transmission. No call audio is recorded.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Action Button
                  if (!_isRoleHeld)
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isRequesting ? null : _requestRole,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.colors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isRequesting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Enable Call Screening',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),

                  if (_isRoleHeld) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.check),
                        label: const Text(
                          'Setup Complete',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: _checkRole,
                        child: const Text('Refresh Status'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: DesignTokens.colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: DesignTokens.colors.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
