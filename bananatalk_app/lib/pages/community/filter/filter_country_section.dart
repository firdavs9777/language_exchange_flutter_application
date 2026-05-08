import 'package:flutter/material.dart';
import 'package:bananatalk_app/l10n/app_localizations.dart';
import 'package:bananatalk_app/utils/theme_extensions.dart';
import 'package:bananatalk_app/core/theme/app_theme.dart';

/// Complete list of all countries with flags (alphabetically sorted).
const List<Map<String, String>> kAllCountries = [
  {'name': 'Afghanistan', 'code': 'AF', 'flag': '🇦🇫'},
  {'name': 'Albania', 'code': 'AL', 'flag': '🇦🇱'},
  {'name': 'Algeria', 'code': 'DZ', 'flag': '🇩🇿'},
  {'name': 'Andorra', 'code': 'AD', 'flag': '🇦🇩'},
  {'name': 'Angola', 'code': 'AO', 'flag': '🇦🇴'},
  {'name': 'Antigua and Barbuda', 'code': 'AG', 'flag': '🇦🇬'},
  {'name': 'Argentina', 'code': 'AR', 'flag': '🇦🇷'},
  {'name': 'Armenia', 'code': 'AM', 'flag': '🇦🇲'},
  {'name': 'Australia', 'code': 'AU', 'flag': '🇦🇺'},
  {'name': 'Austria', 'code': 'AT', 'flag': '🇦🇹'},
  {'name': 'Azerbaijan', 'code': 'AZ', 'flag': '🇦🇿'},
  {'name': 'Bahamas', 'code': 'BS', 'flag': '🇧🇸'},
  {'name': 'Bahrain', 'code': 'BH', 'flag': '🇧🇭'},
  {'name': 'Bangladesh', 'code': 'BD', 'flag': '🇧🇩'},
  {'name': 'Barbados', 'code': 'BB', 'flag': '🇧🇧'},
  {'name': 'Belarus', 'code': 'BY', 'flag': '🇧🇾'},
  {'name': 'Belgium', 'code': 'BE', 'flag': '🇧🇪'},
  {'name': 'Belize', 'code': 'BZ', 'flag': '🇧🇿'},
  {'name': 'Benin', 'code': 'BJ', 'flag': '🇧🇯'},
  {'name': 'Bhutan', 'code': 'BT', 'flag': '🇧🇹'},
  {'name': 'Bolivia', 'code': 'BO', 'flag': '🇧🇴'},
  {'name': 'Bosnia and Herzegovina', 'code': 'BA', 'flag': '🇧🇦'},
  {'name': 'Botswana', 'code': 'BW', 'flag': '🇧🇼'},
  {'name': 'Brazil', 'code': 'BR', 'flag': '🇧🇷'},
  {'name': 'Brunei', 'code': 'BN', 'flag': '🇧🇳'},
  {'name': 'Bulgaria', 'code': 'BG', 'flag': '🇧🇬'},
  {'name': 'Burkina Faso', 'code': 'BF', 'flag': '🇧🇫'},
  {'name': 'Burundi', 'code': 'BI', 'flag': '🇧🇮'},
  {'name': 'Cambodia', 'code': 'KH', 'flag': '🇰🇭'},
  {'name': 'Cameroon', 'code': 'CM', 'flag': '🇨🇲'},
  {'name': 'Canada', 'code': 'CA', 'flag': '🇨🇦'},
  {'name': 'Cape Verde', 'code': 'CV', 'flag': '🇨🇻'},
  {'name': 'Central African Republic', 'code': 'CF', 'flag': '🇨🇫'},
  {'name': 'Chad', 'code': 'TD', 'flag': '🇹🇩'},
  {'name': 'Chile', 'code': 'CL', 'flag': '🇨🇱'},
  {'name': 'China', 'code': 'CN', 'flag': '🇨🇳'},
  {'name': 'Colombia', 'code': 'CO', 'flag': '🇨🇴'},
  {'name': 'Comoros', 'code': 'KM', 'flag': '🇰🇲'},
  {'name': 'Congo', 'code': 'CG', 'flag': '🇨🇬'},
  {'name': 'Costa Rica', 'code': 'CR', 'flag': '🇨🇷'},
  {'name': 'Croatia', 'code': 'HR', 'flag': '🇭🇷'},
  {'name': 'Cuba', 'code': 'CU', 'flag': '🇨🇺'},
  {'name': 'Cyprus', 'code': 'CY', 'flag': '🇨🇾'},
  {'name': 'Czech Republic', 'code': 'CZ', 'flag': '🇨🇿'},
  {'name': 'Denmark', 'code': 'DK', 'flag': '🇩🇰'},
  {'name': 'Djibouti', 'code': 'DJ', 'flag': '🇩🇯'},
  {'name': 'Dominica', 'code': 'DM', 'flag': '🇩🇲'},
  {'name': 'Dominican Republic', 'code': 'DO', 'flag': '🇩🇴'},
  {'name': 'Ecuador', 'code': 'EC', 'flag': '🇪🇨'},
  {'name': 'Egypt', 'code': 'EG', 'flag': '🇪🇬'},
  {'name': 'El Salvador', 'code': 'SV', 'flag': '🇸🇻'},
  {'name': 'Equatorial Guinea', 'code': 'GQ', 'flag': '🇬🇶'},
  {'name': 'Eritrea', 'code': 'ER', 'flag': '🇪🇷'},
  {'name': 'Estonia', 'code': 'EE', 'flag': '🇪🇪'},
  {'name': 'Eswatini', 'code': 'SZ', 'flag': '🇸🇿'},
  {'name': 'Ethiopia', 'code': 'ET', 'flag': '🇪🇹'},
  {'name': 'Fiji', 'code': 'FJ', 'flag': '🇫🇯'},
  {'name': 'Finland', 'code': 'FI', 'flag': '🇫🇮'},
  {'name': 'France', 'code': 'FR', 'flag': '🇫🇷'},
  {'name': 'Gabon', 'code': 'GA', 'flag': '🇬🇦'},
  {'name': 'Gambia', 'code': 'GM', 'flag': '🇬🇲'},
  {'name': 'Georgia', 'code': 'GE', 'flag': '🇬🇪'},
  {'name': 'Germany', 'code': 'DE', 'flag': '🇩🇪'},
  {'name': 'Ghana', 'code': 'GH', 'flag': '🇬🇭'},
  {'name': 'Greece', 'code': 'GR', 'flag': '🇬🇷'},
  {'name': 'Grenada', 'code': 'GD', 'flag': '🇬🇩'},
  {'name': 'Guatemala', 'code': 'GT', 'flag': '🇬🇹'},
  {'name': 'Guinea', 'code': 'GN', 'flag': '🇬🇳'},
  {'name': 'Guinea-Bissau', 'code': 'GW', 'flag': '🇬🇼'},
  {'name': 'Guyana', 'code': 'GY', 'flag': '🇬🇾'},
  {'name': 'Haiti', 'code': 'HT', 'flag': '🇭🇹'},
  {'name': 'Honduras', 'code': 'HN', 'flag': '🇭🇳'},
  {'name': 'Hong Kong', 'code': 'HK', 'flag': '🇭🇰'},
  {'name': 'Hungary', 'code': 'HU', 'flag': '🇭🇺'},
  {'name': 'Iceland', 'code': 'IS', 'flag': '🇮🇸'},
  {'name': 'India', 'code': 'IN', 'flag': '🇮🇳'},
  {'name': 'Indonesia', 'code': 'ID', 'flag': '🇮🇩'},
  {'name': 'Iran', 'code': 'IR', 'flag': '🇮🇷'},
  {'name': 'Iraq', 'code': 'IQ', 'flag': '🇮🇶'},
  {'name': 'Ireland', 'code': 'IE', 'flag': '🇮🇪'},
  {'name': 'Israel', 'code': 'IL', 'flag': '🇮🇱'},
  {'name': 'Italy', 'code': 'IT', 'flag': '🇮🇹'},
  {'name': 'Ivory Coast', 'code': 'CI', 'flag': '🇨🇮'},
  {'name': 'Jamaica', 'code': 'JM', 'flag': '🇯🇲'},
  {'name': 'Japan', 'code': 'JP', 'flag': '🇯🇵'},
  {'name': 'Jordan', 'code': 'JO', 'flag': '🇯🇴'},
  {'name': 'Kazakhstan', 'code': 'KZ', 'flag': '🇰🇿'},
  {'name': 'Kenya', 'code': 'KE', 'flag': '🇰🇪'},
  {'name': 'Kiribati', 'code': 'KI', 'flag': '🇰🇮'},
  {'name': 'Kosovo', 'code': 'XK', 'flag': '🇽🇰'},
  {'name': 'Kuwait', 'code': 'KW', 'flag': '🇰🇼'},
  {'name': 'Kyrgyzstan', 'code': 'KG', 'flag': '🇰🇬'},
  {'name': 'Laos', 'code': 'LA', 'flag': '🇱🇦'},
  {'name': 'Latvia', 'code': 'LV', 'flag': '🇱🇻'},
  {'name': 'Lebanon', 'code': 'LB', 'flag': '🇱🇧'},
  {'name': 'Lesotho', 'code': 'LS', 'flag': '🇱🇸'},
  {'name': 'Liberia', 'code': 'LR', 'flag': '🇱🇷'},
  {'name': 'Libya', 'code': 'LY', 'flag': '🇱🇾'},
  {'name': 'Liechtenstein', 'code': 'LI', 'flag': '🇱🇮'},
  {'name': 'Lithuania', 'code': 'LT', 'flag': '🇱🇹'},
  {'name': 'Luxembourg', 'code': 'LU', 'flag': '🇱🇺'},
  {'name': 'Macau', 'code': 'MO', 'flag': '🇲🇴'},
  {'name': 'Madagascar', 'code': 'MG', 'flag': '🇲🇬'},
  {'name': 'Malawi', 'code': 'MW', 'flag': '🇲🇼'},
  {'name': 'Malaysia', 'code': 'MY', 'flag': '🇲🇾'},
  {'name': 'Maldives', 'code': 'MV', 'flag': '🇲🇻'},
  {'name': 'Mali', 'code': 'ML', 'flag': '🇲🇱'},
  {'name': 'Malta', 'code': 'MT', 'flag': '🇲🇹'},
  {'name': 'Marshall Islands', 'code': 'MH', 'flag': '🇲🇭'},
  {'name': 'Mauritania', 'code': 'MR', 'flag': '🇲🇷'},
  {'name': 'Mauritius', 'code': 'MU', 'flag': '🇲🇺'},
  {'name': 'Mexico', 'code': 'MX', 'flag': '🇲🇽'},
  {'name': 'Micronesia', 'code': 'FM', 'flag': '🇫🇲'},
  {'name': 'Moldova', 'code': 'MD', 'flag': '🇲🇩'},
  {'name': 'Monaco', 'code': 'MC', 'flag': '🇲🇨'},
  {'name': 'Mongolia', 'code': 'MN', 'flag': '🇲🇳'},
  {'name': 'Montenegro', 'code': 'ME', 'flag': '🇲🇪'},
  {'name': 'Morocco', 'code': 'MA', 'flag': '🇲🇦'},
  {'name': 'Mozambique', 'code': 'MZ', 'flag': '🇲🇿'},
  {'name': 'Myanmar', 'code': 'MM', 'flag': '🇲🇲'},
  {'name': 'Namibia', 'code': 'NA', 'flag': '🇳🇦'},
  {'name': 'Nauru', 'code': 'NR', 'flag': '🇳🇷'},
  {'name': 'Nepal', 'code': 'NP', 'flag': '🇳🇵'},
  {'name': 'Netherlands', 'code': 'NL', 'flag': '🇳🇱'},
  {'name': 'New Zealand', 'code': 'NZ', 'flag': '🇳🇿'},
  {'name': 'Nicaragua', 'code': 'NI', 'flag': '🇳🇮'},
  {'name': 'Niger', 'code': 'NE', 'flag': '🇳🇪'},
  {'name': 'Nigeria', 'code': 'NG', 'flag': '🇳🇬'},
  {'name': 'North Korea', 'code': 'KP', 'flag': '🇰🇵'},
  {'name': 'North Macedonia', 'code': 'MK', 'flag': '🇲🇰'},
  {'name': 'Norway', 'code': 'NO', 'flag': '🇳🇴'},
  {'name': 'Oman', 'code': 'OM', 'flag': '🇴🇲'},
  {'name': 'Pakistan', 'code': 'PK', 'flag': '🇵🇰'},
  {'name': 'Palau', 'code': 'PW', 'flag': '🇵🇼'},
  {'name': 'Palestine', 'code': 'PS', 'flag': '🇵🇸'},
  {'name': 'Panama', 'code': 'PA', 'flag': '🇵🇦'},
  {'name': 'Papua New Guinea', 'code': 'PG', 'flag': '🇵🇬'},
  {'name': 'Paraguay', 'code': 'PY', 'flag': '🇵🇾'},
  {'name': 'Peru', 'code': 'PE', 'flag': '🇵🇪'},
  {'name': 'Philippines', 'code': 'PH', 'flag': '🇵🇭'},
  {'name': 'Poland', 'code': 'PL', 'flag': '🇵🇱'},
  {'name': 'Portugal', 'code': 'PT', 'flag': '🇵🇹'},
  {'name': 'Puerto Rico', 'code': 'PR', 'flag': '🇵🇷'},
  {'name': 'Qatar', 'code': 'QA', 'flag': '🇶🇦'},
  {'name': 'Romania', 'code': 'RO', 'flag': '🇷🇴'},
  {'name': 'Russia', 'code': 'RU', 'flag': '🇷🇺'},
  {'name': 'Rwanda', 'code': 'RW', 'flag': '🇷🇼'},
  {'name': 'Saint Kitts and Nevis', 'code': 'KN', 'flag': '🇰🇳'},
  {'name': 'Saint Lucia', 'code': 'LC', 'flag': '🇱🇨'},
  {'name': 'Saint Vincent', 'code': 'VC', 'flag': '🇻🇨'},
  {'name': 'Samoa', 'code': 'WS', 'flag': '🇼🇸'},
  {'name': 'San Marino', 'code': 'SM', 'flag': '🇸🇲'},
  {'name': 'Sao Tome and Principe', 'code': 'ST', 'flag': '🇸🇹'},
  {'name': 'Saudi Arabia', 'code': 'SA', 'flag': '🇸🇦'},
  {'name': 'Senegal', 'code': 'SN', 'flag': '🇸🇳'},
  {'name': 'Serbia', 'code': 'RS', 'flag': '🇷🇸'},
  {'name': 'Seychelles', 'code': 'SC', 'flag': '🇸🇨'},
  {'name': 'Sierra Leone', 'code': 'SL', 'flag': '🇸🇱'},
  {'name': 'Singapore', 'code': 'SG', 'flag': '🇸🇬'},
  {'name': 'Slovakia', 'code': 'SK', 'flag': '🇸🇰'},
  {'name': 'Slovenia', 'code': 'SI', 'flag': '🇸🇮'},
  {'name': 'Solomon Islands', 'code': 'SB', 'flag': '🇸🇧'},
  {'name': 'Somalia', 'code': 'SO', 'flag': '🇸🇴'},
  {'name': 'South Africa', 'code': 'ZA', 'flag': '🇿🇦'},
  {'name': 'South Korea', 'code': 'KR', 'flag': '🇰🇷'},
  {'name': 'South Sudan', 'code': 'SS', 'flag': '🇸🇸'},
  {'name': 'Spain', 'code': 'ES', 'flag': '🇪🇸'},
  {'name': 'Sri Lanka', 'code': 'LK', 'flag': '🇱🇰'},
  {'name': 'Sudan', 'code': 'SD', 'flag': '🇸🇩'},
  {'name': 'Suriname', 'code': 'SR', 'flag': '🇸🇷'},
  {'name': 'Sweden', 'code': 'SE', 'flag': '🇸🇪'},
  {'name': 'Switzerland', 'code': 'CH', 'flag': '🇨🇭'},
  {'name': 'Syria', 'code': 'SY', 'flag': '🇸🇾'},
  {'name': 'Taiwan', 'code': 'TW', 'flag': '🇹🇼'},
  {'name': 'Tajikistan', 'code': 'TJ', 'flag': '🇹🇯'},
  {'name': 'Tanzania', 'code': 'TZ', 'flag': '🇹🇿'},
  {'name': 'Thailand', 'code': 'TH', 'flag': '🇹🇭'},
  {'name': 'Timor-Leste', 'code': 'TL', 'flag': '🇹🇱'},
  {'name': 'Togo', 'code': 'TG', 'flag': '🇹🇬'},
  {'name': 'Tonga', 'code': 'TO', 'flag': '🇹🇴'},
  {'name': 'Trinidad and Tobago', 'code': 'TT', 'flag': '🇹🇹'},
  {'name': 'Tunisia', 'code': 'TN', 'flag': '🇹🇳'},
  {'name': 'Turkey', 'code': 'TR', 'flag': '🇹🇷'},
  {'name': 'Turkmenistan', 'code': 'TM', 'flag': '🇹🇲'},
  {'name': 'Tuvalu', 'code': 'TV', 'flag': '🇹🇻'},
  {'name': 'Uganda', 'code': 'UG', 'flag': '🇺🇬'},
  {'name': 'Ukraine', 'code': 'UA', 'flag': '🇺🇦'},
  {'name': 'United Arab Emirates', 'code': 'AE', 'flag': '🇦🇪'},
  {'name': 'United Kingdom', 'code': 'GB', 'flag': '🇬🇧'},
  {'name': 'United States', 'code': 'US', 'flag': '🇺🇸'},
  {'name': 'Uruguay', 'code': 'UY', 'flag': '🇺🇾'},
  {'name': 'Uzbekistan', 'code': 'UZ', 'flag': '🇺🇿'},
  {'name': 'Vanuatu', 'code': 'VU', 'flag': '🇻🇺'},
  {'name': 'Vatican City', 'code': 'VA', 'flag': '🇻🇦'},
  {'name': 'Venezuela', 'code': 'VE', 'flag': '🇻🇪'},
  {'name': 'Vietnam', 'code': 'VN', 'flag': '🇻🇳'},
  {'name': 'Yemen', 'code': 'YE', 'flag': '🇾🇪'},
  {'name': 'Zambia', 'code': 'ZM', 'flag': '🇿🇲'},
  {'name': 'Zimbabwe', 'code': 'ZW', 'flag': '🇿🇼'},
];

/// Returns the flag emoji for [countryName], falling back to 🌍.
String getCountryFlag(String? countryName) {
  if (countryName == null) return '🌍';
  final country = kAllCountries.firstWhere(
    (c) => c['name'] == countryName,
    orElse: () => {'flag': '🌍'},
  );
  return country['flag'] ?? '🌍';
}

/// Country selector card + auto-detect button.
///
/// The auto-detect action and the open-picker action are callbacks so the
/// parent sheet continues to own all async state (location detection, etc.).
class FilterCountrySelector extends StatelessWidget {
  final String? selectedCountry;
  final bool isDetectingLocation;
  final VoidCallback onDetectLocation;
  final VoidCallback onOpenPicker;
  final VoidCallback onClear;

  const FilterCountrySelector({
    super.key,
    required this.selectedCountry,
    required this.isDetectingLocation,
    required this.onDetectLocation,
    required this.onOpenPicker,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Auto-detect location button
        GestureDetector(
          onTap: isDetectingLocation ? null : onDetectLocation,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: 14,
            ),
            margin: const EdgeInsets.only(bottom: Spacing.md),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: AppRadius.borderMD,
              boxShadow: AppShadows.colored,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isDetectingLocation)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        context.textOnPrimary,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.my_location,
                    color: context.textOnPrimary,
                    size: 20,
                  ),
                Spacing.hGapSM,
                Text(
                  isDetectingLocation
                      ? AppLocalizations.of(context)!.detecting
                      : AppLocalizations.of(context)!.autoDetectLocation,
                  style: context.labelLarge.copyWith(
                    color: context.textOnPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Country picker row
        InkWell(
          onTap: onOpenPicker,
          borderRadius: AppRadius.borderMD,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.lg,
            ),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: AppRadius.borderMD,
              border: Border.all(color: context.dividerColor),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: Spacing.md),
                  child: Text(
                    getCountryFlag(selectedCountry),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                Expanded(
                  child: Text(
                    selectedCountry ?? AppLocalizations.of(context)!.anyCountry,
                    style: context.titleMedium.copyWith(
                      color: selectedCountry != null
                          ? context.textPrimary
                          : context.textSecondary,
                    ),
                  ),
                ),
                if (selectedCountry != null)
                  GestureDetector(
                    onTap: onClear,
                    child: Container(
                      padding: const EdgeInsets.all(Spacing.xs),
                      decoration: BoxDecoration(
                        color: context.containerColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: context.textSecondary,
                      ),
                    ),
                  ),
                Spacing.hGapSM,
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: context.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Standalone bottom sheet for picking a country from [kAllCountries].
class CountryPickerSheet extends StatefulWidget {
  final String? selectedCountry;
  final Function(String?) onSelect;

  const CountryPickerSheet({
    super.key,
    this.selectedCountry,
    required this.onSelect,
  });

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, String>> _filteredCountries = [];

  @override
  void initState() {
    super.initState();
    _filteredCountries = kAllCountries;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = kAllCountries;
      } else {
        _filteredCountries = kAllCountries
            .where(
              (c) =>
                  c['name']!.toLowerCase().contains(query.toLowerCase()) ||
                  c['code']!.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: Spacing.md),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(Spacing.lg),
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context)!.selectCountry,
                  style: context.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => widget.onSelect(null),
                  child: Text(
                    AppLocalizations.of(context)!.anyCountry,
                    style: context.labelLarge.copyWith(
                      color: context.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: TextField(
              controller: _searchController,
              onChanged: _filterCountries,
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchCountry,
                hintStyle: context.bodyMedium.copyWith(
                  color: context.textMuted,
                ),
                prefixIcon: Icon(Icons.search, color: context.textMuted),
                filled: true,
                fillColor: context.containerColor,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.borderMD,
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.md,
                ),
              ),
            ),
          ),

          Spacing.gapSM,

          // Country list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
              itemCount: _filteredCountries.length,
              itemBuilder: (context, index) {
                final country = _filteredCountries[index];
                final isSelected = country['name'] == widget.selectedCountry;

                return ListTile(
                  onTap: () => widget.onSelect(country['name']),
                  leading: Text(
                    country['flag']!,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    country['name']!,
                    style: context.titleSmall.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? context.primaryColor
                          : context.textPrimary,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: context.primaryColor)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppRadius.borderMD,
                  ),
                  tileColor: isSelected
                      ? context.primaryColor.withValues(alpha: 0.1)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
