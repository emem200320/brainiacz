//lib/main.dart
import 'package:brainiacz/providers/auth_providers.dart' as app_providers;
import 'package:brainiacz/providers/tutor_provider.dart';
import 'package:brainiacz/providers/session_provider.dart';
import 'package:brainiacz/screens/admin/admin_reports_screen.dart';
import 'package:brainiacz/screens/admin/admin_content_moderator_screen.dart';
import 'package:brainiacz/screens/admin_home_screen.dart';
import 'package:brainiacz/screens/signup_screen.dart';
import 'package:brainiacz/screens/login_screen.dart';
import 'package:brainiacz/screens/role_selection.dart';
import 'package:brainiacz/screens/splash_screen.dart';
import 'package:brainiacz/screens/student_home_screen.dart';
import 'package:brainiacz/screens/student_profile_screen.dart';
import 'package:brainiacz/screens/tutor/tutor_home_screen.dart';
import 'package:brainiacz/screens/tutor_profile_screen.dart';
import 'package:brainiacz/screens/tutor_details_screen.dart';
import 'package:brainiacz/screens/request_form_screen.dart';
import 'package:brainiacz/services/firestore_services.dart';
import 'package:brainiacz/services/auth_services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brainiacz/widgets/role_guard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:brainiacz/firebase_options.dart';

/// A widget that manages user's online status based on app lifecycle state changes
class AppLifecycleManager extends StatefulWidget {
  final Widget child;
  
  const AppLifecycleManager({
    super.key,
    required this.child,
  });

  @override
  State<AppLifecycleManager> createState() => _AppLifecycleManagerState();
}

class _AppLifecycleManagerState extends State<AppLifecycleManager> with WidgetsBindingObserver {
  final FirestoreService _firestoreService = FirestoreService();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateUserOnlineStatus(true);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _updateUserOnlineStatus(false);
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Track user online/offline status based on app lifecycle changes
    if (state == AppLifecycleState.resumed) {
      // App in foreground, set user as online
      _updateUserOnlineStatus(true);
    } else if (state == AppLifecycleState.paused || 
              state == AppLifecycleState.detached || 
              state == AppLifecycleState.inactive) {
      // App in background or closed, set user as offline
      _updateUserOnlineStatus(false);
    }
  }
  
  void _updateUserOnlineStatus(bool isOnline) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firestoreService.updateUserOnlineStatus(
        userId: user.uid,
        isOnline: isOnline,
      ).catchError((error) {
        // Silently handle any errors updating status
        debugPrint('Error updating online status: $error');
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Explicitly initialize Firebase Storage
  FirebaseStorage.instance;
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppLifecycleManager(
      child: MultiProvider(
        providers: [
          // Use Provider for services that don't need to notify listeners
          Provider<FirestoreService>(create: (_) => FirestoreService()),
          Provider<AuthService>(create: (_) => AuthService()),
          // Use ChangeNotifierProvider for providers that need to notify listeners
          ChangeNotifierProvider(create: (_) => app_providers.AuthProvider()),
          ChangeNotifierProvider(create: (context) => TutorProvider()),
          ChangeNotifierProvider(create: (_) => SessionProvider()),
        ],
        child: MaterialApp(
          title: 'Tutoring App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          home: SplashScreen(),
          routes: {
            '/splash': (context) => SplashScreen(),
            '/roleSelection': (context) => RoleSelectionScreen(),
            '/login': (context) => LoginScreen(
                role:
                    ModalRoute.of(context)!.settings.arguments as String? ?? ''),
            '/signup': (context) => SignupScreen(),

            // Student-Specific Screens
            '/studentHome': (context) => RoleGuard(
                  allowedRoles: ['student'],
                  debugShowCheckedModeBanner: false,
                  child: StudentHomeScreen(),
                ),
            '/studentProfile': (context) => RoleGuard(
                  allowedRoles: ['student'],
                  debugShowCheckedModeBanner: false,
                  child: StudentProfileScreen(),
                ),

            // Tutor-Specific Screens
            '/tutorHome': (context) => RoleGuard(
                  allowedRoles: ['tutor'],
                  debugShowCheckedModeBanner: false,
                  child: TutorHomeScreen(),
                ),
            '/tutorProfile': (context) => RoleGuard(
                  allowedRoles: ['tutor'],
                  debugShowCheckedModeBanner: false,
                  child: TutorProfileScreen(),
                ),

            // Tutor Details Screen (accessible to students)
            '/tutorDetails': (context) => TutorDetailsScreen(
                  tutor: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,
                ),

            // Admin-Specific Screens
            '/adminHome': (context) => RoleGuard(
                  allowedRoles: ['admin'],
                  debugShowCheckedModeBanner: false,
                  child: AdminHomeScreen(),
                ),
            '/adminReports': (context) => RoleGuard(
                  allowedRoles: ['admin'],
                  debugShowCheckedModeBanner: false,
                  child: AdminReportsScreen(),
                ),
            '/adminContentModeration': (context) => RoleGuard(
                  allowedRoles: ['admin'],
                  debugShowCheckedModeBanner: false,
                  child: AdminContentModerationScreen(),
                ),
                
            // Request Form Screen (accessible to students)
            '/requestForm': (context) {
              final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
              return RoleGuard(
                allowedRoles: ['student'],
                debugShowCheckedModeBanner: false,
                child: RequestForm(
                  tutorId: args['tutorId'],
                  tutorName: args['tutorName'],
                  subjectName: args['subject'],
                ),
              );
            },
          },
        ),
      ),
    );
  }
}
