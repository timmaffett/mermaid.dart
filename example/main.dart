// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
//import 'dart:convert';
import 'dart:html';
//import 'dart:svg';

import 'package:markdown/markdown.dart' as md;
import 'package:mermaid/mermaid.dart';

import 'highlight.dart';

final markdownInput = querySelector('#markdown') as TextAreaElement;
final htmlDiv = querySelector('#html') as DivElement;
final versionSpan = querySelector('.version') as SpanElement;

final nullSanitizer = NullTreeSanitizer();
const typing = Duration(milliseconds: 15 /*150*/);
const introText = '''Markdown is the **best**!

* It has lists.
* It has [links](https://dart.dev).
* It has _so much more_...''';

// Flavor support.
final basicRadio = querySelector('#basic-radio') as HtmlElement;
final commonmarkRadio = querySelector('#commonmark-radio') as HtmlElement;
final gfmRadio = querySelector('#gfm-radio') as HtmlElement;
md.ExtensionSet? extensionSet;

final extensionSets = {
  'basic-radio': md.ExtensionSet.none,
  'commonmark-radio': md.ExtensionSet.commonMark,
  'gfm-radio': md.ExtensionSet.gitHubWeb,
};

// mermaid render method radio buttons
final mrLoopRadio = querySelector('#mr-loop-radio') as HtmlElement;
final mrAllRadio = querySelector('#mr-all-radio') as HtmlElement;
final marLoopRadio = querySelector('#mar-loop-radio') as HtmlElement;
final mInitAllRadio = querySelector('#m-init-all-radio') as HtmlElement;

final possibleMermaidThemes = [
  Theme.Base,
  Theme.Forest,
  Theme.Dark,
  Theme.Default,
  Theme.Neutral
];
int nextMInitAllTheme =
    1; // start with 'Forest' first time m-init-all-radio radio button is chosen

String mermaidRenderMethod = 'mr-all-radio';

void main() {
  //mermaidInitialize
  MermaidApi.initialize(Config(
    securityLevel: SecurityLevel.Strict,
    theme: Theme.Forest,
    logLevel: LogLevel.Error,
    startOnLoad: false,
    arrowMarkerAbsolute: true,
    flowchart: FlowChartConfig(htmlLabels: true),
    sequence: SequenceDiagramConfig(),
    gnatt: GnattConfig(),
  ));

  versionSpan.text = 'v${md.version}';
  markdownInput.onKeyUp.listen(_renderMarkdown);

  final String? savedMarkdown = window.localStorage['markdown'];

  if (savedMarkdown != null &&
      savedMarkdown.isNotEmpty &&
      savedMarkdown != introText) {
    markdownInput.value = savedMarkdown;
    markdownInput.focus();
    _renderMarkdown();
  } else {
    _typeItOut(mermaidExample /*introText*/, 82);
  }

  // GitHub is the default extension set.
  gfmRadio.attributes['checked'] = '';
  gfmRadio.querySelector('.glyph')!.text = 'radio_button_checked';
  extensionSet = extensionSets[gfmRadio.id];

  // MermaidRender() all at once is default
  marLoopRadio.attributes['checked'] = '';
  marLoopRadio.querySelector('.glyph')!.text = 'radio_button_checked';
  mermaidRenderMethod = 'mar-loop-radio';

  _renderMarkdown();

  basicRadio.onClick.listen(_switchFlavor);
  commonmarkRadio.onClick.listen(_switchFlavor);
  gfmRadio.onClick.listen(_switchFlavor);

  mrLoopRadio.onClick.listen(_switchMermaidRenderMethod);
  mrAllRadio.onClick.listen(_switchMermaidRenderMethod);
  marLoopRadio.onClick.listen(_switchMermaidRenderMethod);
  mInitAllRadio.onClick.listen(_switchMermaidRenderMethod);

  try {
    final Config conf = MermaidApi.getConfig();
    window.console.log("Mermaid.getConfig Config.theme=${conf.theme}");
  } catch (e) {
    window.console.log('During MermaidApi.getConfig() Exception caught ex $e');
  }
}

/// This _renderMarkdown() function shows A VARIETY of ways of calling
/// into the mermaid library to render the diagrams found within the
/// <code class='language-mermaid'></code> blocks.  This is FOR ILLUSTRATION
/// purposes only and does not need to be this complex.  It can most
/// simply be done with `mermaidRender('code.language-mermaid');
void _renderMarkdown([Event? event]) {
  // First get source markdown and convert it and place it in the dom.
  final markdown = markdownInput.value!;
  htmlDiv.setInnerHtml(
    md.markdownToHtml(markdown, extensionSet: extensionSet),
    treeSanitizer: nullSanitizer,
  );

  // Here we loop over all the generated code blocks and highlight any
  // dart source we find.  If the mermaid render radio button is set to
  // 'mr-loop-radio' then we call render the mermaid diagrams in this loop
  // as well.
  for (final block in htmlDiv.querySelectorAll('pre code')) {
    try {
      if (block.classes.contains('language-mermaid')) {
        if (mermaidRenderMethod == 'mr-loop-radio') {
          MermaidApi.reset(); // in case mermaid config got corrupted previously
          mermaidRender(block);
        }
      } else {
        highlightElement(block);
      }
    } catch (e) {
      window.console
          .error('Error mermaidRender() while looping over code blocks:');
      window.console.error(e);
    }
  }

  // This processes all mermaid blocks in one shot
  if (mermaidRenderMethod == 'mr-all-radio') {
    try {
      //THIS DOES THE SAME ->>  mermaidRender(htmlDiv.querySelectorAll('code.language-mermaid'));
      mermaidRender('code.language-mermaid');
    } catch (e) {
      window.console.error('Error thrown during mermaidRender():');
      window.console.error(e);
    }
  }

  // Mermaid render in loop using the MermaidApi.render() method
  if (mermaidRenderMethod == 'mar-loop-radio') {
    for (final block in htmlDiv.querySelectorAll('code.language-mermaid')) {
      try {
        /* //NOT UNTIL MY PR IS IN MERMAID release (post 9.0.1 sometime)
        void parseError(String error, String hash) {
          window.console
              .log('Mermaid parseError callback error="$error" hash="$hash"');
        }*/
        //NOT UNTIL MY PR IS IN MERMAID release (post 9.0.1 sometime)//MermaidApi.parseError = parseError;

        void setSvgWithElementBinding(String svg,
            [void Function(Element element)? bindFunction]) {
          window.console.log(
              'The bindFunction is ${(bindFunction == null) ? "null" : "NOT null"}');
          window.console.log(
              'SVG Len=${svg.length}  :  ${svg.substring(0, 80)} ......  ');

          block.setInnerHtml(svg, treeSanitizer: nullSanitizer);

          // If a bindFunction() is provided we need to call it with the HTML Element
          // we inserted the SVG into - so that Mermaid can handle any diagram specific
          // events for the diagram.
          if (bindFunction != null) {
            bindFunction(block);
          }
        }

        final String diagramDef = block.innerText;

        // NOT UNTIL BUG in mermaid fixed with my PR (Post mermaid 9.0.1)
        // parse method within mermaid has bug in return value
        //final bool parseResult = MermaidApi.parse(graphDef.trim());
        //window.console.log('parse(```$graphDef```) returned ${parseResult.toString()} for graph source');

        window.console.log('Calling to render diagram');
//OK        var finalSvg = MermaidApi.render(null,diagramDef,hereIsSvg);//,document.querySelector('#mermaidWork'));
//fail it black svgs        var finalSvg = MermaidApi.render('id',diagramDef,hereIsSvg);//,document.querySelector('#mermaidWork'));
//fail with black svgs        var finalSvg = MermaidApi.render('id',diagramDef,hereIsSvg,document.querySelector('#mermaidWork'));
//OK        var finalSvg = MermaidApi.render(null,diagramDef,hereIsSvg,document.querySelector('#mermaidWork'));
//OK        final finalSvg = MermaidApi.render('',diagramDef,hereIsSvg);
//OK        final finalSvg = MermaidApi.render('SCRATCH${uniqueMermaidNum++}', diagramDef, hereIsSvg);
        final svg =
            MermaidApi.render(null, diagramDef, setSvgWithElementBinding);

        window.console
            .log('SVG Len=${svg.length}  :  ${svg.substring(0, 80)} ......  ');
        /* ALTERNATELY to using [setSvgWithElementBinding] we could just do this:
           (but we do not get event binding from mermaid without using the callback) 
        block.setInnerHtml(finalSvg, treeSanitizer: nullSanitizer);
        */
      } catch (e) {
        window.console.error('Error thrown during MermaidApi.render():');
        window.console.error(e);
      }
    }
  }

  //  Just calling the init function over and over with config object and selector...
  if (mermaidRenderMethod == 'm-init-all-radio') {
    if (htmlDiv.querySelector('code.language-mermaid') != null) {
      try {
        window.console.log(
            "calling mermaidInit() with theme ${possibleMermaidThemes[nextMInitAllTheme]}");
        mermaidInit(
            Config(
                theme: possibleMermaidThemes[nextMInitAllTheme],
                securityLevel: SecurityLevel.Strict),
            'code.language-mermaid');
        nextMInitAllTheme++; // Advance through themes when doing this to illustrate changing themes
        if (nextMInitAllTheme >= possibleMermaidThemes.length) {
          nextMInitAllTheme = 0;
        }
      } catch (e) {
        window.console.error('Error thrown during mermaidInit():');
        window.console.error(e);
      }
    }
  }

  if (event != null) {
    // Not simulated typing. Store it.
    window.localStorage['markdown'] = markdown;
  }
}

void _typeItOut(String msg, int pos) {
  late Timer timer;
  markdownInput.onKeyUp.listen((_) {
    timer.cancel();
  });
  void addCharacter() {
    if (pos > msg.length) {
      return;
    }
    markdownInput.value = msg.substring(0, pos);
    markdownInput.focus();
    _renderMarkdown();
    // ignore: parameter_assignments
    pos++;
    timer = Timer(typing, addCharacter);
  }

  timer = Timer(typing, addCharacter);
}

void _switchFlavor(Event e) {
  final target = e.currentTarget as HtmlElement;
  if (!target.attributes.containsKey('checked')) {
    if (basicRadio != target) {
      basicRadio.attributes.remove('checked');
      basicRadio.querySelector('.glyph')!.text = 'radio_button_unchecked';
    }
    if (commonmarkRadio != target) {
      commonmarkRadio.attributes.remove('checked');
      commonmarkRadio.querySelector('.glyph')!.text = 'radio_button_unchecked';
    }
    if (gfmRadio != target) {
      gfmRadio.attributes.remove('checked');
      gfmRadio.querySelector('.glyph')!.text = 'radio_button_unchecked';
    }

    target.attributes['checked'] = '';
    target.querySelector('.glyph')!.text = 'radio_button_checked';
    extensionSet = extensionSets[target.id];
    _renderMarkdown();
  }
}

void _switchMermaidRenderMethod(Event e) {
  final target = e.currentTarget as HtmlElement;
  if (!target.attributes.containsKey('checked')) {
    if (mrLoopRadio != target) {
      mrLoopRadio.attributes.remove('checked');
      mrLoopRadio.querySelector('.glyph')!.text = 'radio_button_unchecked';
    }
    if (mrAllRadio != target) {
      mrAllRadio.attributes.remove('checked');
      mrAllRadio.querySelector('.glyph')!.text = 'radio_button_unchecked';
    }
    if (marLoopRadio != target) {
      marLoopRadio.attributes.remove('checked');
      marLoopRadio.querySelector('.glyph')!.text = 'radio_button_unchecked';
    }
    if (mInitAllRadio != target) {
      mInitAllRadio.attributes.remove('checked');
      mInitAllRadio.querySelector('.glyph')!.text = 'radio_button_unchecked';
    }

    target.attributes['checked'] = '';
    target.querySelector('.glyph')!.text = 'radio_button_checked';
    mermaidRenderMethod = target.id;

    window.console.log('mermaidRenderMethod changed to `$mermaidRenderMethod`');

    _renderMarkdown();
  }
}

class NullTreeSanitizer implements NodeTreeSanitizer {
  @override
  void sanitizeTree(Node node) {}
}

const String mermaidExample = """
```
Test language not specified code block
```

```dart
 mermaid.initialize(Config(theme:Theme.Dark));
```

:merman: Mermaid :mermaid: Diagram Types
Mermaid Diagram Types
=====================

Here are examples of various mermaid diagram types

[Flowchart](http://mermaid-js.github.io/mermaid/#/./flowchart?id=flowcharts-basic-syntax)
-----------
```mermaid
graph TD;
    A-->B;
    A-->C;
    B-->D;
    C-->D;
```

[Sequence Diagram](http://mermaid-js.github.io/mermaid/#/./sequenceDiagram)
------------------
```mermaid
sequenceDiagram
    participant Alice
    participant Bob
    Alice->>John: Hello John, how are you?
    loop Healthcheck
        John->>John: Fight against hypochondria
    end
    Note right of John: Rational thoughts <br/>prevail!
    John-->>Alice: Great!
    John->>Bob: How about you?
    Bob-->>John: Jolly good!
```

[Gantt Diagram](http://mermaid-js.github.io/mermaid/#/./gantt)
----
```mermaid
gantt
dateFormat  YYYY-MM-DD
title Adding GANTT diagram to mermaid
excludes weekdays 2014-01-10

section A section
Completed task            :done,    des1, 2014-01-06,2014-01-08
Active task               :active,  des2, 2014-01-09, 3d
Future task               :         des3, after des2, 5d
Future task2               :         des4, after des3, 5d
```

[Class Diagram](http://mermaid-js.github.io/mermaid/#/./classDiagram)
----
```mermaid
classDiagram
Class01 <|-- AveryLongClass : Cool
Class03 *-- Class04
Class05 o-- Class06
Class07 .. Class08
Class09 --> C2 : Where am i?
Class09 --* C3
Class09 --|> Class07
Class07 : equals()
Class07 : Object[] elementData
Class01 : size()
Class01 : int chimp
Class01 : int gorilla
Class08 <--> C2: Cool label
```

[User Journey Diagram](http://mermaid-js.github.io/mermaid/#/./user-journey)
-----
```mermaid
journey
    title My working day
    section Go to work
      Make tea: 5: Me
      Go upstairs: 3: Me
      Do work: 1: Me, Cat
    section Go home
      Go downstairs: 5: Me
      Sit down: 5: Me
```

[Pie Chart Diagram](http://mermaid-js.github.io/mermaid/#/pie?id=pie-chart-diagrams)
-----
```mermaid
pie showData
    title Key elements in Product X
    "Calcium" : 42.96
    "Potassium" : 50.05
    "Magnesium" : 10.01
    "Iron" :  5
```

[State diagram](http://mermaid-js.github.io/mermaid/#/stateDiagram?id=state-diagrams)
-----
```mermaid
stateDiagram-v2
    [*] --> Still
    Still --> [*]

    Still --> Moving
    Moving --> Still
    Moving --> Crash
    Crash --> [*]
```

[Entity Relationship Diagram](http://mermaid-js.github.io/mermaid/#/entityRelationshipDiagram?id=entity-relationship-diagrams)
-------
```mermaid
erDiagram
    CUSTOMER ||--o{ ORDER : places
    ORDER ||--|{ LINE-ITEM : contains
    CUSTOMER }|..|{ DELIVERY-ADDRESS : uses
```

[Requirement Diagram](http://mermaid-js.github.io/mermaid/#/requirementDiagram?id=requirement-diagram)
---------------
```mermaid
requirementDiagram

    requirement test_req {
    id: 1
    text: the test text.
    risk: high
    verifymethod: test
    }

    element test_entity {
    type: simulation
    }

    test_entity - satisfies -> test_req
```

[Gitgraph Diagrams](http://mermaid-js.github.io/mermaid/#/gitgraph?id=gitgraph-diagrams)
-------
```mermaid
       gitGraph
       commit
       branch develop
       commit tag:"v1.0.0"
       commit
       checkout main
       commit type: HIGHLIGHT
       commit
       merge develop
       commit
       branch featureA
       commit
```
""";

const Map<String, String> samples = {
  'Flow Chart': '''graph TD
    A[Christmas] -->|Get money| B(Go shopping)
    B --> C{Let me think}
    C -->|One| D[Laptop]
    C -->|Two| E[iPhone]
    C -->|Three| F[fa:fa-car Car]''',
  'Sequence Diagram': '''sequenceDiagram
    Alice->>+John: Hello John, how are you?
    Alice->>+John: John, can you hear me?
    John-->>-Alice: Hi Alice, I can hear you!
    John-->>-Alice: I feel great!
            ''',
  'Class Diagram': '''classDiagram
    Animal <|-- Duck
    Animal <|-- Fish
    Animal <|-- Zebra
    Animal : +int age
    Animal : +String gender
    Animal: +isMammal()
    Animal: +mate()
    class Duck{
      +String beakColor
      +swim()
      +quack()
    }
    class Fish{
      -int sizeInFeet
      -canEat()
    }
    class Zebra{
      +bool is_wild
      +run()
    }
            ''',
  'State Diagram': '''stateDiagram-v2
    [*] --> Still
    Still --> [*]
    Still --> Moving
    Moving --> Still
    Moving --> Crash
    Crash --> [*]
            ''',
  'Gantt Chart': '''gantt
    title A Gantt Diagram
    dateFormat  YYYY-MM-DD
    section Section
    A task           :a1, 2014-01-01, 30d
    Another task     :after a1  , 20d
    section Another
    Task in sec      :2014-01-12  , 12d
    another task      : 24d
            ''',
  'Pie Chart': '''pie title Pets adopted by volunteers
    "Dogs" : 386
    "Cats" : 85
    "Rats" : 15
            ''',
  'ER Diagram': '''erDiagram
          CUSTOMER }|..|{ DELIVERY-ADDRESS : has
          CUSTOMER ||--o{ ORDER : places
          CUSTOMER ||--o{ INVOICE : "liable for"
          DELIVERY-ADDRESS ||--o{ ORDER : receives
          INVOICE ||--|{ ORDER : covers
          ORDER ||--|{ ORDER-ITEM : includes
          PRODUCT-CATEGORY ||--|{ PRODUCT : contains
          PRODUCT ||--o{ ORDER-ITEM : "ordered in"
            ''',
  'User Journey': '''  journey
    title My working day
    section Go to work
      Make tea: 5: Me
      Go upstairs: 3: Me
      Do work: 1: Me, Cat
    section Go home
      Go downstairs: 5: Me
      Sit down: 3: Me
      ''',
  'Git Graph': '''    gitGraph
      commit
      commit
      branch develop
      checkout develop
      commit
      commit
      checkout main
      merge develop
      commit
      commit
'''
};
