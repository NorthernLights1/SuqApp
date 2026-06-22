class SupabaseConstants {
  SupabaseConstants._();

  // Values injected at build/run time via --dart-define-from-file=config/env.json
  // Never hardcode these — see config/env.json.example
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}
