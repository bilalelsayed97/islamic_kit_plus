/// Islamic holidays keyed by [hijriMonth][hijriDay] -> list of event names.
/// Ported verbatim from islamic-network/calendar Holydays.php.
const Map<int, Map<int, List<String>>> kHijriHolidays =
    <int, Map<int, List<String>>>{
  1: <int, List<String>>{
    1: <String>['Birth of Khas Muhammad ash-Shirwani ق'],
    9: <String>['Urs of Sayyidina Qāsim ibn Muḥammad ibn Abī Bakr ق'],
    10: <String>[
      'Ashura',
      'Urs of Shaykh Shamsuddin Habīb Allah ق',
      'Urs of Shaykh Abū al‑Hassan al‑Kharqāni ق',
      'Birth of Imam Rābbani Ahmad Al-Fāruqi As-Sirhindi ق'
    ],
    14: <String>['Birth of Khwaja Bahauddin Shah Naqshband ق'],
    16: <String>['Birth of Shaykh Jamaluddin al-Ghumuqi al-Husayni ق'],
    17: <String>['Urs of Shaykh Muhammad Effendi al‑Yaraghi ق'],
    19: <String>['Urs of Shaykh Darwish Muhammad ق'],
    25: <String>['Urs of Sayyidina Ali ibn Zayn al-Abidin ق'],
  },
  2: <int, List<String>>{
    1: <String>['End of the holy months'],
    5: <String>['Urs of Shaykh Yaʿqub al-Charkhi (ق)'],
    12: <String>['Urs of Shaykh Abdullah Dahlawi (ق)'],
    17: <String>['Urs of Imam Rabbani Ahmad al-Faruqi as-Sirhindi (ق)'],
    28: <String>['Martyrdom of Sayyidina al-Hassan al-Mujtaba (ر)'],
  },
  3: <int, List<String>>{
    3: <String>['Urs of Shaykh Bahaʾuddin Shah Naqshband ق'],
    6: <String>['Birth of Mawlāna Jalāluddīn Rūmi ق'],
    9: <String>['Urs of Shaykh Muhammad al-Masūm ق'],
    12: <String>[
      'Mawlid (Birth) al-Nabi ﷺ',
      'Veiling of the Prophet Muhammad ﷺ',
      'Birth of Mawlana Shaykh Abdullāh al Dāghestāni ق',
      'Urs of Shaykh Abu Yāqub Yūsuf al-Hamadāni ق',
      'Urs of Shaykh Abdul Khāliq al-Ghujdawāni ق',
      'Urs of Mawlāna Ubaydullaāh Ahrār ق',
      'Urs of Shaykh Muhammad az-Zāhid ق'
    ],
    17: <String>[
      'Urs of Shaykh Mahmūd al-Anjir al-Faghnāwi ق',
      'Urs of Shaykh Abu Ahmad as-Sughūri ق'
    ],
    18: <String>['Urs of Shaykh Adnān Kabbāni ق'],
  },
  4: <int, List<String>>{
    11: <String>['Urs of Shaykh Abdul Qadir Jilāni ق'],
    14: <String>['Urs of Imām Abu Hamīd al-Ghazzāli ق'],
    22: <String>['Urs of Shaykh Muhiyuddīn Ibn al-‘Arabi ق'],
  },
  5: <int, List<String>>{
    27: <String>['Urs of Shaykh Sharafuddīn ad-Daghestāni ق'],
  },
  6: <int, List<String>>{
    3: <String>['Urs of Mawlānā Shaykh Hishām Kabbāni ق'],
    10: <String>['Urs of Muhammad Bābā as-Samasi ق'],
    14: <String>['Urs of Muhammad Bāqi Billāh  ق'],
  },
  7: <int, List<String>>{
    1: <String>['Beginning of the holy months'],
    6: <String>['Urs of Hadhrat Shaykh Moīn al-Dīn Chishti (ق)'],
    8: <String>['Urs of Mawlāna Shaykh Nāzim al-Haqqāni (ق)'],
    13: <String>['Birth of Sayyidina `Ali ibn Abi Talib (ر)'],
    15: <String>[
      'Urs of Sayyidina Jāfar as-Sādiq (ق)',
      'Urs of Zaynab bint Ali (ر)'
    ],
    27: <String>['Lailat-ul-Miraj'],
  },
  8: <int, List<String>>{
    3: <String>['Birth of Sayyidina Husayn ibn `Ali (ر)'],
    4: <String>['Birth of Sayyidina Abbas ibn `Ali (ر)'],
    5: <String>[
      'Birth of Sayyidina `Ali ibn Husayn (ر)',
      'Urs of Imam Shamil al-Daghestani (ق)'
    ],
    7: <String>['Birth of Sayyidina Qasim ibn Hasan (ر)'],
    11: <String>['Birth of Sayyidina Ali Akbar ibn Husayn (ر)'],
    15: <String>[
      'Lailat-ul-Bara\'at',
      'Urs of Sayyidina Abu Yazid al-Bistami (ق)'
    ],
    22: <String>['Urs of Muhammad Usman Damani (ق)'],
  },
  9: <int, List<String>>{
    1: <String>['1st Day of Ramadan'],
    21: <String>['Lailat-ul-Qadr'],
    23: <String>['Lailat-ul-Qadr'],
    25: <String>['Lailat-ul-Qadr'],
    27: <String>['Lailat-ul-Qadr'],
    29: <String>['Lailat-ul-Qadr'],
  },
  10: <int, List<String>>{
    1: <String>['Eid-ul-Fitr'],
    3: <String>['Urs of Hajjah Amina Ādil ق', 'Birth of Imam Bukhārī (ر)'],
  },
  11: <int, List<String>>{
    1: <String>['Treaty of Hudaybiyya'],
    2: <String>['Birth of Muhammad Effendi al-Yaraghi (ق) '],
    3: <String>['Birth of Sharafuddin ad-Daghestani (ق)'],
    7: <String>['Birth of Ismail Muhammad ash-Shirwani (ق)'],
    13: <String>['Urs of Khalid al-Baghdadi (ق)'],
    18: <String>['Urs of Ali ar-Ramitani (ق)'],
  },
  12: <int, List<String>>{
    8: <String>['Hajj'],
    9: <String>['Hajj', 'Arafa'],
    10: <String>['Eid-ul-Adha', 'Hajj', 'Urs Ismail Muhammad ash-Shirwani ق'],
    11: <String>['Hajj', 'Urs of Uthman ibn Affan (3rd Caliph) (ر)'],
    12: <String>['Hajj'],
    13: <String>['Hajj'],
    19: <String>['First time Adhan was called in 622 AD'],
  },
};
