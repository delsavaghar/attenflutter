فایل‌های پایه پوشه android برای پروژه attendance_flutter

مهم:
این پوشه شامل فایل‌های پیکربندی اصلی است، اما wrapper کامل Gradle (gradlew و gradle-wrapper.jar) در این بسته نیست؛ بنابراین آن را به‌تنهایی به‌عنوان پروژه نهایی تضمین‌شده در Codemagic آپلود نکن.

روش مطمئن‌تر برای Codemagic:
در تنظیمات Workflow، یک Pre-build script اضافه کن و قبل از مرحله Build این دستور را اجرا کن:

flutter create --platforms=android --org com.example .

این دستور در محیط Codemagic که Flutter از قبل نصب است، فایل‌های استاندارد پلتفرم اندروید را ایجاد/تکمیل می‌کند. سپس مرحله Android build را اجرا کن.

اگر می‌خواهی از فایل‌های این بسته استفاده کنی، پوشه android را در کنار lib/main.dart و pubspec.yaml در ریشه پروژه قرار بده. چون ساختار استاندارد Flutter معمولاً کد Dart را در lib/main.dart می‌خواهد، مطمئن شو فایل اصلی برنامه در lib/main.dart قرار دارد؛ قرار گرفتن main.dart در ریشه پروژه ممکن است خودش باعث خطای ساخت شود.
