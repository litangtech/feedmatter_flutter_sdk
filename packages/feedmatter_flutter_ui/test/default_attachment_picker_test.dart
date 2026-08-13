import 'package:feedmatter_flutter_ui/feedmatter_flutter_ui.dart';
import 'package:feedmatter_flutter_sdk/feedmatter_flutter_sdk.dart' as fm;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('inferFileType', () {
    test('maps image extensions to IMG', () {
      expect(inferFileType('photo.jpg'), fm.FileType.IMG);
      expect(inferFileType('photo.PNG'), fm.FileType.IMG);
    });

    test('maps video extensions to VID', () {
      expect(inferFileType('clip.mp4'), fm.FileType.VID);
      expect(inferFileType('clip.MOV'), fm.FileType.VID);
    });

    test('maps txt to TXT and others to DOC', () {
      expect(inferFileType('notes.txt'), fm.FileType.TXT);
      expect(inferFileType('report.pdf'), fm.FileType.DOC);
    });
  });
}
