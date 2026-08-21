// GENERATED DATA — do not edit by hand.
//
// Maps `prayer_times_country_lookups.country_id` (the bundled `prayer_times.db`
// country key) to an ISO 3166-1 alpha-2 code. The database itself carries no ISO
// codes, but `City.country` and [LocationDefaults] are keyed by them.
//
// Derivation: 211 of the 251 country rows matched the English country names of
// the previous `NewCountries.sqlite` asset (whose `CountriesIOS` table carried
// ISO codes); the remaining 40 were spelling variants assigned by hand.
// Validation: the 251 ids yield 251 distinct ISO codes, and ordering the map by
// `country_id` reproduces ISO alpha-2 alphabetical order except for `XK`, `SS`,
// `CS` and `AN` — exactly the user-assigned, late-added and deprecated codes one
// would expect to be appended out of sequence.
//
// Note: ids are not contiguous (they run 1–252 with one gap).

/// `country_id` → ISO 3166-1 alpha-2 country code.
const Map<int, String> kCountryIdToIso = {
  1: 'AD', // Andorra
  2: 'AE', // United Arab Emirates
  3: 'AF', // Afghanistan
  4: 'AG', // Antigua and Barbuda
  5: 'AI', // Anguilla
  6: 'AL', // Albania
  7: 'AM', // Armenia
  8: 'AO', // Angola
  9: 'AQ', // Antarctica
  10: 'AR', // Argentina
  11: 'AS', // American Samoa
  12: 'AT', // Austria
  13: 'AU', // Australia
  14: 'AW', // Aruba
  15: 'AX', // Aland Islands
  16: 'AZ', // Azerbaijan
  17: 'BA', // Bosnia and Herzegovina
  18: 'BB', // Barbados
  19: 'BD', // Bangladesh
  20: 'BE', // Belgium
  21: 'BF', // Burkina Faso
  22: 'BG', // Bulgaria
  23: 'BH', // Bahrain
  24: 'BI', // Burundi
  25: 'BJ', // Benin
  26: 'BL', // Saint Barthelemy
  27: 'BM', // Bermuda
  28: 'BN', // Brunei
  29: 'BO', // Bolivia
  30: 'BQ', // Bonaire, Saint Eustatius and Saba
  31: 'BR', // Brazil
  32: 'BS', // Bahamas
  33: 'BT', // Bhutan
  34: 'BV', // Bouvet Island
  35: 'BW', // Botswana
  36: 'BY', // Belarus
  37: 'BZ', // Belize
  38: 'CA', // Canada
  39: 'CC', // Cocos Islands
  40: 'CD', // Democratic Republic of the Congo
  41: 'CF', // Central African Republic
  42: 'CG', // Republic of the Congo
  43: 'CH', // Switzerland
  44: 'CI', // Ivory Coast
  45: 'CK', // Cook Islands
  46: 'CL', // Chile
  47: 'CM', // Cameroon
  48: 'CN', // China
  49: 'CO', // Colombia
  50: 'CR', // Costa Rica
  51: 'CU', // Cuba
  52: 'CV', // Cabo Verde
  53: 'CW', // Curacao
  54: 'CX', // Christmas Island
  55: 'CY', // Cyprus
  56: 'CZ', // Czechia
  57: 'DE', // Germany
  58: 'DJ', // Djibouti
  59: 'DK', // Denmark
  60: 'DM', // Dominica
  61: 'DO', // Dominican Republic
  62: 'DZ', // Algeria
  63: 'EC', // Ecuador
  64: 'EE', // Estonia
  65: 'EG', // Egypt
  66: 'EH', // Western Sahara
  67: 'ER', // Eritrea
  68: 'ES', // Spain
  69: 'ET', // Ethiopia
  70: 'FI', // Finland
  71: 'FJ', // Fiji
  72: 'FK', // Falkland Islands
  73: 'FM', // Micronesia
  74: 'FO', // Faroe Islands
  75: 'FR', // France
  76: 'GA', // Gabon
  77: 'GB', // United Kingdom
  78: 'GD', // Grenada
  79: 'GE', // Georgia
  80: 'GF', // French Guiana
  81: 'GG', // Guernsey
  82: 'GH', // Ghana
  83: 'GI', // Gibraltar
  84: 'GL', // Greenland
  85: 'GM', // Gambia
  86: 'GN', // Guinea
  87: 'GP', // Guadeloupe
  88: 'GQ', // Equatorial Guinea
  89: 'GR', // Greece
  90: 'GS', // South Georgia and the South Sandwich Islands
  91: 'GT', // Guatemala
  92: 'GU', // Guam
  93: 'GW', // Guinea-Bissau
  94: 'GY', // Guyana
  95: 'HK', // Hong Kong
  96: 'HM', // Heard Island and McDonald Islands
  97: 'HN', // Honduras
  98: 'HR', // Croatia
  99: 'HT', // Haiti
  100: 'HU', // Hungary
  101: 'ID', // Indonesia
  102: 'IE', // Ireland
  104: 'IM', // Isle of Man
  105: 'IN', // India
  106: 'IO', // British Indian Ocean Territory
  107: 'IQ', // Iraq
  108: 'IR', // Iran
  109: 'IS', // Iceland
  110: 'IT', // Italy
  111: 'JE', // Jersey
  112: 'JM', // Jamaica
  113: 'JO', // Jordan
  114: 'JP', // Japan
  115: 'KE', // Kenya
  116: 'KG', // Kyrgyzstan
  117: 'KH', // Cambodia
  118: 'KI', // Kiribati
  119: 'KM', // Comoros
  120: 'KN', // Saint Kitts and Nevis
  121: 'KP', // North Korea
  122: 'KR', // South Korea
  123: 'XK', // Kosovo
  124: 'KW', // Kuwait
  125: 'KY', // Cayman Islands
  126: 'KZ', // Kazakhstan
  127: 'LA', // Laos
  128: 'LB', // Lebanon
  129: 'LC', // Saint Lucia
  130: 'LI', // Liechtenstein
  131: 'LK', // Sri Lanka
  132: 'LR', // Liberia
  133: 'LS', // Lesotho
  134: 'LT', // Lithuania
  135: 'LU', // Luxembourg
  136: 'LV', // Latvia
  137: 'LY', // Libya
  138: 'MA', // Morocco
  139: 'MC', // Monaco
  140: 'MD', // Moldova
  141: 'ME', // Montenegro
  142: 'MF', // Saint Martin
  143: 'MG', // Madagascar
  144: 'MH', // Marshall Islands
  145: 'MK', // North Macedonia
  146: 'ML', // Mali
  147: 'MM', // Myanmar
  148: 'MN', // Mongolia
  149: 'MO', // Macao
  150: 'MP', // Northern Mariana Islands
  151: 'MQ', // Martinique
  152: 'MR', // Mauritania
  153: 'MS', // Montserrat
  154: 'MT', // Malta
  155: 'MU', // Mauritius
  156: 'MV', // Maldives
  157: 'MW', // Malawi
  158: 'MX', // Mexico
  159: 'MY', // Malaysia
  160: 'MZ', // Mozambique
  161: 'NA', // Namibia
  162: 'NC', // New Caledonia
  163: 'NE', // Niger
  164: 'NF', // Norfolk Island
  165: 'NG', // Nigeria
  166: 'NI', // Nicaragua
  167: 'NL', // Netherlands
  168: 'NO', // Norway
  169: 'NP', // Nepal
  170: 'NR', // Nauru
  171: 'NU', // Niue
  172: 'NZ', // New Zealand
  173: 'OM', // Oman
  174: 'PA', // Panama
  175: 'PE', // Peru
  176: 'PF', // French Polynesia
  177: 'PG', // Papua New Guinea
  178: 'PH', // Philippines
  179: 'PK', // Pakistan
  180: 'PL', // Poland
  181: 'PM', // Saint Pierre and Miquelon
  182: 'PN', // Pitcairn
  183: 'PR', // Puerto Rico
  184: 'PS', // Palestinian Territory
  185: 'PT', // Portugal
  186: 'PW', // Palau
  187: 'PY', // Paraguay
  188: 'QA', // Qatar
  189: 'RE', // Reunion
  190: 'RO', // Romania
  191: 'RS', // Serbia
  192: 'RU', // Russia
  193: 'RW', // Rwanda
  194: 'SA', // Saudi Arabia
  195: 'SB', // Solomon Islands
  196: 'SC', // Seychelles
  197: 'SD', // Sudan
  198: 'SS', // South Sudan
  199: 'SE', // Sweden
  200: 'SG', // Singapore
  201: 'SH', // Saint Helena
  202: 'SI', // Slovenia
  203: 'SJ', // Svalbard and Jan Mayen
  204: 'SK', // Slovakia
  205: 'SL', // Sierra Leone
  206: 'SM', // San Marino
  207: 'SN', // Senegal
  208: 'SO', // Somalia
  209: 'SR', // Suriname
  210: 'ST', // Sao Tome and Principe
  211: 'SV', // El Salvador
  212: 'SX', // Sint Maarten
  213: 'SY', // Syria
  214: 'SZ', // Eswatini
  215: 'TC', // Turks and Caicos Islands
  216: 'TD', // Chad
  217: 'TF', // French Southern Territories
  218: 'TG', // Togo
  219: 'TH', // Thailand
  220: 'TJ', // Tajikistan
  221: 'TK', // Tokelau
  222: 'TL', // Timor Leste
  223: 'TM', // Turkmenistan
  224: 'TN', // Tunisia
  225: 'TO', // Tonga
  226: 'TR', // Turkey
  227: 'TT', // Trinidad and Tobago
  228: 'TV', // Tuvalu
  229: 'TW', // Taiwan
  230: 'TZ', // Tanzania
  231: 'UA', // Ukraine
  232: 'UG', // Uganda
  233: 'UM', // United States Minor Outlying Islands
  234: 'US', // United States
  235: 'UY', // Uruguay
  236: 'UZ', // Uzbekistan
  237: 'VA', // Vatican
  238: 'VC', // Saint Vincent and the Grenadines
  239: 'VE', // Venezuela
  240: 'VG', // British Virgin Islands
  241: 'VI', // U.S. Virgin Islands
  242: 'VN', // Vietnam
  243: 'VU', // Vanuatu
  244: 'WF', // Wallis and Futuna
  245: 'WS', // Samoa
  246: 'YE', // Yemen
  247: 'YT', // Mayotte
  248: 'ZA', // South Africa
  249: 'ZM', // Zambia
  250: 'ZW', // Zimbabwe
  251: 'CS', // Serbia and Montenegro
  252: 'AN', // Netherlands Antilles
};

/// ISO 3166-1 alpha-2 country code → `country_id`, inverted from
/// [kCountryIdToIso] for country-filtered lookups.
final Map<String, int> kIsoToCountryId = {
  for (final entry in kCountryIdToIso.entries) entry.value: entry.key,
};

/// Standard-time UTC offsets, in minutes, for IANA zones whose offset is not a
/// whole number of hours.
///
/// `prayer_times_city_lookups.city_time_zone` stores whole hours only and
/// truncates toward zero (Tehran is recorded as `3`, not `3.5`), so these zones
/// must be resolved by `time_zone_id` instead. Legacy zone aliases and
/// fractional zones absent from the current data are included so the table stays
/// correct if the database is refreshed.
const Map<String, int> kFractionalZoneOffsetMinutes = {
  'America/St_Johns': -210,
  'Asia/Calcutta': 330,
  'Asia/Colombo': 330,
  'Asia/Kabul': 270,
  'Asia/Kathmandu': 345,
  'Asia/Katmandu': 345,
  'Asia/Kolkata': 330,
  'Asia/Rangoon': 390,
  'Asia/Tehran': 210,
  'Asia/Yangon': 390,
  'Australia/Adelaide': 570,
  'Australia/Broken_Hill': 570,
  'Australia/Darwin': 570,
  'Australia/Eucla': 525,
  'Australia/Lord_Howe': 630,
  'Indian/Cocos': 390,
  'Pacific/Chatham': 765,
  'Pacific/Marquesas': -570,
};
