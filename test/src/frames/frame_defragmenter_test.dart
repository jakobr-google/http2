// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'package:http2/src/frames/frames.dart';
import 'package:http2/src/frames/frame_defragmenter.dart';

import '../error_matchers.dart';

main() {
  group('frames', () {
    group('frame-defragmenter', () {
      UnknownFrame unknownFrame() {
        return new UnknownFrame(new FrameHeader(0, 0, 0, 1), []);
      }

      HeadersFrame headersFrame(List<int> data,
                                {bool fragmented: false, int streamId: 1}) {
        int flags = fragmented ? 0 : HeadersFrame.FLAG_END_HEADERS;
        var header = new FrameHeader(
            data.length, FrameType.HEADERS, flags, streamId);
        return new HeadersFrame(header, 0, false, null, null, data);
      }

      PushPromiseFrame pushPromiseFrame(List<int> data,
                                        {bool fragmented: false,
                                         int streamId: 1}) {
        int flags = fragmented ? 0 : HeadersFrame.FLAG_END_HEADERS;
        var header = new FrameHeader(
            data.length, FrameType.PUSH_PROMISE, flags, streamId);
        return new PushPromiseFrame(header, 0, 44, data);
      }

      ContinuationFrame continuationFrame(List<int> data,
                                          {bool fragmented: false,
                                           int streamId: 1}) {
        int flags = fragmented ? 0 : ContinuationFrame.FLAG_END_HEADERS;
        var header = new FrameHeader(
            data.length, FrameType.CONTINUATION, flags, streamId);
        return new ContinuationFrame(header, data);
      }

      test('unknown-frame', () {
        var defrag = new FrameDefragmenter();
        expect(defrag.tryDefragmentFrame(unknownFrame()) is UnknownFrame, true);
      });

      test('fragmented-headers-frame', () {
        var defrag = new FrameDefragmenter();

        var f1 = headersFrame([1, 2, 3], fragmented: true);
        var f2 = continuationFrame([4, 5, 6], fragmented: true);
        var f3 = continuationFrame([7, 8, 9], fragmented: false);

        expect(defrag.tryDefragmentFrame(f1), isNull);
        expect(defrag.tryDefragmentFrame(f2), isNull);
        HeadersFrame h = defrag.tryDefragmentFrame(f3);
        expect(h.hasEndHeadersFlag, isTrue);
        expect(h.hasEndStreamFlag, isFalse);
        expect(h.hasPaddedFlag, isFalse);
        expect(h.padLength, 0);
        expect(h.headerBlockFragment, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
      });

      test('fragmented-push-promise-frame', () {
        var defrag = new FrameDefragmenter();

        var f1 = pushPromiseFrame([1, 2, 3], fragmented: true);
        var f2 = continuationFrame([4, 5, 6], fragmented: true);
        var f3 = continuationFrame([7, 8, 9], fragmented: false);

        expect(defrag.tryDefragmentFrame(f1), isNull);
        expect(defrag.tryDefragmentFrame(f2), isNull);
        PushPromiseFrame h = defrag.tryDefragmentFrame(f3);
        expect(h.hasEndHeadersFlag, isTrue);
        expect(h.hasPaddedFlag, isFalse);
        expect(h.padLength, 0);
        expect(h.headerBlockFragment, [1, 2, 3, 4, 5, 6, 7, 8, 9]);
      });

      test('fragmented-headers-frame--wrong-id', () {
        var defrag = new FrameDefragmenter();

        var f1 = headersFrame([1, 2, 3], fragmented: true, streamId: 1);
        var f2 = continuationFrame([4, 5, 6], fragmented: true, streamId: 2);

        expect(defrag.tryDefragmentFrame(f1), isNull);
        expect(() => defrag.tryDefragmentFrame(f2),
               throwsProtocolException);
      });

      test('fragmented-push-promise-frame', () {
        var defrag = new FrameDefragmenter();

        var f1 = pushPromiseFrame([1, 2, 3], fragmented: true, streamId: 1);
        var f2 = continuationFrame([4, 5, 6], fragmented: true, streamId: 2);

        expect(defrag.tryDefragmentFrame(f1), isNull);
        expect(() => defrag.tryDefragmentFrame(f2),
               throwsProtocolException);
      });

      test('fragmented-headers-frame--no-continuation-frame', () {
        var defrag = new FrameDefragmenter();

        var f1 = headersFrame([1, 2, 3], fragmented: true);
        var f2 = unknownFrame();

        expect(defrag.tryDefragmentFrame(f1), isNull);
        expect(() => defrag.tryDefragmentFrame(f2),
               throwsProtocolException);
      });

      test('fragmented-push-promise-no-continuation-frame', () {
        var defrag = new FrameDefragmenter();

        var f1 = pushPromiseFrame([1, 2, 3], fragmented: true);
        var f2 = unknownFrame();

        expect(defrag.tryDefragmentFrame(f1), isNull);
        expect(() => defrag.tryDefragmentFrame(f2),
               throwsProtocolException);
      });

      test('push-without-headres-or-push-promise-frame', () {
        var defrag = new FrameDefragmenter();

        var f1 = continuationFrame([4, 5, 6], fragmented: true, streamId: 1);
        expect(defrag.tryDefragmentFrame(f1), equals(f1));
      });
    });
  });
}
