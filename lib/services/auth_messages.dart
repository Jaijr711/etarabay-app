import 'package:flutter/widgets.dart';

import '../l10n/app_localizations.dart';

/// Turns an [AuthService] result into words the reader understands.
///
/// The service returns a `code` naming what happened rather than a sentence:
/// it has no BuildContext and no business knowing which language anyone reads.
/// Every screen that shows one of its results calls this.
///
/// The English sentence the service still carries is the fallback, so a code
/// added without a translation says something rather than nothing.
String authMessage(BuildContext context, Map<String, dynamic> result) {
  final loc = AppLocalizations.of(context)!;
  final fallback = (result['message'] ?? '').toString();

  switch (result['code']) {
    case 'nothingToUpdate':
      return loc.authNothingToUpdate;
    case 'saveFailed':
      return loc.authSaveFailed;
    case 'usernameTaken':
      return loc.authUsernameTaken;
    case 'useTeacherButton':
      return loc.authUseTeacherButton;
    case 'usernameNotFound':
      return loc.authUsernameNotFound;
    case 'wrongStudentNumber':
      return loc.authWrongStudentNumber;
    case 'connectionError':
      return loc.authConnectionError;
    case 'numberEmpty':
      return loc.authNumberEmpty;
    case 'numberFormat':
      return loc.authNumberFormat;
    case 'numberRepeated':
      return loc.authNumberRepeated;
    case 'numberTaken':
      return loc.authNumberTaken;
    case 'enrollFailed':
      return loc.authEnrollFailed;
    case 'noStudentsToDelete':
      return loc.authNoStudentsToDelete;
    case 'allStudentsDeleted':
      return loc.authAllStudentsDeleted;
    case 'deleteFailed':
      return loc.authDeleteFailed;
    case 'noStudentsToReset':
      return loc.authNoStudentsToReset;
    case 'resetDone':
      return loc
          .authResetDone((result['updatedStudents'] as List?)?.length ?? 0);
    case 'passwordTooShort':
      return loc.authPasswordTooShort;
    case 'resetFailed':
      return loc.authResetFailed;
    default:
      return fallback;
  }
}
