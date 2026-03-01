import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app_lang.dart';

class S {
  static String of(BuildContext context, String key) {
    final lang = context.watch<AppLang>().locale.languageCode;
    final map = _strings[lang] ?? _strings['en']!;
    return map[key] ?? (_strings['en']![key] ?? key);
    // fallback: current lang -> english -> key
  }

  static const Map<String, Map<String, String>> _strings = {
    'en': {
      // -------------------- General --------------------
      'appTitle': 'Clean Madurai',
      'subtitle': 'AI-Powered Cleanliness Platform',
      'place': 'Madurai, Tamil Nadu',
      'headline': 'Making our city cleaner, together',
      'tagline': 'Report issues, track resolutions, earn rewards.',
      'login': 'Login',
      'register': 'Register',
      'features': 'App Features',
      'join': 'Join Clean Madurai',
      'wards': 'Wards',
      'pwa': 'PWA Ready',
      'monitor': 'Monitoring',
      'langBtn': 'தமிழ்',

      // -------------------- Navigation (Citizen) --------------------
      'nav_home': 'Home',
      'nav_report': 'Report',
      'nav_myReports': 'My Reports',
      'nav_feed': 'Feed',
      'nav_profile': 'Profile',

      // -------------------- Navigation (Collector) --------------------
      'c_nav_queue': 'Queue',
      'c_nav_nearMe': 'Near Me',
      'c_nav_route': 'Route',
      'c_nav_profile': 'Profile',

      // -------------------- Landing Features --------------------
      'feature1_title': 'Report Garbage with Photo & Location',
      'feature1_desc':
      'Snap a photo of any garbage problem and instantly report it with your GPS location.',
      'feature2_title': 'Automatic Collector Notifications',
      'feature2_desc':
      'n8n automation sends instant alerts and daily morning summaries to collectors.',
      'feature3_title': 'Dashboard & Analytics',
      'feature3_desc':
      'Live statistics on complaint counts, resolution rates and ward cleanliness scores.',
      'feature4_title': 'Clean Route Suggestions',
      'feature4_desc':
      'Collectors get an optimised daily cleanup route sorted by priority and proximity.',
      'feature5_title': 'Waste Segregation Guidance',
      'feature5_desc':
      'After every complaint you get guidance: recyclable, hazardous or biodegradable.',
      'feature6_title': 'Points & Rewards System',
      'feature6_desc':
      'Earn points for reporting and resolved complaints. Climb the leaderboard.',

      // -------------------- Login Screen --------------------
      'sign_in': 'Sign In',
      'email': 'Email',
      'password': 'Password',
      'enter_email_password': 'Enter email and password',
      'collector_signin': 'Collector Sign In',
      'dont_have_account': "Don't have an account? Register",
      'citizen_role': 'Citizen',
      'collector_role': 'Collector',

      // -------------------- Register Screen --------------------
      'create_account': 'Create Account',
      'full_name': 'Full Name',
      'your_ward': 'Your Ward',
      'collector_details': 'Collector Details',
      'worker_id': 'Worker ID',
      'aadhaar': 'Aadhaar Number',
      'vehicle_number': 'Vehicle Number',
      'create_citizen_account': 'Create Citizen Account',
      'create_collector_account': 'Create Collector Account',

      // -------------------- Shared / Common --------------------
      'status': 'Status',
      'location': 'Location',
      'name': 'Name',
      'ward': 'Ward',
      'reward_points': 'Reward Points',
      'sign_out': 'Sign Out',
      'updated_to': 'Updated to',
      'update_failed': 'Update failed',
      'resolve_failed': 'Resolve failed',
      'meters': 'm',
      'unknown': 'Unknown',
      'dustbin': 'Dustbin',

      // -------------------- Collector Queue --------------------
      'c_queue_title': 'Collector Queue',
      'c_public_board': 'Public Board',
      'c_waste_guide': 'Waste Guide',
      'c_no_pending': 'No pending complaints in your ward.',
      'c_start_work': 'Start Work',
      'c_resolve_after_photo': 'Resolve + After Photo',
      'c_resolved_uploaded': 'Complaint resolved and photo uploaded',

      // -------------------- Nearby Map --------------------
      'c_dustbin_near_me': 'Dustbin Near Me',
      'c_share_live_location': 'Share my live location',
      'c_share_live_location_sub':
      'Used to notify citizens when collector is within 100m',
      'c_markers_preview': 'Markers Preview',
      'c_user_marker': 'User Marker',
      'c_dustbin_markers': 'Dustbin Markers',
      'c_dustbin_markers_sub': 'Loaded from dustbins collection',
      'c_worker_live_marker': 'Worker Live Marker',
      'c_worker_live_marker_sub': 'From worker_live collection',
      'c_no_dustbins_firestore':
      'No dustbin points found. Add docs in Firestore dustbins collection.',

      // -------------------- Collector Profile --------------------
      'c_profile_title': 'Collector Profile',

      // -------------------- Report Screen --------------------
      'rep_title': 'Report Issue',
      'rep_photo_required': 'Photo (Required)',
      'rep_tap_add_photo': 'Tap to add photo',
      'rep_category': 'Category',
      'rep_location': 'Location',
      'rep_getting_location': 'Getting location...',
      'rep_location_unavailable': 'Location unavailable - tap refresh',
      'rep_location_unavailable_err':
      'Location not available. Tap the refresh icon.',
      'rep_description_optional': 'Description (Optional)',
      'rep_desc_hint': 'Describe the issue...',
      'rep_ai_note':
      'AI will analyze your photo for waste type & recycling advice',
      'rep_submitting': 'Submitting...',
      'rep_submit_btn': 'Submit Report (+10 pts)',
      'rep_add_photo_title': 'Add Photo',
      'rep_camera': 'Camera',
      'rep_gallery': 'Gallery',
      'rep_add_photo_err': 'Please add a photo',
      'rep_select_category_err': 'Please select a category',
      'rep_submit_failed': 'Submission failed. Please try again.',

      // -------------------- Report Categories --------------------
      'cat_garbage_overflow': 'Garbage Overflow',
      'cat_open_dumping': 'Open Dumping',
      'cat_sewer_blockage': 'Sewer Blockage',
      'cat_public_toilet': 'Public Toilet Issue',
      'cat_littering': 'Littering',
      'cat_other': 'Other',

      // ==================== NEW: Complaint Success Screen ====================
      'report_submitted': 'Report Submitted!',
      'complaint_id': 'Complaint ID',
      'points_earned_10': '+10 Points Earned!',
      'ai_waste_analysis': 'AI Waste Analysis',
      'waste_type_label': '🗂️ Waste Type',
      'how_to_dispose_label': '♻️ How to Dispose',
      'info_label': '💡 Info',
      'what_next': 'What happens next?',
      'next_step_1': 'Your report is assigned to a ward officer',
      'next_step_2': 'A sanitation worker is dispatched',
      'next_step_3': "You'll be notified when resolved",
      'next_step_4': 'Earn points when complaint resolves!',
      'back_to_home': 'Back to Home',
      'analyzing': 'Analyzing...',
      'please_wait': 'Please wait...',

      // Login extra keys (used in login_screen.dart)
      'login_err_empty': 'Enter email and password',
      'login_err_failed': 'Login failed',

      'login_subtitle_collector': 'Collector login & field operations',
      'login_subtitle_citizen': 'Citizen reports for a cleaner city',

      'signIn': 'Sign In', // (you already have sign_in, but your login uses signIn)
      'role_citizen': '👤 Citizen',
      'role_collector': '🚛 Collector',

      'email_hint': 'enter mail id',
      'password_hint': 'enter password',

      'collectorSignIn': 'Collector Sign In', // (you already have collector_signin but your login uses collectorSignIn)
      'goRegister': "Don't have an account? Register",

      // Register screen extra keys
      'createAccount': 'Create Account',

      'role_citizen_plain': 'Citizen',
      'role_collector_plain': 'Garbage Collector',

      'fullName': 'Full Name',
      'fullName_hint': 'Your full name',

      'password_hint_register': 'Min 6 characters',

      'yourWard': 'Your Ward',

      'collectorDetails': 'Collector Details',

      'workerId_hint': 'Ex: MDU-GC-1076',

      'aadhaarNumber': 'Aadhaar Number',
      'aadhaar_hint': '12 digits',

      'vehicle_hint': 'TN 58 AB 1234',

      // Register errors
      'reg_err_required': 'Fill all mandatory fields',
      'reg_err_collector_fields':
      'Collector needs Worker ID, 12-digit Aadhaar and Vehicle Number',
      'reg_err_failed': 'Registration failed',

      // ======================================================================
      // ================== NEW: Dashboard + Checker Strings ===================
      // ======================================================================

      // Dashboard header
      'dash_hello': 'Hello',
      'dash_citizen': 'Citizen',
      'dash_pts': 'pts',

      // Dashboard stats + sections
      'dash_reports': 'Reports',
      'dash_resolved': 'Resolved',
      'dash_points': 'Points',
      'dash_recent_activity': 'Recent Activity',

      // Report card (dashboard top card)
      'dash_see_dirty': 'See something dirty?',
      'dash_tap_report_tab': 'Tap Report tab below to submit',
      'dash_report_now': 'Report Now →',

      // Ward card
      'dash_score': 'Score',
      'dash_total': 'Total',
      'dash_pending': 'Pending',

      // Recent activity empty
      'dash_no_reports_yet': 'No reports yet. Tap Report to get started!',

      // Degradable checker card + sheet
      'checker_title': 'Degradable Checker',
      'checker_subtitle':
      'Type an item name → biodegradable or non-biodegradable',
      'checker_sheet_title': 'Degradable Checker',
      'checker_sheet_desc':
      'Type the item. Example: banana peel, paper cup, plastic bottle, batteries.',
      'checker_hint': 'Enter waste item name...',
      'checker_btn': 'Check',
      'checker_snack_empty':
      'Type an item name (example: banana peel, plastic bottle)',

      // Result box labels
      'checker_examples': 'Examples',
      'checker_loading_label': 'Loading dataset… ⏳',
      'checker_loading_tip': 'Please try again in 1 second.',
      'checker_unknown_label': 'Unknown 🤔',
      'checker_unknown_tip':
      'Try a more specific name like “plastic bottle”, “banana peel”, “battery”, “glass jar”.',
      'checker_bio_label': 'Biodegradable ✅',
      'checker_bio_tip': 'Put in WET bin / compostable waste.',
      'checker_nonbio_label': 'Non-biodegradable ✅',
      'checker_nonbio_tip':
      'Put in DRY bin / recyclables. Keep plastic, glass, metal separate if possible.',

      'assistant_title': 'Clean Madurai Assistant',
      'assistant_greeting': "Hi 👋 I’m Clean Madurai Assistant.\nPick a question below or type your question.",
      'assistant_hint': 'Ask about recycling, composting, bins…',
      'assistant_send': 'Send',
      'assistant_fallback': "I’m not sure yet 😅\nTry a clearer question like “What goes in wet bin?” or “How to dispose batteries?”",
    },

    'ta': {
      // -------------------- General --------------------
      'appTitle': 'க்ளீன் மதுரை',
      'subtitle': 'AI ஆதாரமான தூய்மை தளம்',
      'place': 'மதுரை, தமிழ்நாடு',
      'headline': 'நாம் சேர்ந்து நகரத்தை சுத்தமாக்கலாம்',
      'tagline': 'புகார் செய்யுங்கள், தீர்வை கண்காணியுங்கள், பரிசுகள் பெறுங்கள்.',
      'login': 'உள்நுழை',
      'register': 'பதிவு செய்',
      'features': 'அம்சங்கள்',
      'join': 'க்ளீன் மதுரையில் சேருங்கள்',
      'wards': 'வார்டுகள்',
      'pwa': 'PWA தயார்',
      'monitor': 'கண்காணிப்பு',
      'langBtn': 'EN',

      // -------------------- Navigation (Citizen) --------------------
      'nav_home': 'முகப்பு',
      'nav_report': 'புகார்',
      'nav_myReports': 'என் புகார்கள்',
      'nav_feed': 'பொது Feed',
      'nav_profile': 'சுயவிவரம்',

      // -------------------- Navigation (Collector) --------------------
      'c_nav_queue': 'புகார் வரிசை',
      'c_nav_nearMe': 'அருகில்',
      'c_nav_route': 'பாதை',
      'c_nav_profile': 'சுயவிவரம்',

      // -------------------- Landing Features --------------------
      'feature1_title': 'படம் + இடத்துடன் குப்பை புகார்',
      'feature1_desc':
      'குப்பை பிரச்சினையை படம் எடுத்து உங்கள் GPS இடத்துடன் உடனே புகாரளிக்கலாம்.',
      'feature2_title': 'தானியங்கி சேகரிப்பாளர் அறிவிப்பு',
      'feature2_desc':
      'n8n மூலம் உடனடி அறிவிப்பு மற்றும் தினசரி சுருக்கம் சேகரிப்பாளருக்கு அனுப்பப்படும்.',
      'feature3_title': 'டாஷ்போர்டு & பகுப்பாய்வு',
      'feature3_desc':
      'புகார் எண்ணிக்கை, தீர்வு வீதம், வார்டு தூய்மை மதிப்பெண் போன்றவை நேரலை.',
      'feature4_title': 'சுத்தம் செய்யும் பாதை பரிந்துரை',
      'feature4_desc':
      'முக்கியத்துவம் மற்றும் அருகாமை அடிப்படையில் தினசரி பாதை தானாக பரிந்துரைக்கப்படும்.',
      'feature5_title': 'கழிவு பிரிப்பதற்கான வழிகாட்டி',
      'feature5_desc':
      'ஒவ்வொரு புகாருக்குப் பிறகும்: மறுசுழற்சி/அபாயம்/சிதைவடையுமா என வழிகாட்டும்.',
      'feature6_title': 'புள்ளிகள் & பரிசுகள்',
      'feature6_desc':
      'புகார் மற்றும் தீர்வு அடிப்படையில் புள்ளிகள் பெறுங்கள். லீடர்போர்டில் மேலேறுங்கள்.',

      // -------------------- Login Screen --------------------
      'sign_in': 'உள்நுழை',
      'email': 'மின்னஞ்சல்',
      'password': 'கடவுச்சொல்',
      'enter_email_password': 'மின்னஞ்சல் மற்றும் கடவுச்சொல் உள்ளிடவும்',
      'collector_signin': 'சேகரிப்பாளர் உள்நுழை',
      'dont_have_account': 'கணக்கு இல்லையா? பதிவு செய்யுங்கள்',
      'citizen_role': 'பொது நபர்',
      'collector_role': 'சேகரிப்பாளர்',

      // -------------------- Register Screen --------------------
      'create_account': 'கணக்கு உருவாக்கு',
      'full_name': 'முழு பெயர்',
      'your_ward': 'உங்கள் வார்டு',
      'collector_details': 'சேகரிப்பாளர் விவரங்கள்',
      'worker_id': 'பணியாளர் ID',
      'aadhaar': 'ஆதார் எண்',
      'vehicle_number': 'வாகன எண்',
      'create_citizen_account': 'பொது கணக்கு உருவாக்கு',
      'create_collector_account': 'சேகரிப்பாளர் கணக்கு உருவாக்கு',

      // -------------------- Shared / Common --------------------
      'status': 'நிலை',
      'location': 'இடம்',
      'name': 'பெயர்',
      'ward': 'வார்டு',
      'reward_points': 'புள்ளிகள்',
      'sign_out': 'வெளியேறு',
      'updated_to': 'புதுப்பிக்கப்பட்டது',
      'update_failed': 'புதுப்பிப்பு தோல்வி',
      'resolve_failed': 'தீர்வு தோல்வி',
      'meters': 'மீ',
      'unknown': 'தெரியவில்லை',
      'dustbin': 'குப்பைத்தொட்டி',

      // -------------------- Collector Queue --------------------
      'c_queue_title': 'சேகரிப்பாளர் வரிசை',
      'c_public_board': 'பொது பலகை',
      'c_waste_guide': 'கழிவு வழிகாட்டி',
      'c_no_pending': 'உங்கள் வார்டில் நிலுவை புகார்கள் இல்லை.',
      'c_start_work': 'வேலை தொடங்கு',
      'c_resolve_after_photo': 'தீர்வு + படம்',
      'c_resolved_uploaded': 'புகார் தீர்க்கப்பட்டது, படம் பதிவேற்றப்பட்டது',

      // -------------------- Nearby Map --------------------
      'c_dustbin_near_me': 'அருகிலுள்ள குப்பைத்தொட்டி',
      'c_share_live_location': 'என் நேரடி இடத்தை பகிர்',
      'c_share_live_location_sub':
      '100 மீட்டரில் சேகரிப்பாளர் வந்தால் அறிவிக்க பயன்படும்',
      'c_markers_preview': 'மார்க்கர்கள் முன்னோட்டம்',
      'c_user_marker': 'பயனர் மார்க்கர்',
      'c_dustbin_markers': 'குப்பைத்தொட்டி மார்க்கர்கள்',
      'c_dustbin_markers_sub': 'dustbins சேகரிப்பிலிருந்து',
      'c_worker_live_marker': 'நேரடி சேகரிப்பாளர்',
      'c_worker_live_marker_sub': 'worker_live சேகரிப்பிலிருந்து',
      'c_no_dustbins_firestore': 'Firestore dustbins சேகரிப்பில் தரவு இல்லை.',

      // -------------------- Collector Profile --------------------
      'c_profile_title': 'சேகரிப்பாளர் சுயவிவரம்',

      // -------------------- Report Screen --------------------
      'rep_title': 'புகார் அளிக்க',
      'rep_photo_required': 'படம் (கட்டாயம்)',
      'rep_tap_add_photo': 'படம் சேர்க்க தட்டவும்',
      'rep_category': 'வகை',
      'rep_location': 'இடம்',
      'rep_getting_location': 'இடத்தை பெறுகிறது...',
      'rep_location_unavailable': 'இடம் கிடைக்கவில்லை - புதுப்பிக்க தட்டவும்',
      'rep_location_unavailable_err':
      'இடம் கிடைக்கவில்லை. Refresh ஐ தட்டவும்.',
      'rep_description_optional': 'விளக்கம் (விருப்பம்)',
      'rep_desc_hint': 'பிரச்சினையை விவரிக்கவும்...',
      'rep_ai_note':
      'AI உங்கள் படத்தை பகுப்பாய்ந்து கழிவு வகை & மறுசுழற்சி ஆலோசனை தரும்',
      'rep_submitting': 'அனுப்புகிறது...',
      'rep_submit_btn': 'புகார் அனுப்பு (+10 புள்ளிகள்)',
      'rep_add_photo_title': 'படம் சேர்க்க',
      'rep_camera': 'கேமரா',
      'rep_gallery': 'கேலரி',
      'rep_add_photo_err': 'தயவு செய்து படம் சேர்க்கவும்',
      'rep_select_category_err': 'தயவு செய்து வகையை தேர்ந்தெடுக்கவும்',
      'rep_submit_failed': 'அனுப்ப முடியவில்லை. மீண்டும் முயற்சிக்கவும்.',

      // -------------------- Report Categories --------------------
      'cat_garbage_overflow': 'குப்பை நிரம்பி வழிகிறது',
      'cat_open_dumping': 'திறந்த இடத்தில் குப்பை கொட்டல்',
      'cat_sewer_blockage': 'கழிவுநீர் அடைப்பு',
      'cat_public_toilet': 'பொது கழிப்பறை பிரச்சினை',
      'cat_littering': 'சாலையில் குப்பை போடுதல்',
      'cat_other': 'மற்றவை',

      // ==================== NEW: Complaint Success Screen ====================
      'report_submitted': 'புகார் வெற்றிகரமாக அனுப்பப்பட்டது!',
      'complaint_id': 'புகார் எண்',
      'points_earned_10': '+10 புள்ளிகள் கிடைத்தது!',
      'ai_waste_analysis': 'AI கழிவு பகுப்பாய்வு',
      'waste_type_label': '🗂️ கழிவு வகை',
      'how_to_dispose_label': '♻️ எப்படித் தள்ள வேண்டும்',
      'info_label': '💡 தகவல்',
      'what_next': 'அடுத்து என்ன நடக்கும்?',
      'next_step_1': 'உங்கள் புகார் வார்டு அதிகாரிக்கு ஒதுக்கப்படும்',
      'next_step_2': 'சுகாதார பணியாளர் அனுப்பப்படுவார்',
      'next_step_3': 'தீர்வு ஆனதும் உங்களுக்கு அறிவிப்பு வரும்',
      'next_step_4': 'புகார் தீர்வு ஆனதும் புள்ளிகள் கிடைக்கும்!',
      'back_to_home': 'முகப்பிற்கு திரும்ப',
      'analyzing': 'பகுப்பாய்வு நடக்கிறது...',
      'please_wait': 'தயவு செய்து காத்திருக்கவும்...',

      'login_err_empty': 'மின்னஞ்சல் மற்றும் கடவுச்சொல் உள்ளிடவும்',
      'login_err_failed': 'உள்நுழை தோல்வி',

      'login_subtitle_collector': 'சேகரிப்பாளர் உள்நுழை & பணி செயல்கள்',
      'login_subtitle_citizen': 'நகரத்தை சுத்தமாக்க குடிமகன் புகார்கள்',

      'signIn': 'உள்நுழை',
      'role_citizen': '👤 குடிமகன்',
      'role_collector': '🚛 சேகரிப்பாளர்',

      'email_hint': 'மின்னஞ்சலை உள்ளிடவும்',
      'password_hint': 'கடவுச்சொல்லை உள்ளிடவும்',

      'collectorSignIn': 'சேகரிப்பாளர் உள்நுழை',
      'goRegister': 'கணக்கு இல்லையா? பதிவு செய்யுங்கள்',

      // Register screen extra keys
      'createAccount': 'கணக்கு உருவாக்கு',

      'role_citizen_plain': 'குடிமகன்',
      'role_collector_plain': 'குப்பை சேகரிப்பாளர்',

      'fullName': 'முழு பெயர்',
      'fullName_hint': 'உங்கள் முழு பெயர்',

      'password_hint_register': 'குறைந்தது 6 எழுத்துகள்',

      'yourWard': 'உங்கள் வார்டு',

      'collectorDetails': 'சேகரிப்பாளர் விவரங்கள்',

      'workerId_hint': 'உதா: MDU-GC-1076',

      'aadhaarNumber': 'ஆதார் எண்',
      'aadhaar_hint': '12 இலக்கங்கள்',

      'vehicle_hint': 'TN 58 AB 1234',

      // Register errors
      'reg_err_required': 'தேவையான புலங்களை நிரப்பவும்',
      'reg_err_collector_fields':
      'சேகரிப்பாளருக்கு Worker ID, 12 இலக்க ஆதார் மற்றும் வாகன எண் தேவை',
      'reg_err_failed': 'பதிவு தோல்வி',

      // ======================================================================
      // ================== NEW: Dashboard + Checker Strings ===================
      // ======================================================================

      // Dashboard header
      'dash_hello': 'வணக்கம்',
      'dash_citizen': 'மக்கள்',
      'dash_pts': 'புள்ளிகள்',

      // Dashboard stats + sections
      'dash_reports': 'புகார்கள்',
      'dash_resolved': 'தீர்வு',
      'dash_points': 'புள்ளிகள்',
      'dash_recent_activity': 'சமீபத்திய செயல்பாடு',

      // Report card (dashboard top card)
      'dash_see_dirty': 'சுத்தமில்லையா தெரியுதா?',
      'dash_tap_report_tab': 'கீழே உள்ள Report டாப்-ஐ தட்டி புகார் அளிக்கவும்',
      'dash_report_now': 'இப்போ புகார் →',

      // Ward card
      'dash_score': 'மதிப்பெண்',
      'dash_total': 'மொத்தம்',
      'dash_pending': 'நிலுவையில்',

      // Recent activity empty
      'dash_no_reports_yet':
      'இன்னும் எந்த புகாரும் இல்லை. தொடங்க Report-ஐ தட்டுங்கள்!',

      // Degradable checker card + sheet
      'checker_title': 'அழுகக்கூடியது சரிபார்ப்பு',
      'checker_subtitle': 'பொருளை உள்ளிடுங்கள் → அழுகும் / அழுகாத கழிவு',
      'checker_sheet_title': 'அழுகக்கூடியது சரிபார்ப்பு',
      'checker_sheet_desc':
      'பொருளின் பெயரை உள்ளிடுங்கள். உதாரணம்: வாழைத்தோல், பேப்பர் கப், பிளாஸ்டிக் பாட்டில், பேட்டரி.',
      'checker_hint': 'கழிவு பொருள் பெயரை உள்ளிடுங்கள்...',
      'checker_btn': 'சரிபார்',
      'checker_snack_empty':
      'ஒரு பொருளின் பெயரை உள்ளிடுங்கள் (உதா: வாழைத்தோல், பிளாஸ்டிக் பாட்டில்)',

      // Result box labels
      'checker_examples': 'உதாரணங்கள்',
      'checker_loading_label': 'தரவு ஏற்றுகிறது… ⏳',
      'checker_loading_tip': '1 விநாடிக்கு பிறகு மீண்டும் முயற்சிக்கவும்.',
      'checker_unknown_label': 'தெரியவில்லை 🤔',
      'checker_unknown_tip':
      'சற்று தெளிவாக எழுதுங்கள்: “பிளாஸ்டிக் பாட்டில்”, “வாழைத்தோல்”, “பேட்டரி”, “கண்ணாடி ஜார்”.',
      'checker_bio_label': 'அழுகக்கூடியது ✅',
      'checker_bio_tip': 'WET பின் / உரமாகும் கழிவில் போடுங்கள்.',
      'checker_nonbio_label': 'அழுகாதது ✅',
      'checker_nonbio_tip':
      'DRY பின் / மறுசுழற்சி கழிவில் போடுங்கள். பிளாஸ்டிக், கண்ணாடி, உலோகம் தனித்தனியாக வைத்தால் நல்லது.',

      'assistant_title': 'க்ளீன் மதுரை உதவியாளர்',
      'assistant_greeting': "வணக்கம் 👋 நான் Clean Madurai உதவியாளர்.\nகீழே உள்ள கேள்வியைத் தேர்வு செய்யுங்கள் அல்லது உங்கள் கேள்வியை টাইப் செய்யுங்கள்.",
      'assistant_hint': 'மறுசுழற்சி, உரம், குப்பைத் தொட்டி பற்றி கேளுங்கள்…',
      'assistant_send': 'அனுப்பு',
      'assistant_fallback_ta': "இப்போ சரியாக புரியலை 😅\nஉதா: “WET பின்ல என்ன போடலாம்?” அல்லது “பேட்டரியை எப்படி தள்ள வேண்டும்?” என்று கேளுங்கள்.",
    },
  };
}