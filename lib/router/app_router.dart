import 'package:go_router/go_router.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/otp_screen.dart';
import '../screens/auth/registration_screen.dart';
import '../screens/customer/dashboard_screen.dart';
import '../screens/customer/history_screen.dart';
import '../screens/customer/settings_screen.dart';
import '../screens/customer/notification_screen.dart';
import '../screens/customer/profile_detail_screen.dart';
import '../screens/rescuer/dashboard_screen.dart';
import '../screens/rescuer/earnings_screen.dart';
import '../screens/rescuer/profile_screen.dart';
import '../screens/customer/create_request_screen.dart';
import '../screens/customer/offers_screen.dart';
import '../screens/customer/tracking_screen.dart';
import '../screens/customer/rating_screen.dart';
import '../screens/rescuer/profile_setup_screen.dart';
import '../screens/rescuer/incoming_requests_screen.dart';
import '../screens/rescuer/fare_offer_screen.dart';
import '../screens/rescuer/navigation_map_screen.dart';
import '../screens/rescuer/account_status_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/role-selection',
    routes: [
      GoRoute(
        path: '/role-selection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OTPScreen(),
      ),
      GoRoute(
        path: '/registration',
        builder: (context, state) => const RegistrationScreen(),
      ),
      // Customer Routes
      GoRoute(
        path: '/customer-dashboard',
        builder: (context, state) => const CustomerDashboardScreen(),
      ),
      GoRoute(
        path: '/customer-history',
        builder: (context, state) => const CustomerHistoryScreen(),
      ),
      GoRoute(
        path: '/customer-settings',
        builder: (context, state) => const CustomerSettingsScreen(),
      ),
      GoRoute(
        path: '/customer-notifications',
        builder: (context, state) => const CustomerNotificationScreen(),
      ),
      GoRoute(
        path: '/customer-profile',
        builder: (context, state) => const CustomerProfileDetailScreen(),
      ),
      GoRoute(
        path: '/create-request',
        builder: (context, state) {
          final problemType =
              state.uri.queryParameters['problem'] ?? 'General Assistance';
          return CreateRequestScreen(problemType: problemType);
        },
      ),
      GoRoute(
        path: '/offers',
        builder: (context, state) => const OffersScreen(),
      ),
      GoRoute(
        path: '/tracking',
        builder: (context, state) => const TrackingScreen(),
      ),
      GoRoute(
        path: '/rating',
        builder: (context, state) => const RatingScreen(),
      ),
      // Rescuer Routes
      GoRoute(
        path: '/rescuer-dashboard',
        builder: (context, state) => const RescuerDashboardScreen(),
      ),
      GoRoute(
        path: '/rescuer-earnings',
        builder: (context, state) => const RescuerEarningsScreen(),
      ),
      GoRoute(
        path: '/rescuer-profile',
        builder: (context, state) => const RescuerProfileScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/incoming-requests',
        builder: (context, state) => const IncomingRequestsScreen(),
      ),
      GoRoute(
        path: '/fare-offer',
        builder: (context, state) => const FareOfferScreen(),
      ),
      GoRoute(
        path: '/navigation-map',
        builder: (context, state) => const NavigationMapScreen(),
      ),
      GoRoute(
        path: '/account-status',
        builder: (context, state) => const AccountStatusScreen(),
      ),
    ],
  );
}
