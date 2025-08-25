import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/analytics_service.dart';
import '../services/coppa_compliance_service.dart';

class AnalyticsConsentScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onConsentGiven;
  final VoidCallback onConsentDenied;

  const AnalyticsConsentScreen({
    Key? key,
    required this.profile,
    required this.onConsentGiven,
    required this.onConsentDenied,
  }) : super(key: key);

  @override
  State<AnalyticsConsentScreen> createState() => _AnalyticsConsentScreenState();
}

class _AnalyticsConsentScreenState extends State<AnalyticsConsentScreen> {
  bool _isLoading = false;
  String _message = '';
  bool _isChild = false;
  bool _requiresParentalConsent = false;

  @override
  void initState() {
    super.initState();
    _checkConsentRequirements();
  }

  Future<void> _checkConsentRequirements() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user is a child
      _isChild = widget.profile.role == UserRole.child;

      if (_isChild) {
        // Check if parental consent is required
        final coppaService = COPPAComplianceService();
        _requiresParentalConsent = await coppaService.isConsentRequired(widget.profile);
      }

      // Request consent through analytics service
      final analyticsService = AnalyticsService();
      final consentResult = await analyticsService.requestConsent(widget.profile);

      setState(() {
        _message = consentResult.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _message = 'Error checking consent requirements: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _grantConsent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analyticsService = AnalyticsService();
      
      // Create consent details
      final consentDetails = ConsentDetails(
        consentId: 'consent_${DateTime.now().millisecondsSinceEpoch}',
        consentedAt: DateTime.now(),
        allowedEventTypes: [
          'app_launch',
          'feature_usage',
          'user_interaction',
          'error',
        ],
        allowDataSharing: false, // Default to not sharing data
        consentVersion: '1.0',
      );

      // Grant consent
      await analyticsService.grantConsent(widget.profile.id, consentDetails);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Notify parent widget
        widget.onConsentGiven();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Error granting consent: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _denyConsent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analyticsService = AnalyticsService();
      
      // Deny consent
      await analyticsService.denyConsent(widget.profile.id);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Notify parent widget
        widget.onConsentDenied();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _message = 'Error denying consent: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Analytics Consent'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Help Us Improve',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'We would like to collect anonymous usage data to help us improve the app and understand how people use it.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              const Text(
                'What we collect:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildBulletPoint('App launch and usage statistics'),
              _buildBulletPoint('Feature usage patterns'),
              _buildBulletPoint('Error reports to help fix bugs'),
              _buildBulletPoint('Device information (type, OS version)'),
              const SizedBox(height: 20),
              const Text(
                'What we DO NOT collect:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildBulletPoint('Personal messages or communication content'),
              _buildBulletPoint('Personal identification information'),
              _buildBulletPoint('Location data'),
              _buildBulletPoint('Contact information'),
              const SizedBox(height: 20),
              if (_isChild && _requiresParentalConsent) ...[
                const Text(
                  'Parental Consent Required',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Since this is a child profile, a parent or guardian must provide consent for analytics collection.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
              ],
              if (_message.isNotEmpty) ...[
                Text(
                  _message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 20),
              ],
              const Spacer(),
              if (_isLoading) ...[
                const Center(
                  child: CupertinoActivityIndicator(
                    radius: 20,
                  ),
                ),
                const SizedBox(height: 20),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _grantConsent,
                    child: const Text('Allow Analytics'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    onPressed: _denyConsent,
                    child: const Text('No Thanks'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'You can change this setting anytime in the app settings.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}