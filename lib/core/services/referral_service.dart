/// Referral Service
/// Auto-appends professional referrals to AI responses for specific themes
///
/// Encourages professional help for:
/// - Mental health issues (therapy)
/// - Addiction (12-step programs, counseling)
/// - Eating disorders (NEDA hotline)
/// - Legal issues (attorney)
/// - Medical issues (doctor)

/// Professional referral information
class ProfessionalReferral {
  final String message;
  final String? hotline;
  final String? website;
  final ReferralType type;

  const ProfessionalReferral({
    required this.message,
    required this.type,
    this.hotline,
    this.website,
  });
}

/// Type of professional referral
enum ReferralType {
  therapy,
  addiction,
  eatingDisorder,
  medical,
  legal,
  pastoral,
}

/// Service for managing professional referrals
class ReferralService {
  /// Map of themes that require professional referrals
  static const Map<String, ReferralType> _themeReferrals = {
    // Mental health themes
    'anxiety_disorders': ReferralType.therapy,
    'depression': ReferralType.therapy,
    'panic_attacks': ReferralType.therapy,
    'trauma': ReferralType.therapy,
    'ptsd': ReferralType.therapy,
    'ocd': ReferralType.therapy,
    'social_anxiety': ReferralType.therapy,
    'burnout': ReferralType.therapy,
    'imposter_syndrome': ReferralType.therapy,
    'perfectionism': ReferralType.therapy,

    // Addiction
    'addiction': ReferralType.addiction,
    'substance_abuse': ReferralType.addiction,
    'alcohol': ReferralType.addiction,
    'drugs': ReferralType.addiction,
    'pornography': ReferralType.addiction,
    'gambling': ReferralType.addiction,

    // Eating disorders
    'eating_disorders': ReferralType.eatingDisorder,
    'anorexia': ReferralType.eatingDisorder,
    'bulimia': ReferralType.eatingDisorder,
    'binge_eating': ReferralType.eatingDisorder,

    // Medical issues
    'illness': ReferralType.medical,
    'chronic_pain': ReferralType.medical,
    'disability': ReferralType.medical,

    // Legal issues
    'divorce': ReferralType.legal,
    'custody': ReferralType.legal,
    'immigration': ReferralType.legal,

    // Pastoral care
    'church_hurt': ReferralType.pastoral,
    'spiritual_abuse': ReferralType.pastoral,
  };

  /// Get referral for a specific theme
  ProfessionalReferral? getReferral(String theme) {
    final referralType = _themeReferrals[theme.toLowerCase()];
    if (referralType == null) return null;

    return _getReferralByType(referralType);
  }

  /// Get referral by type
  ProfessionalReferral _getReferralByType(ReferralType type) {
    switch (type) {
      case ReferralType.therapy:
        return const ProfessionalReferral(
          type: ReferralType.therapy,
          message:
              'Consider speaking with a licensed therapist. Therapy is not a sign of weak faith - it\'s a practical tool for healing. You can find Christian counselors at Christian Counseling Network (ccn.thedirectoryonline.net).',
        );

      case ReferralType.addiction:
        return const ProfessionalReferral(
          type: ReferralType.addiction,
          message:
              'Recovery is possible with professional support. Consider:\n'
              '• Celebrate Recovery (12-step Christian program)\n'
              '• SAMHSA National Helpline: 1-800-662-4357 (free, confidential, 24/7)\n'
              '• Licensed addiction counselor\n'
              'You don\'t have to fight alone.',
          hotline: '1-800-662-4357',
          website: 'samhsa.gov',
        );

      case ReferralType.eatingDisorder:
        return const ProfessionalReferral(
          type: ReferralType.eatingDisorder,
          message:
              'Eating disorders require professional treatment. Please reach out:\n'
              '• NEDA Helpline: 1-800-931-2237 (Mon-Thu 9am-9pm ET, Fri 9am-5pm ET)\n'
              '• NEDA Crisis Text Line: Text "NEDA" to 741741\n'
              '• Work with an eating disorder specialist\n'
              'Your body is a temple, and healing is possible.',
          hotline: '1-800-931-2237',
          website: 'nationaleatingdisorders.org',
        );

      case ReferralType.medical:
        return const ProfessionalReferral(
          type: ReferralType.medical,
          message:
              'Please consult with a licensed medical doctor for diagnosis and treatment. This app cannot provide medical advice.',
        );

      case ReferralType.legal:
        return const ProfessionalReferral(
          type: ReferralType.legal,
          message:
              'Please consult with a licensed attorney for legal guidance. This app cannot provide legal advice.',
        );

      case ReferralType.pastoral:
        return const ProfessionalReferral(
          type: ReferralType.pastoral,
          message:
              'Consider connecting with a trusted pastor or spiritual director for one-on-one pastoral care. If you\'ve experienced spiritual abuse, find a trauma-informed counselor who understands religious contexts.',
        );
    }
  }

  /// Append referral to AI response
  /// Returns modified response with referral appended
  String appendReferral(String response, String theme) {
    final referral = getReferral(theme);
    if (referral == null) return response;

    // Add spacing and referral message
    const separator = '\n\n---\n\n';
    return '$response$separator📋 **Professional Support:**\n${referral.message}';
  }

  /// Check if theme requires referral
  bool requiresReferral(String theme) {
    return _themeReferrals.containsKey(theme.toLowerCase());
  }

  /// Get all themes that require referrals
  List<String> getThemesRequiringReferrals() {
    return _themeReferrals.keys.toList();
  }

  /// Get referral statistics (for monitoring)
  Map<ReferralType, int> getReferralStats() {
    // This would track how often each referral type is shown
    return {
      ReferralType.therapy: 0,
      ReferralType.addiction: 0,
      ReferralType.eatingDisorder: 0,
      ReferralType.medical: 0,
      ReferralType.legal: 0,
      ReferralType.pastoral: 0,
    };
  }
}
