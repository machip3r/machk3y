// Environment Configuration
// Copy this file to lib/core/config/env.dart and update with your Supabase credentials

class Env {
  // Supabase Configuration
  static const String supabaseUrl = 'https://rrlvioujpgppnctmxvqf.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJybHZpb3VqcGdwcG5jdG14dnFmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjEzNjYzMDAsImV4cCI6MjA3Njk0MjMwMH0.cPOmQoxnNhZb3oxywzJ1A7zCAzZfSPoSySJZyPxGOuA';

  // App Configuration
  static const String appName = 'MachKey';
  static const String appVersion = '1.0.0';

  // Security Configuration
  static const int pbkdf2Iterations = 100000;
  static const int keyLength = 256;
  static const int nonceLength = 12;

  // API Endpoints
  static const String hibpApiUrl = 'https://api.pwnedpasswords.com/range/';
  static const String faviconApiUrl =
      'https://www.google.com/s2/favicons?domain=';

  // Development flags
  static const bool isDebug = true;
  static const bool enableLogging = true;
}
