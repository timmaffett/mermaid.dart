// Copyright (c) 2022, Tim Maffett and others.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// this ignore_for_file is here so that we can have constant names that match the
// underlying javascript library and documentation.
// ignore_for_file: non_constant_identifier_names

@JS('mermaid')
library mermaid;

import 'dart:html';
import 'dart:math';
import 'package:js/js.dart';

/// mermaid.init
/// By default, mermaid.init will be called when the document is ready,
/// finding all elements with class="mermaid". If you are adding content after
/// mermaid is loaded, or otherwise need finer-grained control of this behavior,
/// you can call init yourself with:
///
/// [ingored] a configuration object that is always ignored, use [mermaidInitialize]
/// [selectorStringOrElementOrListOfElements] A W3C selector String, or an Element,
/// or an List<Element>
@JS('init')
external void mermaidInitNative(
    Config? ingored, Object? selectorStringOrElementOrListOfElements);

/// This wraps the native mermaid.init() with an additional call to
/// mermaid.Initialize() so the Config parameter is honored.  (the native
/// mermaid.init() always INGORES the configuration object, which
/// can be confusing because mermaid docs don't always indicate that).
/// If no selector is specified than all elements with class="mermaid"
/// are targeted
/// [configObject] a configuration object that will be sent to [mermaidInitialize].
/// [selectorStringOrElementOrListOfElements] A W3C selector String, or an Element,
/// or an List<Element>
void mermaidInit(
    Config? configObject, Object? selectorStringOrElementOrListOfElements) {
  if (configObject != null) {
    mermaidInitialize(configObject);
  }
  mermaidInitNative(null, selectorStringOrElementOrListOfElements);
}

/// Our wrapper function that calls JS mermaid.init() and can be used to
/// render the specified mermaid element(s).
/// [selectorStringOrElementOrListOfElements] A W3C selector String, or an Element,
/// or an List<Element>
void mermaidRender(Object? selectorStringOrElementOrListOfElements) {
  if (selectorStringOrElementOrListOfElements is ElementList) {
    mermaidInit(null, selectorStringOrElementOrListOfElements.toList());
  } else {
    // selectorStringOrElementOrListOfElements should be String (W3C selector), Element or
    // List<Element>
    mermaidInit(null, selectorStringOrElementOrListOfElements);
  }
}

/// Initialize mermaid settings.  Pass a configuration object as described in
/// [mermaid configation object documentation.](https://github.com/mermaid-js/mermaid/blob/develop/docs/Setup.md)
@JS('initialize')
external void mermaidInitialize([Config? config]); //Config config);

/// Used to render a graph and receive have the source for the created SVG file.
/// The complete SVG file will be returned and sent to the [bindingCallback] if one
/// is provided.  The [bindingCallback] callback only needs to be used if you want to
/// use the [bindingCallback] to allow mermaid to bind event handlers to the element
/// within the DOM that you are placing the SVG file within.
/// [idOfAScratchDivToCreate] is a NEVER BEFORE USED html element ID that can
/// use used to create a scratch div (or iframe for sandbox mode). This element
/// will BE REMOVED from the dom before this returns, so DO NOT pass in id's of
/// existing elements.
/// NOTE: This MUST BE a id that was NEVER passed into render() previously -
/// re-using the same scratch ID will not work.  The DART mermaidApi.render()
/// wrapper function will automatically generate random IDs if '' or null is
/// passed for the [idOfAScratchDivToCreate] parameter.
/// [diagramDef] is the source for the diagram being rendered.
/// [bindingCallback] is the callback that will be called with the SVG code and
/// binding callback-callback.
/// [scratchElementWhereMermaidWillMakeSVG] is a scratch div within the dom
/// that mermaid can use. The [idOfAScratchDivToCreate] must STILL BE a unique
/// ID when using the [scratchElementWhereMermaidWillMakeSVG] parameter.
/// The underlying JS mermaid library is very peculiar behavior here that I cannot
/// explain.
@JS("mermaidAPI.render")
external String mermaidApiRender(
    String idOfAScratchDivToCreate, String diagramDef,
    [void Function(String svgCode, void Function(Element element))?
        bindingCallback,
    Element? scratchElementWhereMermaidWillMakeSVG]);

/// Used to test diagram code before calling render().  Returns true if the
/// diagram syntax is valid.  If [mermaidSetParseErrorHandler] has been used to set
/// a parseError() handler then this method will return false if the diagram
/// syntax is invalid.  (If no parseError() handler has been set then parse()
/// will throw an exception in javascript as render() would with invalid
/// syntax).
/// NOTE: Note as of mermaid version 9.0.1 the behavior of parse() method has a BUG
/// - it is doced to return true if valid and false if invalid, but instead it
/// returns the parser() object itself ??!!!
/// I have submitted a PR to fix the behavior to match the docs and the user here - so
/// at some point this should work as intended.
@JS("mermaidAPI.parse")
external bool mermaidApiParse(String text);

/// Used to set a handler to be called when invalid diagram syntax is encountered.
/// The definition of the function should match `void parseError(String err,String hash)`.
/// NOTE: As of mermaid version 9.0.1 this method does not exists, but I have submitted
/// a PR that adds this method.  The reason for this is that we cannot (from dart interop)
/// add a mermaid.parseError member when none previously existed. (from within
/// javascript this was done simply as mermaid.parseError = function(err,hash) {})
@JS("mermaidAPI.setParseErrorHandler")
external void mermaidSetParseErrorHandler(
    void Function(String error, String hash) parseError);

/// Calls mermaidAPI.initialize
@JS("mermaidAPI.initialize")
external void mermaidApiInitialize(Config options);

/// Calls mermaidAPI.getConfig() and returns the current configuration object.
@JS("mermaidAPI.getConfig")
external Config mermaidApiGetConfig();

/// Resets all configuration and state information to defaults.
/// Calls mermaidApi.reset()
@JS("mermaidAPI.reset")
external Config mermaidReset();

/// Wrapper for methods calls so they can be called from MermaidApi.  This more
/// closely matches the docs for the mermaid javascript library.  (Note:
/// MermaidApi is used as name instead of mermaidAPI because of Dart naming
/// conventions).
/// In some cases we do not call the underlying mermaidAPI version but instead
/// we call the mermaid version because of inconsistencies in mermaid 9.0.1
/// mermaidAPI object code and behavior.
class MermaidApi {
  static const _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  static final Random _rnd = Random();

  static String _getRandomString(int length) =>
      String.fromCharCodes(Iterable.generate(
          length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  /// Initialize mermaid settings.  Pass a configuration object as described in
  /// [mermaid configation object documentation.](https://github.com/mermaid-js/mermaid/blob/develop/docs/Setup.md)
  static void initialize(Config config) => mermaidInitialize(config);

  /// Used to render a graph and receive have the source for the created SVG file.
  /// The complete SVG file will be returned and sent to the [bindingCallback] if one
  /// is provided.  The [bindingCallback] callback only needs to be used if you want to
  /// use the [bindingCallback] to allow mermaid to bind event handlers to the element
  /// within the DOM that you are placing the SVG file within.
  /// [idOfAScratchDivToCreate] can be '' or null and this wrapper function
  /// will automatically generate random IDs, or it can be a NEVER BEFORE
  /// USED html element ID that can use used to create a scratch div (or iframe
  /// for sandbox mode). This element will BE REMOVED from the dom before this
  /// returns, so DO NOT pass in id's of existing elements.
  /// NOTE: This MUST BE a id that was NEVER passed into render() previously -
  /// re-using the same scratch ID will not work.
  /// [diagramDef] is the source for the diagram being rendered.
  /// [bindingCallback] is the callback that will be called with the SVG code and
  /// binding callback-callback.
  /// [scratchElementWhereMermaidWillMakeSVG] is a scratch div within the dom
  /// that mermaid can use. The [idOfAScratchDivToCreate] must STILL BE a unique
  /// ID when using the [scratchElementWhereMermaidWillMakeSVG] parameter.
  /// The underlying JS mermaid library is very peculiar behavior here that I cannot
  /// explain.
  static String render(String? idOfAScratchDivToCreate, String diagramDef,
      [void Function(String svgCode,
              [void Function(Element element)? bindFunction])?
          bindingCallback,
      Element? scratchElementWhereMermaidWillMakeSVG]) {
    if (idOfAScratchDivToCreate == null || idOfAScratchDivToCreate == '') {
      // ignore: parameter_assignments
      idOfAScratchDivToCreate = 'SCRATCH${_getRandomString(10)}';
    }
    if (bindingCallback != null &&
        scratchElementWhereMermaidWillMakeSVG != null) {
      return mermaidApiRender(idOfAScratchDivToCreate, diagramDef,
          allowInterop(bindingCallback), scratchElementWhereMermaidWillMakeSVG);
    } else if (bindingCallback != null) {
      return mermaidApiRender(
          idOfAScratchDivToCreate, diagramDef, allowInterop(bindingCallback));
    } else {
      return mermaidApiRender(idOfAScratchDivToCreate, diagramDef);
    }
  }

  /// Used to test diagram code before calling render().  Returns true if the
  /// diagram syntax is valid.  If [MermaidApi.parseError] or [mermaidSetParseErrorHandler]
  /// have been used to set a parseError() handler then this method will return
  /// false if the diagram syntax is invalid.  (If no parseError() handler has
  /// been set then parse() will throw an exception in javascript as render()
  /// would with invalid syntax).
  /// NOTE: Note as of mermaid version 9.0.1 the behavior of parse() method has a BUG
  /// - it is doced to return true if valid and false if invalid, but instead it
  /// returns the parser() object itself ??!!!
  /// I have submitted a PR to fix the behavior to match the docs and the user here - so
  /// at some point this should work as intended.
  static bool parse(String text) => mermaidApiParse(text);

  /// Used to set a handler to be called when invalid diagram syntax is encountered.
  /// The definition of the function should match `void parseError(String err,String hash)`.
  /// NOTE: As of mermaid version 9.0.1 this method does not exists, but I have submitted
  /// a PR that adds this method.  The reason for this is that we cannot (from dart interop)
  /// add a mermaid.parseError member when none previously existed. (from within
  /// javascript this was done simply as mermaid.parseError = function(err,hash) {})
  static set parseError(
          void Function(String error, String hash) parseErrorCallback) =>
      mermaidSetParseErrorHandler(allowInterop(parseErrorCallback));

  /// Calls mermaidAPI.getConfig() and returns the current configuration object.
  static Config getConfig() => mermaidApiGetConfig();

  /// Resets all configuration and state information to defaults.
  /// Calls mermaidApi.reset()
  static void reset() => mermaidReset();
}

/// This is here to simply allow use of 'mermaidAPI.xyz()' as javascript docs will be showing.
MermaidApi mermaidAPI = MermaidApi();

/// Can be used for passing allowed strings to [Config.securityLevel].
class SecurityLevel {
  /// (default) tags in text are encoded, click functionality is disabled
  static String Strict = 'strict';

  /// tags in text are allowed, click functionality is enabled
  static String Loose = 'loose';

  /// html tags in text are allowed, (only script element is removed), click functionality is enabled
  static String Antiscript = 'antiscript';

  /// with this security level all rendering takes place in a sandboxed iframe.
  /// This prevent any javascript running in the context.
  /// This may hinder interactive functionality of the diagram like scripts,
  /// popups in sequence diagram or links to other tabs/targets etc.
  static String Sandbox = 'sandbox';
}

/// Can be used for passing allowed strings to [Config.theme].
class Theme {
  /// Designed to modified, as the name implies it is supposed to be used as the base for making custom themes.
  static String Base = 'base';

  /// A theme full of light greens that is easy on the eyes.
  static String Forest = 'forest';

  /// A theme that would go well with other dark colored elements.
  static String Dark = 'dark';

  /// The default theme for all diagrams.
  static String Default = 'default';

  /// The theme to be used for black and white printing
  static String Neutral = 'neutral';
}

/// Can be used for psassing allowed num values to [Config.logLevel].
class LogLevel {
  static num Debug = 1;
  static num Info = 2;
  static num Warn = 3;
  static num Error = 4;
  static num Fatal = 5;
}

@JS()
@anonymous
abstract class FlowChartConfig {
  external factory FlowChartConfig({bool htmlLabels, String curve});

  /// [htmlLabels] - Flag for setting whether or not a html tag should be used for rendering labels
  /// on the edges
  /// default: true
  external bool get htmlLabels;
  external set htmlLabels(bool v);

  /// default: 'linear'
  external String get curve;
  external set curve(String v);
}

@JS()
@anonymous
abstract class SequenceDiagramConfig {
  external factory SequenceDiagramConfig(
      {num diagramMarginX,
      num diagramMarginY,
      num actorMargin,
      num width,
      num height,
      num boxMargin,
      num boxTextMargin,
      num noteMargin,
      num messageMargin,
      bool mirrorActors,
      num bottomMarginAdj,
      bool useMaxWidth});

  /// [diagramMarginX] - margin to the right and left of the sequence diagram
  /// default: 50
  external num get diagramMarginX;
  external set diagramMarginX(num v);

  /// [diagramMarginY] - margin to the over and under the sequence diagram
  /// default: 10
  external num get diagramMarginY;
  external set diagramMarginY(num v);

  /// [actorMargin] - Margin between actors
  /// default: 10
  external num get actorMargin;
  external set actorMargin(num v);

  /// [width] - Width of actor boxes
  /// default: 150
  external num get width;
  external set width(num v);

  /// [height] - Height of actor boxes
  /// default: 65
  external num get height;
  external set height(num v);

  /// [boxMargin] - Margin around loop boxes
  /// default: 10
  external num get boxMargin;
  external set boxMargin(num v);

  /// [boxTextMargin] - margin around the text in loop/alt/opt boxes
  /// default: 5
  external num get boxTextMargin;
  external set boxTextMargin(num v);

  /// [noteMargin] - margin around notes
  /// default: 10
  external num get noteMargin;
  external set noteMargin(num v);

  /// [messageMargin] - Space between messages
  /// default: 35
  external num get messageMargin;
  external set messageMargin(num v);

  /// [mirrorActors] - mirror actors under diagram
  /// default: true
  external bool get mirrorActors;
  external set mirrorActors(bool v);

  /// [bottomMarginAdj] - Depending on css styling this might need adjustment.
  /// Prolongs the edge of the diagram downwards
  /// default: 1
  external num get bottomMarginAdj;
  external set bottomMarginAdj(num v);

  /// [useMaxWidth] - when this flag is set the height and width is set to 100% and is then scaling with the
  /// available space if not the absolute space required is used
  /// default: true
  external bool get useMaxWidth;
  external set useMaxWidth(bool v);
}

@JS()
@anonymous
abstract class GnattConfig {
  external factory GnattConfig(
      {num titleTopMargin,
      num barHeight,
      num barGap,
      num topPadding,
      num leftPadding,
      num gridLineStartPadding,
      num fontSize,
      String fontFamily,
      num numberSectionStyles,
      String axisFormat});

  /// [titleTopMargin] - margin top for the text over the gantt diagram
  /// default: 25
  external num get titleTopMargin;
  external set titleTopMargin(num v);

  /// [barHeight] - the height of the bars in the graph
  /// default: 20
  external num get barHeight;
  external set barHeight(num v);

  /// [barGap] - the margin between the different activities in the gantt diagram
  /// default: 4
  external num get barGap;
  external set barGap(num v);

  /// [topPadding] - margin between title and gantt diagram and between axis and gantt diagram.
  /// default: 50
  external num get topPadding;
  external set topPadding(num v);

  /// [leftPadding] - the space allocated for the section name to the left of the activities.
  /// default: 75
  external num get leftPadding;
  external set leftPadding(num v);

  /// [gridLineStartPadding] - Vertical starting position of the grid lines
  /// default: 35
  external num get gridLineStartPadding;
  external set gridLineStartPadding(num v);

  /// [fontSize] - font size ...
  /// default: 11
  external num get fontSize;
  external set fontSize(num v);

  /// [fontFamily] - font family ...
  /// default:  '"Open-Sans", "sans-serif"'
  external String get fontFamily;
  external set fontFamily(String v);

  /// [numberSectionStyles] - the number of alternating section styles
  /// default: 4
  external num get numberSectionStyles;
  external set numberSectionStyles(num v);

  /// [axisFormat] - datetime format of the axis, this might need adjustment to match your locale and preferences
  /// default: '%Y-%m-%d'
  external String get axisFormat;
  external set axisFormat(String v);
}

@JS()
@anonymous
abstract class Config {
  external factory Config(
      {String securityLevel,
      String? theme,
      String themeCSS,
      num logLevel,
      bool startOnLoad,
      bool arrowMarkerAbsolute,
      FlowChartConfig flowchart,
      SequenceDiagramConfig sequence,
      GnattConfig gnatt,
      dynamic git});

  /// Disallow/allow potentially dangerous cross-site scripting behavior.
  /// See [SecurityLevel] class for possible values.
  /// default: [SecurityLevel.Strict]
  /// If the value is not present, the default behavior is [SecurityLevel.Strict]
  external String get securityLevel;
  external set securityLevel(String v);

  /// See [Theme] class for possible values.
  /// - [Theme.Base] : Designed to modified, as the name implies it is supposed to be used as the base for making custom themes.
  /// - [Theme.Forest] : A theme full of light greens that is easy on the eyes.
  /// - [Theme.Dark] : A theme that would go well with other dark colored elements.
  /// - [Theme.Default] : The default theme for all diagrams.
  /// - [Theme.Neutral] : The theme to be used for black and white printing
  /// Notes: To disable any pre-defined mermaid theme, set to null.
  /// TODO: setting to null did not work in my testing - tmm 4/28/22
  external String? get theme;
  external set theme(String? v);

  external String get themeCSS;
  external set themeCSS(String v);

  //themeVariables: { primaryColor: '#ff0000' }
//%%{init:{"theme":"base", "themeVariables": {"primaryColor":"#411d4e", "titleColor":"white", "darkMode":true}}}%%
  //        %%{init: {'theme': 'base',  'fontFamily': 'courier', 'themeVariables': {  'primaryColor': '#fff000'}}}%%
/*
%%{init: { "logLevel": "debug", "theme": "default" , "gitGraph" : {"showBranches":"false"},"themeVariables": {
              "gitBranchLabel0": "#ff0000",
              "gitBranchLabel1": "#00ff00",
              "gitBranchLabel2": "#0000ff",
              "git0": "#550055"
       } } }%%


themeVariables: {
    commitLabelColor: '#9400D3',
    commitLabelBackground: '#FFFFFF',
           darkMode: true,
          background: '#222',
           textColor: 'white',
       primaryTextColor: '#f4f4f4',

    nodeBkg: '#ff0000',
    mainBkg: '#0000ff',
     tertiaryColor: '#ffffcc',
  },
    const themeVariables = conf.themeVariables;
    var myGeneratedColors = [
      themeVariables.pie1,
      themeVariables.pie2,
      themeVariables.pie3,
      themeVariables.pie4,
      themeVariables.pie5,
      themeVariables.pie6,
      themeVariables.pie7,
      themeVariables.pie8,
      themeVariables.pie9,
      themeVariables.pie10,
      themeVariables.pie11,
      themeVariables.pie12,
    ];
*/

  /// logLevel , decides the amount of logging to be used.
  /// See [LogLevel] class for possible values.
  /// default: [LogLevel.Fatal]
  external num get logLevel;
  external set logLevel(num v);

  /// [startOnLoad] - This options controls whether or mermaid starts when the page loads
  /// default: true
  external bool get startOnLoad;
  external set startOnLoad(bool v);

  /// [arrowMarkerAbsolute] - This options controls whether or arrow markers in html code will be absolute paths or
  /// an anchor, #. This matters if you are using base tag settings.
  /// default: false
  external bool get arrowMarkerAbsolute;
  external set arrowMarkerAbsolute(bool v);

  /// ### flowchart
  /// *The object containing configurations specific for flowcharts*
  external FlowChartConfig get flowchart;
  external set flowchart(FlowChartConfig v);

  /// ###  sequenceDiagram
  /// The object containing configurations specific for sequence diagrams
  external SequenceDiagramConfig get sequence;
  external set sequence(SequenceDiagramConfig v);

  /// ### gantt
  /// The object containing configurations specific for gantt diagrams*
  external GnattConfig get gnatt;
  external set gnatt(GnattConfig v);

  //external dynamic get JS$class;
  //external set JS$class(dynamic v);

  external dynamic get git;
  external set git(dynamic v);

  /// This option controls if the generated ids of nodes in the SVG are generated
  /// randomly or based on a seed. If set to false, the IDs are generated based on
  /// the current date and thus are not deterministic. This is the default behaviour.
  /// Notes:
  /// This matters if your files are checked into sourcecontrol e.g. git and
  /// should not change unless content is changed.
  external bool get deterministicIds;
  external set deterministicIds(bool v);

  /// This option is the optional seed for deterministic ids. if set to null
  /// but deterministicIds is true, a simple number iterator is used. You can set
  /// this attribute to base the seed on a static string.
  external bool? get deterministicIDSeed;
  external set deterministicIDSeed(bool? v);

  /// This option controls which currentConfig keys are considered secure and
  /// can only be changed via call to mermaidAPI.initialize. Calls to
  /// mermaidAPI.reinitialize cannot make changes to the secure keys in the
  /// current currentConfig. This prevents malicious graph directives from
  /// overriding a site's default security.
  /// Notes:
  /// Default value: `['secure', 'securityLevel', 'startOnLoad', 'maxTextSize']`
  external List<String> get secure;
  external set secure(List<String> v);

  static String stringifyConfig(Config? c) {
    if (c == null) {
      return 'config is null';
    }
    return '''securityLevel:${c.securityLevel},
theme:${c.theme},
logLevel:${c.logLevel},
startOnLoad:${c.startOnLoad},
arrowMarkerAbsolute:${c.arrowMarkerAbsolute},
''';
  }
}

/*
TIM JAVASCRIPT for dark theme in mermaid

Misc other notes and code taken from Mermaid.js for building this file

TODO: @timmaffett Clean up this code make sure it is all incorporated or removed.


import { invert, lighten, darken, rgba, adjust } from 'khroma';
import { mkBorder } from './theme-helpers';
class Theme {
  constructor() {
    this.background = '#333';
    this.primaryColor = '#1f2020';
    this.secondaryColor = lighten(this.primaryColor, 16);

    this.tertiaryColor = adjust(this.primaryColor, { h: -160 });
    this.primaryBorderColor = invert(this.background);
    this.secondaryBorderColor = mkBorder(this.secondaryColor, this.darkMode);
    this.tertiaryBorderColor = mkBorder(this.tertiaryColor, this.darkMode);
    this.primaryTextColor = invert(this.primaryColor);
    this.secondaryTextColor = invert(this.secondaryColor);
    this.tertiaryTextColor = invert(this.tertiaryColor);
    this.lineColor = invert(this.background);
    this.textColor = invert(this.background);

    this.mainBkg = '#1f2020';
    this.secondBkg = 'calculated';
    this.mainContrastColor = 'lightgrey';
    this.darkTextColor = lighten(invert('#323D47'), 10);
    this.lineColor = 'calculated';
    this.border1 = '#81B1DB';
    this.border2 = rgba(255, 255, 255, 0.25);
    this.arrowheadColor = 'calculated';
    this.fontFamily = '"trebuchet ms", verdana, arial, sans-serif';
    this.fontSize = '16px';
    this.labelBackground = '#181818';
    this.textColor = '#ccc';
    /* Flowchart variables */

    this.nodeBkg = 'calculated';
    this.nodeBorder = 'calculated';
    this.clusterBkg = 'calculated';
    this.clusterBorder = 'calculated';
    this.defaultLinkColor = 'calculated';
    this.titleColor = '#F9FFFE';
    this.edgeLabelBackground = 'calculated';

    /* Sequence Diagram variables */

    this.actorBorder = 'calculated';
    this.actorBkg = 'calculated';
    this.actorTextColor = 'calculated';
    this.actorLineColor = 'calculated';
    this.signalColor = 'calculated';
    this.signalTextColor = 'calculated';
    this.labelBoxBkgColor = 'calculated';
    this.labelBoxBorderColor = 'calculated';
    this.labelTextColor = 'calculated';
    this.loopTextColor = 'calculated';
    this.noteBorderColor = 'calculated';
    this.noteBkgColor = '#fff5ad';
    this.noteTextColor = 'calculated';
    this.activationBorderColor = 'calculated';
    this.activationBkgColor = 'calculated';
    this.sequenceNumberColor = 'black';

    /* Gantt chart variables */

    this.sectionBkgColor = darken('#EAE8D9', 30);
    this.altSectionBkgColor = 'calculated';
    this.sectionBkgColor2 = '#EAE8D9';
    this.taskBorderColor = rgba(255, 255, 255, 70);
    this.taskBkgColor = 'calculated';
    this.taskTextColor = 'calculated';
    this.taskTextLightColor = 'calculated';
    this.taskTextOutsideColor = 'calculated';
    this.taskTextClickableColor = '#003163';
    this.activeTaskBorderColor = rgba(255, 255, 255, 50);
    this.activeTaskBkgColor = '#81B1DB';
    this.gridColor = 'calculated';
    this.doneTaskBkgColor = 'calculated';
    this.doneTaskBorderColor = 'grey';
    this.critBorderColor = '#E83737';
    this.critBkgColor = '#E83737';
    this.taskTextDarkColor = 'calculated';
    this.todayLineColor = '#DB5757';

    /* state colors */
    this.labelColor = 'calculated';

    this.errorBkgColor = '#a44141';
    this.errorTextColor = '#ddd';
  }
  updateColors() {
    this.secondBkg = lighten(this.mainBkg, 16);
    this.lineColor = this.mainContrastColor;
    this.arrowheadColor = this.mainContrastColor;
    /* Flowchart variables */

    this.nodeBkg = this.mainBkg;
    this.nodeBorder = this.border1;
    this.clusterBkg = this.secondBkg;
    this.clusterBorder = this.border2;
    this.defaultLinkColor = this.lineColor;
    this.edgeLabelBackground = lighten(this.labelBackground, 25);

    /* Sequence Diagram variables */

    this.actorBorder = this.border1;
    this.actorBkg = this.mainBkg;
    this.actorTextColor = this.mainContrastColor;
    this.actorLineColor = this.mainContrastColor;
    this.signalColor = this.mainContrastColor;
    this.signalTextColor = this.mainContrastColor;
    this.labelBoxBkgColor = this.actorBkg;
    this.labelBoxBorderColor = this.actorBorder;
    this.labelTextColor = this.mainContrastColor;
    this.loopTextColor = this.mainContrastColor;
    this.noteBorderColor = this.secondaryBorderColor;
    this.noteBkgColor = this.secondBkg;
    this.noteTextColor = this.secondaryTextColor;
    this.activationBorderColor = this.border1;
    this.activationBkgColor = this.secondBkg;

    /* Gantt chart variables */

    this.altSectionBkgColor = this.background;
    this.taskBkgColor = lighten(this.mainBkg, 23);
    this.taskTextColor = this.darkTextColor;
    this.taskTextLightColor = this.mainContrastColor;
    this.taskTextOutsideColor = this.taskTextLightColor;
    this.gridColor = this.mainContrastColor;
    this.doneTaskBkgColor = this.mainContrastColor;
    this.taskTextDarkColor = this.darkTextColor;

    /* state colors */
    this.transitionColor = this.transitionColor || this.lineColor;
    this.transitionLabelColor = this.transitionLabelColor || this.textColor;
    this.stateLabelColor = this.stateLabelColor || this.stateBkg || this.primaryTextColor;
    this.stateBkg = this.stateBkg || this.mainBkg;
    this.labelBackgroundColor = this.labelBackgroundColor || this.stateBkg;
    this.compositeBackground = this.compositeBackground || this.background || this.tertiaryColor;
    this.altBackground = this.altBackground || '#555';
    this.compositeTitleBackground = this.compositeTitleBackground || this.mainBkg;
    this.compositeBorder = this.compositeBorder || this.nodeBorder;
    this.innerEndBackground = this.primaryBorderColor;
    this.specialStateColor = '#f4f4f4'; // this.lineColor;

    this.errorBkgColor = this.errorBkgColor || this.tertiaryColor;
    this.errorTextColor = this.errorTextColor || this.tertiaryTextColor;

    this.fillType0 = this.primaryColor;
    this.fillType1 = this.secondaryColor;
    this.fillType2 = adjust(this.primaryColor, { h: 64 });
    this.fillType3 = adjust(this.secondaryColor, { h: 64 });
    this.fillType4 = adjust(this.primaryColor, { h: -64 });
    this.fillType5 = adjust(this.secondaryColor, { h: -64 });
    this.fillType6 = adjust(this.primaryColor, { h: 128 });
    this.fillType7 = adjust(this.secondaryColor, { h: 128 });

    /* pie */
    this.pie1 = this.pie1 || '#0b0000';
    this.pie2 = this.pie2 || '#4d1037';
    this.pie3 = this.pie3 || '#3f5258';
    this.pie4 = this.pie4 || '#4f2f1b';
    this.pie5 = this.pie5 || '#6e0a0a';
    this.pie6 = this.pie6 || '#3b0048';
    this.pie7 = this.pie7 || '#995a01';
    this.pie8 = this.pie8 || '#154706';
    this.pie9 = this.pie9 || '#161722';
    this.pie10 = this.pie10 || '#00296f';
    this.pie11 = this.pie11 || '#01629c';
    this.pie12 = this.pie12 || '#010029';
    this.pieTitleTextSize = this.pieTitleTextSize || '25px';
    this.pieTitleTextColor = this.pieTitleTextColor || this.taskTextDarkColor;
    this.pieSectionTextSize = this.pieSectionTextSize || '17px';
    this.pieSectionTextColor = this.pieSectionTextColor || this.textColor;
    this.pieLegendTextSize = this.pieLegendTextSize || '17px';
    this.pieLegendTextColor = this.pieLegendTextColor || this.taskTextDarkColor;
    this.pieStrokeColor = this.pieStrokeColor || 'black';
    this.pieStrokeWidth = this.pieStrokeWidth || '2px';
    this.pieOpacity = this.pieOpacity || '0.7';

    /* class */
    this.classText = this.primaryTextColor;

    /* requirement-diagram */
    this.requirementBackground = this.requirementBackground || this.primaryColor;
    this.requirementBorderColor = this.requirementBorderColor || this.primaryBorderColor;
    this.requirementBorderSize = this.requirementBorderSize || this.primaryBorderColor;
    this.requirementTextColor = this.requirementTextColor || this.primaryTextColor;
    this.relationColor = this.relationColor || this.lineColor;
    this.relationLabelBackground =
      this.relationLabelBackground ||
      (this.darkMode ? darken(this.secondaryColor, 30) : this.secondaryColor);
    this.relationLabelColor = this.relationLabelColor || this.actorTextColor;

    /* git */
    this.git0 = lighten(this.secondaryColor, 20);
    this.git1 = lighten(this.pie2 || this.secondaryColor, 20);
    this.git2 = lighten(this.pie3 || this.tertiaryColor, 20);
    this.git3 = lighten(this.pie4 || adjust(this.primaryColor, { h: -30 }), 20);
    this.git4 = lighten(this.pie5 || adjust(this.primaryColor, { h: -60 }), 20);
    this.git5 = lighten(this.pie6 || adjust(this.primaryColor, { h: -90 }), 10);
    this.git6 = lighten(this.pie7 || adjust(this.primaryColor, { h: +60 }), 10);
    this.git7 = lighten(this.pie8 || adjust(this.primaryColor, { h: +120 }), 20);
    this.gitInv0 = this.gitInv0 || invert(this.git0);
    this.gitInv1 = this.gitInv1 || invert(this.git1);
    this.gitInv2 = this.gitInv2 || invert(this.git2);
    this.gitInv3 = this.gitInv3 || invert(this.git3);
    this.gitInv4 = this.gitInv4 || invert(this.git4);
    this.gitInv5 = this.gitInv5 || invert(this.git5);
    this.gitInv6 = this.gitInv6 || invert(this.git6);
    this.gitInv7 = this.gitInv7 || invert(this.git7);

    this.tagLabelColor = this.tagLabelColor || this.primaryTextColor;
    this.tagLabelBackground = this.tagLabelBackground || this.primaryColor;
    this.tagLabelBorder = this.tagBorder || this.primaryBorderColor;
    this.commitLabelColor = this.commitLabelColor || this.secondaryTextColor;
    this.commitLabelBackground = this.commitLabelBackground || this.secondaryColor;
  }
  calculate(overrides) {
    if (typeof overrides !== 'object') {
      // Calculate colors form base colors
      this.updateColors();
      return;
    }

    const keys = Object.keys(overrides);

    // Copy values from overrides, this is mainly for base colors
    keys.forEach((k) => {
      this[k] = overrides[k];
    });

    // Calculate colors form base colors
    this.updateColors();
    // Copy values from overrides again in case of an override of derived value
    keys.forEach((k) => {
      this[k] = overrides[k];
    });
  }
}

export const getThemeVariables = (userOverrides) => {
  const theme = new Theme();
  theme.calculate(userOverrides);
  return theme;
};



*/

/* 
DEFAULT CONFIG OBJECT FROM MERMAID

import theme from './themes';
/**
 * **Configuration methods in Mermaid version 8.6.0 have been updated, to learn more[[click
 * here](8.6.0_docs.md)].**
 *
 * ## **What follows are config instructions for older versions**
 *
 * These are the default options which can be overridden with the initialization call like so:
 *
 * **Example 1:**<pre> mermaid.initialize({ flowchart:{ htmlLabels: false } }); </pre>
 *
 * **Example 2:**<pre> <script> var config = { startOnLoad:true, flowchart:{ useMaxWidth:true,
 * htmlLabels:true, curve:'cardinal', },
 *
 *     securityLevel:'loose',
 *
 * }; mermaid.initialize(config); </script> </pre>
 *
 * A summary of all options and their defaults is found [here](#mermaidapi-configuration-defaults).
 * A description of each option follows below.
 *
 * @name Configuration
 */
const config = {
  /**
   * Theme , the CSS style sheet
   *
   * | Parameter | Description     | Type   | Required | Values                                         |
   * | --------- | --------------- | ------ | -------- | ---------------------------------------------- |
   * | theme     | Built in Themes | string | Optional | 'default', 'forest', 'dark', 'neutral', 'null' |
   *
   * **Notes:** To disable any pre-defined mermaid theme, use "null".<pre> "theme": "forest",
   * "themeCSS": ".node rect { fill: red; }" </pre>
   */
  theme: 'default',
  themeVariables: theme['default'].getThemeVariables(),
  themeCSS: undefined,
  /* **maxTextSize** - The maximum allowed size of the users text diagram */
  maxTextSize: 50000,
  darkMode: false,

  /**
   * | Parameter  | Description                                            | Type   | Required | Values                      |
   * | ---------- | ------------------------------------------------------ | ------ | -------- | --------------------------- |
   * | fontFamily | specifies the font to be used in the rendered diagrams | string | Required | Any Possible CSS FontFamily |
   *
   * **Notes:** Default value: '"trebuchet ms", verdana, arial, sans-serif;'.
   */
  fontFamily: '"trebuchet ms", verdana, arial, sans-serif;',

  /**
   * | Parameter | Description                                           | Type             | Required | Values        |
   * | --------- | ----------------------------------------------------- | ---------------- | -------- | ------------- |
   * | logLevel  | This option decides the amount of logging to be used. | string \| number | Required | 1, 2, 3, 4, 5 |
   *
   * **Notes:**
   *
   * - Debug: 1
   * - Info: 2
   * - Warn: 3
   * - Error: 4
   * - Fatal: 5 (default)
   */
  logLevel: 5,

  /**
   * | Parameter     | Description                       | Type   | Required | Values                          |
   * | ------------- | --------------------------------- | ------ | -------- | ------------------------------- |
   * | securitylevel | Level of trust for parsed diagram | string | Required | 'strict', 'loose', 'antiscript' |
   *
   * **Notes**:
   *
   * - **strict**: (**default**) tags in text are encoded, click functionality is disabled
   * - **loose**: tags in text are allowed, click functionality is enabled
   * - **antiscript**: html tags in text are allowed, (only script element is removed), click
   *   functionality is enabled
   */
  securityLevel: 'strict',

  /**
   * | Parameter   | Description                                  | Type    | Required | Values      |
   * | ----------- | -------------------------------------------- | ------- | -------- | ----------- |
   * | startOnLoad | Dictates whether mermaid starts on Page load | boolean | Required | true, false |
   *
   * **Notes:** Default value: true
   */
  startOnLoad: true,

  /**
   * | Parameter           | Description                                                                  | Type    | Required | Values      |
   * | ------------------- | ---------------------------------------------------------------------------- | ------- | -------- | ----------- |
   * | arrowMarkerAbsolute | Controls whether or arrow markers in html code are absolute paths or anchors | boolean | Required | true, false |
   *
   * **Notes**:
   *
   * This matters if you are using base tag settings.
   *
   * Default value: false
   */
  arrowMarkerAbsolute: false,

  /**
   * This option controls which currentConfig keys are considered _secure_ and can only be changed
   * via call to mermaidAPI.initialize. Calls to mermaidAPI.reinitialize cannot make changes to the
   * `secure` keys in the current currentConfig. This prevents malicious graph directives from
   * overriding a site's default security.
   *
   * **Notes**:
   *
   * Default value: ['secure', 'securityLevel', 'startOnLoad', 'maxTextSize']
   */
  secure: ['secure', 'securityLevel', 'startOnLoad', 'maxTextSize'],

  /**
   * This option controls if the generated ids of nodes in the SVG are generated randomly or based
   * on a seed. If set to false, the IDs are generated based on the current date and thus are not
   * deterministic. This is the default behaviour.
   *
   * **Notes**:
   *
   * This matters if your files are checked into sourcecontrol e.g. git and should not change unless
   * content is changed.
   *
   * Default value: false
   */
  deterministicIds: false,

  /**
   * This option is the optional seed for deterministic ids. if set to undefined but
   * deterministicIds is true, a simple number iterator is used. You can set this attribute to base
   * the seed on a static string.
   */
  deterministicIDSeed: undefined,

  /** The object containing configurations specific for flowcharts */
  flowchart: {
    /**
     * | Parameter      | Description                                     | Type    | Required | Values             |
     * | -------------- | ----------------------------------------------- | ------- | -------- | ------------------ |
     * | diagramPadding | Amount of padding around the diagram as a whole | Integer | Required | Any Positive Value |
     *
     * **Notes:**
     *
     * The amount of padding around the diagram as a whole so that embedded diagrams have margins,
     * expressed in pixels
     *
     * Default value: 8
     */
    diagramPadding: 8,

    /**
     * | Parameter  | Description                                                                                  | Type    | Required | Values      |
     * | ---------- | -------------------------------------------------------------------------------------------- | ------- | -------- | ----------- |
     * | htmlLabels | Flag for setting whether or not a html tag should be used for rendering labels on the edges. | boolean | Required | true, false |
     *
     * **Notes:** Default value: true.
     */
    htmlLabels: true,

    /**
     * | Parameter   | Description                                         | Type    | Required | Values              |
     * | ----------- | --------------------------------------------------- | ------- | -------- | ------------------- |
     * | nodeSpacing | Defines the spacing between nodes on the same level | Integer | Required | Any positive Number |
     *
     * **Notes:**
     *
     * Pertains to horizontal spacing for TB (top to bottom) or BT (bottom to top) graphs, and the
     * vertical spacing for LR as well as RL graphs.**
     *
     * Default value: 50
     */
    nodeSpacing: 50,

    /**
     * | Parameter   | Description                                           | Type    | Required | Values              |
     * | ----------- | ----------------------------------------------------- | ------- | -------- | ------------------- |
     * | rankSpacing | Defines the spacing between nodes on different levels | Integer | Required | Any Positive Number |
     *
     * **Notes**:
     *
     * Pertains to vertical spacing for TB (top to bottom) or BT (bottom to top), and the horizontal
     * spacing for LR as well as RL graphs.
     *
     * Default value 50
     */
    rankSpacing: 50,

    /**
     * | Parameter | Description                                        | Type   | Required | Values                        |
     * | --------- | -------------------------------------------------- | ------ | -------- | ----------------------------- |
     * | curve     | Defines how mermaid renders curves for flowcharts. | string | Required | 'basis', 'linear', 'cardinal' |
     *
     * **Notes:**
     *
     * Default Value: 'basis'
     */
    curve: 'basis',
    // Only used in new experimental rendering
    // represents the padding between the labels and the shape
    padding: 15,

    /**
     * | Parameter   | Description | Type    | Required | Values      |
     * | ----------- | ----------- | ------- | -------- | ----------- |
     * | useMaxWidth | See notes   | boolean | 4        | true, false |
     *
     * **Notes:**
     *
     * When this flag is set the height and width is set to 100% and is then scaling with the
     * available space if not the absolute space required is used.
     *
     * Default value: true
     */
    useMaxWidth: true,

    /**
     * | Parameter       | Description | Type    | Required | Values                  |
     * | --------------- | ----------- | ------- | -------- | ----------------------- |
     * | defaultRenderer | See notes   | boolean | 4        | dagre-d3, dagre-wrapper |
     *
     * **Notes:**
     *
     * Decides which rendering engine that is to be used for the rendering. Legal values are:
     * dagre-d3 dagre-wrapper - wrapper for dagre implemented in mermaid
     *
     * Default value: 'dagre-d3'
     */
    defaultRenderer: 'dagre-d3',
  },

  /** The object containing configurations specific for sequence diagrams */
  sequence: {
    hideUnusedParticipants: false,
    /**
     * | Parameter       | Description                  | Type    | Required | Values             |
     * | --------------- | ---------------------------- | ------- | -------- | ------------------ |
     * | activationWidth | Width of the activation rect | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value :10
     */
    activationWidth: 10,

    /**
     * | Parameter      | Description                                          | Type    | Required | Values             |
     * | -------------- | ---------------------------------------------------- | ------- | -------- | ------------------ |
     * | diagramMarginX | Margin to the right and left of the sequence diagram | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 50
     */
    diagramMarginX: 50,

    /**
     * | Parameter      | Description                                       | Type    | Required | Values             |
     * | -------------- | ------------------------------------------------- | ------- | -------- | ------------------ |
     * | diagramMarginY | Margin to the over and under the sequence diagram | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 10
     */
    diagramMarginY: 10,

    /**
     * | Parameter   | Description           | Type    | Required | Values             |
     * | ----------- | --------------------- | ------- | -------- | ------------------ |
     * | actorMargin | Margin between actors | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 50
     */
    actorMargin: 50,

    /**
     * | Parameter | Description          | Type    | Required | Values             |
     * | --------- | -------------------- | ------- | -------- | ------------------ |
     * | width     | Width of actor boxes | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 150
     */
    width: 150,

    /**
     * | Parameter | Description           | Type    | Required | Values             |
     * | --------- | --------------------- | ------- | -------- | ------------------ |
     * | height    | Height of actor boxes | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 65
     */
    height: 65,

    /**
     * | Parameter | Description              | Type    | Required | Values             |
     * | --------- | ------------------------ | ------- | -------- | ------------------ |
     * | boxMargin | Margin around loop boxes | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 10
     */
    boxMargin: 10,

    /**
     * | Parameter     | Description                                  | Type    | Required | Values             |
     * | ------------- | -------------------------------------------- | ------- | -------- | ------------------ |
     * | boxTextMargin | Margin around the text in loop/alt/opt boxes | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 5
     */
    boxTextMargin: 5,

    /**
     * | Parameter  | Description         | Type    | Required | Values             |
     * | ---------- | ------------------- | ------- | -------- | ------------------ |
     * | noteMargin | margin around notes | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 10
     */
    noteMargin: 10,

    /**
     * | Parameter     | Description            | Type    | Required | Values             |
     * | ------------- | ---------------------- | ------- | -------- | ------------------ |
     * | messageMargin | Space between messages | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 35
     */
    messageMargin: 35,

    /**
     * | Parameter    | Description                 | Type   | Required | Values                    |
     * | ------------ | --------------------------- | ------ | -------- | ------------------------- |
     * | messageAlign | Multiline message alignment | string | Required | 'left', 'center', 'right' |
     *
     * **Notes:** Default value: 'center'
     */
    messageAlign: 'center',

    /**
     * | Parameter    | Description                 | Type    | Required | Values      |
     * | ------------ | --------------------------- | ------- | -------- | ----------- |
     * | mirrorActors | Mirror actors under diagram | boolean | Required | true, false |
     *
     * **Notes:** Default value: true
     */
    mirrorActors: true,

    /**
     * | Parameter  | Description                                                             | Type    | Required | Values      |
     * | ---------- | ----------------------------------------------------------------------- | ------- | -------- | ----------- |
     * | forceMenus | forces actor popup menus to always be visible (to support E2E testing). | Boolean | Required | True, False |
     *
     * **Notes:**
     *
     * Default value: false.
     */
    forceMenus: false,

    /**
     * | Parameter       | Description                                | Type    | Required | Values             |
     * | --------------- | ------------------------------------------ | ------- | -------- | ------------------ |
     * | bottomMarginAdj | Prolongs the edge of the diagram downwards | Integer | Required | Any Positive Value |
     *
     * **Notes:**
     *
     * Depending on css styling this might need adjustment.
     *
     * Default value: 1
     */
    bottomMarginAdj: 1,

    /**
     * | Parameter   | Description | Type    | Required | Values      |
     * | ----------- | ----------- | ------- | -------- | ----------- |
     * | useMaxWidth | See Notes   | boolean | Required | true, false |
     *
     * **Notes:** When this flag is set to true, the height and width is set to 100% and is then
     * scaling with the available space. If set to false, the absolute space required is used.
     *
     * Default value: true
     */
    useMaxWidth: true,

    /**
     * | Parameter   | Description                          | Type    | Required | Values      |
     * | ----------- | ------------------------------------ | ------- | -------- | ----------- |
     * | rightAngles | display curve arrows as right angles | boolean | Required | true, false |
     *
     * **Notes:**
     *
     * This will display arrows that start and begin at the same node as right angles, rather than a curve
     *
     * Default value: false
     */
    rightAngles: false,

    /**
     * | Parameter           | Description                     | Type    | Required | Values      |
     * | ------------------- | ------------------------------- | ------- | -------- | ----------- |
     * | showSequenceNumbers | This will show the node numbers | boolean | Required | true, false |
     *
     * **Notes:** Default value: false
     */
    showSequenceNumbers: false,

    /**
     * | Parameter     | Description                                        | Type    | Required | Values             |
     * | ------------- | -------------------------------------------------- | ------- | -------- | ------------------ |
     * | actorFontSize | This sets the font size of the actor's description | Integer | Require  | Any Positive Value |
     *
     * **Notes:** **Default value 14**..
     */
    actorFontSize: 14,

    /**
     * | Parameter       | Description                                          | Type   | Required | Values                      |
     * | --------------- | ---------------------------------------------------- | ------ | -------- | --------------------------- |
     * | actorFontFamily | This sets the font family of the actor's description | string | Required | Any Possible CSS FontFamily |
     *
     * **Notes:** Default value: "'Open Sans", sans-serif'
     */
    actorFontFamily: '"Open Sans", sans-serif',

    /**
     * This sets the font weight of the actor's description
     *
     * **Notes:** Default value: 400.
     */
    actorFontWeight: 400,

    /**
     * | Parameter    | Description                                     | Type    | Required | Values             |
     * | ------------ | ----------------------------------------------- | ------- | -------- | ------------------ |
     * | noteFontSize | This sets the font size of actor-attached notes | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 14
     */
    noteFontSize: 14,

    /**
     * | Parameter      | Description                                        | Type   | Required | Values                      |
     * | -------------- | -------------------------------------------------- | ------ | -------- | --------------------------- |
     * | noteFontFamily | This sets the font family of actor-attached notes. | string | Required | Any Possible CSS FontFamily |
     *
     * **Notes:** Default value: ''"trebuchet ms", verdana, arial, sans-serif'
     */
    noteFontFamily: '"trebuchet ms", verdana, arial, sans-serif',

    /**
     * This sets the font weight of the note's description
     *
     * **Notes:** Default value: 400
     */
    noteFontWeight: 400,

    /**
     * | Parameter | Description                                          | Type   | Required | Values                    |
     * | --------- | ---------------------------------------------------- | ------ | -------- | ------------------------- |
     * | noteAlign | This sets the text alignment of actor-attached notes | string | required | 'left', 'center', 'right' |
     *
     * **Notes:** Default value: 'center'
     */
    noteAlign: 'center',

    /**
     * | Parameter       | Description                               | Type    | Required | Values              |
     * | --------------- | ----------------------------------------- | ------- | -------- | ------------------- |
     * | messageFontSize | This sets the font size of actor messages | Integer | Required | Any Positive Number |
     *
     * **Notes:** Default value: 16
     */
    messageFontSize: 16,

    /**
     * | Parameter         | Description                                 | Type   | Required | Values                      |
     * | ----------------- | ------------------------------------------- | ------ | -------- | --------------------------- |
     * | messageFontFamily | This sets the font family of actor messages | string | Required | Any Possible CSS FontFamily |
     *
     * **Notes:** Default value: '"trebuchet ms", verdana, arial, sans-serif'
     */
    messageFontFamily: '"trebuchet ms", verdana, arial, sans-serif',

    /**
     * This sets the font weight of the message's description
     *
     * **Notes:** Default value: 400.
     */
    messageFontWeight: 400,

    /**
     * This sets the auto-wrap state for the diagram
     *
     * **Notes:** Default value: false.
     */
    wrap: false,

    /**
     * This sets the auto-wrap padding for the diagram (sides only)
     *
     * **Notes:** Default value: 0.
     */
    wrapPadding: 10,

    /**
     * This sets the width of the loop-box (loop, alt, opt, par)
     *
     * **Notes:** Default value: 50.
     */
    labelBoxWidth: 50,

    /**
     * This sets the height of the loop-box (loop, alt, opt, par)
     *
     * **Notes:** Default value: 20.
     */
    labelBoxHeight: 20,

    messageFont: function () {
      return {
        fontFamily: this.messageFontFamily,
        fontSize: this.messageFontSize,
        fontWeight: this.messageFontWeight,
      };
    },
    noteFont: function () {
      return {
        fontFamily: this.noteFontFamily,
        fontSize: this.noteFontSize,
        fontWeight: this.noteFontWeight,
      };
    },
    actorFont: function () {
      return {
        fontFamily: this.actorFontFamily,
        fontSize: this.actorFontSize,
        fontWeight: this.actorFontWeight,
      };
    },
  },

  /** The object containing configurations specific for gantt diagrams */
  gantt: {
    /**
     * ### titleTopMargin
     *
     * | Parameter      | Description                                    | Type    | Required | Values             |
     * | -------------- | ---------------------------------------------- | ------- | -------- | ------------------ |
     * | titleTopMargin | Margin top for the text over the gantt diagram | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 25
     */
    titleTopMargin: 25,

    /**
     * | Parameter | Description                         | Type    | Required | Values             |
     * | --------- | ----------------------------------- | ------- | -------- | ------------------ |
     * | barHeight | The height of the bars in the graph | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 20
     */
    barHeight: 20,

    /**
     * | Parameter | Description                                                      | Type    | Required | Values             |
     * | --------- | ---------------------------------------------------------------- | ------- | -------- | ------------------ |
     * | barGap    | The margin between the different activities in the gantt diagram | Integer | Optional | Any Positive Value |
     *
     * **Notes:** Default value: 4
     */
    barGap: 4,

    /**
     * | Parameter  | Description                                                                | Type    | Required | Values             |
     * | ---------- | -------------------------------------------------------------------------- | ------- | -------- | ------------------ |
     * | topPadding | Margin between title and gantt diagram and between axis and gantt diagram. | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 50
     */
    topPadding: 50,

    /**
     * | Parameter    | Description                                                             | Type    | Required | Values             |
     * | ------------ | ----------------------------------------------------------------------- | ------- | -------- | ------------------ |
     * | rightPadding | The space allocated for the section name to the right of the activities | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 75
     */
    rightPadding: 75,

    /**
     * | Parameter   | Description                                                            | Type    | Required | Values             |
     * | ----------- | ---------------------------------------------------------------------- | ------- | -------- | ------------------ |
     * | leftPadding | The space allocated for the section name to the left of the activities | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 75
     */
    leftPadding: 75,

    /**
     * | Parameter            | Description                                  | Type    | Required | Values             |
     * | -------------------- | -------------------------------------------- | ------- | -------- | ------------------ |
     * | gridLineStartPadding | Vertical starting position of the grid lines | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 35
     */
    gridLineStartPadding: 35,

    /**
     * | Parameter | Description | Type    | Required | Values             |
     * | --------- | ----------- | ------- | -------- | ------------------ |
     * | fontSize  | Font size   | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 11
     */
    fontSize: 11,

    /**
     * | Parameter       | Description            | Type    | Required | Values             |
     * | --------------- | ---------------------- | ------- | -------- | ------------------ |
     * | sectionFontSize | Font size for sections | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 11
     */
    sectionFontSize: 11,

    /**
     * | Parameter           | Description                              | Type    | Required | Values             |
     * | ------------------- | ---------------------------------------- | ------- | -------- | ------------------ |
     * | numberSectionStyles | The number of alternating section styles | Integer | 4        | Any Positive Value |
     *
     * **Notes:** Default value: 4
     */
    numberSectionStyles: 4,

    /**
     * | Parameter  | Description                 | Type | Required | Values           |
     * | ---------- | --------------------------- | ---- | -------- | ---------------- |
     * | axisFormat | Datetime format of the axis | 3    | Required | Date in yy-mm-dd |
     *
     * **Notes:**
     *
     * This might need adjustment to match your locale and preferences
     *
     * Default value: '%Y-%m-%d'.
     */
    axisFormat: '%Y-%m-%d',

    /**
     * | Parameter   | Description | Type    | Required | Values      |
     * | ----------- | ----------- | ------- | -------- | ----------- |
     * | useMaxWidth | See notes   | boolean | 4        | true, false |
     *
     * **Notes:**
     *
     * When this flag is set the height and width is set to 100% and is then scaling with the
     * available space if not the absolute space required is used.
     *
     * Default value: true
     */
    useMaxWidth: true,

    /**
     * | Parameter | Description | Type    | Required | Values      |
     * | --------- | ----------- | ------- | -------- | ----------- |
     * | topAxis   | See notes   | Boolean | 4        | True, False |
     *
     * **Notes:** when this flag is set date labels will be added to the top of the chart
     *
     * **Default value false**.
     */
    topAxis: false,

    useWidth: undefined,
  },

  /** The object containing configurations specific for journey diagrams */
  journey: {
    /**
     * | Parameter      | Description                                          | Type    | Required | Values             |
     * | -------------- | ---------------------------------------------------- | ------- | -------- | ------------------ |
     * | diagramMarginX | Margin to the right and left of the sequence diagram | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 50
     */
    diagramMarginX: 50,

    /**
     * | Parameter      | Description                                        | Type    | Required | Values             |
     * | -------------- | -------------------------------------------------- | ------- | -------- | ------------------ |
     * | diagramMarginY | Margin to the over and under the sequence diagram. | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 10
     */
    diagramMarginY: 10,

    /**
     * | Parameter   | Description           | Type    | Required | Values             |
     * | ----------- | --------------------- | ------- | -------- | ------------------ |
     * | actorMargin | Margin between actors | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 50
     */
    leftMargin: 150,

    /**
     * | Parameter | Description          | Type    | Required | Values             |
     * | --------- | -------------------- | ------- | -------- | ------------------ |
     * | width     | Width of actor boxes | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 150
     */
    width: 150,

    /**
     * | Parameter | Description           | Type    | Required | Values             |
     * | --------- | --------------------- | ------- | -------- | ------------------ |
     * | height    | Height of actor boxes | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 65
     */
    height: 50,

    /**
     * | Parameter | Description              | Type    | Required | Values             |
     * | --------- | ------------------------ | ------- | -------- | ------------------ |
     * | boxMargin | Margin around loop boxes | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 10
     */
    boxMargin: 10,

    /**
     * | Parameter     | Description                                  | Type    | Required | Values             |
     * | ------------- | -------------------------------------------- | ------- | -------- | ------------------ |
     * | boxTextMargin | Margin around the text in loop/alt/opt boxes | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 5
     */
    boxTextMargin: 5,

    /**
     * | Parameter  | Description         | Type    | Required | Values             |
     * | ---------- | ------------------- | ------- | -------- | ------------------ |
     * | noteMargin | Margin around notes | Integer | Required | Any Positive Value |
     *
     * **Notes:** Default value: 10
     */
    noteMargin: 10,

    /**
     * | Parameter     | Description             | Type    | Required | Values             |
     * | ------------- | ----------------------- | ------- | -------- | ------------------ |
     * | messageMargin | Space between messages. | Integer | Required | Any Positive Value |
     *
     * **Notes:**
     *
     * Space between messages.
     *
     * Default value: 35
     */
    messageMargin: 35,

    /**
     * | Parameter    | Description                 | Type | Required | Values                    |
     * | ------------ | --------------------------- | ---- | -------- | ------------------------- |
     * | messageAlign | Multiline message alignment | 3    | 4        | 'left', 'center', 'right' |
     *
     * **Notes:** Default value: 'center'
     */
    messageAlign: 'center',

    /**
     * | Parameter       | Description                                | Type    | Required | Values             |
     * | --------------- | ------------------------------------------ | ------- | -------- | ------------------ |
     * | bottomMarginAdj | Prolongs the edge of the diagram downwards | Integer | 4        | Any Positive Value |
     *
     * **Notes:**
     *
     * Depending on css styling this might need adjustment.
     *
     * Default value: 1
     */
    bottomMarginAdj: 1,

    /**
     * | Parameter   | Description | Type    | Required | Values      |
     * | ----------- | ----------- | ------- | -------- | ----------- |
     * | useMaxWidth | See notes   | boolean | 4        | true, false |
     *
     * **Notes:**
     *
     * When this flag is set the height and width is set to 100% and is then scaling with the
     * available space if not the absolute space required is used.
     *
     * Default value: true
     */
    useMaxWidth: true,

    /**
     * | Parameter   | Description                       | Type | Required | Values      |
     * | ----------- | --------------------------------- | ---- | -------- | ----------- |
     * | rightAngles | Curved Arrows become Right Angles | 3    | 4        | true, false |
     *
     * **Notes:**
     *
     * This will display arrows that start and begin at the same node as right angles, rather than a curves
     *
     * Default value: false
     */
    rightAngles: false,
    taskFontSize: 14,
    taskFontFamily: '"Open Sans", sans-serif',
    taskMargin: 50,
    // width of activation box
    activationWidth: 10,

    // text placement as: tspan | fo | old only text as before
    textPlacement: 'fo',
    actorColours: ['#8FBC8F', '#7CFC00', '#00FFFF', '#20B2AA', '#B0E0E6', '#FFFFE0'],

    sectionFills: ['#191970', '#8B008B', '#4B0082', '#2F4F4F', '#800000', '#8B4513', '#00008B'],
    sectionColours: ['#fff'],
  },
  class: {
    arrowMarkerAbsolute: false,

    /**
     * | Parameter   | Description | Type    | Required | Values      |
     * | ----------- | ----------- | ------- | -------- | ----------- |
     * | useMaxWidth | See notes   | boolean | 4        | true, false |
     *
     * **Notes:**
     *
     * When this flag is set the height and width is set to 100% and is then scaling with the
     * available space if not the absolute space required is used.
     *
     * Default value: true
     */
    useMaxWidth: true,
    /**
     * | Parameter       | Description | Type    | Required | Values                  |
     * | --------------- | ----------- | ------- | -------- | ----------------------- |
     * | defaultRenderer | See notes   | boolean | 4        | dagre-d3, dagre-wrapper |
     *
     * **Notes**:
     *
     * Decides which rendering engine that is to be used for the rendering. Legal values are:
     * dagre-d3 dagre-wrapper - wrapper for dagre implemented in mermaid
     *
     * Default value: 'dagre-d3'
     */
    defaultRenderer: 'dagre-wrapper',
  },
  state: {
    dividerMargin: 10,
    sizeUnit: 5,
    padding: 8,
    textHeight: 10,
    titleShift: -15,
    noteMargin: 10,
    forkWidth: 70,
    forkHeight: 7,
    // Used
    miniPadding: 2,
    // Font size factor, this is used to guess the width of the edges labels before rendering by dagre
    // layout. This might need updating if/when switching font
    fontSizeFactor: 5.02,
    fontSize: 24,
    labelHeight: 16,
    edgeLengthFactor: '20',
    compositTitleSize: 35,
    radius: 5,
    /**
     * | Parameter   | Description | Type    | Required | Values      |
     * | ----------- | ----------- | ------- | -------- | ----------- |
     * | useMaxWidth | See notes   | boolean | 4        | true, false |
     *
     * **Notes:**
     *
     * When this flag is set the height and width is set to 100% and is then scaling with the
     * available space if not the absolute space required is used.
     *
     * Default value: true
     */
    useMaxWidth: true,
    /**
     * | Parameter       | Description | Type    | Required | Values                  |
     * | --------------- | ----------- | ------- | -------- | ----------------------- |
     * | defaultRenderer | See notes   | boolean | 4        | dagre-d3, dagre-wrapper |
     *
     * **Notes:**
     *
     * Decides which rendering engine that is to be used for the rendering. Legal values are:
     * dagre-d3 dagre-wrapper - wrapper for dagre implemented in mermaid
     *
     * Default value: 'dagre-d3'
     */
    defaultRenderer: 'dagre-wrapper',
  },

  /** The object containing configurations specific for entity relationship diagrams */
  er: {
    /**
     * | Parameter      | Description                                     | Type    | Required | Values             |
     * | -------------- | ----------------------------------------------- | ------- | -------- | ------------------ |
     * | diagramPadding | Amount of padding around the diagram as a whole | Integer | Required | Any Positive Value |
     *
     * **Notes:**
     *
     * The amount of padding around the diagram as a whole so that embedded diagrams have margins,
     * expressed in pixels
     *
     * Default value: 20
     */
    diagramPadding: 20,

    /**
     * | Parameter       | Description                              | Type   | Required | Values                 |
     * | --------------- | ---------------------------------------- | ------ | -------- | ---------------------- |
     * | layoutDirection | Directional bias for layout of entities. | string | Required | "TB", "BT", "LR", "RL" |
     *
     * **Notes:**
     *
     * 'TB' for Top-Bottom, 'BT'for Bottom-Top, 'LR' for Left-Right, or 'RL' for Right to Left.
     *
     * T = top, B = bottom, L = left, and R = right.
     *
     * Default value: 'TB'
     */
    layoutDirection: 'TB',

    /**
     * | Parameter      | Description                        | Type    | Required | Values             |
     * | -------------- | ---------------------------------- | ------- | -------- | ------------------ |
     * | minEntityWidth | The minimum width of an entity box | Integer | Required | Any Positive Value |
     *
     * **Notes:** Expressed in pixels. Default value: 100
     */
    minEntityWidth: 100,

    /**
     * | Parameter       | Description                         | Type    | Required | Values             |
     * | --------------- | ----------------------------------- | ------- | -------- | ------------------ |
     * | minEntityHeight | The minimum height of an entity box | Integer | 4        | Any Positive Value |
     *
     * **Notes:** Expressed in pixels Default value: 75
     */
    minEntityHeight: 75,

    /**
     * | Parameter     | Description                                                 | Type    | Required | Values             |
     * | ------------- | ----------------------------------------------------------- | ------- | -------- | ------------------ |
     * | entityPadding | Minimum internal padding betweentext in box and box borders | Integer | 4        | Any Positive Value |
     *
     * **Notes:**
     *
     * The minimum internal padding betweentext in an entity box and the enclosing box borders,
     * expressed in pixels.
     *
     * Default value: 15
     */
    entityPadding: 15,

    /**
     * | Parameter | Description                         | Type   | Required | Values               |
     * | --------- | ----------------------------------- | ------ | -------- | -------------------- |
     * | stroke    | Stroke color of box edges and lines | string | 4        | Any recognized color |
     *
     * **Notes:** Default value: 'gray'
     */
    stroke: 'gray',

    /**
     * | Parameter | Description                | Type   | Required | Values               |
     * | --------- | -------------------------- | ------ | -------- | -------------------- |
     * | fill      | Fill color of entity boxes | string | 4        | Any recognized color |
     *
     * **Notes:** Default value: 'honeydew'
     */
    fill: 'honeydew',

    /**
     * | Parameter | Description         | Type    | Required | Values             |
     * | --------- | ------------------- | ------- | -------- | ------------------ |
     * | fontSize  | Font Size in pixels | Integer |          | Any Positive Value |
     *
     * **Notes:**
     *
     * Font size (expressed as an integer representing a number of pixels) Default value: 12
     */
    fontSize: 12,

    /**
     * | Parameter   | Description | Type    | Required | Values      |
     * | ----------- | ----------- | ------- | -------- | ----------- |
     * | useMaxWidth | See Notes   | boolean | Required | true, false |
     *
     * **Notes:**
     *
     * When this flag is set to true, the diagram width is locked to 100% and scaled based on
     * available space. If set to false, the diagram reserves its absolute width.
     *
     * Default value: true
     */
    useMaxWidth: true,
  },

  /** The object containing configurations specific for pie diagrams */
  pie: {
    useWidth: undefined,

    /**
     * | Parameter   | Description | Type    | Required | Values      |
     * | ----------- | ----------- | ------- | -------- | ----------- |
     * | useMaxWidth | See Notes   | boolean | Required | true, false |
     *
     * **Notes:**
     *
     * When this flag is set to true, the diagram width is locked to 100% and scaled based on
     * available space. If set to false, the diagram reserves its absolute width.
     *
     * Default value: true
     */
    useMaxWidth: true,
  },

  /** The object containing configurations specific for req diagrams */
  requirement: {
    useWidth: undefined,

    /**
     * | Parameter   | Description | Type    | Required | Values      |
     * | ----------- | ----------- | ------- | -------- | ----------- |
     * | useMaxWidth | See Notes   | boolean | Required | true, false |
     *
     * **Notes:**
     *
     * When this flag is set to true, the diagram width is locked to 100% and scaled based on
     * available space. If set to false, the diagram reserves its absolute width.
     *
     * Default value: true
     */
    useMaxWidth: true,

    rect_fill: '#f9f9f9',
    text_color: '#333',
    rect_border_size: '0.5px',
    rect_border_color: '#bbb',
    rect_min_width: 200,
    rect_min_height: 200,
    fontSize: 14,
    rect_padding: 10,
    line_height: 20,
  },
  gitGraph: {
    diagramPadding: 8,
    nodeLabel: {
      width: 75,
      height: 100,
      x: -25,
      y: 0,
    },
    mainBranchName: 'main',
    showCommitLabel: true,
    showBranches: true,
  },
};

config.class.arrowMarkerAbsolute = config.arrowMarkerAbsolute;
config.gitGraph.arrowMarkerAbsolute = config.arrowMarkerAbsolute;

const keyify = (obj, prefix = '') =>
  Object.keys(obj).reduce((res, el) => {
    if (Array.isArray(obj[el])) {
      return res;
    } else if (typeof obj[el] === 'object' && obj[el] !== null) {
      return [...res, prefix + el, ...keyify(obj[el], '')];
    }
    return [...res, prefix + el];
  }, []);

export const configKeys = keyify(config, '');
export default config;



*/
