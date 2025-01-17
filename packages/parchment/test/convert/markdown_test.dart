// Copyright (c) 2018, the Zefyr project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:convert';

import 'package:parchment/convert.dart';
import 'package:parchment/parchment.dart';
import 'package:quill_delta/quill_delta.dart';
import 'package:test/test.dart';

void main() {
  group('$ParchmentMarkdownCodec.encode', () {
    test('unimplemented', () {
      expect(() {
        parchmentMarkdown.decode('test');
      }, throwsUnimplementedError);
    });
  });

  group('$ParchmentMarkdownCodec.encode', () {
    test('split adjacent paragraphs', () {
      final delta = Delta()..insert('First line\nSecond line\n');
      final result = parchmentMarkdown.encode(delta);
      expect(result, 'First line\n\nSecond line\n\n');
    });

    test('bold italic', () {
      void runFor(ParchmentAttribute<bool> attribute, String expected) {
        final delta = Delta()
          ..insert('This ')
          ..insert('house', attribute.toJson())
          ..insert(' is a ')
          ..insert('circus', attribute.toJson())
          ..insert('\n');

        final result = parchmentMarkdown.encode(delta);
        expect(result, expected);
      }

      runFor(ParchmentAttribute.bold, 'This **house** is a **circus**\n\n');
      runFor(ParchmentAttribute.italic, 'This _house_ is a _circus_\n\n');
    });

    test('intersecting inline styles', () {
      final b = ParchmentAttribute.bold.toJson();
      final i = ParchmentAttribute.italic.toJson();
      final bi = Map<String, dynamic>.from(b);
      bi.addAll(i);

      final delta = Delta()
        ..insert('This ')
        ..insert('house', b)
        ..insert(' is a ', bi)
        ..insert('circus', b)
        ..insert('\n');

      final result = parchmentMarkdown.encode(delta);
      expect(result, 'This **house _is a_ circus**\n\n');
    });

    test('normalize inline styles', () {
      final b = ParchmentAttribute.bold.toJson();
      final i = ParchmentAttribute.italic.toJson();
      final delta = Delta()
        ..insert('This')
        ..insert(' house ', b)
        ..insert('is a')
        ..insert(' circus ', i)
        ..insert('\n');

      final result = parchmentMarkdown.encode(delta);
      expect(result, 'This **house** is a _circus_ \n\n');
    });

    test('links', () {
      final b = ParchmentAttribute.bold.toJson();
      final link = ParchmentAttribute.link.fromString('https://github.com');
      final delta = Delta()
        ..insert('This')
        ..insert(' house ', b)
        ..insert('is a')
        ..insert(' circus ', link.toJson())
        ..insert('\n');

      final result = parchmentMarkdown.encode(delta);
      expect(result, 'This **house** is a [circus](https://github.com) \n\n');
    });

    test('heading styles', () {
      void runFor(
          ParchmentAttribute<int> attribute, String source, String expected) {
        final delta = Delta()
          ..insert(source)
          ..insert('\n', attribute.toJson());
        final result = parchmentMarkdown.encode(delta);
        expect(result, expected);
      }

      runFor(ParchmentAttribute.h1, 'Title', '# Title\n\n');
      runFor(ParchmentAttribute.h2, 'Title', '## Title\n\n');
      runFor(ParchmentAttribute.h3, 'Title', '### Title\n\n');
    });

    test('block styles', () {
      void runFor(ParchmentAttribute<String> attribute, String source,
          String expected) {
        final delta = Delta()
          ..insert(source)
          ..insert('\n', attribute.toJson());
        final result = parchmentMarkdown.encode(delta);
        expect(result, expected);
      }

      runFor(ParchmentAttribute.ul, 'List item', '* List item\n\n');
      runFor(ParchmentAttribute.ol, 'List item', '1. List item\n\n');
      runFor(ParchmentAttribute.bq, 'List item', '> List item\n\n');
      runFor(ParchmentAttribute.code, 'List item', '```\nList item\n```\n\n');
    });

    test('multiline blocks', () {
      void runFor(ParchmentAttribute<String> attribute, String source,
          String expected) {
        final delta = Delta()
          ..insert(source)
          ..insert('\n', attribute.toJson())
          ..insert(source)
          ..insert('\n', attribute.toJson());
        final result = parchmentMarkdown.encode(delta);
        expect(result, expected);
      }

      runFor(ParchmentAttribute.ul, 'text', '* text\n* text\n\n');
      runFor(ParchmentAttribute.ol, 'text', '1. text\n1. text\n\n');
      runFor(ParchmentAttribute.bq, 'text', '> text\n> text\n\n');
      runFor(ParchmentAttribute.code, 'text', '```\ntext\ntext\n```\n\n');
    });

    test('multiple styles', () {
      final result = parchmentMarkdown.encode(delta);
      expect(result, expectedMarkdown);
    });
  });
}

final doc =
    r'[{"insert":"Fleather"},{"insert":"\n","attributes":{"heading":1}},{"insert":"Soft and gentle rich text editing for Flutter applications.","attributes":{"i":true}},{"insert":"\nFleather is an "},{"insert":"early preview","attributes":{"b":true}},{"insert":" open source library.\nDocumentation"},{"insert":"\n","attributes":{"heading":3}},{"insert":"Quick Start"},{"insert":"\n","attributes":{"block":"ul"}},{"insert":"Data format and Document Model"},{"insert":"\n","attributes":{"block":"ul"}},{"insert":"Style attributes"},{"insert":"\n","attributes":{"block":"ul"}},{"insert":"Heuristic rules"},{"insert":"\n","attributes":{"block":"ul"}},{"insert":"Clean and modern look"},{"insert":"\n","attributes":{"heading":2}},{"insert":"Fleather’s rich text editor is built with simplicity and flexibility in mind. It provides clean interface for distraction-free editing. Think Medium.com-like experience.\nimport ‘package:flutter/material.dart’;"},{"insert":"\n","attributes":{"block":"code"}},{"insert":"import ‘package:parchment/parchment.dart’;"},{"insert":"\n\n","attributes":{"block":"code"}},{"insert":"void main() {"},{"insert":"\n","attributes":{"block":"code"}},{"insert":" print(“Hello world!”);"},{"insert":"\n","attributes":{"block":"code"}},{"insert":"}"},{"insert":"\n","attributes":{"block":"code"}}]';
final delta = Delta.fromJson(json.decode(doc) as List);

final expectedMarkdown = '''
# Fleather

_Soft and gentle rich text editing for Flutter applications._

Fleather is an **early preview** open source library.

### Documentation

* Quick Start
* Data format and Document Model
* Style attributes
* Heuristic rules

## Clean and modern look

Fleather’s rich text editor is built with simplicity and flexibility in mind. It provides clean interface for distraction-free editing. Think Medium.com-like experience.

```
import ‘package:flutter/material.dart’;
import ‘package:parchment/parchment.dart’;

void main() {
 print(“Hello world!”);
}
```

''';
