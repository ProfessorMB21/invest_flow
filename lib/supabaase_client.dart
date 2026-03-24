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

    final url = dotenv.env['SUPABASE_URL'];
    final anonKey = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || url.isEmpty) {
      throw Exception('SUPABASE_URL is not set in .env file');
    }
    if (anonKey == null || anonKey.isEmpty) {
      throw Exception('SUPABASE_ANON_KEY is not set in .env file');
    }

    print('***** Supabase URL: ${url.substring(0,20)}... ********');

    await Supabase.initialize(
      url: url,
      anonKey: anonKey
    );
    supabase = Supabase.instance;
  }
}
