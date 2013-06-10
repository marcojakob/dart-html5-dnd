/**
 * Helper library for reordering of HTML elements with native HTML5 Drag and
 * Drop.
 */
library html5_sortable;

import 'dart:html';
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';
import 'package:html5_dnd/html5_dnd.dart';

import 'package:html5_dnd/src/css_utils.dart' as css;
import 'package:html5_dnd/src/html5_utils.dart' as html5;

part 'sortable.dart';

final _logger = new Logger("html5_sortable");

_Placeholder _currentPlaceholder;
