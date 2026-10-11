/**
 * The quiz content: 3 levels × 10 quizzes × 5 questions = 150 questions.
 * Every quiz has one question of each of the five types, in this order:
 * word meaning, listen & select, true/false, fill in the blank, translate.
 *
 * Fields per type (see lib/core/quiz_service.dart):
 *   wm  arabic, transliteration, options (English), correctIndex
 *   ls  arabic (spoken aloud), options ("(Translit) عربي"), correctIndex
 *   tf  arabic, english, isCorrect
 *   fb  promptArabic ("___" marks the blank), promptEnglish, answer, acceptedAnswers?
 *   tr  promptEnglish, answer, acceptedAnswers?
 * Typed answers are compared ignoring vowel marks, hamza/alef variants, ى/ي and
 * punctuation, so acceptedAnswers only needs genuinely different wording.
 * Option order is shuffled in the app each time, so correctIndex position doesn't matter.
 */
const wm = (arabic, transliteration, options, correctIndex) =>
  ({type: "word_meaning", arabic, transliteration, options, correctIndex});
const ls = (arabic, options, correctIndex) =>
  ({type: "listen_select", arabic, options, correctIndex});
const tf = (arabic, english, isCorrect) =>
  ({type: "true_false", arabic, english, isCorrect});
const fb = (promptArabic, promptEnglish, answer, acceptedAnswers = []) =>
  ({type: "fill_blank", promptArabic, promptEnglish, answer, acceptedAnswers});
const tr = (promptEnglish, answer, acceptedAnswers = []) =>
  ({type: "translate_to_arabic", promptEnglish, answer, acceptedAnswers});

const beginner = [
  // 1 — greetings & basics
  [
    wm("مرحبا", "Marhaba", ["Hello", "Goodbye", "Thanks", "Sorry"], 0),
    ls("شكرًا", ["(Shukran) شكرًا", "(Afwan) عفوًا", "(Marhaban) مرحبًا", "(Ma'a salama) مع السلامة"], 0),
    tf("قطة", "Dog", false),
    fb("صباح ___", "Good morning! (the blank means \"the goodness\")", "الخير"),
    tr("I am a student", "أنا طالب", ["أنا طالبة"]),
  ],
  // 2 — everyday objects
  [
    wm("كتاب", "Kitaab", ["Book", "Pen", "Table", "Door"], 0),
    ls("قلم", ["(Baab) باب", "(Kitaab) كتاب", "(Qalam) قلم", "(Tawila) طاولة"], 2),
    tf("شمس", "Sun", true),
    fb("هذا ___ كبير", "This is a big ___ (house)", "بيت", ["البيت"]),
    tr("The book is big", "الكتاب كبير"),
  ],
  // 3 — food & drink
  [
    wm("ماء", "Maa'", ["Water", "Bread", "Milk", "Tea"], 0),
    ls("خبز", ["(Khubz) خبز", "(Kharouf) خروف", "(Khayma) خيمة", "(Khaatam) خاتم"], 0),
    tf("حليب", "Tea", false),
    fb("أنا أشرب ___", "I drink ___ (water)", "ماء", ["الماء"]),
    tr("I eat bread", "أنا آكل الخبز", ["آكل الخبز", "أنا آكل خبزا", "آكل خبزا"]),
  ],
  // 4 — family
  [
    wm("أم", "Umm", ["Mother", "Father", "Sister", "Brother"], 0),
    ls("أب", ["(Ab) أب", "(Akh) أخ", "(Ukht) أخت", "(Umm) أم"], 0),
    tf("أخ", "Sister", false),
    fb("أنا أحب ___", "I love my ___ (mother)", "أمي", ["والدتي"]),
    tr("This is my father", "هذا أبي", ["هذا والدي"]),
  ],
  // 5 — colors
  [
    wm("أحمر", "Ahmar", ["Red", "Blue", "Green", "Yellow"], 0),
    ls("أخضر", ["(Akhdar) أخضر", "(Azraq) أزرق", "(Aswad) أسود", "(Abyad) أبيض"], 0),
    tf("أبيض", "White", true),
    fb("السماء ___", "The sky is ___ (blue)", "زرقاء"),
    tr("The car is red", "السيارة حمراء"),
  ],
  // 6 — numbers
  [
    wm("ثلاثة", "Thalatha", ["One", "Two", "Three", "Four"], 2),
    ls("خمسة", ["(Arba'a) أربعة", "(Khamsa) خمسة", "(Sitta) ستة", "(Sab'a) سبعة"], 1),
    tf("عشرة", "Ten", true),
    fb("واحد، اثنان، ___", "One, two, ___ (three)", "ثلاثة"),
    tr("I have two books", "عندي كتابان", ["لدي كتابان", "عندي كتابين", "لدي كتابين"]),
  ],
  // 7 — places
  [
    wm("مدرسة", "Madrasa", ["School", "Hospital", "Market", "Park"], 0),
    ls("سوق", ["(Suq) سوق", "(Saaq) ساق", "(Sayf) صيف", "(Sijn) سجن"], 0),
    tf("مستشفى", "School", false),
    fb("أذهب إلى ___ كل صباح", "I go to ___ every morning (school)", "المدرسة"),
    tr("The school is big", "المدرسة كبيرة"),
  ],
  // 8 — days & time
  [
    wm("يوم", "Yawm", ["Day", "Night", "Week", "Year"], 0),
    ls("صباح", ["(Masaa') مساء", "(Sabaah) صباح", "(Layl) ليل", "(Yawm) يوم"], 1),
    tf("ليل", "Night", true),
    fb("بعد الاثنين يأتي يوم ___", "After Monday comes ___ (Tuesday)", "الثلاثاء"),
    tr("Today is Friday", "اليوم هو الجمعة", ["اليوم الجمعة"]),
  ],
  // 9 — animals & nature
  [
    wm("كلب", "Kalb", ["Dog", "Cat", "Bird", "Horse"], 0),
    ls("حصان", ["(Hisaan) حصان", "(Hasan) حسن", "(Hamaam) حمام", "(Himaar) حمار"], 0),
    tf("قمر", "Sun", false),
    fb("القطة تحب ___", "The cat loves ___ (milk)", "الحليب", ["حليب"]),
    tr("The cat is small", "القطة صغيرة"),
  ],
  // 10 — review
  [
    wm("يأكل", "Ya'kul", ["He eats", "He drinks", "He sleeps", "He walks"], 0),
    ls("سيارة", ["(Sayyara) سيارة", "(Safina) سفينة", "(Tayyara) طيارة", "(Darraaja) دراجة"], 0),
    tf("بيت", "House", true),
    fb("أنا ___ الكتاب", "I ___ the book (read)", "أقرأ"),
    tr("I love Arabic", "أحب اللغة العربية", ["أحب العربية", "أنا أحب اللغة العربية", "أنا أحب العربية"]),
  ],
];

const intermediate = [
  // 1 — verbs & prepositions
  [
    wm("يكتب", "Yaktub", ["He reads", "He writes", "He eats", "He sleeps"], 1),
    ls("مفتاح", ["(Miftaah) مفتاح", "(Maktab) مكتب", "(Maftooh) مفتوح", "(Mat'am) مطعم"], 0),
    tf("أخت", "Mother", false),
    fb("أنا ___ إلى المدرسة كل يوم", "I ___ to school every day", "أذهب"),
    tr("The book is on the table", "الكتاب على الطاولة", ["الكتاب فوق الطاولة"]),
  ],
  // 2 — places & wants
  [
    wm("مستشفى", "Mustashfa", ["Hospital", "Airport", "Market", "Library"], 0),
    ls("مدينة", ["(Madrasa) مدرسة", "(Mudarris) مدرس", "(Madeena) مدينة", "(Maktaba) مكتبة"], 2),
    tf("يشرب", "He drinks", true),
    fb("القلم ___ الحقيبة", "The pen is ___ the bag (in)", "في", ["داخل"]),
    tr("I want to drink water", "أريد أن أشرب الماء",
        ["أريد أن أشرب ماء", "أريد شرب الماء", "أنا أريد أن أشرب الماء"]),
  ],
  // 3 — daily routine
  [
    wm("يستيقظ", "Yastayqidh", ["He wakes up", "He sleeps", "He sits", "He runs"], 0),
    ls("فطور", ["(Ghadaa') غداء", "(Futuur) فطور", "(Ashaa') عشاء", "(Shurba) شوربة"], 1),
    tf("عشاء", "Breakfast", false),
    fb("أنام في ___", "I sleep at ___ (night)", "الليل"),
    tr("I wake up early", "أستيقظ مبكرا", ["أصحو مبكرا", "أنا أستيقظ مبكرا"]),
  ],
  // 4 — weather & seasons
  [
    wm("مطر", "Matar", ["Rain", "Snow", "Wind", "Cloud"], 0),
    ls("شتاء", ["(Sayf) صيف", "(Shitaa') شتاء", "(Rabee') ربيع", "(Kharif) خريف"], 1),
    tf("ثلج", "Snow", true),
    fb("في ___ الجو حار", "In ___ the weather is hot (summer)", "الصيف"),
    tr("The weather is cold today", "الجو بارد اليوم", ["الطقس بارد اليوم"]),
  ],
  // 5 — shopping
  [
    wm("سعر", "Si'r", ["Price", "Money", "Shop", "Gift"], 0),
    ls("رخيص", ["(Ghaali) غالي", "(Rakhees) رخيص", "(Jadeed) جديد", "(Qadeem) قديم"], 1),
    tf("غالي", "Expensive", true),
    fb("كم ___ هذا الكتاب؟", "How much is this book? (price)", "سعر", ["ثمن"]),
    tr("How much does it cost?", "كم سعره؟", ["بكم هذا؟", "كم ثمنه؟", "بكم؟"]),
  ],
  // 6 — directions
  [
    wm("يمين", "Yameen", ["Right", "Left", "Straight", "Behind"], 0),
    ls("شارع", ["(Shaari') شارع", "(Shaatir) شاطر", "(Shaahid) شاهد", "(Shaa'ir) شاعر"], 0),
    tf("يسار", "Right", false),
    fb("المطعم ___ المدرسة", "The restaurant is ___ the school (next to)", "بجانب",
        ["بجوار", "قرب", "بقرب", "بالقرب من"]),
    tr("Where is the hospital?", "أين المستشفى؟", ["أين يقع المستشفى؟"]),
  ],
  // 7 — jobs
  [
    wm("طبيب", "Tabeeb", ["Doctor", "Teacher", "Engineer", "Driver"], 0),
    ls("مهندس", ["(Muhandis) مهندس", "(Mudarris) مدرس", "(Mumarrid) ممرض", "(Muhaasib) محاسب"], 0),
    tf("معلم", "Teacher", true),
    fb("أبي ___ في المستشفى", "My father is a ___ at the hospital (doctor)", "طبيب"),
    tr("She is a teacher", "هي معلمة", ["هي مدرسة", "هي أستاذة"]),
  ],
  // 8 — feelings
  [
    wm("سعيد", "Sa'eed", ["Happy", "Sad", "Angry", "Tired"], 0),
    ls("متعب", ["(Mut'ab) متعب", "(Muhibb) محب", "(Mu'allim) معلم", "(Muntazir) منتظر"], 0),
    tf("حزين", "Happy", false),
    fb("أنا ___ لأن الجو جميل", "I am ___ because the weather is nice (happy)", "سعيد",
        ["سعيدة", "مسرور", "مسرورة", "فرحان", "فرحانة"]),
    tr("I am very tired", "أنا متعب جدا", ["أنا متعبة جدا", "أنا تعبان جدا", "أنا تعبانة جدا"]),
  ],
  // 9 — family & friends
  [
    wm("جدة", "Jadda", ["Grandmother", "Aunt", "Cousin", "Daughter"], 0),
    ls("صديق", ["(Sadeeq) صديق", "(Sa'eed) سعيد", "(Saghir) صغير", "(Saabir) صابر"], 0),
    tf("عم", "Aunt", false),
    fb("عندي ___ كبيرة", "I have a big ___ (family)", "عائلة", ["أسرة", "عيلة"]),
    tr("My friend lives in Amman", "صديقي يسكن في عمان", ["صديقي يعيش في عمان"]),
  ],
  // 10 — review
  [
    wm("يتعلم", "Yata'allam", ["He learns", "He teaches", "He forgets", "He asks"], 0),
    ls("جامعة", ["(Jaami'a) جامعة", "(Jaami') جامع", "(Jami'an) جميعا", "(Jamaal) جمال"], 0),
    tf("سفر", "Travel", true),
    fb("أحب أن ___ العربية", "I like to ___ Arabic (learn)", "أتعلم", ["أدرس"]),
    tr("I study Arabic at the university", "أدرس اللغة العربية في الجامعة",
        ["أدرس العربية في الجامعة", "أتعلم العربية في الجامعة", "أتعلم اللغة العربية في الجامعة"]),
  ],
];

const advanced = [
  // 1 — knowledge & duty
  [
    wm("حكومة", "Hukuma", ["Government", "Economy", "Society", "Culture"], 0),
    ls("اقتصاد", ["(Iqtisaad) اقتصاد", "(Ijtimaa') اجتماع", "(Intikhaab) انتخاب", "(Istiqlaal) استقلال"], 0),
    tf("مستقبل", "Future", true),
    fb("يجب أن ___ القوانين", "We must ___ the laws (respect)", "نحترم"),
    tr("Knowledge is power", "العلم قوة", ["المعرفة قوة"]),
  ],
  // 2 — responsibility
  [
    wm("مسؤولية", "Mas'uliyya", ["Opportunity", "Responsibility", "Freedom", "Experience"], 1),
    ls("مكتبة", ["(Maktab) مكتب", "(Kitaaba) كتابة", "(Maktaba) مكتبة", "(Katiba) كتيبة"], 2),
    tf("ماضي", "Present", false),
    fb("هذا الكتاب ___ من ذاك", "This book is ___ than that one (better)", "أفضل", ["أحسن"]),
    tr("I have been studying Arabic for two years", "أدرس اللغة العربية منذ سنتين",
        ["أدرس العربية منذ سنتين", "أتعلم اللغة العربية منذ سنتين", "أتعلم العربية منذ سنتين",
          "أدرس اللغة العربية منذ عامين", "أدرس العربية منذ عامين", "أتعلم العربية منذ عامين"]),
  ],
  // 3 — society
  [
    wm("مجتمع", "Mujtama'", ["Society", "Government", "Law", "Border"], 0),
    ls("انتخابات", ["(Intikhaabaat) انتخابات", "(Ijtimaa'aat) اجتماعات", "(Istithmaar) استثمار", "(Istiqbaal) استقبال"], 0),
    tf("قانون", "Law", true),
    fb("حقوق ___ مهمة", "___ rights are important (human)", "الإنسان"),
    tr("Freedom is a human right", "الحرية حق من حقوق الإنسان", ["الحرية حق للإنسان"]),
  ],
  // 4 — economy
  [
    wm("شركة", "Sharika", ["Company", "Factory", "Bank", "Office"], 0),
    ls("مصنع", ["(Masna') مصنع", "(Maslak) مسلك", "(Maktab) مكتب", "(Masraf) مصرف"], 0),
    tf("راتب", "Tax", false),
    fb("يعمل أخي في ___ كبيرة", "My brother works in a big ___ (company)", "شركة", ["مؤسسة"]),
    tr("The economy depends on tourism", "يعتمد الاقتصاد على السياحة", ["الاقتصاد يعتمد على السياحة"]),
  ],
  // 5 — education & research
  [
    wm("بحث", "Bahth", ["Research", "Exam", "Lesson", "Degree"], 0),
    ls("امتحان", ["(Imtihaan) امتحان", "(Intiqaal) انتقال", "(Intizaar) انتظار", "(Intishaar) انتشار"], 0),
    tf("معرفة", "Knowledge", true),
    fb("كتبت ___ عن تاريخ المدينة", "I wrote a ___ about the city's history (research)", "بحثا",
        ["بحث", "مقالا", "مقال", "مقالة"]),
    tr("Education is the key to success", "التعليم مفتاح النجاح", ["التعليم هو مفتاح النجاح"]),
  ],
  // 6 — health & environment
  [
    wm("بيئة", "Bee'a", ["Environment", "Weather", "Nature", "Pollution"], 0),
    ls("صحة", ["(Sihha) صحة", "(Sahraa') صحراء", "(Safha) صفحة", "(Sakhra) صخرة"], 0),
    tf("تلوث", "Health", false),
    fb("يجب أن نحافظ على ___", "We must protect the ___ (environment)", "البيئة"),
    tr("Exercise is good for health", "الرياضة مفيدة للصحة", ["الرياضة جيدة للصحة"]),
  ],
  // 7 — needs & difficulty
  [
    wm("يحتاج", "Yahtaaj", ["He needs", "He avoids", "He refuses", "He accepts"], 0),
    ls("صعب", ["(Sa'b) صعب", "(Sab') سبع", "(Subh) صبح", "(Sabr) صبر"], 0),
    tf("سهل", "Difficult", false),
    fb("هذا السؤال ___ جدا", "This question is very ___ (difficult)", "صعب", ["معقد"]),
    tr("I need more time", "أحتاج إلى مزيد من الوقت",
        ["أحتاج وقتا أكثر", "أحتاج إلى وقت أكثر", "أحتاج مزيدا من الوقت", "أحتاج المزيد من الوقت"]),
  ],
  // 8 — connectors
  [
    wm("لكن", "Laakin", ["But", "Because", "Therefore", "Or"], 0),
    ls("لأن", ["(Li'anna) لأن", "(Laakin) لكن", "(Lammaa) لما", "(Law) لو"], 0),
    tf("بعد", "Before", false),
    fb("ذهبت إلى السوق ___ لم أشتر شيئا", "I went to the market ___ I didn't buy anything (but)", "لكن",
        ["ولكن", "لكنني", "لكني"]),
    tr("I stayed home because it was raining", "بقيت في البيت لأنها كانت تمطر",
        ["بقيت في المنزل لأنها كانت تمطر", "مكثت في المنزل لأنها كانت تمطر", "بقيت في المنزل بسبب المطر"]),
  ],
  // 9 — culture & values
  [
    wm("كرم", "Karam", ["Generosity", "Courage", "Patience", "Honesty"], 0),
    ls("ضيافة", ["(Diyaafa) ضيافة", "(Diyaa') ضياء", "(Dayf) ضيف", "(Dayaa') ضياع"], 0),
    tf("صبر", "Patience", true),
    fb("الصبر ___ الفرج", "Patience is the ___ of relief (key)", "مفتاح"),
    tr("Generosity is a part of Arab culture", "الكرم جزء من الثقافة العربية", ["الكرم جزء من ثقافة العرب"]),
  ],
  // 10 — conditionals
  [
    wm("إذا", "Idhaa", ["If / When", "Until", "Unless", "Although"], 0),
    ls("رغم", ["(Raghm) رغم", "(Ragheef) رغيف", "(Raghba) رغبة", "(Raghwa) رغوة"], 0),
    tf("حتى", "Until", true),
    fb("___ كنت غنيا لسافرت حول العالم", "___ I were rich, I would travel around the world (if)", "لو"),
    tr("If you study hard, you will succeed", "إذا درست بجد فسوف تنجح",
        ["إذا اجتهدت نجحت", "إذا درست بجد تنجح", "إذا درست بجد ستنجح", "إن درست بجد نجحت", "إذا درست بجد فستنجح"]),
  ],
];

module.exports = {bank: {beginner, intermediate, advanced}};
