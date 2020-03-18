library flutter_widget_detector;

import 'package:flutter/widgets.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math' show min, max;


//@author: shine.lei
///Used for display testing detector info
class WidgetDetector extends StatefulWidget {
  final Widget child;
  final bool isEnabled;
  WidgetDetector({this.child, this.isEnabled = true});

  @override
  State<StatefulWidget> createState() {
    return WidgetDetectorState();
  }
}

class WidgetDetectorState extends State<WidgetDetector> {
  ///If selectMode is true, pointer interactions trigger widget selection,
  ///instead of normal interactions.
  bool isSelectMode = false;
  List<_RenderObjectSelection> _selections;

  final GlobalKey _ignorePointerKey = GlobalKey();

  Offset _lastPointerPosition;

  //enable toggle button pressed
  void _handleEnableSelect() {
    setState(() {
      isSelectMode = !isSelectMode;
      if (!isSelectMode) _selections = null;
    });
  }

  void _handlePanDown(DragDownDetails event) {
    _lastPointerPosition = event.globalPosition;
  }

  void _handleTap() {
    if (!isSelectMode) return;
    _detectPosition(_lastPointerPosition);
  }

  ///check which widgets user tapped on
  void _detectPosition(Offset position) {
    if (!isSelectMode) return;

    final RenderIgnorePointer renderIgnorePointer = _ignorePointerKey.currentContext.findRenderObject();
    RenderBox childRenderObject = renderIgnorePointer.child;
    //make sure childRenderObject is RenderBox
    while (childRenderObject is! RenderBox) {
      RenderBox result;
      childRenderObject.visitChildren((object){
        if (result != null) return;
        if (object is RenderBox) {
          result = object;
        }
        childRenderObject = object;
      });
    }
    List<_RenderObjectSelection> selections = <_RenderObjectSelection>[];
    _hitTest(selections, position, childRenderObject);

    setState(() {
      _selections = selections;
    });
  }

  void _hitTest(List<_RenderObjectSelection> selections, Offset position, RenderBox object) {
    //get hitTest candidates from RenderBox/RenderSliver hit test methods
    HitTestResult testResult = BoxHitTestResult();
    //flaw: if renderObject doesn't implement hitTest or add itself to result, then we can't obtain it. Fix later!
    object.hitTest(testResult, position: position);

    List hitTestEntries = testResult.path.toList();
    //get element of renderObject in order to get widget.key and runtimeType
    for (int i = 0; i < hitTestEntries.length; i++) {
      //BoxHitTestEntry or SliverHitTestEntry
      dynamic testEntry = hitTestEntries[i];
      //traverse parent of current element until it is next render object's element
      Element ele = testEntry.target.debugCreator.element;
      if (_checkElement(ele)) {
        selections.add(_RenderObjectSelection(renderObject: testEntry.target, element: ele));
      }
      dynamic nextTestEntry = (i + 1) < hitTestEntries.length ? hitTestEntries[i+1] : null;
      //we need traverse up the elements tree until we meet element of render object of nextTestEntry
      ele.visitAncestorElements((Element ancestor){
        if (nextTestEntry == null || ancestor == nextTestEntry.target.debugCreator.element)
          return false;

        if (_checkElement(ancestor)) {
          selections.add(_RenderObjectSelection(renderObject: testEntry.target, element: ancestor));
          return true;
        }
        return false;
      });
    }
  }

  ///validate if the element is that we created or its widget with specified key
  bool _checkElement(Element ele) {
//    Key key = ele.widget.key;
//    if (key is ValueKey) return true;

//    String widgetType = ele.widget.runtimeType.toString();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (WidgetsApp.debugShowWidgetInspectorOverride || !widget.isEnabled) return widget.child;
    final List<Widget> children = <Widget>[];
    children.add(GestureDetector(
      onTap: isSelectMode ? _handleTap : null,
      onPanDown: isSelectMode ? _handlePanDown : null,
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      child: IgnorePointer(
        key: _ignorePointerKey,
        ignoring: isSelectMode,
        child: widget.child,
      ),
    ));
    children.add(_buildSwitchButton());
    if (isSelectMode && _selections != null && _selections.length > 0)
      children.add(_WidgetDetectorOverlay(selections: _selections, pointerPosition: _lastPointerPosition,));
    return Stack(children: children, textDirection: TextDirection.ltr);
  }

  double _switchButtonLeft = _windowSize.width - 20 - _SwitchButton._kWidth;
  double _switchButtonTop = _windowSize.height - 120 - _SwitchButton._kHeight;
  _buildSwitchButton() {
    return Positioned(
        left: _switchButtonLeft,
        top: _switchButtonTop,
        child: GestureDetector(
          onPanUpdate: (DragUpdateDetails details){
            _switchButtonLeft = details.globalPosition.dx - _SwitchButton._kWidth/2;
            _switchButtonTop = details.globalPosition.dy - _SwitchButton._kHeight/2;
            setState(() {});
          },
          onPanEnd: (_){
            if (_switchButtonLeft + _SwitchButton._kWidth/2 < _windowSize.width/2) _switchButtonLeft = 20;
            else _switchButtonLeft = _windowSize.width - 20 - _SwitchButton._kWidth;
            _switchButtonTop = min(_windowSize.height - 20 - _SwitchButton._kHeight, max(20, _switchButtonTop));
            setState(() {});
          },
          child: _SwitchButton(text: isSelectMode ? 'On' : 'Off', onTap: _handleEnableSelect),
        )
    );
  }
}

///switch button to toggle on/off of detector
class _SwitchButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  _SwitchButton({this.text, this.onTap});

  static const double _kWidth = 40;
  static const double _kHeight = 50;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _kWidth,
        height: _kHeight,
        decoration: BoxDecoration(
            color: Color(0xDDFFFFFF),
            borderRadius: BorderRadius.all(Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 8.0,
                  offset: Offset(0, 0)),
            ]),
        child: Directionality(textDirection: TextDirection.ltr,
          child: Center(
            child: RichText(text: TextSpan(text: "Detect\n", style: TextStyle(color: Color(0xFF000000), fontSize: 12),
                children: [TextSpan(text: text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
              textAlign: TextAlign.center,),
          ),
        ),
      ),
    );
  }
}

final Size _windowSize = WidgetsBinding.instance.window.physicalSize / WidgetsBinding.instance.window.devicePixelRatio;

//draw content text or border of all selections in the selection path
class _WidgetDetectorOverlay extends LeafRenderObjectWidget {
  const _WidgetDetectorOverlay({
    Key key,
    @required this.selections,
    @required this.pointerPosition,
  }) : super(key: key);

  final List<_RenderObjectSelection> selections;
  final Offset pointerPosition;

  @override
  _RenderWidgetDetectorOverlay createRenderObject(BuildContext context) {
    return _RenderWidgetDetectorOverlay(selections: selections, pointerPosition: pointerPosition);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderWidgetDetectorOverlay renderObject) {
    renderObject.selections = selections;
    renderObject.pointerPosition = pointerPosition;
  }
}

///draw layer
class _RenderWidgetDetectorOverlay extends RenderBox {
  List<_RenderObjectSelection> selections;
  Offset pointerPosition;

  static const Color _kHighlightedFillColor = Color.fromARGB(128, 128, 128, 255);
  static const Color _kHighlightedBorderColor = Color.fromARGB(128, 64, 64, 128);
  static const Color _kTextColor = Color.fromARGB(255, 255, 255, 255);
  static const Color _kTextBgColor = Color.fromARGB(200, 160, 160, 160);
  static const Color _kInfoTextColor = Color.fromARGB(255, 255, 255, 224);

  _RenderWidgetDetectorOverlay({this.selections, this.pointerPosition});

  @override
  bool get sizedByParent => true;

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void performResize() {
    size = constraints.constrain(const Size(double.infinity, double.infinity));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    Canvas canvas = context.canvas;

    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _kHighlightedFillColor;

    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = _kHighlightedBorderColor;

    RenderBox lastRenderBox;
    List<_RenderObjectSelection> selectionsOfSameSize = [];
    bool hasPaintedSelection = false;
    for (int i = 0; i < selections.length; i++) {
      _RenderObjectSelection selection = this.selections[i];
      if (selection.renderObject is! RenderBox) continue;

      RenderBox renderBox = selection.renderObject;
      //avoid repeated paint on same size/renderObject
      if (lastRenderBox != null && renderBox.size != lastRenderBox.size) {
        //transform local coordinate to global
        Matrix4 transform = lastRenderBox.getTransformTo(null);
        Offset origin = MatrixUtils.transformPoint(transform, Offset.zero);
        Rect boundsRect = origin & lastRenderBox.paintBounds.size;

        //paint selection widget
        if (!hasPaintedSelection) {
          List<_RenderObjectSelection> localCreatedSelections = [];
          selectionsOfSameSize.forEach((selection){
            if (selection._isCreatedLocally()) localCreatedSelections.add(selection);
          });
          if (localCreatedSelections.length > 0) {
            hasPaintedSelection = true;
            canvas.drawRect(boundsRect, fillPaint);
            //draw text info
            _paintText(canvas, boundsRect, localCreatedSelections);
          }
        }
        //paint border of every different size
        if (hasPaintedSelection) {
          canvas.drawRect(boundsRect.inflate(0.5), borderPaint);
        }
        //clear array of selections of same size
        selectionsOfSameSize.removeRange(0, selectionsOfSameSize.length);
        selectionsOfSameSize.add(selection);
      } else {
        selectionsOfSameSize.add(selection);
      }
      lastRenderBox = renderBox;
    }
  }

  //selections is RenderBoxes
  void _paintText(Canvas canvas, Rect boundsRect, List<_RenderObjectSelection> selections) {
    final Paint textBgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _kTextBgColor;

    final TextPainter textPainter = TextPainter()
      ..textDirection = TextDirection.ltr;

    List<TextSpan> textSpans = [];
    //size info to display
    final RenderBox firstRenderObject = selections.first.renderObject;
    String sizeText = "${firstRenderObject.size.width} * ${firstRenderObject.size.height}";
    if (boundsRect.size != _windowSize) {
      sizeText += "\ninset LTRB: (${boundsRect.left}, ${boundsRect.top},"
          + " ${_windowSize.width - boundsRect.right}, ${_windowSize.height - boundsRect.bottom})";
    }
    textSpans.add(TextSpan(text: sizeText,
        style: TextStyle(color: _kInfoTextColor, fontWeight: FontWeight.bold, decorationStyle: TextDecorationStyle.dashed)));

    //widget info to display
    for (_RenderObjectSelection selection in selections) {
      if (textSpans.length > 0) textSpans.add(TextSpan(text: "\n"));
      textSpans.add(TextSpan(text: selection.widgetTypeString, style: TextStyle(fontWeight: FontWeight.bold)));
      String widgetKey = selection.widgetKeyString != null ? " ,key: ${selection.widgetKeyString}" : "";
      if (widgetKey.length > 0) textSpans.add(TextSpan(text: widgetKey));
      textSpans.add(TextSpan(text: "\n${selection.localFilePosition}"));
    }
    textPainter.text = TextSpan(text: "", children: textSpans, style: TextStyle(color: _kTextColor, fontSize: 12));
    textPainter.layout();

    Rect textBgRect;
    Size textPainterSize = textPainter.size + Offset(4, 4);
    if (textPainterSize.width > boundsRect.width || textPainterSize.height > boundsRect.height) {
      //move out of bound rect
      double left = min(boundsRect.left, _windowSize.width - textPainterSize.width);
      if (boundsRect.bottom < _windowSize.height * 0.7) {
        //text displays beneath selection
        textBgRect = Offset(left, boundsRect.bottom) & textPainterSize;
      } else if (boundsRect.top > _windowSize.height * 0.3) {
        //text displays on top of selection
        textBgRect = Offset(left, boundsRect.top - textPainterSize.height) & textPainterSize;
      } else {
        //text displays inside of selection area
        textBgRect = Offset(left, boundsRect.top + boundsRect.height/2 - textPainterSize.height/2) & textPainterSize;
      }
    } else {
      textBgRect = Offset(boundsRect.left + 1, boundsRect.top) & textPainterSize;
    }
    double topPadding = WidgetsBinding.instance.window.padding.top / WidgetsBinding.instance.window.devicePixelRatio;
    if (textBgRect.top < topPadding) {
      textBgRect = textBgRect.translate(0, topPadding - textBgRect.top);
    }
    canvas.drawRect(textBgRect, textBgPaint);
    textPainter.paint(canvas, Offset(textBgRect.left + 2, textBgRect.top + 2));
  }
}

///
class _RenderObjectSelection with WidgetInspectorService {
  RenderObject renderObject;
  Element element;

  _RenderObjectSelection({this.renderObject, this.element});

  Key get widgetKey => element.widget.key;
  String get widgetKeyString {
    if (widgetKey is ValueKey) {
      return widgetKey.toString();
    }
    return null;
  }

  Type get widgetType => element.widget.runtimeType;
  String get widgetTypeString => widgetType.toString();

  Map _jsonInfoMap;
  ///in which file widget is constructed. Map keys: file, line, column
  Map get locationInfoMap {
    if (_jsonInfoMap == null) getJsonInfo();
    return _jsonInfoMap["creationLocation"];
  }

  String get localFilePosition {
    if (_isCreatedLocally()) {
      String filePath = locationInfoMap["file"];
      var pathPattern = RegExp('.*(/lib/.+)');
      filePath = pathPattern.firstMatch(filePath).group(1);
      return "file: $filePath, line: ${locationInfoMap["line"]}";
    }
    return null;
  }

  Map getJsonInfo() {
    if (_jsonInfoMap != null) return _jsonInfoMap;
    //warning: consumes a lot of time
    WidgetInspectorService.instance.setSelection(element);
    String jsonStr = WidgetInspectorService.instance.getSelectedWidget(null, null);
    return _jsonInfoMap = json.decode(jsonStr);
  }

  bool _isCreatedLocally() {
    String fileLocation = locationInfoMap["file"];
    final String flutterFrameworkPath = "/packages/flutter/lib/src/";
    return !fileLocation.contains(flutterFrameworkPath);
  }

  @override
  String toString() {
    return "renderObject: $renderObject, widgetKey: $widgetKey, widgetType: $widgetType";
  }
}