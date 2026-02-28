enum AppLocale { pl, en }

class S {
  static AppLocale _locale = AppLocale.pl;

  static void setLocale(AppLocale locale) => _locale = locale;
  static AppLocale get locale => _locale;

  static String get appName => _t('Sąsiedzi & Seniorzy', 'Neighbors & Seniors');
  static String get login => _t('Zaloguj się', 'Log in');
  static String get register => _t('Zarejestruj się', 'Register');
  static String get email => _t('Email', 'Email');
  static String get password => _t('Hasło', 'Password');
  static String get name => _t('Imię i nazwisko', 'Full name');
  static String get phone => _t('Numer telefonu', 'Phone number');
  static String get home => _t('Główna', 'Home');
  static String get orders => _t('Zlecenia', 'Orders');
  static String get profile => _t('Profil', 'Profile');
  static String get equipment => _t('Sprzęt', 'Equipment');
  static String get friends => _t('Znajomi', 'Friends');
  static String get directory => _t('Katalog', 'Directory');
  static String get notifications => _t('Powiadomienia', 'Notifications');
  static String get settings => _t('Ustawienia', 'Settings');
  static String get newOrder => _t('Nowe zlecenie', 'New order');
  static String get available => _t('Dostępne', 'Available');
  static String get myOrders => _t('Moje zlecenia', 'My orders');
  static String get noOrders => _t('Brak zleceń', 'No orders');
  static String get save => _t('Zapisz', 'Save');
  static String get cancel => _t('Anuluj', 'Cancel');
  static String get confirm => _t('Potwierdź', 'Confirm');
  static String get search => _t('Szukaj', 'Search');
  static String get serverError => _t('Błąd połączenia z serwerem', 'Server connection error');
  static String get loading => _t('Ładowanie...', 'Loading...');
  static String get logout => _t('Wyloguj się', 'Log out');
  static String get noAccount => _t('Nie masz konta? Zarejestruj się', "Don't have an account? Register");
  static String get serverAddress => _t('Adres serwera', 'Server address');
  static String get points => _t('Punkty', 'Points');
  static String get badges => _t('Odznaki', 'Badges');
  static String get level => _t('Poziom', 'Level');
  static String get reviews => _t('Opinie', 'Reviews');
  static String get disputes => _t('Spory', 'Disputes');
  static String get payments => _t('Płatności', 'Payments');
  static String get accessCodes => _t('Kody dostępu', 'Access codes');
  static String get reservations => _t('Rezerwacje', 'Reservations');
  static String get addEquipment => _t('Dodaj sprzęt', 'Add equipment');
  static String get searchDirectory => _t('Szukaj usługodawców', 'Search providers');
  static String get createOffer => _t('Utwórz ofertę', 'Create offer');
  static String get free => _t('Bezpłatne', 'Free');
  static String get volunteer => _t('Wolontariat', 'Volunteer');
  static String get platformSubtitle =>
      _t('Platforma łącząca sąsiadów z seniorami', 'Platform connecting neighbors with seniors');
  static String get selectRole => _t('Wybierz typ konta:', 'Select account type:');
  static String get capabilities => _t('Możliwości', 'Capabilities');
  static String get manageCapabilities =>
      _t('Zarządzaj swoimi rolami', 'Manage your roles');
  static String get checkIn => _t('Zameldowanie', 'Check in');
  static String get checkOut => _t('Wymeldowanie', 'Check out');

  static String greeting(String name) =>
      _t('Cześć, $name!', 'Hi, $name!');

  static String _t(String pl, String en) =>
      _locale == AppLocale.pl ? pl : en;
}
