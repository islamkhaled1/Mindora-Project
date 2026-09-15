import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/core/utils/child_avatar_helper.dart';

void main() {
  group('ChildAvatarHelper', () {
    test('Real uploaded avatarUrl takes absolute priority over gender', () {
      const uploadedUrl = 'https://mindora.app/avatars/custom_photo.jpg';

      // Even if gender is Girl or Boy, real uploaded photo wins
      expect(
        ChildAvatarHelper.resolve(gender: 'girl', avatarUrl: uploadedUrl),
        equals(uploadedUrl),
      );
      expect(
        ChildAvatarHelper.resolve(gender: 'boy', avatarUrl: uploadedUrl),
        equals(uploadedUrl),
      );
      expect(
        ChildAvatarHelper.resolve(gender: null, avatarUrl: uploadedUrl),
        equals(uploadedUrl),
      );
    });

    test('Resolves girl avatar for female variations', () {
      const expected = ChildAvatarHelper.defaultGirlAsset;

      expect(ChildAvatarHelper.resolve(gender: 'girl'), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 'Girl'), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 'GIRL'), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 'female'), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 'Female'), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: '2'), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 2), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 'بنت'), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 'أنثى'), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 'انثى'), equals(expected));
    });

    test('Resolves boy avatar for male variations', () {
      const expected = ChildAvatarHelper.defaultBoyAsset;

      expect(ChildAvatarHelper.resolve(gender: 'boy'), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 'Boy'), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 'male'), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 'Male'), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: '1'), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 1), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 'ولد'), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 'ذكر'), equals(expected));
    });

    test('Falls back to safe default avatar for null, empty, other or unknown', () {
      const expected = ChildAvatarHelper.fallbackAsset;

      expect(ChildAvatarHelper.resolve(gender: null), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: ''), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: '   '), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 'Other'), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 'unknown'), equals(expected));
      expect(ChildAvatarHelper.resolve(gender: 99), equals(expected));
    });

    test('isNetworkUrl correctly detects remote HTTP and HTTPS URLs', () {
      expect(ChildAvatarHelper.isNetworkUrl('https://example.com/a.png'), isTrue);
      expect(ChildAvatarHelper.isNetworkUrl('http://example.com/a.png'), isTrue);
      expect(ChildAvatarHelper.isNetworkUrl('HTTPS://EXAMPLE.COM/A.PNG'), isTrue);

      expect(ChildAvatarHelper.isNetworkUrl('assets/images/kid_image.png'), isFalse);
      expect(ChildAvatarHelper.isNetworkUrl('/storage/emulated/0/photo.jpg'), isFalse);
      expect(ChildAvatarHelper.isNetworkUrl(''), isFalse);
      expect(ChildAvatarHelper.isNetworkUrl(null), isFalse);
    });
  });
}
