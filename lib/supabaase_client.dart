import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClient {
  static final SupabaseClient _instance = SupabaseClient._internal();
  factory SupabaseClient() => _instance;
  SupabaseClient._internal();

  late final Supabase supabase;

  Future<void> init() async {
    // load from assets
    await dotenv.load(fileName: ".env");

    if (dotenv.env['SUPABASE_URL'] == null) {
      final envContent = await rootBundle.loadString('.env');
      final lines = envContent.split('\n');
      for (var line in lines) {
        if (line.contains('=')) {
          final parts = line.split('=');
          if (parts.length == 2) {
            dotenv.env[parts[0].trim()] = parts[1].trim();
          }
        }
      }
    }

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    supabase = Supabase.instance;
  }
}
