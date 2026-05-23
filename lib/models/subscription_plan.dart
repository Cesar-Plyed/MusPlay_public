class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final double price;
  final int maxUploadSongs;
  final int maxDownloadSongs;
  final bool canUploadSongs;
  final bool canListenCloud;
  final List<String> features;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.maxUploadSongs,
    required this.maxDownloadSongs,
    required this.canUploadSongs,
    required this.canListenCloud,
    required this.features,
  });

  int get maxSongs => maxUploadSongs;
  bool get canDownloadOffline => maxDownloadSongs > 0;
  bool get canListenOffline => canListenCloud;

  static List<SubscriptionPlan> getAllPlans() => [
    const SubscriptionPlan(
      id: 'free',
      name: 'Gratis',
      description: 'Para empezar',
      price: 0,
      maxUploadSongs: 20,
      maxDownloadSongs: 20,
      canUploadSongs: true,
      canListenCloud: false,
      features: [
        'Reproducir música local',
        'Subir hasta 20 canciones a tu Google Drive',
        'Descargar hasta 20 canciones',
        'Sin reproducción desde la nube',
      ],
    ),
    const SubscriptionPlan(
      id: 'premium',
      name: 'Premium',
      description: 'Sin límites',
      price: 49,
      maxUploadSongs: 200,
      maxDownloadSongs: 200,
      canUploadSongs: true,
      canListenCloud: true,
      features: [
        'Subir hasta 200 canciones a tu Google Drive',
        'Descargar hasta 200 canciones',
        'Escuchar música desde tu Google Drive',
        'Acceso desde cualquier dispositivo',
      ],
    ),
  ];

  static SubscriptionPlan getPlanById(String id) =>
      getAllPlans().firstWhere((p) => p.id == id, orElse: () => getAllPlans().first);
}
