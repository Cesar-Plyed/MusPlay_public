import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'core/config/env_config.dart';
import 'services/audio_handler.dart';
import 'services/auth_service.dart';
import 'services/google_drive_service.dart';
import 'features/player/presentation/player_screen.dart';
import 'features/library/presentation/library_screen.dart';
import 'cloud/presentation/cloud_library_screen.dart';
import 'services/auth/presentation/login_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/playlists/providers/playlist_provider.dart';
import 'features/playlists/presentation/playlists_screen.dart';

late MyAudioHandler audioHandler;
bool isGuestMode = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Cargar variables de entorno
  await EnvConfig.load();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.musplay.channel.audio',
      androidNotificationChannelName: 'Reproducción de música',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  await audioHandler.restoreLastSong();

  runApp(MultiProvider(
    providers: [
      Provider<MyAudioHandler>.value(value: audioHandler),
      Provider<AuthService>(create: (_) => AuthService()),
      ChangeNotifierProvider(create: (_) => GoogleDriveService()),
      ChangeNotifierProvider(create: (_) => PlaylistProvider()),
    ],
    child: const MusicPlayerApp(),
  ));
}

class MusicPlayerApp extends StatelessWidget {
  const MusicPlayerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MusPlay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (!isGuestMode && user == null) return const LoginScreen();
        if (user != null) {
          Future.microtask(() {
            if (!mounted) return;
            // final sub = Provider.of<SubscriptionProvider>(context, listen: false);
            // if (sub.userId != user.uid) {
            //   sub.initialize(user.uid, 'free');
            //   Provider.of<PlaylistProvider>(context, listen: false)
            //       .initialize(user.uid, sub.isPremium);
            // }
          });
        }
        return const MainScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    LibraryScreen(),
    PlaylistsScreen(),
    CloudLibraryScreen(),
    PlayerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('MusPlay',
                style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: AppTheme.surface,
            elevation: 0,
            actions: [
              IconButton(
                icon: Icon(
                  user != null ? Icons.account_circle : Icons.person_outline,
                  color: AppTheme.accent,
                  size: 28,
                ),
                onPressed: () => user != null
                    ? _showUserMenu(context, user)
                    : _showGuestMenu(context),
              ),
            ],
          ),
          body: IndexedStack(index: _currentIndex, children: _screens),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            backgroundColor: AppTheme.surface,
            selectedItemColor: AppTheme.accent,
            unselectedItemColor: AppTheme.textSecondary,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                  icon: Icon(Icons.phone_android), label: 'Local'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.queue_music_rounded), label: 'Playlists'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.add_to_drive), label: 'Mi Nube'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.play_circle), label: 'Reproductor'),
            ],
          ),
        );
      },
    );
  }

  void _showGuestMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Modo Invitado',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary)),
              SizedBox(height: 10),
              Text('Inicia sesión para guardar tu música en Google Drive.',
                  style:
                      TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            ]),
          ),
          const Divider(color: AppTheme.divider),
          ListTile(
            leading: const Icon(Icons.login, color: AppTheme.accent),
            title: const Text('Iniciar sesión / Crear cuenta',
                style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () {
              Navigator.pop(ctx);
              setState(() => isGuestMode = false);
            },
          ),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }

  void _showUserMenu(BuildContext context, User user) {
    // final sub = Provider.of<SubscriptionProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: AppTheme.accent,
                child: Text(user.email?[0].toUpperCase() ?? 'U',
                    style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ),
              const SizedBox(width: 15),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(user.displayName ?? 'Usuario',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary)),
                    Text(user.email ?? '',
                        style: const TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                  ])),
              // Container(
              //   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              //   decoration: BoxDecoration(
              //     color: sub.isFree ? Colors.grey.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
              //     borderRadius: BorderRadius.circular(12),
              //   ),
              //   child: Text(sub.currentPlanId.toUpperCase(),
              //       style: TextStyle(color: sub.isFree ? Colors.grey : Colors.amber,
              //           fontWeight: FontWeight.bold, fontSize: 10)),
              // ),
            ]),
          ),
          // const Divider(color: AppTheme.divider),
          // ListTile(
          //   leading: const Icon(Icons.stars, color: Colors.amber),
          //   title: Text(sub.isFree ? 'Mejorar a Premium' : 'Mi suscripción',
          //       style: const TextStyle(color: AppTheme.textPrimary)),
          //   subtitle: const Text('Más almacenamiento en Drive',
          //       style: TextStyle(fontSize: 11)),
          //   onTap: () {
          //     Navigator.pop(ctx);
          //     Navigator.push(context,
          //         MaterialPageRoute(builder: (_) => const SubscriptionPlansScreen()));
          //   },
          // ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Cerrar sesión',
                style: TextStyle(color: AppTheme.textPrimary)),
            onTap: () async {
              Navigator.pop(ctx);
              await context.read<AuthService>().signOut();
              await context.read<GoogleDriveService>().disconnect();
              // sub.reset();
              context.read<PlaylistProvider>().reset();
              setState(() => isGuestMode = false);
            },
          ),
          const SizedBox(height: 10),
        ]),
      ),
    );
  }
}
