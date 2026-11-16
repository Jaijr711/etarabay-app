import 'package:e_tarabay/utils/class_struggle.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> kid(double overall,
        {int mat = 0, int kulay = 0, int pamilya = 0}) =>
    {
      'overallProgress': overall,
      'matematika': {'gamesCompleted': mat, 'totalGames': 21},
      'kulay': {'totalCompleted': kulay, 'totalActivities': 9},
      'pamilya': {'completedLevels': pamilya, 'totalLevels': 9},
    };

void main() {
  test('names the lesson a child is furthest behind the class in', () {
    final marks = ClassStruggle.of({
      'ana': kid(.5, mat: 12, kulay: 6, pamilya: 4),
      'ben': kid(.2, mat: 2, kulay: 6, pamilya: 4), // far behind in Bilang
      'carlo': kid(.4, mat: 10, kulay: 5, pamilya: 3),
      'dina': kid(.3, mat: 9, kulay: 1, pamilya: 4), // behind in Kulay
    });
    expect(marks, {'ben': 'matematika', 'dina': 'kulay'});
  });

  test('a child who has not started is not marked', () {
    final marks = ClassStruggle.of({
      'ana': kid(.5, mat: 12),
      'ben': kid(.4, mat: 10),
      'enzo': kid(0),
    });
    expect(marks.containsKey('enzo'), isFalse);
  });

  test('a lesson nobody has started marks nobody', () {
    final marks = ClassStruggle.of({
      'ana': kid(.5, mat: 12),
      'ben': kid(.4, mat: 11),
    });
    expect(marks, isEmpty);
  });

  test('one child alone has no class to be behind', () {
    expect(ClassStruggle.of({'ana': kid(.1, mat: 1)}), isEmpty);
  });

  test('a record with no lesson counts reads as nothing done', () {
    expect(ClassStruggle.share(null, 'matematika'), 0);
    expect(ClassStruggle.share({'matematika': 'x'}, 'matematika'), 0);
    expect(
        ClassStruggle.share({
          'kulay': {'totalCompleted': 3, 'totalActivities': 9}
        }, 'kulay'),
        closeTo(1 / 3, 1e-9));
  });
}
