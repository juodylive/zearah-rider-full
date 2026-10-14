import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/workspace.dart';
import '../../../core/services/data_store.dart';

/// "Women only" ride option: when ON, only female drivers are searched and the
/// booking is flagged `women_only=1` so the server/admin can see and enforce it.
class WomenOnlyCubit extends Cubit<bool> {
  WomenOnlyCubit() : super(false);

  void set(bool value) => emit(value);

  /// The option is offered to female riders only (gender comes from the
  /// profile: "female"). Unknown/other genders do not see it.
  static bool isFemaleRider() {
    String? g = loginModel?.data?.gender;
    if (g == null || g.isEmpty) {
      try {
        final raw = box.get("UserData");
        if (raw != null) {
          final m = jsonDecode(raw.toString());
          dynamic v = m is Map ? m['gender'] : null;
          if (v == null && m is Map && m['data'] is Map) v = m['data']['gender'];
          g = v?.toString();
        }
      } catch (_) {}
    }
    return (g ?? '').trim().toLowerCase() == 'female';
  }
}
