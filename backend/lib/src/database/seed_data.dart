import 'dart:math';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/order_service.dart';
import '../services/review_service.dart';
import '../services/equipment_service.dart';
import '../services/social_service.dart';
import '../services/payment_service.dart';
import '../services/directory_service.dart';
import 'database.dart';

final _rng = Random(42);

void seedDemoData({
  required AppDatabase database,
  required AuthService authService,
  required UserService userService,
  required OrderService orderService,
  required ReviewService reviewService,
  required EquipmentService equipmentService,
  required SocialService socialService,
  required PaymentService paymentService,
  required DirectoryService directoryService,
}) {
  final existing = database.db.select('SELECT COUNT(*) as cnt FROM users');
  if ((existing.first['cnt'] as int) > 0) return;

  print('📦 Seeding demo data...');

  // ─── 1. Users ───────────────────────────────────────────────
  authService.register(
    email: 'admin@sasiedzi.pl', password: 'admin1234',
    name: 'Administrator', phone: '+48000000000', role: 'admin',
  );

  final families = <Map<String, dynamic>>[];
  final workers = <Map<String, dynamic>>[];
  final seniors = <Map<String, dynamic>>[];

  final familyData = [
    ['Anna Kowalska', 'anna@test.pl', '+48111111111'],
    ['Piotr Zieliński', 'piotr@test.pl', '+48111222333'],
    ['Katarzyna Wójcik', 'kasia@test.pl', '+48111333444'],
    ['Tomasz Kamiński', 'tomasz@test.pl', '+48111444555'],
    ['Magdalena Lewandowska', 'magda@test.pl', '+48111555666'],
    ['Robert Szymański', 'robert@test.pl', '+48111666777'],
    ['Joanna Dąbrowska', 'joanna@test.pl', '+48111777888'],
  ];
  for (final f in familyData) {
    final u = authService.register(
      email: f[1], password: 'test1234', name: f[0], phone: f[2], role: 'family',
    );
    if (u != null) families.add(u['user'] as Map<String, dynamic>);
  }

  final workerData = [
    ['Jan Nowak', 'jan@test.pl', '+48222111111'],
    ['Marek Wiśniewski', 'marek@test.pl', '+48222222222'],
    ['Ewa Kozłowska', 'ewa@test.pl', '+48222333333'],
    ['Adam Jankowski', 'adam@test.pl', '+48222444444'],
    ['Sylwia Mazur', 'sylwia@test.pl', '+48222555555'],
    ['Krzysztof Krawczyk', 'krzysztof@test.pl', '+48222666666'],
    ['Dorota Piotrowska', 'dorota@test.pl', '+48222777777'],
    ['Łukasz Grabowski', 'lukasz@test.pl', '+48222888888'],
  ];
  for (final w in workerData) {
    final u = authService.register(
      email: w[1], password: 'test1234', name: w[0], phone: w[2], role: 'worker',
    );
    if (u != null) workers.add(u['user'] as Map<String, dynamic>);
  }

  final seniorData = [
    ['Maria Wiśniewska', 'maria@test.pl', '+48333111111'],
    ['Stanisław Kowalczyk', 'stanislaw@test.pl', '+48333222222'],
    ['Helena Nowak', 'helena@test.pl', '+48333333333'],
    ['Józef Wójcik', 'jozef@test.pl', '+48333444444'],
    ['Krystyna Kamińska', 'krystyna@test.pl', '+48333555555'],
    ['Tadeusz Lewandowski', 'tadeusz@test.pl', '+48333666666'],
  ];
  for (final s in seniorData) {
    final u = authService.register(
      email: s[1], password: 'test1234', name: s[0], phone: s[2], role: 'senior',
    );
    if (u != null) seniors.add(u['user'] as Map<String, dynamic>);
  }

  // Set worker verifications mixed
  for (var i = 0; i < workers.length; i++) {
    final status = i < 4 ? 'verified' : (i < 6 ? 'pending' : 'unverified');
    userService.updateUser(workers[i]['id'] as String, {'verificationStatus': status});
  }

  // Add points to some users
  for (var i = 0; i < workers.length; i++) {
    socialService.addPoints(workers[i]['id'] as String, 30 + _rng.nextInt(200));
  }
  for (var i = 0; i < families.length; i++) {
    socialService.addPoints(families[i]['id'] as String, 10 + _rng.nextInt(80));
  }

  // ─── 2. Orders (across all types and statuses) ──────────────
  final warsawLocations = [
    ['ul. Kwiatowa 15, Warszawa', 52.2297, 21.0122],
    ['ul. Marszałkowska 100, Warszawa', 52.2290, 21.0170],
    ['ul. Puławska 45, Warszawa', 52.2050, 21.0230],
    ['ul. Żoliborska 12, Warszawa', 52.2680, 21.0130],
    ['ul. Praga Północ 8, Warszawa', 52.2560, 21.0430],
    ['ul. Mokotowska 33, Warszawa', 52.2150, 21.0120],
    ['ul. Ursynowska 7, Warszawa', 52.1550, 21.0450],
    ['ul. Wilanowska 22, Warszawa', 52.1650, 21.0900],
    ['ul. Bemowo 55, Warszawa', 52.2550, 20.9100],
    ['ul. Wola 18, Warszawa', 52.2370, 20.9800],
  ];

  final orderSeed = [
    // Shopping
    ['shopping', 'Zakupy spożywcze na tydzień', 'Mleko, chleb, masło, jajka, warzywa, owoce', 50.0],
    ['shopping', 'Zakupy z apteki', 'Lista leków do odbioru z apteki na rogu', 30.0],
    ['shopping', 'Zakupy na święta', 'Większe zakupy: mąka, cukier, masło, jajka, czekolada', 85.0],
    // Transport
    ['transport', 'Transport do lekarza', 'Wizyta u lekarza rodzinnego, przychodnia', 35.0],
    ['transport', 'Odwiezienie na rehabilitację', 'Rehabilitacja o 10:00, potrzebny transport tam i z powrotem', 60.0],
    ['transport', 'Transport na badania', 'Badania krwi w laboratorium, poranne godziny', 40.0],
    // Cleaning
    ['cleaning', 'Sprzątanie mieszkania', 'Cotygodniowe sprzątanie mieszkania 2-pokojowego', 120.0],
    ['cleaning', 'Mycie okien', 'Mycie okien w mieszkaniu na 3. piętrze, 6 okien', 80.0],
    ['cleaning', 'Gruntowne sprzątanie po remoncie', 'Dokładne sprzątanie po malowaniu', 200.0],
    // Plumbing
    ['plumbing', 'Naprawa cieknącego kranu', 'Kran w kuchni cieknie, wymaga naprawy', 90.0],
    ['plumbing', 'Wymiana baterii łazienkowej', 'Stara bateria do wymiany w łazience', 150.0],
    // Gardening
    ['gardening', 'Koszenie trawnika', 'Trawnik ok. 100m², cotygodniowe koszenie', 60.0],
    ['gardening', 'Przycinanie żywopłotu', 'Żywopłot 20m do przycięcia i uporządkowania', 100.0],
    ['gardening', 'Sadzenie kwiatów', 'Pomoc przy sadzeniu kwiatów w ogródku', 45.0],
    // Repair
    ['repair', 'Naprawa drzwi', 'Skrzypiące drzwi, potrzebna regulacja zawiasów', 70.0],
    ['repair', 'Montaż półek', 'Montaż 3 półek w salonie', 80.0],
    ['repair', 'Naprawa rolety', 'Roleta w sypialni się zacięła', 65.0],
    // Paramedical
    ['paramedical', 'Opieka paramedyczna wieczorna', 'Pomoc przy wieczornej toalecie i podaniu leków', 90.0],
    ['paramedical', 'Zmiana opatrunków', 'Codzienne opatrunki po operacji', 60.0],
    // Caregiving
    ['caregiving', 'Opieka domowa popołudniowa', 'Towarzystwo i pomoc 14:00-18:00', 100.0],
    ['caregiving', 'Opieka nocna', 'Dyżur nocny przy seniorze po operacji', 180.0],
    // Volunteer
    ['volunteer', 'Pomoc w ogrodzie - wolontariat', 'Poszukuję wolontariusza do pomocy w ogrodzie', 0.0],
    ['volunteer', 'Spacer z seniorem', 'Towarzystwo na godzinny spacer, okolice parku', 0.0],
    ['volunteer', 'Czytanie książek', 'Czytanie na głos seniorce z osłabionym wzrokiem', 0.0],
    ['volunteer', 'Pomoc z komputerem', 'Nauka korzystania z tabletu i internetu', 0.0],
    // Tool sharing
    ['toolSharing', 'Wypożyczenie wiertarki', 'Potrzebuję wiertarki udarowej na weekend', 25.0],
    // Housing
    ['housing', 'Wymiana mieszkaniowa na wakacje', 'Oferuję mieszkanie w Warszawie za dom na wsi', 0.0],
  ];

  final statuses = ['pending', 'accepted', 'inProgress', 'completed', 'completed', 'completed', 'cancelled'];
  final createdOrders = <Map<String, dynamic>>[];

  for (var i = 0; i < orderSeed.length; i++) {
    final o = orderSeed[i];
    final loc = warsawLocations[i % warsawLocations.length];
    final requester = i % 3 == 0 ? families[i % families.length] : seniors[i % seniors.length];
    final status = statuses[i % statuses.length];

    final order = orderService.createOrder(
      type: o[0] as String,
      title: o[1] as String,
      description: o[2] as String,
      requesterId: requester['id'] as String,
      price: o[3] as double,
      address: loc[0] as String,
      lat: loc[1] as double,
      lng: loc[2] as double,
    );
    createdOrders.add(order);

    // Assign worker and update status
    if (status != 'pending') {
      final worker = workers[i % workers.length];
      orderService.updateOrderStatus(
        order['id'] as String,
        status == 'cancelled' ? 'cancelled' : 'accepted',
        workerId: worker['id'] as String,
      );
      if (status == 'inProgress' || status == 'completed') {
        orderService.updateOrderStatus(order['id'] as String, 'inProgress');
      }
      if (status == 'completed') {
        orderService.updateOrderStatus(order['id'] as String, 'completed');
      }
    }
  }

  // ─── 3. Reviews (for completed orders) ──────────────────────
  final reviewComments = [
    'Doskonała obsługa! Polecam serdecznie.',
    'Bardzo punktualny i rzetelny. Na pewno skorzystam ponownie.',
    'Świetna praca, mieszkanie lśni czystością.',
    'Profesjonalne podejście, szybka realizacja.',
    'Miła i cierpliwa osoba, babcia bardzo zadowolona.',
    'Solidna robota, cena adekwatna do jakości.',
    'Bardzo pomocny, wrócę na pewno.',
    'Trochę się spóźnił ale poza tym wszystko OK.',
    'Rewelacja! Najlepszy fachowiec w okolicy.',
    'Dobra komunikacja i terminowa realizacja.',
    'Polecam! Uczciwy i dokładny.',
    'Bardzo miła pani, mama jest zachwycona.',
  ];

  for (final order in createdOrders) {
    if (order['status'] != 'completed' || order['workerId'] == null) continue;
    final rating = 3 + _rng.nextInt(3); // 3-5
    reviewService.createReview(
      orderId: order['id'] as String,
      reviewerId: order['requesterId'] as String,
      revieweeId: order['workerId'] as String,
      rating: rating,
      comment: reviewComments[_rng.nextInt(reviewComments.length)],
    );
  }

  // ─── 4. Equipment ───────────────────────────────────────────
  final equipmentSeed = [
    ['Wiertarka udarowa Bosch', 'Profesjonalna wiertarka 800W, walizka + wiertła', 'powerTools', 'good', 25.0, 100.0, 'Warszawa, Mokotów'],
    ['Kosiarka elektryczna Makita', 'Kosiarka do trawników do 200m²', 'gardenEquipment', 'likeNew', 40.0, 150.0, 'Warszawa, Ursynów'],
    ['Szlifierka kątowa', 'Szlifierka 125mm do metalu i kamienia', 'powerTools', 'good', 20.0, 80.0, 'Warszawa, Wola'],
    ['Piła tarczowa', 'Ręczna piła tarczowa do drewna', 'powerTools', 'fair', 30.0, 120.0, 'Warszawa, Bemowo'],
    ['Nożyce do żywopłotu', 'Elektryczne nożyce do żywopłotu 50cm', 'gardenEquipment', 'good', 15.0, 60.0, 'Warszawa, Wilanów'],
    ['Myjka ciśnieniowa Kärcher', 'Myjka 130 bar, idealna do tarasów i samochodów', 'cleaningEquipment', 'likeNew', 50.0, 200.0, 'Warszawa, Mokotów'],
    ['Odkurzacz piorący', 'Odkurzacz piorący do dywanów i tapicerki', 'cleaningEquipment', 'good', 35.0, 150.0, 'Warszawa, Praga'],
    ['Drabina aluminiowa 3m', 'Drabina rozstawna 3 sekcje', 'handTools', 'good', 10.0, 50.0, 'Warszawa, Żoliborz'],
    ['Wózek inwalidzki', 'Lekki wózek inwalidzki składany', 'medicalAids', 'good', 0.0, 200.0, 'Warszawa, Ochota'],
    ['Balkonik rehabilitacyjny', 'Balkonik z kółkami i hamulcami', 'medicalAids', 'likeNew', 0.0, 100.0, 'Warszawa, Bielany'],
    ['Zestaw kluczy nasadowych', 'Kompletny zestaw 150 elementów', 'handTools', 'brandNew', 8.0, 40.0, 'Warszawa, Targówek'],
    ['Agregat prądotwórczy', 'Agregat 2kW, idealny na działkę', 'powerTools', 'fair', 60.0, 300.0, 'Piaseczno'],
    ['Rower treningowy', 'Rower stacjonarny z wyświetlaczem', 'sportEquipment', 'good', 5.0, 100.0, 'Warszawa, Mokotów'],
    ['Robot kuchenny', 'Wielofunkcyjny robot kuchenny 1000W', 'kitchenAppliances', 'likeNew', 15.0, 80.0, 'Warszawa, Śródmieście'],
    ['Namiot 4-osobowy', 'Namiot turystyczny z przedsionkiem', 'other', 'good', 20.0, 100.0, 'Warszawa, Kabaty'],
  ];

  final createdEquipment = <Map<String, dynamic>>[];
  for (var i = 0; i < equipmentSeed.length; i++) {
    final e = equipmentSeed[i];
    final owner = i < 7 ? families[i % families.length] : workers[i % workers.length];
    final eq = equipmentService.createEquipment(
      ownerId: owner['id'] as String,
      title: e[0] as String,
      description: e[1] as String,
      category: e[2] as String,
      condition: e[3] as String,
      pricePerUnit: e[4] as double,
      priceUnit: 'day',
      depositAmount: e[5] as double,
      location: e[6] as String,
      lat: 52.15 + _rng.nextDouble() * 0.15,
      lng: 20.90 + _rng.nextDouble() * 0.20,
    );
    createdEquipment.add(eq);
  }

  // Equipment reservations
  for (var i = 0; i < 6; i++) {
    final eq = createdEquipment[i];
    final borrower = seniors[i % seniors.length];
    final now = DateTime.now();
    equipmentService.createReservation(
      equipmentId: eq['id'] as String,
      borrowerId: borrower['id'] as String,
      ownerId: eq['ownerId'] as String,
      startDate: now.subtract(Duration(days: 5 - i)).toIso8601String(),
      endDate: now.add(Duration(days: i + 1)).toIso8601String(),
      totalPrice: (eq['pricePerUnit'] as num).toDouble() * (i + 2),
      depositAmount: (eq['depositAmount'] as num?)?.toDouble(),
    );
  }
  // Mark some reservations as different statuses
  final reservations = database.db.select('SELECT id FROM equipment_reservations');
  if (reservations.length >= 4) {
    database.db.execute("UPDATE equipment_reservations SET status = 'inUse' WHERE id = ?", [reservations[0]['id']]);
    database.db.execute("UPDATE equipment_reservations SET status = 'inUse' WHERE id = ?", [reservations[1]['id']]);
    database.db.execute("UPDATE equipment_reservations SET status = 'returned' WHERE id = ?", [reservations[2]['id']]);
    database.db.execute("UPDATE equipment_reservations SET status = 'underReview' WHERE id = ?", [reservations[3]['id']]);
  }

  // ─── 5. Friendships ─────────────────────────────────────────
  // Create a friendship network
  for (var i = 0; i < families.length - 1; i++) {
    socialService.sendFriendRequest(
      userId: families[i]['id'] as String,
      friendId: families[i + 1]['id'] as String,
    );
  }
  // Accept most of them
  final pendingFriends = database.db.select("SELECT id FROM friendships WHERE status = 'pending'");
  for (var i = 0; i < pendingFriends.length; i++) {
    if (i < pendingFriends.length - 2) {
      socialService.acceptFriendRequest(pendingFriends[i]['id'] as String);
    }
  }

  // Cross-role friendships
  for (var i = 0; i < 4; i++) {
    socialService.sendFriendRequest(
      userId: workers[i]['id'] as String,
      friendId: families[i]['id'] as String,
    );
    socialService.acceptFriendRequest(
      database.db.select("SELECT id FROM friendships WHERE user_id = ? AND friend_id = ?",
        [workers[i]['id'], families[i]['id']]).first['id'] as String,
    );
  }
  for (var i = 0; i < 3; i++) {
    socialService.sendFriendRequest(
      userId: seniors[i]['id'] as String,
      friendId: families[i]['id'] as String,
    );
    socialService.acceptFriendRequest(
      database.db.select("SELECT id FROM friendships WHERE user_id = ? AND friend_id = ?",
        [seniors[i]['id'], families[i]['id']]).first['id'] as String,
    );
  }

  // ─── 6. Service offers (directory) ──────────────────────────
  final offerSeed = [
    ['Hydraulik - naprawy domowe', 'Profesjonalne usługi hydrauliczne', 'plumbing', 80.0, 300.0, 'hydraulika,naprawy,instalacje'],
    ['Sprzątanie mieszkań i domów', 'Regularne i jednorazowe sprzątanie', 'cleaning', 50.0, 200.0, 'sprzątanie,mycie okien,porządki'],
    ['Opieka nad seniorem', 'Doświadczona opiekunka, certyfikaty', 'caregiving', 25.0, 40.0, 'opieka,seniorzy,pomoc domowa'],
    ['Ogrodnik - kompleksowa pielęgnacja', 'Koszenie, przycinanie, sadzenie', 'gardening', 40.0, 150.0, 'ogród,koszenie,przycinanie'],
    ['Złota rączka - drobne naprawy', 'Montaż, naprawy, drobne prace', 'repair', 60.0, 200.0, 'naprawy,montaż,remonty'],
    ['Transport medyczny', 'Transport na wizyty lekarskie i badania', 'transport', 30.0, 80.0, 'transport,lekarz,rehabilitacja'],
    ['Fizjoterapia domowa', 'Wykwalifikowany fizjoterapeuta', 'paramedical', 100.0, 180.0, 'fizjoterapia,rehabilitacja,masaż'],
    ['Zakupy i dostawy', 'Zakupy spożywcze i apteczne z dostawą', 'shopping', 20.0, 50.0, 'zakupy,dostawa,apteka'],
    ['Wolontariat - spacery z seniorami', 'Wolontariackie spacery i towarzystwo', 'volunteer', 0.0, 0.0, 'wolontariat,spacer,towarzystwo'],
    ['Pomoc informatyczna', 'Konfiguracja komputerów, telefonów, tabletów', 'repair', 50.0, 120.0, 'komputer,telefon,internet'],
  ];

  for (var i = 0; i < offerSeed.length; i++) {
    final o = offerSeed[i];
    final provider = workers[i % workers.length];
    directoryService.createOffer(
      providerId: provider['id'] as String,
      title: o[0] as String,
      description: o[1] as String,
      serviceType: o[2] as String,
      priceFrom: o[3] as double,
      priceTo: o[4] as double,
      location: 'Warszawa',
      lat: 52.20 + _rng.nextDouble() * 0.10,
      lng: 20.95 + _rng.nextDouble() * 0.15,
      radiusKm: 10.0 + _rng.nextDouble() * 20.0,
      skills: (o[5] as String).split(','),
    );
  }

  // ─── 7. Payments (escrow) ───────────────────────────────────
  for (final order in createdOrders) {
    final price = order['price'] as num?;
    if (price == null || price == 0 || order['workerId'] == null) continue;
    final status = order['status'] as String;
    final paymentStatus = status == 'completed' ? 'released' : (status == 'cancelled' ? 'refunded' : 'blocked');

    paymentService.createPayment(
      orderId: order['id'] as String,
      payerId: order['requesterId'] as String,
      payeeId: order['workerId'] as String,
      amount: price.toDouble(),
      depositAmount: null,
      commissionAmount: price.toDouble() * 0.10,
    );
    // Update payment status
    final payments = database.db.select(
      'SELECT id FROM payments WHERE order_id = ?', [order['id']]);
    if (payments.isNotEmpty) {
      database.db.execute(
        'UPDATE payments SET status = ? WHERE id = ?',
        [paymentStatus, payments.first['id']],
      );
    }
  }

  // ─── 8. Disputes ────────────────────────────────────────────
  final disputeSeed = [
    ['serviceQuality', 'Niekompletne sprzątanie', 'Nie posprzątano łazienki mimo umówienia się na całe mieszkanie', 'open'],
    ['payment', 'Opóźnienie w płatności', 'Pieniądze nie zostały zwolnione po 3 dniach od zakończenia', 'underReview'],
    ['noShow', 'Nieobecność wykonawcy', 'Wykonawca nie pojawił się na umówionej wizycie', 'open'],
    ['equipmentDamage', 'Uszkodzona wiertarka', 'Wiertarka zwrócona z uszkodzonym uchwytem', 'open'],
    ['other', 'Problem z komunikacją', 'Brak odpowiedzi od wykonawcy po zaakceptowaniu zlecenia', 'resolved'],
    ['serviceQuality', 'Niezadowalająca jakość naprawy', 'Kran nadal cieknie po naprawie', 'escalated'],
  ];

  for (var i = 0; i < disputeSeed.length; i++) {
    final d = disputeSeed[i];
    final reporter = families[i % families.length];
    final respondent = workers[i % workers.length];
    final orderId = createdOrders.length > i ? createdOrders[i]['id'] as String? : null;

    paymentService.createDispute(
      type: d[0],
      orderId: orderId,
      reporterId: reporter['id'] as String,
      respondentId: respondent['id'] as String,
      title: d[1],
      description: d[2],
    );
    // Update dispute status
    final disputes = database.db.select(
      'SELECT id FROM disputes WHERE reporter_id = ? ORDER BY created_at DESC LIMIT 1',
      [reporter['id']]);
    if (disputes.isNotEmpty && d[3] != 'open') {
      database.db.execute(
        'UPDATE disputes SET status = ? WHERE id = ?',
        [d[3], disputes.first['id']],
      );
      if (d[3] == 'resolved') {
        database.db.execute(
          "UPDATE disputes SET resolution = 'Sprawa rozwiązana po mediacji administratora. Ustalono zwrot częściowy.' WHERE id = ?",
          [disputes.first['id']],
        );
      }
    }
  }

  // ─── 9. Notifications ───────────────────────────────────────
  final notifSeed = [
    ['reservationConfirmed', 'Rezerwacja potwierdzona', 'Twoja rezerwacja wiertarki została potwierdzona'],
    ['serviceCompleted', 'Zlecenie zakończone', 'Zlecenie "Sprzątanie mieszkania" zostało zakończone'],
    ['accessCodeDelivered', 'Kod dostępu', 'Otrzymałeś kod dostępu: 482910'],
    ['friendRequest', 'Nowe zaproszenie', 'Anna Kowalska chce dodać Cię do znajomych'],
    ['badgeEarned', 'Nowa odznaka!', 'Zdobyłeś odznakę "Pomocna dłoń"!'],
    ['paymentUpdate', 'Płatność zwolniona', 'Środki za zlecenie zostały zwolnione na Twoje konto'],
    ['overdueReturn', 'Zaległy zwrot', 'Termin zwrotu kosiarki minął wczoraj'],
    ['disputeUpdate', 'Aktualizacja sporu', 'Twój spór został przekazany do rozpatrzenia'],
    ['verificationUpdate', 'Weryfikacja zakończona', 'Twój profil został zweryfikowany!'],
    ['newMessage', 'Nowa wiadomość', 'Masz nową wiadomość od Marka Wiśniewskiego'],
  ];

  for (var i = 0; i < notifSeed.length; i++) {
    final n = notifSeed[i];
    final userId = i % 2 == 0
        ? families[i % families.length]['id'] as String
        : workers[i % workers.length]['id'] as String;

    database.db.execute(
      'INSERT INTO notifications (id, user_id, title, body, read, type, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        'notif-${i + 1}',
        userId,
        n[1],
        n[2],
        i < 4 ? 0 : 1,
        n[0],
        DateTime.now().subtract(Duration(hours: i * 3)).toIso8601String(),
      ],
    );
  }

  // ─── 10. Access codes ───────────────────────────────────────
  for (var i = 0; i < 4; i++) {
    if (i >= createdOrders.length) break;
    final order = createdOrders[i];
    socialService.createAccessCode(
      orderId: order['id'] as String,
      granterId: order['requesterId'] as String,
      recipientId: order['workerId'] as String?,
      accessType: i % 2 == 0 ? 'keybox' : 'digitalCode',
      instructions: i % 2 == 0
          ? 'Skrzynka na klucze przy drzwiach wejściowych, obok skrzynki pocztowej'
          : 'Wprowadź kod na domofonie, potem klatka B, 3 piętro',
      expiresAt: DateTime.now().add(const Duration(hours: 24)).toIso8601String(),
    );
  }

  // ─── 11. Check-in logs ──────────────────────────────────────
  for (var i = 0; i < 5; i++) {
    if (i >= createdOrders.length) break;
    final order = createdOrders[i];
    if (order['workerId'] == null) continue;
    socialService.logCheckIn(
      orderId: order['id'] as String,
      userId: order['workerId'] as String,
      isCheckIn: true,
      lat: 52.22 + _rng.nextDouble() * 0.05,
      lng: 21.00 + _rng.nextDouble() * 0.05,
    );
    if (order['status'] == 'completed') {
      socialService.logCheckIn(
        orderId: order['id'] as String,
        userId: order['workerId'] as String,
        isCheckIn: false,
        lat: 52.22 + _rng.nextDouble() * 0.05,
        lng: 21.00 + _rng.nextDouble() * 0.05,
      );
    }
  }

  // Award some badges
  for (var i = 0; i < workers.length; i++) {
    socialService.awardBadge(workers[i]['id'] as String, 'badge-newcomer');
    if (i < 4) socialService.awardBadge(workers[i]['id'] as String, 'badge-helper');
    if (i < 2) socialService.awardBadge(workers[i]['id'] as String, 'badge-trusted');
  }
  for (var i = 0; i < families.length; i++) {
    socialService.awardBadge(families[i]['id'] as String, 'badge-newcomer');
  }

  print('✅ Demo data seeded:');
  print('   ${families.length + workers.length + seniors.length + 1} users');
  print('   ${createdOrders.length} orders');
  print('   ${createdEquipment.length} equipment items');
  print('   6 reservations');
  print('   ${disputeSeed.length} disputes');
  print('   10 service offers');
  print('   ${notifSeed.length} notifications');
}
