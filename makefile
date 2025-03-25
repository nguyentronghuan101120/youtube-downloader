analyze:
	fvm flutter analyze

.PHONY: format 
format:
	fvm dart format lib/

.PHONY: format-analyze
format-analyze:
	fvm flutter format --dry-run lib/
	fvm flutter analyze

.PHONY: build-runner
b:
	fvm flutter packages pub run build_runner build

d:
	fvm flutter pub run build_runner build --delete-conflicting-outputs

w:
	fvm dart run build_runner watch --delete-conflicting-outputs

c:
	rm ios/Podfile.lock | true
	rm -rf ios/Pods/ | true
	rm -rf ios/Runner.xcworkspace/ | true
	rm ios/Flutter/Flutter.podspec | true
	rm -rf ~/Library/Developer/Xcode/DerivedData/ | true
	rm pubspec.lock | true
	fvm flutter clean
	fvm flutter pub get
	unameOut=$$(uname -s); \
	if [ "$$unameOut" = "Darwin" ]; then \
	  cd ios && pod install; \
	fi

g:
	fvm flutter pub run easy_localization:generate --source-dir assets/translations -o ../gen/codegen_loader.g.dart
	fvm flutter pub run easy_localization:generate -S assets/translations -f keys -o ../gen/locale_keys.g.dart
