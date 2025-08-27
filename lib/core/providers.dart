import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'services/openai_service.dart';

/// Global provider for the application locale.
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));

/// Provides a single instance of [OpenAIService].
final openAIServiceProvider = Provider<OpenAIService>((ref) => OpenAIService());

