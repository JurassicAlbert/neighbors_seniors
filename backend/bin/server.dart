import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';

import 'package:neighbors_seniors_backend/src/database/database.dart';
import 'package:neighbors_seniors_backend/src/services/auth_service.dart';
import 'package:neighbors_seniors_backend/src/services/user_service.dart';
import 'package:neighbors_seniors_backend/src/services/order_service.dart';
import 'package:neighbors_seniors_backend/src/services/review_service.dart';
import 'package:neighbors_seniors_backend/src/services/stats_service.dart';
import 'package:neighbors_seniors_backend/src/services/equipment_service.dart';
import 'package:neighbors_seniors_backend/src/services/social_service.dart';
import 'package:neighbors_seniors_backend/src/services/payment_service.dart';
import 'package:neighbors_seniors_backend/src/services/directory_service.dart';
import 'package:neighbors_seniors_backend/src/routes/auth_routes.dart';
import 'package:neighbors_seniors_backend/src/routes/user_routes.dart';
import 'package:neighbors_seniors_backend/src/routes/order_routes.dart';
import 'package:neighbors_seniors_backend/src/routes/review_routes.dart';
import 'package:neighbors_seniors_backend/src/routes/admin_routes.dart';
import 'package:neighbors_seniors_backend/src/routes/equipment_routes.dart';
import 'package:neighbors_seniors_backend/src/routes/social_routes.dart';
import 'package:neighbors_seniors_backend/src/routes/payment_routes.dart';
import 'package:neighbors_seniors_backend/src/routes/directory_routes.dart';
import 'package:neighbors_seniors_backend/src/middleware/auth_middleware.dart';

void main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final dbPath = Platform.environment['DB_PATH'] ?? 'neighbors_seniors.db';

  final database = AppDatabase(path: dbPath);
  final authService = AuthService(database);
  final userService = UserService(database);
  final orderService = OrderService(database);
  final reviewService = ReviewService(database);
  final statsService = StatsService(database);
  final equipmentService = EquipmentService(database);
  final socialService = SocialService(database);
  final paymentService = PaymentService(database);
  final directoryService = DirectoryService(database);

  // Seed default admin user
  authService.register(
    email: 'admin@sasiedzi.pl',
    password: 'admin1234',
    name: 'Administrator',
    phone: '+48000000000',
    role: 'admin',
  );

  // Seed demo users
  final demoFamily = authService.register(
    email: 'rodzina@test.pl',
    password: 'test1234',
    name: 'Anna Kowalska',
    phone: '+48111111111',
    role: 'family',
  );
  final demoWorker = authService.register(
    email: 'wykonawca@test.pl',
    password: 'test1234',
    name: 'Jan Nowak',
    phone: '+48222222222',
    role: 'worker',
  );
  authService.register(
    email: 'senior@test.pl',
    password: 'test1234',
    name: 'Maria Wiśniewska',
    phone: '+48333333333',
    role: 'senior',
  );

  // Seed demo orders
  if (demoFamily != null) {
    final familyId = (demoFamily['user'] as Map<String, dynamic>)['id'] as String;
    orderService.createOrder(
      type: 'shopping',
      title: 'Zakupy spożywcze na tydzień',
      description: 'Potrzebne zakupy: mleko, chleb, masło, jajka, warzywa',
      requesterId: familyId,
      price: 50.0,
      address: 'ul. Kwiatowa 15, Warszawa',
      lat: 52.2297,
      lng: 21.0122,
    );
    orderService.createOrder(
      type: 'transport',
      title: 'Transport do lekarza',
      description: 'Wizyta u lekarza rodzinnego, przychodnia ul. Zdrowia 5',
      requesterId: familyId,
      price: 35.0,
      address: 'ul. Zdrowia 5, Warszawa',
      lat: 52.2350,
      lng: 21.0200,
    );
    orderService.createOrder(
      type: 'cleaning',
      title: 'Sprzątanie mieszkania',
      description: 'Cotygodniowe sprzątanie mieszkania 2-pokojowego',
      requesterId: familyId,
      price: 120.0,
      address: 'ul. Słoneczna 8, Warszawa',
      lat: 52.2400,
      lng: 21.0300,
    );
    orderService.createOrder(
      type: 'volunteer',
      title: 'Pomoc w ogrodzie - wolontariat',
      description: 'Poszukuję wolontariusza do pomocy w przydomowym ogrodzie',
      requesterId: familyId,
      price: 0,
      address: 'ul. Ogrodowa 22, Warszawa',
    );

    // Seed demo equipment
    equipmentService.createEquipment(
      ownerId: familyId,
      title: 'Wiertarka udarowa Bosch',
      description: 'Profesjonalna wiertarka udarowa, idealna do prac remontowych',
      category: 'powerTools',
      condition: 'good',
      pricePerUnit: 25.0,
      priceUnit: 'day',
      depositAmount: 100.0,
      location: 'Warszawa, Mokotów',
      lat: 52.1935,
      lng: 21.0340,
    );
    equipmentService.createEquipment(
      ownerId: familyId,
      title: 'Kosiarka elektryczna',
      description: 'Kosiarka do małych i średnich trawników',
      category: 'gardenEquipment',
      condition: 'likeNew',
      pricePerUnit: 40.0,
      priceUnit: 'day',
      depositAmount: 150.0,
      location: 'Warszawa, Ursynów',
      lat: 52.1548,
      lng: 21.0448,
    );
  }

  // Mark worker verification as pending
  if (demoWorker != null) {
    final workerId = (demoWorker['user'] as Map<String, dynamic>)['id'] as String;
    userService.updateUser(workerId, {'verificationStatus': 'pending'});

    // Seed demo service offer for worker
    directoryService.createOffer(
      providerId: workerId,
      title: 'Hydraulik - naprawy domowe',
      description: 'Profesjonalne usługi hydrauliczne, naprawy kranów, rur i instalacji',
      serviceType: 'plumbing',
      priceFrom: 80.0,
      priceTo: 300.0,
      location: 'Warszawa',
      lat: 52.2297,
      lng: 21.0122,
      radiusKm: 15.0,
      skills: ['hydraulika', 'naprawy', 'instalacje'],
    );
  }

  // Seed badges
  _seedBadges(database);

  final authRoutes = AuthRoutes(authService);
  final userRoutes = UserRoutes(userService);
  final orderRoutes = OrderRoutes(orderService);
  final reviewRoutes = ReviewRoutes(reviewService);
  final adminRoutes = AdminRoutes(userService, orderService, statsService);
  final equipmentRoutes = EquipmentRoutes(equipmentService);
  final socialRoutes = SocialRoutes(socialService);
  final paymentRoutes = PaymentRoutes(paymentService);
  final directoryRoutes = DirectoryRoutes(directoryService);

  final app = Router();

  // Public routes
  app.mount('/api/auth/', authRoutes.router.call);

  // Protected routes
  final protectedPipeline = const Pipeline()
      .addMiddleware(authMiddleware(authService));

  app.mount('/api/users/', protectedPipeline.addHandler(userRoutes.router.call));
  app.mount('/api/orders/', protectedPipeline.addHandler(orderRoutes.router.call));
  app.mount('/api/reviews/', protectedPipeline.addHandler(reviewRoutes.router.call));

  // v2 protected routes
  app.mount('/api/v2/equipment/', protectedPipeline.addHandler(equipmentRoutes.router.call));
  app.mount('/api/v2/social/', protectedPipeline.addHandler(socialRoutes.router.call));
  app.mount('/api/v2/payments/', protectedPipeline.addHandler(paymentRoutes.router.call));
  app.mount('/api/v2/directory/', protectedPipeline.addHandler(directoryRoutes.router.call));

  // Admin routes (auth + admin check)
  final adminPipeline = const Pipeline()
      .addMiddleware(authMiddleware(authService))
      .addMiddleware(adminMiddleware());

  app.mount('/api/admin/', adminPipeline.addHandler(adminRoutes.router.call));

  // Health check
  app.get('/health', (Request request) {
    return Response.ok('{"status": "ok", "version": "2.0.0"}',
        headers: {'content-type': 'application/json'});
  });

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(app.call);

  final server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
  print('🚀 Neighbors & Seniors API v2 running on http://localhost:${server.port}');
  print('📋 Demo accounts:');
  print('   Admin:     admin@sasiedzi.pl / admin1234');
  print('   Family:    rodzina@test.pl / test1234');
  print('   Worker:    wykonawca@test.pl / test1234');
  print('   Senior:    senior@test.pl / test1234');
}

void _seedBadges(AppDatabase database) {
  final existing = database.db.select('SELECT COUNT(*) as cnt FROM badges');
  if ((existing.first['cnt'] as int) > 0) return;

  final badges = [
    ['badge-newcomer', 'Nowy sąsiad', 'Dołączył do społeczności', '🏠', 0, 'community'],
    ['badge-helper', 'Pomocna dłoń', 'Zrealizował 5 zleceń', '🤝', 50, 'service'],
    ['badge-trusted', 'Zaufany sąsiad', 'Uzyskał 10 pozytywnych opinii', '⭐', 100, 'trust'],
    ['badge-volunteer', 'Wolontariusz roku', 'Wykonał 10 zadań wolontariackich', '💛', 200, 'volunteer'],
    ['badge-sharer', 'Mistrz udostępniania', 'Udostępnił sprzęt 10 razy', '🛠️', 150, 'equipment'],
  ];

  for (final b in badges) {
    database.db.execute(
      'INSERT INTO badges (id, name, description, icon, required_points, category) VALUES (?, ?, ?, ?, ?, ?)',
      b,
    );
  }
}
