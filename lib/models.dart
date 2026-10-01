class Zikr {
  final String id;
  final String arabic;
  final String name;
  final String translation;
  final bool isCustom;

  const Zikr({
    required this.id,
    required this.arabic,
    required this.name,
    this.translation = '',
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'arabic': arabic,
        'name': name,
        'translation': translation,
      };

  factory Zikr.fromJson(Map<dynamic, dynamic> json) => Zikr(
        id: json['id'] as String,
        arabic: (json['arabic'] ?? '') as String,
        name: (json['name'] ?? '') as String,
        translation: (json['translation'] ?? '') as String,
        isCustom: true,
      );
}

const List<Zikr> builtInAzkar = [
  Zikr(
    id: 'subhanallah',
    arabic: 'سُبْحَانَ اللّٰهِ',
    name: 'سبحان اللہ',
    translation: 'اللہ پاک ہے۔',
  ),
  Zikr(
    id: 'alhamdulillah',
    arabic: 'الْحَمْدُ لِلّٰهِ',
    name: 'الحمدللہ',
    translation: 'تمام تعریفیں اللہ ہی کے لیے ہیں۔',
  ),
  Zikr(
    id: 'allahuakbar',
    arabic: 'اللّٰهُ أَكْبَرُ',
    name: 'اللہ اکبر',
    translation: 'اللہ سب سے بڑا ہے۔',
  ),
  Zikr(
    id: 'astaghfirullah',
    arabic: 'أَسْتَغْفِرُ اللّٰهَ',
    name: 'استغفار',
    translation: 'میں اللہ سے مغفرت طلب کرتا ہوں۔',
  ),
  Zikr(
    id: 'tawheed',
    arabic: 'لَا إِلٰهَ إِلَّا اللّٰهُ',
    name: 'کلمۂ توحید',
    translation: 'اللہ کے سوا کوئی معبود نہیں۔',
  ),
  Zikr(
    id: 'hawqala',
    arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللّٰهِ',
    name: 'حوقلہ',
    translation: 'اللہ کے بغیر نہ کوئی طاقت ہے نہ قوت۔',
  ),
  Zikr(
    id: 'yunus',
    arabic: 'لَا إِلٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
    name: 'دعائے یونسؑ',
    translation:
        'اے اللہ! تیرے سوا کوئی معبود نہیں، تو پاک ہے، بے شک میں ظالموں میں سے تھا۔',
  ),
  Zikr(
    id: 'salawat',
    arabic: 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَىٰ مُحَمَّدٍ',
    name: 'درود شریف',
    translation: 'اے اللہ! محمد ﷺ پر رحمت اور سلام نازل فرما۔',
  ),
];

class Ayat {
  final String arabic;
  final String urdu;
  final String ref;
  const Ayat(this.arabic, this.urdu, this.ref);
}

const List<Ayat> ayatList = [
  Ayat(
    'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ',
    'یاد رکھو! اللہ کے ذکر ہی سے دلوں کو اطمینان حاصل ہوتا ہے۔',
    'سورۃ الرعد، 13:28',
  ),
  Ayat(
    'فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ',
    'پس تم مجھے یاد کرو، میں تمہیں یاد کروں گا، اور میرا شکر ادا کرو اور ناشکری نہ کرو۔',
    'سورۃ البقرۃ، 2:152',
  ),
  Ayat(
    'وَاذْكُرُوا اللَّهَ كَثِيرًا لَّعَلَّكُمْ تُفْلِحُونَ',
    'اور اللہ کو بہت زیادہ یاد کرو تاکہ تم فلاح پاؤ۔',
    'سورۃ الأنفال، 8:45',
  ),
  Ayat(
    'يَا أَيُّهَا الَّذِينَ آمَنُوا اذْكُرُوا اللَّهَ ذِكْرًا كَثِيرًا',
    'اے ایمان والو! اللہ کو کثرت سے یاد کرو۔',
    'سورۃ الأحزاب، 33:41',
  ),
  Ayat(
    'وَاذْكُر رَّبَّكَ إِذَا نَسِيتَ',
    'اور جب بھول جاؤ تو اپنے رب کو یاد کرو۔',
    'سورۃ الکہف، 18:24',
  ),
];

/// Threshold definitions for the achievements list. `metric` is either
/// 'total' or 'streak'.
class Achievement {
  final String icon;
  final String title;
  final String desc;
  final String metric;
  final int threshold;
  const Achievement(this.icon, this.title, this.desc, this.metric, this.threshold);
}

const List<Achievement> achievementDefs = [
  Achievement('🌱', 'پہلا قدم', 'کم از کم 100 اذکار مکمل کریں', 'total', 100),
  Achievement('🌿', 'ہزار کا سفر', 'کل 1,000 اذکار مکمل کریں', 'total', 1000),
  Achievement('🏅', 'پانچ ہزار', 'کل 5,000 اذکار مکمل کریں', 'total', 5000),
  Achievement('💎', 'دس ہزار', 'کل 10,000 اذکار مکمل کریں', 'total', 10000),
  Achievement('🔥', 'مسلسل 7 دن', 'سات دن کا streak مکمل کریں', 'streak', 7),
];
