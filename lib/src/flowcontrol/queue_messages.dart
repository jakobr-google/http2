// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library http2.src.flowcontrol.queue_messages;

import '../../transport.dart';

/// The subclasses of [Message] are objects that are coming from the
/// connection layer on top of frames.
///
/// Messages on a HTTP/2 stream will be represented by a different class
/// hierarchy.
abstract class Message {
  final int streamId;
  final bool endStream;

  Message(this.streamId, this.endStream);
}

class HeadersMessage extends Message {
  final List<Header> headers;

  HeadersMessage(int streamId, this.headers, bool endStream)
      : super(streamId, endStream);

  String toString()
      => 'HeadersMessage(headers: ${headers.length}, endStream: $endStream)';
}

class DataMessage extends Message {
  final List<int> bytes;

  DataMessage(int streamId, this.bytes, bool endStream)
      : super(streamId, endStream);

  String toString()
      => 'DataMessage(bytes: ${bytes.length}, endStream: $endStream)';
}

class PushPromiseMessage extends Message {
  final List<Header> headers;
  final int promisedStreamId;
  final TransportStream pushedStream;

  PushPromiseMessage(
      int streamId, this.headers, this.promisedStreamId, this.pushedStream,
      bool endStream) : super(streamId, endStream);

  String toString()
      => 'PushPromiseMessage(bytes: ${headers.length}, '
         'promisedStreamId: $promisedStreamId, endStream: $endStream)';
}
