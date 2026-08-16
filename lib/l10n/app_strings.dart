import 'package:flutter/widgets.dart';

import '../app/app_scope.dart';

/// Small, dependency-free UI string catalog.
///
/// Reads the active language from [AppScope] and returns the matching string.
/// Without a scope (standalone widgets in tests) it falls back to English, so
/// individual screens keep their base-language text when not hosted by the
/// app shell. `{}` placeholders are replaced in order by [args].
class AppStrings {
  AppStrings._();

  static String t(
    BuildContext context,
    String key, {
    List<Object?> args = const [],
  }) {
    var text = _lookup(key, AppScope.maybeOf(context)?.languageCode);
    for (final arg in args) {
      text = text.replaceFirst('{}', '$arg');
    }
    return text;
  }

  static String _lookup(String key, String? languageCode) {
    switch (languageCode) {
      case 'fr':
        return _fr[key] ?? _en[key] ?? key;
      case 'ar':
        return _ar[key] ?? _fr[key] ?? _en[key] ?? key;
      default:
        return _en[key] ?? key;
    }
  }

  static const _en = <String, String>{
    // Navigation
    'nav_home': 'Home',
    'nav_learn': 'Learn',
    'nav_practice': 'Practice',
    'nav_progress': 'Progress',
    'nav_profile': 'Profile',
    // Onboarding
    'profile_page_title': 'BAC profile',
    'onboarding_title': 'Set up your journey',
    'back': 'Back',
    'next': 'Next',
    'start_studying': 'Start studying',
    'save_changes': 'Save changes',
    'onboarding_stream_title':
        'Which BAC stream are you preparing for?',
    'onboarding_stream_subtitle':
        'This helps us keep your study journey focused.',
    'bac_stream_label': 'BAC stream',
    'stream_experimental_sciences': 'Experimental sciences',
    'stream_mathematics': 'Mathematics',
    'stream_technical_mathematics': 'Technical mathematics',
    'stream_management_economics': 'Management and economics',
    'stream_literature_philosophy': 'Literature and philosophy',
    'stream_foreign_languages': 'Foreign languages',
    'stream_arts': 'Arts',
    'onboarding_year_title': 'When are you taking the BAC?',
    'onboarding_year_subtitle':
        'We will use this for your countdown and planning.',
    'bac_year_label': 'BAC year',
    'onboarding_target_title': 'What is your target average?',
    'onboarding_target_subtitle':
        'This is your personal goal, not an official prediction.',
    'onboarding_language_title': 'Which language do you prefer?',
    'onboarding_language_subtitle':
        'We will use this preference as localization expands.',
    'onboarding_goal_title': 'How much can you study each day?',
    'onboarding_goal_subtitle':
        'A small consistent goal is better than an unrealistic one.',
    // Profile
    'profile_title': 'Profile',
    'profile_header_default_title': 'MY Algeria BAC',
    'profile_header_default_subtitle': 'Your focused BAC study space.',
    'settings_title': 'Settings',
    'appearance': 'Appearance',
    'system_default': 'System default',
    'light': 'Light',
    'dark': 'Dark',
    'study_preferences': 'Study preferences',
    'study_preferences_subtitle': 'Set your daily study plan.',
    'coming_next': 'Coming next',
    'set_up_bac_profile': 'Set up BAC profile',
    'bac_profile': 'BAC profile',
    'set_up_bac_profile_subtitle':
        'Choose your stream, target, language, and daily goal.',
    'minutes_per_day': '{} minutes per day',
    'content_title': 'Content',
    'content_subtitle': 'Content version and updates.',
    'content_version': 'Content version',
    'content_source': 'Source',
    'content_source_bundled': 'Bundled with app',
    'content_source_cached': 'Cached release',
    'content_last_checked': 'Last checked',
    'content_never_checked': 'Never',
    'content_check_updates': 'Check for updates',
    'content_checking': 'Checking…',
    'content_checked_ok': 'Checked.',
    'content_clear_cache': 'Clear cached content',
    'content_clear_confirm_title': 'Clear cached content?',
    'content_clear_confirm_body':
        'Downloads will be removed. The app will use the bundled version until the next sync.',
    'content_cleared': 'Cached content cleared.',
    'content_sync_failed': 'Update check failed. Your current content is safe.',
    // Study settings
    'study_preferences_saved': 'Study preferences saved.',
    'how_much_study': 'How much can you study each day?',
    'weak_points': 'Weak points',
    'weak_points_subtitle': 'Prioritize concepts you struggle with.',
    'lessons': 'Lessons',
    'lessons_subtitle': 'Include new and unfinished lessons.',
    'practice': 'Practice',
    'practice_subtitle': 'Include targeted questions.',
    'save': 'Save',
    // Home
    'ready_for_bac': 'Ready for BAC?',
    'todays_mission': 'TODAY\'S MISSION',
    'set_bac_date': 'Set BAC date',
    'set_bac_date_prompt': 'Set your BAC exam date\nto start the countdown.',
    'stat_questions': 'Questions',
    'stat_longest_streak': 'Longest streak',
    'stat_weak_concepts': 'Weak concepts',
    'enter_arena': 'Enter the Arena',
    'banner_checking': 'Checking for content updates…',
    'banner_content_updated': 'Content updated to v{}',
    'banner_content_downloaded': 'Content v{} downloaded',
    'banner_content_up_to_date': 'Content up to date (v{})',
    'banner_up_to_date': 'Up to date',
    'banner_offline_cached': 'Offline — using cached content (v{})',
    'banner_offline_bundled': 'Offline — using bundled content',
    'banner_update_rejected_cached': 'Update rejected — keeping v{}',
    'banner_update_rejected_bundled':
        'Update rejected — using bundled content',
    'banner_using_bundled': 'Using bundled content',
    // Learn
    'learn_title': 'Learn',
    'choose_subject': 'Choose a subject to start learning.',
    'learning_path': 'Learning path',
    'learning_path_subtitle':
        'Complete the lessons in order and practice what you learn.',
    // BAC Arena
    'bac_arena': 'BAC Arena',
    'could_not_load_exams': 'Could not load exams.',
    // Lesson
    'lesson': 'Lesson',
    'lesson_not_found': 'Lesson not found.',
    'estimated_time': 'Estimated time',
    'minutes_value': '{} minutes',
    'concepts_label': 'Concepts',
    'concepts_count': '{} concepts',
    'lesson_content': 'Lesson content',
    'quiz_unavailable': 'Quiz unavailable',
    'start_quiz': 'Start quiz ({})',
    'demo_content_warning':
        'This is demonstration content only. '
        'It is not official BAC material.',
    'what_you_will_learn': 'What you will learn',
    'bullet_core_idea': 'Understand the core idea.',
    'bullet_important_concepts': 'Recognize the important concepts.',
    'bullet_practice': 'Practice with questions.',
    // Quiz
    'end_quiz': 'End quiz',
    'end_quiz_confirm':
        'You can end the quiz early and save your current score.',
    'continue': 'Continue',
    'no_questions_yet': 'No questions available yet.',
    'finish_and_save': 'Finish and save',
    // Quiz result
    'result_excellent': 'Excellent!',
    'result_great_work': 'Great work!',
    'result_good_start': 'Good start!',
    'result_keep_practicing': 'Keep practicing!',
    'quiz_result': 'Quiz result',
    'correct_of_total': '{}/{} correct',
    'accuracy': 'Accuracy',
    'correct': 'Correct',
    'wrong': 'Wrong',
    'xp': 'XP',
    'back_to_lesson': 'Back to lesson',
    'level_up': 'LEVEL UP!',
    'level_x_to_y': '{} → {}',
    'achievement_unlocked': 'Achievement unlocked',
    // Exam session
    'submit_exam_question': 'Submit exam?',
    'submit_unanswered_one':
        'You have 1 unanswered question. Unanswered questions score zero.',
    'submit_unanswered_many':
        'You have {} unanswered questions. Unanswered questions score zero.',
    'submit_all_answered':
        'You answered every question. Submit your exam now?',
    'keep_working': 'Keep working',
    'submit': 'Submit',
    'exam_not_found': 'Exam not found.',
    'exam_no_questions': 'This exam has no questions yet.',
    'bac_boss': 'BAC Boss',
    'question_of': 'Question {} of {}',
    'answered_of': '{}/{} answered',
    'flag': 'Flag',
    'flagged': 'Flagged',
    'question_navigator': 'Question navigator',
    'previous': 'Previous',
    'submit_exam': 'Submit exam',
    'full_paper': 'Full paper',
    'time': 'Time',
    'questions': 'Questions',
    'hints': 'Hints',
    'distractions': 'Distractions',
    'disabled': 'Disabled',
    'exam_intro_rules':
        'Treat this like a real exam. No hints, no XP popups, '
        'no interruptions. Manage the clock and review your '
        'answers before submitting.',
    'resume_note':
        'You have an unfinished attempt — {} seconds left.\n'
        'Resuming keeps your answers and the clock.',
    'resume_note_no_time':
        'You have an unfinished attempt.\n'
        'Resuming keeps your answers and the clock.',
    'resume_exam': 'Resume exam',
    'enter_the_boss': 'Enter the Boss',
    'unanswered': 'Unanswered',
    'answered': 'Answered',
    // Exam report
    'exam_report': 'Exam report',
    'time_ran_out': 'Time ran out — your exam was submitted automatically.',
    'out_of_20': 'out of 20',
    'time_used': 'Time used',
    'time_management': 'Time management',
    'score_disclaimer':
        'Scores are a demo estimate: every question counts equally '
        'toward /20. Official point allocations are not part of the '
        'source content.',
    'strong_concepts': 'Strong concepts',
    'nothing_to_highlight': 'Nothing to highlight yet.',
    'percent_correct': '{}% correct',
    'weak_concepts': 'Weak concepts',
    'no_weak_concepts_attempt': 'No weak concepts in this attempt.',
    'rematch': 'Rematch',
    'back_to_practice': 'Back to practice',
    'passing_grade_reached': 'Passing grade reached — keep it up!',
    'not_result_wanted_question': 'Not the result you wanted?',
    'comeback_pitch':
        'We built a 7-day plan around {} to get you back on track.',
    'improving_vs': 'You are improving: +{} vs your previous attempt.',
    'previous_attempt':
        'Previous attempt: {}/20. This is where the rematch starts.',
    'start_comeback': 'Start comeback',
    'level_up_banner': '🎉 LEVEL UP!',
    'xp_reward': '+{} XP',
    // Streak
    'my_streak': 'My Streak',
    'unable_to_load_streak': 'Unable to load your streak.',
    'day_streak': 'DAY STREAK',
    'longest_days': 'Longest: {} days',
    'today': 'Today',
    'minutes_of_goal': '{} / {} minutes',
    'streak_alive_today': '🔥 You kept your streak alive today.',
    'streak_goal_hint':
        'Complete at least {} minutes of real study activity.',
    'next_milestone': 'Next milestone',
    'milestone_days': '{} consecutive study days',
    'streak_motivation_title': 'Every day counts.',
    'streak_motivation_body':
        'You do not need to study a lot every day. The point is to never stop.',
    // Weak points
    'weak_point_hunter': 'Weak Point Hunter',
    'weak_point_hunter_badge': 'WEAK POINT HUNTER',
    'weak_points_header_one': '1 concept needs your attention',
    'weak_points_header_many': '{} concepts need your attention',
    'weak_points_evidence':
        'Evidence-backed: every concept here has at least 3 attempts and '
        'is ranked by recency-weighted mastery. A single wrong answer '
        'never makes the list.',
    'percent_mastery': '{}% mastery',
    'attempts_count': '{} attempts',
    'train_this_weakness': 'Train this weakness',
    'priority_critical': 'CRITICAL',
    'priority_high': 'HIGH',
    'priority_medium': 'MEDIUM',
    'priority_low': 'LOW',
    'not_enough_data': 'Not enough data yet',
    'not_enough_data_hint':
        'Answer at least 3 questions on a concept and we will start '
        'identifying your weak points.',
    // Mission
    'mission_du_jour': 'Mission du Jour',
    'no_mission': 'No mission available.',
    'mission_du_jour_badge': 'MISSION DU JOUR',
    'today_badge': 'TODAY',
    'todays_progress': 'Today\'s progress',
    'completed': 'Completed',
    'mission_completed_xp': 'Mission completed! XP awarded.',
    'come_back_tomorrow': 'Come back tomorrow for a new challenge.',
    'fix_this_weakness': 'Fix this weakness',
    'start_the_exam': 'Start the exam',
    'start_practice': 'Start practice',
    // Practice
    'no_exams_available': 'No exams available yet.',
    'practice_page_subtitle':
        'Take full BAC exams under timed conditions.',
    'section_one': 'section',
    'section_many': 'sections',
    'demo_tag': 'Demo',
    'minutes_short': '{} min',
    // Study plan
    'my_study_plan': 'My Study Plan',
    'plan_error': 'We could not create your study plan.',
    'retry': 'Retry',
    'smart_study_plan': '🎯 SMART STUDY PLAN',
    'tasks_count': '{} / {} tasks',
    'minutes_available': '{} minutes available today',
    // Comeback
    'comeback_plan': 'Comeback plan',
    'not_result_wanted_plain': 'Not the result you wanted.',
    'here_is_7day_plan': 'Here is your 7-day plan to beat it.',
    'last_score': 'Last score',
    'target': 'Target',
    'up': 'Up',
    'down': 'Down',
    'main_target': 'Main target: {}',
    'plan_explainer':
        'Days 1–3 build this concept back up, day 4 is a timed '
        'rehearsal, and day 7 is the rematch.',
    'rematch_now': 'Rematch now',
    // Home
    'set_date': 'Set date',
    'bac_countdown': 'BAC COUNTDOWN',
    'days_remaining': '{} DAYS',
    'weeks_hours': '{} weeks • {} hours',
    'plan_hook': 'A plan built around what you need to improve.',
    'overall_accuracy': 'Overall accuracy',
    'your_bac_profile': 'Your BAC profile',
    'profile_empty_hint':
        'Answer some questions to see your per-subject profile.',
    'no_weak_concepts_keep_up': 'No weak concepts — keep it up!',
    'concepts_need_attention': '{} concepts need attention',
    'bac_boss_brand': 'BAC BOSS',
    'survive_full_paper': 'Can you survive a full paper?',
    'exams_available_one':
        '1 exam available • timed • real conditions',
    'exams_available_many':
        '{} exams available • timed • real conditions',
  };

  static const _fr = <String, String>{
    'nav_home': 'Accueil',
    'nav_learn': 'Apprendre',
    'nav_practice': 'Entraînement',
    'nav_progress': 'Progression',
    'nav_profile': 'Profil',
    'profile_page_title': 'Profil BAC',
    'onboarding_title': 'Prépare ton parcours',
    'back': 'Retour',
    'next': 'Suivant',
    'start_studying': 'Commencer à étudier',
    'save_changes': 'Enregistrer',
    'onboarding_stream_title': 'Pour quel bac te prépares-tu ?',
    'onboarding_stream_subtitle':
        'Ça nous aide à garder ton parcours ciblé.',
    'bac_stream_label': 'Filière du bac',
    'stream_experimental_sciences': 'Sciences expérimentales',
    'stream_mathematics': 'Mathématiques',
    'stream_technical_mathematics': 'Technique mathématique',
    'stream_management_economics': 'Gestion et économie',
    'stream_literature_philosophy': 'Lettres et philosophie',
    'stream_foreign_languages': 'Langues étrangères',
    'stream_arts': 'Arts',
    'onboarding_year_title': 'Quand passes-tu le bac ?',
    'onboarding_year_subtitle':
        'On s’en servira pour ton compte à rebours et ta planification.',
    'bac_year_label': 'Année du bac',
    'onboarding_target_title': 'Quel est ton objectif de moyenne ?',
    'onboarding_target_subtitle':
        'C’est ton objectif personnel, pas une prédiction officielle.',
    'onboarding_language_title': 'Quelle langue préfères-tu ?',
    'onboarding_language_subtitle':
        'On utilisera ce choix au fur et à mesure de la localisation.',
    'onboarding_goal_title':
        'Combien de temps peux-tu étudier chaque jour ?',
    'onboarding_goal_subtitle':
        'Un petit objectif régulier vaut mieux qu’un objectif irréaliste.',
    'profile_title': 'Profil',
    'profile_header_default_title': 'MY Algeria BAC',
    'profile_header_default_subtitle':
        'Ton espace d’étude BAC concentré.',
    'settings_title': 'Réglages',
    'appearance': 'Apparence',
    'system_default': 'Par défaut',
    'light': 'Clair',
    'dark': 'Sombre',
    'study_preferences': 'Préférences d’étude',
    'study_preferences_subtitle': 'Règle ton plan d’étude quotidien.',
    'coming_next': 'À venir',
    'set_up_bac_profile': 'Configurer le profil BAC',
    'bac_profile': 'Profil BAC',
    'set_up_bac_profile_subtitle':
        'Choisis ta filière, ton objectif, ta langue et ton but quotidien.',
    'minutes_per_day': '{} minutes par jour',
    'content_title': 'Contenu',
    'content_subtitle': 'Version du contenu et mises à jour.',
    'content_version': 'Version du contenu',
    'content_source': 'Source',
    'content_source_bundled': 'Inclus avec l’application',
    'content_source_cached': 'Version en cache',
    'content_last_checked': 'Dernière vérification',
    'content_never_checked': 'Jamais',
    'content_check_updates': 'Vérifier les mises à jour',
    'content_checking': 'Vérification…',
    'content_checked_ok': 'Vérifié.',
    'content_clear_cache': 'Effacer le contenu en cache',
    'content_clear_confirm_title': 'Effacer le contenu en cache ?',
    'content_clear_confirm_body':
        'Les téléchargements seront supprimés. L’application utilisera la version incluse jusqu’à la prochaine synchronisation.',
    'content_cleared': 'Contenu en cache effacé.',
    'content_sync_failed':
        'Échec de la vérification. Ton contenu actuel est conservé.',
    'study_preferences_saved': 'Préférences d’étude enregistrées.',
    'how_much_study': 'Combien de temps peux-tu étudier chaque jour ?',
    'weak_points': 'Points faibles',
    'weak_points_subtitle':
        'Priorise les concepts qui te posent problème.',
    'lessons': 'Leçons',
    'lessons_subtitle': 'Inclure les leçons nouvelles et inachevées.',
    'practice': 'Entraînement',
    'practice_subtitle': 'Inclure des questions ciblées.',
    'save': 'Enregistrer',
    'ready_for_bac': 'Prêt pour le BAC ?',
    'todays_mission': 'MISSION DU JOUR',
    'set_bac_date': 'Choisir la date du BAC',
    'set_bac_date_prompt':
        'Choisis la date de ton examen BAC\npour lancer le compte à rebours.',
    'stat_questions': 'Questions',
    'stat_longest_streak': 'Plus longue série',
    'stat_weak_concepts': 'Concepts faibles',
    'enter_arena': 'Entrer dans l’arène',
    'banner_checking': 'Vérification des mises à jour…',
    'banner_content_updated': 'Contenu mis à jour (v{})',
    'banner_content_downloaded': 'Contenu v{} téléchargé',
    'banner_content_up_to_date': 'Contenu à jour (v{})',
    'banner_up_to_date': 'À jour',
    'banner_offline_cached': 'Hors ligne — contenu en cache (v{})',
    'banner_offline_bundled': 'Hors ligne — contenu intégré',
    'banner_update_rejected_cached':
        'Mise à jour refusée — conservation de v{}',
    'banner_update_rejected_bundled':
        'Mise à jour refusée — contenu intégré',
    'banner_using_bundled': 'Contenu intégré',
    'learn_title': 'Apprendre',
    'choose_subject': 'Choisis une matière pour commencer à apprendre.',
    'learning_path': 'Parcours d’apprentissage',
    'learning_path_subtitle':
        'Suis les leçons dans l’ordre et entraîne-toi sur ce que tu apprends.',
    'bac_arena': 'Arène du BAC',
    'could_not_load_exams': 'Impossible de charger les examens.',
    // Lesson
    'lesson': 'Leçon',
    'lesson_not_found': 'Leçon introuvable.',
    'estimated_time': 'Temps estimé',
    'minutes_value': '{} minutes',
    'concepts_label': 'Concepts',
    'concepts_count': '{} concepts',
    'lesson_content': 'Contenu de la leçon',
    'quiz_unavailable': 'Quiz indisponible',
    'start_quiz': 'Commencer le quiz ({})',
    'demo_content_warning':
        'Ceci est un contenu de démonstration uniquement. '
        'Ce n’est pas du matériel officiel du BAC.',
    'what_you_will_learn': 'Ce que tu vas apprendre',
    'bullet_core_idea': 'Comprendre l’idée principale.',
    'bullet_important_concepts': 'Reconnaître les concepts importants.',
    'bullet_practice': 'S’entraîner avec des questions.',
    // Quiz
    'end_quiz': 'Terminer le quiz',
    'end_quiz_confirm':
        'Tu peux terminer le quiz tôt et enregistrer ton score actuel.',
    'continue': 'Continuer',
    'no_questions_yet': 'Aucune question disponible pour le moment.',
    'finish_and_save': 'Terminer et enregistrer',
    // Quiz result
    'result_excellent': 'Excellent !',
    'result_great_work': 'Bon travail !',
    'result_good_start': 'Bon début !',
    'result_keep_practicing': 'Continue de t’entraîner !',
    'quiz_result': 'Résultat du quiz',
    'correct_of_total': '{}/{} correctes',
    'accuracy': 'Précision',
    'correct': 'Correctes',
    'wrong': 'Fausses',
    'xp': 'XP',
    'back_to_lesson': 'Retour à la leçon',
    'level_up': 'NIVEAU SUPÉRIEUR !',
    'achievement_unlocked': 'Succès débloqué',
    // Exam session
    'submit_exam_question': 'Soumettre l’examen ?',
    'submit_unanswered_one':
        'Tu as 1 question sans réponse. '
        'Les questions sans réponse comptent zéro.',
    'submit_unanswered_many':
        'Tu as {} questions sans réponse. '
        'Les questions sans réponse comptent zéro.',
    'submit_all_answered':
        'Tu as répondu à toutes les questions. Soumettre l’examen maintenant ?',
    'keep_working': 'Continuer',
    'submit': 'Soumettre',
    'exam_not_found': 'Examen introuvable.',
    'exam_no_questions': 'Cet examen n’a pas encore de questions.',
    'bac_boss': 'BAC Boss',
    'question_of': 'Question {} sur {}',
    'answered_of': '{}/{} répondues',
    'flag': 'Marquer',
    'flagged': 'Marquée',
    'question_navigator': 'Navigateur de questions',
    'previous': 'Précédent',
    'submit_exam': 'Soumettre l’examen',
    'full_paper': 'Sujet complet',
    'time': 'Temps',
    'questions': 'Questions',
    'hints': 'Indices',
    'distractions': 'Distractions',
    'disabled': 'Désactivées',
    'exam_intro_rules':
        'Traite ça comme un vrai examen. Pas d’indices, pas de popups XP, '
        'aucune interruption. Gère le chrono et revois tes réponses avant '
        'de soumettre.',
    'resume_note':
        'Tu as une tentative inachevée — {} secondes restantes.\n'
        'Reprendre garde tes réponses et le chrono.',
    'resume_note_no_time':
        'Tu as une tentative inachevée.\n'
        'Reprendre garde tes réponses et le chrono.',
    'resume_exam': 'Reprendre l’examen',
    'enter_the_boss': 'Entrer dans l’arène',
    'unanswered': 'Sans réponse',
    'answered': 'Répondue',
    // Exam report
    'exam_report': 'Rapport d’examen',
    'time_ran_out': 'Le temps est écoulé — ton examen a été soumis '
        'automatiquement.',
    'out_of_20': 'sur 20',
    'time_used': 'Temps utilisé',
    'time_management': 'Gestion du temps',
    'score_disclaimer':
        'Les scores sont une estimation de démo : chaque question compte '
        'également vers /20. Les barèmes officiels ne font pas partie du '
        'contenu source.',
    'strong_concepts': 'Concepts solides',
    'nothing_to_highlight': 'Rien à souligner pour le moment.',
    'percent_correct': '{}% correctes',
    'weak_concepts': 'Concepts faibles',
    'no_weak_concepts_attempt': 'Aucun concept faible dans cette tentative.',
    'rematch': 'Revanche',
    'back_to_practice': 'Retour à l’entraînement',
    'passing_grade_reached': 'Seuil de réussite atteint — continue !',
    'not_result_wanted_question': 'Pas le résultat que tu espérais ?',
    'comeback_pitch':
        'Nous avons construit un plan de 7 jours autour de {} pour te '
        'remettre sur les rails.',
    'improving_vs':
        'Tu progresses : +{} par rapport à ta tentative précédente.',
    'previous_attempt':
        'Tentative précédente : {}/20. C’est là que la revanche commence.',
    'start_comeback': 'Commencer le plan de reprise',
    'level_up_banner': '🎉 NIVEAU SUPÉRIEUR !',
    'level_x_to_y': '{} → {}',
    'xp_reward': '+{} XP',
    // Streak
    'my_streak': 'Ma série',
    'unable_to_load_streak': 'Impossible de charger ta série.',
    'day_streak': 'JOURS DE SÉRIE',
    'longest_days': 'Record : {} jours',
    'today': 'Aujourd’hui',
    'minutes_of_goal': '{} / {} minutes',
    'streak_alive_today': '🔥 Tu as gardé ta série en vie aujourd’hui.',
    'streak_goal_hint':
        'Termine au moins {} minutes de vraie activité d’étude.',
    'next_milestone': 'Prochain jalon',
    'milestone_days': '{} jours d’étude consécutifs',
    'streak_motivation_title': 'Chaque jour compte.',
    'streak_motivation_body':
        'ماشي لازم تقرا بزاف كل يوم. المهم ما توقفش.',
    // Weak points
    'weak_point_hunter': 'Chasseur de points faibles',
    'weak_point_hunter_badge': 'CHASSEUR DE POINTS FAIBLES',
    'weak_points_header_one': '1 concept a besoin de ton attention',
    'weak_points_header_many': '{} concepts ont besoin de ton attention',
    'weak_points_evidence':
        'Basé sur des preuves : chaque concept ici a au moins 3 tentatives '
        'et est classé par maîtrise pondérée par la récence. Une seule '
        'mauvaise réponse ne crée jamais la liste.',
    'percent_mastery': '{}% de maîtrise',
    'attempts_count': '{} tentatives',
    'train_this_weakness': 'Travailler ce point faible',
    'priority_critical': 'CRITIQUE',
    'priority_high': 'ÉLEVÉE',
    'priority_medium': 'MOYENNE',
    'priority_low': 'BASSE',
    'not_enough_data': 'Pas encore assez de données',
    'not_enough_data_hint':
        'Réponds à au moins 3 questions sur un concept et nous '
        'commencerons à identifier tes points faibles.',
    // Mission
    'mission_du_jour': 'Mission du Jour',
    'no_mission': 'Aucune mission disponible.',
    'mission_du_jour_badge': 'MISSION DU JOUR',
    'today_badge': 'AUJOURD’HUI',
    'todays_progress': 'Progression du jour',
    'completed': 'Terminée',
    'mission_completed_xp': 'Mission terminée ! XP attribués.',
    'come_back_tomorrow': 'Reviens demain pour un nouveau défi.',
    'fix_this_weakness': 'Corriger ce point faible',
    'start_the_exam': 'Commencer l’examen',
    'start_practice': 'Commencer l’entraînement',
    // Practice
    'no_exams_available': 'Aucun examen disponible pour le moment.',
    'practice_page_subtitle':
        'Passe des examens BAC complets dans des conditions chronométrées.',
    'section_one': 'section',
    'section_many': 'sections',
    'demo_tag': 'Démo',
    'minutes_short': '{} min',
    // Study plan
    'my_study_plan': 'Mon plan d’étude',
    'plan_error': 'Impossible de créer ton plan d’étude.',
    'retry': 'Réessayer',
    'smart_study_plan': '🎯 PLAN D’ÉTUDE INTELLIGENT',
    'tasks_count': '{} / {} tâches',
    'minutes_available': '{} minutes disponibles aujourd’hui',
    // Comeback
    'comeback_plan': 'Plan de reprise',
    'not_result_wanted_plain': 'Pas le résultat que tu espérais.',
    'here_is_7day_plan': 'Voici ton plan de 7 jours pour le battre.',
    'last_score': 'Dernier score',
    'target': 'Objectif',
    'up': 'En hausse',
    'down': 'En baisse',
    'main_target': 'Objectif principal : {}',
    'plan_explainer':
        'Les jours 1–3 reconstruisent ce concept, le jour 4 est une '
        'répétition chronométrée, et le jour 7 est la revanche.',
    'rematch_now': 'Revanche maintenant',
    // Home
    'set_date': 'Choisir la date',
    'bac_countdown': 'COMPTE À REBOURS BAC',
    'days_remaining': '{} JOURS',
    'weeks_hours': '{} semaines • {} heures',
    'plan_hook': 'Un plan construit autour de ce que tu dois améliorer.',
    'overall_accuracy': 'Précision globale',
    'your_bac_profile': 'Ton profil BAC',
    'profile_empty_hint':
        'Réponds à quelques questions pour voir ton profil par matière.',
    'no_weak_concepts_keep_up': 'Aucun concept faible — continue !',
    'concepts_need_attention': '{} concepts demandent de l’attention',
    'bac_boss_brand': 'BAC BOSS',
    'survive_full_paper': 'Peux-tu survivre à un sujet complet ?',
    'exams_available_one':
        '1 examen disponible • chronométré • conditions réelles',
    'exams_available_many':
        '{} examens disponibles • chronométré • conditions réelles',
  };

  static const _ar = <String, String>{
    'nav_home': 'الرئيسية',
    'nav_learn': 'تعلّم',
    'nav_practice': 'تمرين',
    'nav_progress': 'التقدّم',
    'nav_profile': 'الملف الشخصي',
    'profile_page_title': 'ملف البكالوريا',
    'onboarding_title': 'جهّز رحلتك',
    'back': 'رجوع',
    'next': 'التالي',
    'start_studying': 'ابدأ الدراسة',
    'save_changes': 'حفظ التغييرات',
    'onboarding_stream_title':
        'ما الشعبة التي تستعد لها في البكالوريا؟',
    'onboarding_stream_subtitle':
        'هذا يساعدنا على إبقاء رحلتك الدراسية مركّزة.',
    'bac_stream_label': 'شعبة البكالوريا',
    'stream_experimental_sciences': 'علوم تجريبية',
    'stream_mathematics': 'رياضيات',
    'stream_technical_mathematics': 'تقني رياضي',
    'stream_management_economics': 'تسيير واقتصاد',
    'stream_literature_philosophy': 'آداب وفلسفة',
    'stream_foreign_languages': 'لغات أجنبية',
    'stream_arts': 'فنون',
    'onboarding_year_title': 'متى تجتاز البكالوريا؟',
    'onboarding_year_subtitle':
        'سنستخدم هذا للعدّ التنازلي والتخطيط.',
    'bac_year_label': 'سنة البكالوريا',
    'onboarding_target_title': 'ما هو المعدل الذي تهدف إليه؟',
    'onboarding_target_subtitle':
        'هذا هدفك الشخصي، وليس توقّعاً رسمياً.',
    'onboarding_language_title': 'ما اللغة التي تفضّلها؟',
    'onboarding_language_subtitle':
        'سنستخدم هذا التفضيل مع توسّع الترجمة.',
    'onboarding_goal_title': 'كم يمكنك أن تدرس كل يوم؟',
    'onboarding_goal_subtitle':
        'هدف صغير ومنتظم أفضل من هدف غير واقعي.',
    'profile_title': 'الملف الشخصي',
    'profile_header_default_title': 'باك الجزائر',
    'profile_header_default_subtitle':
        'مساحة دراستك المركّزة للبكالوريا.',
    'settings_title': 'الإعدادات',
    'appearance': 'المظهر',
    'system_default': 'حسب النظام',
    'light': 'فاتح',
    'dark': 'داكن',
    'study_preferences': 'تفضيلات الدراسة',
    'study_preferences_subtitle': 'حدّد خطتك اليومية.',
    'coming_next': 'قريباً',
    'set_up_bac_profile': 'إعداد ملف البكالوريا',
    'bac_profile': 'ملف البكالوريا',
    'set_up_bac_profile_subtitle':
        'اختر شعبتك وهدفك ولغتك وهدفك اليومي.',
    'minutes_per_day': '{} دقيقة في اليوم',
    'content_title': 'المحتوى',
    'content_subtitle': 'إصدار المحتوى والتحديثات.',
    'content_version': 'إصدار المحتوى',
    'content_source': 'المصدر',
    'content_source_bundled': 'مضمّن مع التطبيق',
    'content_source_cached': 'نسخة مخزنة',
    'content_last_checked': 'آخر فحص',
    'content_never_checked': 'أبداً',
    'content_check_updates': 'التحقق من التحديثات',
    'content_checking': 'جارٍ الفحص…',
    'content_checked_ok': 'تم الفحص.',
    'content_clear_cache': 'مسح المحتوى المخزن',
    'content_clear_confirm_title': 'مسح المحتوى المخزن؟',
    'content_clear_confirm_body':
        'ستُحذف التنزيلات. سيستخدم التطبيق النسخة المضمّنة حتى المزامنة التالية.',
    'content_cleared': 'تم مسح المحتوى المخزن.',
    'content_sync_failed': 'فشل التحقق من التحديثات. المحتوى الحالي آمن.',
    'study_preferences_saved': 'تم حفظ تفضيلات الدراسة.',
    'how_much_study': 'كم يمكنك أن تدرس كل يوم؟',
    'weak_points': 'النقاط الضعيفة',
    'weak_points_subtitle':
        'أولوية للمفاهيم التي تجد فيها صعوبة.',
    'lessons': 'الدروس',
    'lessons_subtitle': 'تضمين الدروس الجديدة وغير المكتملة.',
    'practice': 'التمرين',
    'practice_subtitle': 'تضمين أسئلة موجّهة.',
    'save': 'حفظ',
    'ready_for_bac': 'جاهز للبكالوريا؟',
    'todays_mission': 'مهمة اليوم',
    'set_bac_date': 'تحديد موعد البكالوريا',
    'set_bac_date_prompt': 'حدّد موعد امتحان البكالوريا\nلبدء العدّ التنازلي.',
    'stat_questions': 'الأسئلة',
    'stat_longest_streak': 'أطول سلسلة',
    'stat_weak_concepts': 'المفاهيم الضعيفة',
    'enter_arena': 'دخول الساحة',
    'banner_checking': 'جارٍ التحقق من التحديثات…',
    'banner_content_updated': 'تم تحديث المحتوى (v{})',
    'banner_content_downloaded': 'تم تنزيل المحتوى v{}',
    'banner_content_up_to_date': 'المحتوى محدّث (v{})',
    'banner_up_to_date': 'محدّث',
    'banner_offline_cached': 'غير متصل — استخدام المحتوى المخزّن (v{})',
    'banner_offline_bundled': 'غير متصل — استخدام المحتوى المدمج',
    'banner_update_rejected_cached':
        'تم رفض التحديث — الإبقاء على v{}',
    'banner_update_rejected_bundled':
        'تم رفض التحديث — استخدام المحتوى المدمج',
    'banner_using_bundled': 'استخدام المحتوى المدمج',
    'learn_title': 'تعلّم',
    'choose_subject': 'اختر مادة لبدء التعلّم.',
    'learning_path': 'مسار التعلّم',
    'learning_path_subtitle':
        'أكمل الدروس بالترتيب وتمرّن على ما تتعلمه.',
    'bac_arena': 'ساحة البكالوريا',
    'could_not_load_exams': 'تعذّر تحميل الامتحانات.',
    // Lesson
    'lesson': 'درس',
    'lesson_not_found': 'الدرس غير موجود.',
    'estimated_time': 'المدة التقديرية',
    'minutes_value': '{} دقيقة',
    'concepts_label': 'مفاهيم',
    'concepts_count': '{} مفاهيم',
    'lesson_content': 'محتوى الدرس',
    'quiz_unavailable': 'الاختبار غير متوفر',
    'start_quiz': 'ابدأ الاختبار ({})',
    'demo_content_warning':
        'هذا محتوى تجريبي فقط. '
        'ليس مادة رسمية للبكالوريا.',
    'what_you_will_learn': 'ما الذي ستتعلمه',
    'bullet_core_idea': 'افهم الفكرة الأساسية.',
    'bullet_important_concepts': 'تعرّف على المفاهيم المهمة.',
    'bullet_practice': 'تمرّن بالأسئلة.',
    // Quiz
    'end_quiz': 'إنهاء الاختبار',
    'end_quiz_confirm':
        'يمكنك إنهاء الاختبار مبكراً وحفظ نتيجتك الحالية.',
    'continue': 'متابعة',
    'no_questions_yet': 'لا توجد أسئلة متاحة بعد.',
    'finish_and_save': 'إنهاء وحفظ',
    // Quiz result
    'result_excellent': 'ممتاز!',
    'result_great_work': 'عمل رائع!',
    'result_good_start': 'بداية جيدة!',
    'result_keep_practicing': 'واصل التدريب!',
    'quiz_result': 'نتيجة الاختبار',
    'correct_of_total': '{} من {} صحيحة',
    'accuracy': 'الدقة',
    'correct': 'صحيحة',
    'wrong': 'خاطئة',
    'xp': 'XP',
    'back_to_lesson': 'العودة إلى الدرس',
    'level_up': 'مستوى جديد!',
    'achievement_unlocked': 'إنجاز مفتوح',
    // Exam session
    'submit_exam_question': 'تسليم الامتحان؟',
    'submit_unanswered_one':
        'لديك سؤال واحد بدون إجابة. '
        'الأسئلة التي لم تُجب عنها تُحسب صفراً.',
    'submit_unanswered_many':
        'لديك {} أسئلة بدون إجابة. '
        'الأسئلة التي لم تُجب عنها تُحسب صفراً.',
    'submit_all_answered':
        'أجبت عن جميع الأسئلة. تسليم الامتحان الآن؟',
    'keep_working': 'مواصلة العمل',
    'submit': 'تسليم',
    'exam_not_found': 'الامتحان غير موجود.',
    'exam_no_questions': 'لا توجد أسئلة لهذا الامتحان بعد.',
    'bac_boss': 'بوس البكالوريا',
    'question_of': 'سؤال {} من {}',
    'answered_of': '{}/{} مُجاب',
    'flag': 'تحديد',
    'flagged': 'مُحدّد',
    'question_navigator': 'متصفّح الأسئلة',
    'previous': 'السابق',
    'submit_exam': 'تسليم الامتحان',
    'full_paper': 'موضوع كامل',
    'time': 'الوقت',
    'questions': 'الأسئلة',
    'hints': 'تلميحات',
    'distractions': 'المشتتات',
    'disabled': 'معطّل',
    'exam_intro_rules':
        'تعامل مع هذا كامتحان حقيقي. لا تلميحات، لا نوافذ خبرة، '
        'لا تشتيت. دبّر الوقت وراجع إجاباتك قبل التسليم.',
    'resume_note':
        'لديك محاولة غير مكتملة — متبقٍ {} ثانية.\n'
        'استئناف يحفظ إجاباتك والمؤقت.',
    'resume_note_no_time':
        'لديك محاولة غير مكتملة.\n'
        'الاستئناف يحفظ إجاباتك والمؤقت.',
    'resume_exam': 'استئناف الامتحان',
    'enter_the_boss': 'دخول المعركة',
    'unanswered': 'بدون إجابة',
    'answered': 'مُجاب',
    // Exam report
    'exam_report': 'تقرير الامتحان',
    'time_ran_out': 'انتهى الوقت — تم تسليم امتحانك تلقائياً.',
    'out_of_20': 'من 20',
    'time_used': 'الوقت المستخدم',
    'time_management': 'إدارة الوقت',
    'score_disclaimer':
        'النتائج تقديرية تجريبية: كل سؤال يُحتسب بالتساوي ضمن /20. '
        'التوزيع الرسمي للنقاط ليس جزءاً من المحتوى المصدر.',
    'strong_concepts': 'مفاهيم قوية',
    'nothing_to_highlight': 'لا شيء لإبرازه بعد.',
    'percent_correct': 'صحيح بنسبة {}%',
    'weak_concepts': 'مفاهيم ضعيفة',
    'no_weak_concepts_attempt': 'لا مفاهيم ضعيفة في هذه المحاولة.',
    'rematch': 'إعادة المباراة',
    'back_to_practice': 'العودة إلى التمرين',
    'passing_grade_reached': 'بلغت درجة النجاح — واصل!',
    'not_result_wanted_question': 'ليست النتيجة التي أردتها؟',
    'comeback_pitch':
        'جهّزنا لك خطة 7 أيام حول {} لإعادتك إلى المسار.',
    'improving_vs':
        'أنت تتحسّن: +{} مقارنة بمحاولتك السابقة.',
    'previous_attempt':
        'المحاولة السابقة: {}/20. من هنا تبدأ إعادة المباراة.',
    'start_comeback': 'ابدأ خطة العودة',
    'level_up_banner': '🎉 مستوى جديد!',
    'level_x_to_y': '{} ← {}',
    'xp_reward': '+{} خبرة',
    // Streak
    'my_streak': 'سلسلتي',
    'unable_to_load_streak': 'تعذّر تحميل سلسلتك.',
    'day_streak': 'أيام متتالية',
    'longest_days': 'الأطول: {} أيام',
    'today': 'اليوم',
    'minutes_of_goal': '{} من {} دقيقة',
    'streak_alive_today': '🔥 حافظت على سلسلتك اليوم.',
    'streak_goal_hint':
        'أكمل {} دقيقة على الأقل من نشاط دراسة حقيقي.',
    'next_milestone': 'المحطة القادمة',
    'milestone_days': '{} أيام دراسة متتالية',
    'streak_motivation_title': 'كل يوم له قيمته.',
    'streak_motivation_body':
        'ليس عليك أن تدرس كثيراً كل يوم. المهم ألا تتوقف.',
    // Weak points
    'weak_point_hunter': 'صياد النقاط الضعيفة',
    'weak_point_hunter_badge': 'صياد النقاط الضعيفة',
    'weak_points_header_one': 'مفهوم واحد يحتاج انتباهك',
    'weak_points_header_many': '{} مفاهيم تحتاج انتباهك',
    'weak_points_evidence':
        'مبني على الأدلة: كل مفهوم هنا لديه 3 محاولات على الأقل '
        'ويُرتَّب حسب الإتقان المرجّح بالحداثة. إجابة خاطئة واحدة '
        'لا تدرجه أبداً في القائمة.',
    'percent_mastery': 'إتقان {}%',
    'attempts_count': '{} محاولة',
    'train_this_weakness': 'درّب هذا الضعف',
    'priority_critical': 'حرِج',
    'priority_high': 'عالٍ',
    'priority_medium': 'متوسط',
    'priority_low': 'منخفض',
    'not_enough_data': 'لا توجد بيانات كافية بعد',
    'not_enough_data_hint':
        'أجب عن 3 أسئلة على الأقل حول مفهوم وسنبدأ في تحديد نقاط ضعفك.',
    // Mission
    'mission_du_jour': 'مهمة اليوم',
    'no_mission': 'لا توجد مهمة متاحة.',
    'mission_du_jour_badge': 'مهمة اليوم',
    'today_badge': 'اليوم',
    'todays_progress': 'تقدّم اليوم',
    'completed': 'مكتملة',
    'mission_completed_xp': 'اكتملت المهمة! تم منح الخبرة.',
    'come_back_tomorrow': 'عُد غداً لتحدٍّ جديد.',
    'fix_this_weakness': 'عالج هذا الضعف',
    'start_the_exam': 'ابدأ الامتحان',
    'start_practice': 'ابدأ التمرين',
    // Practice
    'no_exams_available': 'لا تتوفر امتحانات بعد.',
    'practice_page_subtitle':
        'أدِّ امتحانات البكالوريا الكاملة في ظروف بتوقيت محدد.',
    'section_one': 'قسم',
    'section_many': 'أقسام',
    'demo_tag': 'تجريبي',
    'minutes_short': '{} دقيقة',
    // Study plan
    'my_study_plan': 'خطتي الدراسية',
    'plan_error': 'تعذّر إنشاء خطتك الدراسية.',
    'retry': 'إعادة المحاولة',
    'smart_study_plan': '🎯 خطة دراسة ذكية',
    'tasks_count': '{} من {} مهام',
    'minutes_available': '{} دقيقة متاحة اليوم',
    // Comeback
    'comeback_plan': 'خطة العودة',
    'not_result_wanted_plain': 'ليست النتيجة التي أردتها.',
    'here_is_7day_plan': 'إليك خطتك لمدة 7 أيام لتجاوزها.',
    'last_score': 'آخر نتيجة',
    'target': 'الهدف',
    'up': 'ارتفاع',
    'down': 'انخفاض',
    'main_target': 'الهدف الرئيسي: {}',
    'plan_explainer':
        'الأيام 1–3 تعيد بناء هذا المفهوم، اليوم 4 بروفة بتوقيت، '
        'واليوم 7 إعادة المباراة.',
    'rematch_now': 'أعد المباراة الآن',
    // Home
    'set_date': 'تحديد الموعد',
    'bac_countdown': 'العد التنازلي للبكالوريا',
    'days_remaining': '{} يوم',
    'weeks_hours': '{} أسابيع • {} ساعة',
    'plan_hook': 'خطة مبنية على ما تحتاج تحسينه.',
    'overall_accuracy': 'الدقة الإجمالية',
    'your_bac_profile': 'ملفك للبكالوريا',
    'profile_empty_hint':
        'أجب عن بعض الأسئلة لترى ملفك حسب المادة.',
    'no_weak_concepts_keep_up': 'لا مفاهيم ضعيفة — واصل!',
    'concepts_need_attention': '{} مفاهيم تحتاج اهتماماً',
    'bac_boss_brand': 'بوس البكالوريا',
    'survive_full_paper': 'هل يمكنك اجتياز موضوع كامل؟',
    'exams_available_one': 'امتحان واحد متاح • بتوقيت • ظروف حقيقية',
    'exams_available_many': '{} امتحانات متاحة • بتوقيت • ظروف حقيقية',
  };
}
