//library mermaid;

import 'dart:html';

import 'package:js/js.dart';

import 'package:markdown/markdown.dart' as md;
import 'package:mermaid/mermaid.dart';
import 'package:test/test.dart';

//@JS()
@TestOn('browser')

/*
@JS()
external num addNumbers(num a, num b);

@JS()
abstract class Animal {
  external factory Animal(String name);
  external String talk();
}

@JS()
@anonymous
abstract class ObjectWithName {
  external factory ObjectWithName({String name});
  external String get name;
}
*/

final markdownInput = querySelector('#markdown') as TextAreaElement;
final htmlDiv = querySelector('#html') as DivElement;
final mermaidWork = querySelector('#mermaidWork') as DivElement;

final nullSanitizer = NullTreeSanitizer();

void main() {
  MermaidApi.initialize(Config(
    securityLevel: SecurityLevel.Strict,
    theme: Theme.Forest,
    /*      themeCSS: '''.node rect { fill: red; }
        .edgePath .path {stroke: orange;} .arrowheadPath {fill: purple;}
        
        ''',*/
    logLevel: LogLevel.Error,
    startOnLoad: false,
    arrowMarkerAbsolute: true,
    flowchart: FlowChartConfig(htmlLabels: true),
    sequence: SequenceDiagramConfig(),
    gnatt: GnattConfig(),
  ));
  final markdown = markdownInput.value!;
  final markdownConvertedToHtml =
      md.markdownToHtml(markdown, extensionSet: md.ExtensionSet.gitHubWeb);
  htmlDiv.setInnerHtml(
    markdownConvertedToHtml,
    treeSanitizer: nullSanitizer,
  );

  test('Html Elements markdownInput,htmlDiv,mermaidWork are not null', () {
    expect(markdownInput, isNotNull);
    expect(htmlDiv, isNotNull);
    expect(mermaidWork, isNotNull);
  });

  test('Get markdown from textarea and convert with markdown and put in html',
      () {
    expect(markdown, isNotNull);
    expect(markdown, isNotEmpty);
    expect(markdown, contains('mermaid'));
  });

  test('test getting mermaid config', () {
    final Config conf = mermaidApiGetConfig();
    expect(conf, isNotNull);
    expect(conf.theme, matches('forest'));

    final Config conf2 = MermaidApi.getConfig();
    expect(conf2, isNotNull);
    expect(conf.theme == conf2.theme, isTrue);
  });

  test('test invoking mermaid to render code.language-mermaid blocks', () {
    final ElementList mermaidCodeList =
        htmlDiv.querySelectorAll('code.language-mermaid');

    expect(mermaidCodeList, isNotEmpty);
    expect(mermaidCodeList.length, 10);

    for (final block in mermaidCodeList) {
      void hereIsSvg(String svg,
          [void Function(Element element)? bindFunction]) {
        expect(svg, isNotNull);
        expect(svg, isNotEmpty);
        expect(svg, startsWith('<svg'));
      }

      final String graphDef = block.innerText;

      expect(graphDef, isNotNull);
      expect(graphDef, isNotEmpty);

      MermaidApi.render(
          'id',
          graphDef,
          allowInterop(expectAsync2(hereIsSvg,
              count: 5,
              max: 10,
              id: 'hereIsSvg',
              reason: 'rendering graphs with MermaidApi.render')),
          mermaidWork);
    }
  });
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
