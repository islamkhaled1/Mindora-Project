import '../models/baseline_assessment_models.dart';

/// Predefined list of 8 supportive baseline performance tasks.
///
/// Strictly covers the 4 backend score dimensions (2 tasks per domain):
/// - Motor (Tasks 1, 2)
/// - Communication (Tasks 3, 4)
/// - Cognitive (Tasks 5, 6)
/// - Emotional (Tasks 7, 8)
final List<AssessmentTask> kDefaultAssessmentTasks = [
  // 1. Motor Domain
  const AssessmentTask(
    id: 'motor_fine',
    domain: AssessmentDomain.motor,
    title: 'التناسق الحركي الدقيق واستخدام الأصابع',
    description:
        'مدى قدرة الطفل على الإمساك بالأشياء الصغيرة واستخدام الأدوات أو المكعبات أثناء اللعب.',
    options: [
      AssessmentTaskOption(
        label: 'يحتاج إلى مساعدة كاملة في الإمساك والتحكم',
        points: 25.0,
      ),
      AssessmentTaskOption(
        label: 'يمسك بالأشياء ولكن يحتاج لمساعدة لتوجيه حركته',
        points: 50.0,
      ),
      AssessmentTaskOption(
        label: 'يمسك بالأدوات ويؤدي معظم الحركات بتوجيه بسيط',
        points: 75.0,
      ),
      AssessmentTaskOption(
        label: 'يتحكم بالأشياء الدقيقة باستقلالية وسهولة',
        points: 100.0,
      ),
    ],
  ),
  const AssessmentTask(
    id: 'motor_gross',
    domain: AssessmentDomain.motor,
    title: 'التوازن والحركة الكلية للجسم',
    description:
        'مستوى ثبات الطفل وتوازنه أثناء المشي، الجري، أو صعود الدرج.',
    options: [
      AssessmentTaskOption(
        label: 'يواجه صعوبة في الحفاظ على التوازن ويحتاج للمساعدة المستمرة',
        points: 25.0,
      ),
      AssessmentTaskOption(
        label: 'يمشي بثبات نسبي ولكنه يحتاج لمساعدة عند الحركة السريعة',
        points: 50.0,
      ),
      AssessmentTaskOption(
        label: 'يتحرك ويتنقل بثبات مع حاجة يسيرة للتوجيه',
        points: 75.0,
      ),
      AssessmentTaskOption(
        label: 'حركته وتوازنه متناسقان ويتحرك باستقلالية تامة',
        points: 100.0,
      ),
    ],
  ),

  // 2. Communication Domain
  const AssessmentTask(
    id: 'comm_expressive',
    domain: AssessmentDomain.communication,
    title: 'التعبير عن الاحتياجات والرغبات',
    description:
        'كيف يعبر الطفل عما يحتاجه (بالإشارة، الأصوات، الإيماءات، أو الكلمات).',
    options: [
      AssessmentTaskOption(
        label: 'يصعب عليه التعبير عن احتياجاته بمفرده ويحتاج مساعدة كاملة',
        points: 25.0,
      ),
      AssessmentTaskOption(
        label: 'يعبر بالإشارة البسيطة أو الأصوات بمساعدة وتخمين الأهل',
        points: 50.0,
      ),
      AssessmentTaskOption(
        label: 'يستخدم كلمات أو إشارات واضحة لطلب ما يريد',
        points: 75.0,
      ),
      AssessmentTaskOption(
        label: 'يعبر بوضوح واستقلالية تامة عن كافة رغباته',
        points: 100.0,
      ),
    ],
  ),
  const AssessmentTask(
    id: 'comm_receptive',
    domain: AssessmentDomain.communication,
    title: 'الفهم والاستجابة للتوجيهات البسيطة',
    description:
        'مدى استجابة الطفل عند مناداته باسمه أو إعطائه طلباً بسيطاً ومألوفاً.',
    options: [
      AssessmentTaskOption(
        label: 'نادراً ما يستجيب للنداء أو التوجيهات اللفظية المباشرة',
        points: 25.0,
      ),
      AssessmentTaskOption(
        label: 'يستجيب أحياناً بعد تكرار النداء ولفت انتباهه بحركة أو لمس',
        points: 50.0,
      ),
      AssessmentTaskOption(
        label: 'يستجيب للتوجيهات والنداء المألوف في أغلب الأوقات',
        points: 75.0,
      ),
      AssessmentTaskOption(
        label: 'يفهم ويستجيب بسرعة وبشكل مباشر للتعليمات البسيطة',
        points: 100.0,
      ),
    ],
  ),

  // 3. Cognitive Domain
  const AssessmentTask(
    id: 'cog_attention',
    domain: AssessmentDomain.cognitive,
    title: 'مدى التركيز والانتباه في النشاط',
    description:
        'الفترة التي يستطيع الطفل خلالها الاستمرار في نشاط واحد موجه دون تشتت سريع.',
    options: [
      AssessmentTaskOption(
        label: 'يتشتت سريعاً جداً (أقل من دقيقتين في النشاط الواحد)',
        points: 25.0,
      ),
      AssessmentTaskOption(
        label: 'يستمر في النشاط من 3 إلى 5 دقائق بتشجيع ومساندة مستمرة',
        points: 50.0,
      ),
      AssessmentTaskOption(
        label: 'يحافظ على تركيزه من 5 إلى 10 دقائق في الأنشطة المفضلة',
        points: 75.0,
      ),
      AssessmentTaskOption(
        label: 'يركز باهتمام لأكثر من 10 دقائق في الأنشطة الموجهة',
        points: 100.0,
      ),
    ],
  ),
  const AssessmentTask(
    id: 'cog_problem_solving',
    domain: AssessmentDomain.cognitive,
    title: 'المطابقة وحل المشكلات البسيطة',
    description:
        'قدرة الطفل على مطابقة الألوان، وضع الأشكال في أماكنها، أو البحث عن لعبة.',
    options: [
      AssessmentTaskOption(
        label: 'يحتاج إلى إرشاده ووضع القطع في يده بالكامل لإكمال النشاط',
        points: 25.0,
      ),
      AssessmentTaskOption(
        label: 'يحاول المطابقة بنشاط ولكنه يحتاج لمساعدة متكررة لإكمالها',
        points: 50.0,
      ),
      AssessmentTaskOption(
        label: 'يطابق الأشكال الأساسية بنجاح بعد محاولات تجريبية بسيطة',
        points: 75.0,
      ),
      AssessmentTaskOption(
        label: 'يحل الأنشطة التركيبية والمطابقة بسهولة واستقلالية',
        points: 100.0,
      ),
    ],
  ),

  // 4. Emotional & Social Domain
  const AssessmentTask(
    id: 'emo_social',
    domain: AssessmentDomain.emotional,
    title: 'التفاعل الاجتماعي والمشاركة',
    description:
        'تفاعل الطفل مع الوالدين والمحيطين وتبادل الابتسامات أو الاهتمام المشترك.',
    options: [
      AssessmentTaskOption(
        label: 'يفضل اللعب بمفرده تماماً ويتجنب التفاعل الاجتماعي المباشر',
        points: 25.0,
      ),
      AssessmentTaskOption(
        label: 'يتفاعل لفترات قصيرة عند المبادرة والتشجيع المستمر من الأهل',
        points: 50.0,
      ),
      AssessmentTaskOption(
        label: 'يشارك ويتفاعل بإيجابية مع أفراد الأسرة في معظم الأوقات',
        points: 75.0,
      ),
      AssessmentTaskOption(
        label: 'مبادر في التواصل والتفاعل الاجتماعي ويستمتع باللعب التشاركي',
        points: 100.0,
      ),
    ],
  ),
  const AssessmentTask(
    id: 'emo_regulation',
    domain: AssessmentDomain.emotional,
    title: 'التنظيم والتكيف مع تغيير النشاط',
    description:
        'كيف يتصرف الطفل عند انتهاء نشاط ممتع أو الانتقال إلى نشاط جديد.',
    options: [
      AssessmentTaskOption(
        label: 'يظهر انزعاجاً كبيراً ويستغرق وقتاً طويلاً للهدوء عند الانتقال',
        points: 25.0,
      ),
      AssessmentTaskOption(
        label: 'يحتاج إلى مساندة واحتواء ملحوظ ليهدأ ويتكيف مع التغيير',
        points: 50.0,
      ),
      AssessmentTaskOption(
        label: 'يتكيف مع التغيير بعد تهيئة بسيطة وتوضيح هادئ من الوالدين',
        points: 75.0,
      ),
      AssessmentTaskOption(
        label: 'مرن في الانتقال بين الأنشطة ويتكيف بسهولة مع التغييرات',
        points: 100.0,
      ),
    ],
  ),
];

/// Encapsulates assessment progress and deterministic scoring calculation.
class BaselineAssessmentState {
  final List<AssessmentTask> tasks;
  int currentTaskIndex = 0;

  /// Map of task ID to selected option index (0..3).
  final Map<String, int> _selectedOptionIndices = {};

  BaselineAssessmentState({List<AssessmentTask>? tasks})
      : tasks = tasks ?? kDefaultAssessmentTasks;

  int get totalTasks => tasks.length;

  AssessmentTask get currentTask => tasks[currentTaskIndex];

  bool get isFirstTask => currentTaskIndex == 0;

  bool get isLastTask => currentTaskIndex == tasks.length - 1;

  int? getSelectedOptionIndex(String taskId) => _selectedOptionIndices[taskId];

  void selectOption(String taskId, int optionIndex) {
    _selectedOptionIndices[taskId] = optionIndex;
  }

  bool get isCurrentTaskAnswered =>
      _selectedOptionIndices.containsKey(currentTask.id);

  bool get allTasksAnswered =>
      tasks.every((t) => _selectedOptionIndices.containsKey(t.id));

  void nextTask() {
    if (currentTaskIndex < tasks.length - 1) {
      currentTaskIndex++;
    }
  }

  void previousTask() {
    if (currentTaskIndex > 0) {
      currentTaskIndex--;
    }
  }

  /// Calculates points earned for a specific task.
  /// Defaults to 0.0 if not yet answered.
  double getTaskPoints(String taskId) {
    final idx = _selectedOptionIndices[taskId];
    if (idx == null) return 0.0;
    final task = tasks.firstWhere((t) => t.id == taskId);
    if (idx < 0 || idx >= task.options.length) return 0.0;
    return task.options[idx].points;
  }

  /// Deterministic Motor score: Average points across all Motor tasks.
  double get motorScore {
    final motorTasks =
        tasks.where((t) => t.domain == AssessmentDomain.motor).toList();
    if (motorTasks.isEmpty) return 0.0;
    final sum = motorTasks.fold<double>(
        0.0, (acc, t) => acc + getTaskPoints(t.id));
    return _round(sum / motorTasks.length);
  }

  /// Deterministic Communication score: Average points across all Communication tasks.
  double get communicationScore {
    final commTasks = tasks
        .where((t) => t.domain == AssessmentDomain.communication)
        .toList();
    if (commTasks.isEmpty) return 0.0;
    final sum = commTasks.fold<double>(
        0.0, (acc, t) => acc + getTaskPoints(t.id));
    return _round(sum / commTasks.length);
  }

  /// Deterministic Cognitive score: Average points across all Cognitive tasks.
  double get cognitiveScore {
    final cogTasks =
        tasks.where((t) => t.domain == AssessmentDomain.cognitive).toList();
    if (cogTasks.isEmpty) return 0.0;
    final sum =
        cogTasks.fold<double>(0.0, (acc, t) => acc + getTaskPoints(t.id));
    return _round(sum / cogTasks.length);
  }

  /// Deterministic Emotional score: Average points across all Emotional tasks.
  double get emotionalScore {
    final emoTasks =
        tasks.where((t) => t.domain == AssessmentDomain.emotional).toList();
    if (emoTasks.isEmpty) return 0.0;
    final sum =
        emoTasks.fold<double>(0.0, (acc, t) => acc + getTaskPoints(t.id));
    return _round(sum / emoTasks.length);
  }

  /// Deterministic Overall score: Arithmetic mean of the 4 domain scores.
  double get overallScore {
    final avg = (motorScore +
            communicationScore +
            cognitiveScore +
            emotionalScore) /
        4.0;
    return _round(avg);
  }

  /// Converts the current state to a validated request DTO for the backend.
  RecordBaselineAssessmentRequest toRequest() {
    if (!allTasksAnswered) {
      throw StateError('يجب إكمال جميع مهام التقييم قبل إرسال النتيجة.');
    }

    return RecordBaselineAssessmentRequest(
      overallScore: overallScore,
      cognitiveScore: cognitiveScore,
      communicationScore: communicationScore,
      motorScore: motorScore,
      emotionalScore: emotionalScore,
    );
  }

  static double _round(double val) {
    return double.parse(val.toStringAsFixed(1));
  }
}
