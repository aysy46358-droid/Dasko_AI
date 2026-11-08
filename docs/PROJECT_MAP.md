# خريطة مشروع Dasko AI

هذه الوثيقة تصف البنية التي تحققت منها في الكود، وليست قاعدة جامدة أو بديلاً عن مراجعة التنفيذ. يوصي Flutter بفصل المسؤوليات، مع تكييف المعمارية مع احتياجات التطبيق؛ لذلك تُحدّث هذه الخريطة عند تغير الكود، ولا تُستخدم لاستنتاج سلوك غير موجود.

## تدفق بدء التطبيق

1. يبدأ التطبيق من `lib/main.dart`، ويهيئ Flutter bindings.
2. يحاول تهيئة Firebase Core اختيارياً؛ فشل التهيئة يُسجّل ولا يمنع تشغيل واجهة النموذج الأولي.
3. يُشغّل `DaskoApp` من `lib/app/app.dart`.
4. تُسجّل الاعتمادات في `lib/app/providers.dart` باستخدام Riverpod؛ والربط الحالي لـ `AiEngine` هو `MockAiEngine`.

## تدفق إرسال رسالة

`ChatScreen` → `ChatNotifier` → `SendMessage` → عقد `AiEngine` → `MockAiEngine` حالياً.

- `ChatNotifier` يدير حالة الطلب والرسائل.
- `SendMessage` في طبقة Domain يستدعي العقد ويحوّل النتيجة إلى رسالة أو `Failure`.
- `AiEngine` هو العقد؛ التنفيذ الحالي الوهمي موجود في Services.
- طبقة Presentation تحوّل حالة الطلب إلى تعبير الروبوت وتعرض الواجهة.
- استبدال المحرك مستقبلاً يجب أن يحافظ على العقد أو يغيّره مع تحديث الاختبارات والطبقات المتأثرة. لا يوجد حالياً تكامل LLM حقيقي.

## أين أبدأ عند التعديل؟

- تغيير شاشة أو سلوك عرض: `lib/features/*/presentation/`، واختبارات الواجهة ذات الصلة.
- تغيير حالة المحادثة: `lib/features/chat/application/` مع اختبارات `ChatNotifier`.
- تغيير قواعد إرسال الرسالة: `lib/domain/usecases/send_message.dart` واختباراته.
- إضافة محرك: تنفيذ `AiEngine` في `lib/services/` ثم تغيير ربطه في `lib/app/providers.dart` واختبارات المحرك؛ لا تضع مفتاح API سرياً داخل التطبيق.
- تغيير أخطاء المجال أو النصوص المشتركة أو الأصول: راجع `lib/core/` واختبار المتأثر.
- تغيير بناء Android أو CI: راجع `android/` و`.github/workflows/` و`tooling/` واختبارات التحقق ذات الصلة.

## الاختبارات والبناء

- اختبارات Dart/Flutter موجودة في `test/` وتُشغّل بواسطة `flutter test`.
- سير `Build APK` يتضمن تنسيق Dart والتحليل والاختبارات والتحقق من أصول الروبوت وسياسة الشبكة ثم بناء APK والتحقق من بياناته وتوقيعه. نجاحه يثبت اجتياز هذه الفحوص في بيئة CI لذلك الالتزام فقط؛ لا يثبت خلو التطبيق من كل عيب أو اكتمال فحص Firebase الخارجي.
- فحص اتساق هذه الخريطة له سير CI مستقل، ولا يعتمد عليه سير بناء APK.

## حدود التكاملات والأمان بحسب المستودع

- Firebase Core مهيأ اختيارياً عند الإقلاع، وCrashlytics مهيأ في `lib/main.dart` لتسجيل الأخطاء غير القاتلة على Android وiOS وmacOS بعد نجاح تهيئة Firebase. يمرر التقرير نوع الخطأ ومصدره الثابت وإطارات المكدس فقط، لا نص الاستثناء الخام أو محتوى المحادثة أو مفاتيح API أو معرّفات المستخدم. لم يُتحقق بعد من وصول التقارير إلى Firebase Console أو اختبارها على جهاز.
- لا يوجد تكامل Auth أو Firestore أو Realtime Database أو Storage أو callable Functions أو App Check.
- لا توجد في المستودع قواعد Firebase قابلة للنشر؛ إعدادات القواعد والإنفاذ في Firebase Console خارج نطاق الملفات ويجب التحقق منها هناك قبل إضافة اعتماد على بيانات أو خدمات Firebase.
- إعداد `google-services.json` هو إعداد عميل Android؛ لا يُعامل كمكان لحفظ أسرار مزود ذكاء اصطناعي.

## جرد الملفات المتتبعة

القائمة التالية تُولّد من فهرس Git للملفات المتتبعة فقط. لا تُدرج ملفات غير متتبعة أو متجاهلة، ولا يقرأ المولّد محتوى الملفات. بعد إضافة/حذف ملف: أضف/سجّل التغيير في Git، ثم شغّل `python3 tooling/project_map.py --write`، وراجع التغيير. فحص CI يستخدم `--check` ولا يكتب إلى المستودع.

<!-- BEGIN AUTO-GENERATED FILE INVENTORY -->
- `.gitattributes`
- `.github/workflows/build_apk.yml`
- `.github/workflows/format_experimental.yml`
- `.github/workflows/project_map.yml`
- `.gitignore`
- `.metadata`
- `.vscode/settings.json`
- `README.md`
- `analysis_options.yaml`
- `android/.gitignore`
- `android/app/build.gradle.kts`
- `android/app/src/debug/AndroidManifest.xml`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/com/dasko/dasko_ai/MainActivity.kt`
- `android/app/src/main/res/drawable-v21/launch_background.xml`
- `android/app/src/main/res/drawable/launch_background.xml`
- `android/app/src/main/res/mipmap-hdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-mdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png`
- `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`
- `android/app/src/main/res/values-night/styles.xml`
- `android/app/src/main/res/values/styles.xml`
- `android/app/src/main/res/xml/network_security_config.xml`
- `android/app/src/profile/AndroidManifest.xml`
- `android/build.gradle.kts`
- `android/gradle.properties`
- `android/gradle/wrapper/gradle-wrapper.jar`
- `android/gradle/wrapper/gradle-wrapper.properties`
- `android/gradlew`
- `android/gradlew.bat`
- `android/settings.gradle.kts`
- `assets/icon/README.md`
- `assets/icon/dasko_icon.svg`
- `assets/images/README.md`
- `assets/images/dasko_robot_poster.png`
- `assets/models/dasko_robot.glb`
- `assets/persona/dasko_constitution.yaml`
- `assets/sounds/README.md`
- `assets/sounds/welcome.wav`
- `docs/ANDROID_SIGNING.md`
- `docs/DASKO_ROBOT_3D.md`
- `docs/PROJECT_CONTROL.md`
- `docs/PROJECT_MAP.md`
- `google-services.json`
- `lib/app/app.dart`
- `lib/app/providers.dart`
- `lib/core/constants/app_assets.dart`
- `lib/core/constants/app_constants.dart`
- `lib/core/constants/app_strings.dart`
- `lib/core/errors/app_exception.dart`
- `lib/core/errors/failures.dart`
- `lib/core/theme/app_theme.dart`
- `lib/domain/entities/message.dart`
- `lib/domain/repositories/ai_engine.dart`
- `lib/domain/usecases/send_message.dart`
- `lib/features/chat/application/chat_notifier.dart`
- `lib/features/chat/application/chat_request_status.dart`
- `lib/features/chat/presentation/animated_neon_border.dart`
- `lib/features/chat/presentation/chat_robot_state_mapper.dart`
- `lib/features/chat/presentation/chat_screen.dart`
- `lib/features/chat/presentation/dasko_intro_screen.dart`
- `lib/features/chat/presentation/dasko_robot_state.dart`
- `lib/features/chat/presentation/digital_space_background.dart`
- `lib/features/chat/presentation/interactive_dasko_robot.dart`
- `lib/features/chat/presentation/model_viewer_bridge_event.dart`
- `lib/features/chat/presentation/robot_animation_name.dart`
- `lib/features/cinematic_ui/presentation/widgets/audio_waveform_widget.dart`
- `lib/features/cinematic_ui/presentation/widgets/cinematic_screen.dart`
- `lib/features/settings/application/theme_provider.dart`
- `lib/features/settings/presentation/settings_screen.dart`
- `lib/main.dart`
- `lib/services/ai_engine/mock_ai_engine.dart`
- `pubspec.lock`
- `pubspec.yaml`
- `test/chat_notifier_test.dart`
- `test/chat_robot_state_mapper_test.dart`
- `test/chat_screen_robot_state_test.dart`
- `test/model_viewer_bridge_event_test.dart`
- `test/send_message_test.dart`
- `test/widget_test.dart`
- `tooling/allocate_android_version.sh`
- `tooling/android_certificate_verifier.sh`
- `tooling/create_dasko_robot_model.py`
- `tooling/project_map.py`
- `tooling/setup_environment.sh`
- `tooling/test_allocate_android_version.sh`
- `tooling/test_android_certificate_verifier.sh`
- `tooling/test_project_map.py`
- `tooling/test_setup_environment.sh`
- `tooling/validate_dasko_robot_assets.py`
<!-- END AUTO-GENERATED FILE INVENTORY -->

## المراجع التقنية

- [دليل Flutter لمعمارية التطبيقات](https://docs.flutter.dev/app-architecture/guide)
- [اختبارات Flutter](https://docs.flutter.dev/testing/overview)
- [أمان GitHub Actions](https://docs.github.com/en/actions/reference/security/secure-use)
