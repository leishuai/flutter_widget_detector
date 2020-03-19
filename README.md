# flutter_widget_detector

A tool widget that can display file location where widgets are created and some info of widget type, e.g. widget key, size and position at runtime. No need to connect observatory or any other tools. Hopes it can help you locate the code quickly and solve UI problems.

## Version

If your flutter sdk is later than 1.7.8(included), please use version above 0.1.0. Otherwise  use version below 0.1.0. 

## How to use

1. Edit your pubspec.yml file of your flutter project. And add code below in <b>dev_dependencies:</b>, because this only works in <b>Debug</b> mode.
```
    flutter_widget_detector: 0.1.2
```

2. Place your Widget Detector as the parent of any widget to be detected, which is normally your app widget in the runApp() method, and wrap it with assert in order to exclude it from production build. For example:

```
    Widget appWidget = MaterialApp(...);
    assert((){
        appWidget = WidgetDetector(child: appWidget, isEnabled: true);
        return true;
    }());
    return appWidget;
```

3. After you run the app, you can see a button with text "Detect Off" on the topmost of the screen. When it's off, the app can recognize the gestures as usual. When it's on, Widget Detector intercepts the gestures and only responds to tap where it will display its infos nearby.

![](http://chuantu.xyz/t6/703/1575198002x3703728804.png)

## How it works

For current version, it uses the hit test method to get a list of render objects from HitTestResult of responding chain. By traversing the render object path from innerside to outside and also checking the file location of where the widget are constructed(thru widget_inspector in flutter framework), it get the render object you probably want to detect, paint the area and border with colors, and draw infos text.

It filters away the widgets created by flutter framework to let you focus on the widget you project creates. 

And for your information, Row/Column or custom widgets that it doesn't override hit test method nor add itself to hit test path result can't be outlined currently. This can be optimized in the future update by traversing the element tree instead of using hit test methods.

