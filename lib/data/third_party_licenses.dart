import 'package:flutter/foundation.dart';

/// Licences for artwork that ships inside the app but is not ours.
///
/// The medals on the Awards page use Microsoft's Fluent Emoji 3D pictures
/// (assets/images/badges/), which are MIT-licensed: free to use in the app as
/// long as this notice travels with it. Registering it puts it in the app's
/// licence list beside the packages' own.
void registerThirdPartyLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['Fluent Emoji (Microsoft)'],
      _fluentEmojiMit,
    );
    // Bundled so the web version has its letters with no connection
    // (assets/fonts/, with the full licence text beside the files).
    yield const LicenseEntryWithLineBreaks(
      ['Roboto (Google)'],
      'Copyright 2011 Google Inc. All Rights Reserved.\n\n'
      'Licensed under the Apache License, Version 2.0 (the "License"); '
      'you may not use this file except in compliance with the License. '
      'You may obtain a copy of the License at\n\n'
      '    http://www.apache.org/licenses/LICENSE-2.0\n\n'
      'Unless required by applicable law or agreed to in writing, software '
      'distributed under the License is distributed on an "AS IS" BASIS, '
      'WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or '
      'implied. See the License for the specific language governing '
      'permissions and limitations under the License.',
    );
  });
}

const String _fluentEmojiMit = '''MIT License

Copyright (c) Microsoft Corporation.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.''';
