class RankService {
  static String rankFromPoints(int points) {
    if (points < 850) return 'Rekrut';
    if (points < 950) return 'Sergent';
    if (points < 1050) return 'Løjtnant';
    if (points < 1150) return 'Kaptajn';
    if (points < 1300) return 'Major';
    if (points < 1450) return 'Oberst';
    if (points < 1650) return 'General';
    return 'Marskal';
  }

  static String nextRankFromPoints(int points) {
    if (points < 850) return 'Sergent';
    if (points < 950) return 'Løjtnant';
    if (points < 1050) return 'Kaptajn';
    if (points < 1150) return 'Major';
    if (points < 1300) return 'Oberst';
    if (points < 1450) return 'General';
    if (points < 1650) return 'Marskal';
    return 'Højeste rang';
  }

  static int? pointsToNextRank(int points) {
    if (points < 850) return 850 - points;
    if (points < 950) return 950 - points;
    if (points < 1050) return 1050 - points;
    if (points < 1150) return 1150 - points;
    if (points < 1300) return 1300 - points;
    if (points < 1450) return 1450 - points;
    if (points < 1650) return 1650 - points;
    return null;
  }
}
