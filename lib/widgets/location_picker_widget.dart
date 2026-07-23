import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:skillpay/theme/app_theme.dart';

// ── Bundled fallback data ────────────────────────────────────────────────────
// A small but usable dataset for major countries so the picker works even
// when the countriesnow API is unreachable.
const Map<String, List<String>> _fallbackStates = {
  'United States': [
    'Alabama','Alaska','Arizona','Arkansas','California','Colorado',
    'Connecticut','Delaware','Florida','Georgia','Hawaii','Idaho',
    'Illinois','Indiana','Iowa','Kansas','Kentucky','Louisiana','Maine',
    'Maryland','Massachusetts','Michigan','Minnesota','Mississippi',
    'Missouri','Montana','Nebraska','Nevada','New Hampshire',
    'New Jersey','New Mexico','New York','North Carolina','North Dakota',
    'Ohio','Oklahoma','Oregon','Pennsylvania','Rhode Island',
    'South Carolina','South Dakota','Tennessee','Texas','Utah','Vermont',
    'Virginia','Washington','West Virginia','Wisconsin','Wyoming',
  ],
  'Nigeria': [
    'Abia','Adamawa','Akwa Ibom','Anambra','Bauchi','Bayelsa','Benue',
    'Borno','Cross River','Delta','Ebonyi','Edo','Ekiti','Enugu','Gombe',
    'Imo','Jigawa','Kaduna','Kano','Katsina','Kebbi','Kogi','Kwara',
    'Lagos','Nasarawa','Niger','Ogun','Ondo','Osun','Oyo','Plateau',
    'Rivers','Sokoto','Taraba','Yobe','Zamfara','FCT',
  ],
  'United Kingdom': [
    'England','Scotland','Wales','Northern Ireland',
  ],
  'Canada': [
    'Alberta','British Columbia','Manitoba','New Brunswick',
    'Newfoundland and Labrador','Nova Scotia','Ontario',
    'Prince Edward Island','Quebec','Saskatchewan',
  ],
  'Australia': [
    'New South Wales','Victoria','Queensland','Western Australia',
    'South Australia','Tasmania','ACT','Northern Territory',
  ],
  'Ghana': [
    'Ahafo','Ashanti','Bono','Bono East','Central','Eastern',
    'Greater Accra','North East','Northern','Oti','Savannah',
    'Upper East','Upper West','Volta','Western','Western North',
  ],
  'South Africa': [
    'Eastern Cape','Free State','Gauteng','KwaZulu-Natal','Limpopo',
    'Mpumalanga','North West','Northern Cape','Western Cape',
  ],
  'India': [
    'Andhra Pradesh','Arunachal Pradesh','Assam','Bihar','Chhattisgarh',
    'Goa','Gujarat','Haryana','Himachal Pradesh','Jharkhand','Karnataka',
    'Kerala','Madhya Pradesh','Maharashtra','Manipur','Meghalaya','Mizoram',
    'Nagaland','Odisha','Punjab','Rajasthan','Sikkim','Tamil Nadu',
    'Telangana','Tripura','Uttar Pradesh','Uttarakhand','West Bengal',
  ],
  'Germany': [
    'Baden-Württemberg','Bavaria','Berlin','Brandenburg','Bremen',
    'Hamburg','Hesse','Lower Saxony','Mecklenburg-Vorpommern',
    'North Rhine-Westphalia','Rhineland-Palatinate','Saarland','Saxony',
    'Saxony-Anhalt','Schleswig-Holstein','Thuringia',
  ],
};

// ─────────────────────────────────────────────────────────────────────────────

class LocationPickerWidget extends StatefulWidget {
  final void Function(String country, String state, String city) onChanged;

  const LocationPickerWidget({super.key, required this.onChanged});

  @override
  State<LocationPickerWidget> createState() => _LocationPickerWidgetState();
}

class _LocationPickerWidgetState extends State<LocationPickerWidget> {
  String? _selectedCountry;
  String? _selectedState;
  String? _selectedCity;

  List<String> _countries = [];
  List<String> _states = [];
  List<String> _cities = [];

  bool _loadingCountries = true;
  bool _loadingStates = false;
  bool _loadingCities = false;

  static const String _baseUrl = 'https://countriesnow.space/api/v0.1';

  @override
  void initState() {
    super.initState();
    _loadCountries();
  }

  Future<void> _loadCountries() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/countries/positions'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'];
        if (mounted) {
          setState(() {
            _countries = list.map((e) => e['name'].toString()).toList()..sort();
            _loadingCountries = false;
          });
        }
        return;
      }
    } catch (_) {}
    // Fallback to bundled list
    if (mounted) {
      setState(() {
        _countries = [
          'Australia','Bangladesh','Brazil','Canada','China','Colombia',
          'Egypt','Ethiopia','France','Germany','Ghana','India','Indonesia',
          'Iraq','Ireland','Italy','Japan','Kenya','Malaysia','Mexico',
          'Morocco','Netherlands','New Zealand','Nigeria','Norway',
          'Pakistan','Philippines','Poland','Portugal','Qatar',
          'Romania','Russia','Saudi Arabia','Senegal','Singapore',
          'South Africa','South Korea','Spain','Sri Lanka','Sweden',
          'Switzerland','Tanzania','Thailand','Turkey','Uganda','Ukraine',
          'United Arab Emirates','United Kingdom','United States','Venezuela',
          'Vietnam','Zimbabwe',
        ]..sort();
        _loadingCountries = false;
      });
    }
  }

  Future<void> _loadStates(String country) async {
    setState(() {
      _loadingStates = true;
      _states = [];
      _cities = [];
      _selectedState = null;
      _selectedCity = null;
    });

    // Try API first, then bundled fallback
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/countries/states'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'country': country}),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List statesList = data['data']['states'];
        final apiStates = statesList.map((s) => s['name'].toString()).toList()..sort();
        if (apiStates.isNotEmpty && mounted) {
          setState(() {
            _states = apiStates;
            _loadingStates = false;
          });
          return;
        }
      }
    } catch (_) {}

    // Fallback to bundled data
    if (mounted) {
      setState(() {
        _states = List<String>.from(_fallbackStates[country] ?? []);
        _loadingStates = false;
      });
    }
  }

  Future<void> _loadCities(String country, String state) async {
    setState(() {
      _loadingCities = true;
      _cities = [];
      _selectedCity = null;
    });
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/countries/state/cities'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'country': country, 'state': state}),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['data'];
        if (list.isNotEmpty && mounted) {
          setState(() {
            _cities = list.map((c) => c.toString()).toList()..sort();
            _loadingCities = false;
          });
          return;
        }
      }
    } catch (_) {}
    // Fallback: free-type city
    if (mounted) {
      setState(() {
        _cities = [];
        _loadingCities = false;
      });
    }
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
    bool loading = false,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: enabled ? Colors.white : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: enabled ? const Color(0xFFD0D0D0) : const Color(0xFFEEEEEE),
            ),
          ),
          child: loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      SizedBox(width: 12),
                      Text('Loading...'),
                    ],
                  ),
                )
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: (value != null && items.contains(value)) ? value : null,
                    hint: Text(
                      'Select $label',
                      style: GoogleFonts.outfit(
                        color: enabled ? const Color(0xFFAAAAAA) : const Color(0xFFCCCCCC),
                        fontSize: 15,
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: enabled ? AppColors.textMedium : const Color(0xFFCCCCCC),
                    ),
                    style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textDark),
                    onChanged: enabled ? onChanged : null,
                    items: items.map((String item) {
                      return DropdownMenuItem<String>(
                        value: item,
                        child: Text(item, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdown(
          label: 'Country',
          value: _selectedCountry,
          items: _countries,
          loading: _loadingCountries,
          onChanged: (val) {
            setState(() => _selectedCountry = val);
            if (val != null) _loadStates(val);
            widget.onChanged(val ?? '', '', '');
          },
        ),
        const SizedBox(height: 16),
        _buildDropdown(
          label: 'State / Province',
          value: _selectedState,
          items: _states,
          loading: _loadingStates,
          enabled: _selectedCountry != null && !_loadingStates,
          onChanged: (val) {
            setState(() => _selectedState = val);
            if (_selectedCountry != null && val != null) {
              _loadCities(_selectedCountry!, val);
            }
            widget.onChanged(_selectedCountry ?? '', val ?? '', '');
          },
        ),
        const SizedBox(height: 16),
        // City: dropdown if we have data, text field if empty
        _cities.isNotEmpty
            ? _buildDropdown(
                label: 'City',
                value: _selectedCity,
                items: _cities,
                loading: _loadingCities,
                enabled: _selectedState != null && !_loadingCities,
                onChanged: (val) {
                  setState(() => _selectedCity = val);
                  widget.onChanged(
                    _selectedCountry ?? '',
                    _selectedState ?? '',
                    val ?? '',
                  );
                },
              )
            : _CityTextField(
                enabled: _selectedState != null,
                loading: _loadingCities,
                onChanged: (val) {
                  _selectedCity = val;
                  widget.onChanged(
                    _selectedCountry ?? '',
                    _selectedState ?? '',
                    val,
                  );
                },
              ),
      ],
    );
  }
}

/// Fallback city text input when API returns no city list
class _CityTextField extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final void Function(String) onChanged;

  const _CityTextField({
    required this.enabled,
    required this.loading,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'City',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textMedium,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          enabled: enabled && !loading,
          onChanged: onChanged,
          style: GoogleFonts.outfit(fontSize: 15, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: loading ? 'Loading cities...' : 'Enter city name',
            hintStyle: GoogleFonts.outfit(color: const Color(0xFFBDBDBD), fontSize: 15),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            filled: true,
            fillColor: enabled ? Colors.white : const Color(0xFFF5F5F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEEEEEE)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
