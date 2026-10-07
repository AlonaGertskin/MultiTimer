import 'package:shared_preferences/shared_preferences.dart';
import 'bundle_model.dart';

class BundleStore {
  static const String _key = 'saved_bundles';

  Future<List<Bundle>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_key);
    if (json == null) return [];
    return Bundle.listFromJson(json);
  }

  Future<void> save(List<Bundle> bundles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, Bundle.listToJson(bundles));
  }
}
