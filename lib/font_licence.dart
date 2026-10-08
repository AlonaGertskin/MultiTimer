import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void registerFontLicence() {
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/Nunito-OFL.txt');
    yield LicenseEntryWithLineBreaks(['Nunito'], text);
  });
}
