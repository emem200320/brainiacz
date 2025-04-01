//lib/utils/constant.dart

class AppConstants {
  // App Name
  static const String appName = 'Tutoring App';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String tutorsCollection = 'tutors';
  static const String studentsCollection = 'students';
  static const String adminsCollection = 'admins';
  static const String subjectsCollection = 'subjects';
  static const String requestsCollection = 'requests';
  static const String messagesCollection = 'messages';
  static const String ratingsCollection = 'ratings';
  static const String complaintsCollection = 'complaints';

  // User Roles
  static const String studentRole = 'student';
  static const String tutorRole = 'tutor';
  static const String adminRole = 'admin';

  // Request Status
  static const String requestPending = 'pending';
  static const String requestAccepted = 'accepted';
  static const String requestRejected = 'rejected';

  // Default Values
  static const String defaultProfileImageUrl = 'https://example.com/default_profile.png';
  static const double defaultRating = 0.0;
  static const bool defaultAvailability = true;

  // Error Messages
  static const String unauthorizedAccessError = 'Unauthorized access';
  static const String loginFailedError = 'Login failed';
  static const String signupFailedError = 'Signup failed';
  static const String fillAllFieldsError = 'Please fill all fields';

  // Success Messages
  static const String profileUpdatedSuccess = 'Profile updated successfully!';
  static const String reviewSubmittedSuccess = 'Review submitted!';

  // Image Picker Constants
  static const double imagePickerQuality = 0.8;
  static const int imagePickerMaxWidth = 800;
  static const int imagePickerMaxHeight = 800;

  // Date and Time Formats
  static const String dateFormat = 'yyyy-MM-dd';
  static const String timeFormat = 'HH:mm';

  // Navigation Routes
  static const String splashRoute = '/splash';
  static const String roleSelectionRoute = '/roleSelection';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String studentHomeRoute = '/studentHome';
  static const String tutorHomeRoute = '/tutorHome';
  static const String adminHomeRoute = '/adminHome';
  static const String studentProfileRoute = '/studentProfile';
  static const String tutorProfileRoute = '/tutorProfile';
  static const String searchRoute = '/search';
  static const String chatRoute = '/chat';

  // API Endpoints (if applicable)
  static const String baseApiUrl = 'https://api.example.com';
  static const String loginApiEndpoint = '$baseApiUrl/login';
  static const String signupApiEndpoint = '$baseApiUrl/signup';

  // Other Constants
  static const int maxSubjects = 5;
  static const int maxBioLength = 500;
  static const int maxReviewLength = 1000;
}