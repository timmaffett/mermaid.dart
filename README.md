Mermaid (Dart)
================================================================================

Dart JS interop for [Mermaid](https://github.com/mermaid-js/mermaid) - Javascript library that makes use of a markdown based syntax to render customizable diagrams, charts and visualizations..

## Usage

1. Register the Dart package in your `pubspec.yaml`:

    ```yaml
    dependencies:
      mermaid: ^0.9.0
    ```

2. Load the latest Mermaid source (js and css) in your html layout:

    ```html
    <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
    
    <div id="html"></div>
    ```

3. Call methods on `Mermaid`:

    ```dart
    import 'dart:html';

    import 'package:markdown/markdown.dart' as md;
    import 'package:mermaid/mermaid.dart';

    const testMarkdownWithMermaid="""
    [Sequence Diagram](http://mermaid-js.github.io/mermaid/#/./sequenceDiagram)
    ------------------
    ``​`mermaid
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
    ``​`
    """;

    final nullSanitizer_SVGCantBeInsertedWithoutIt = NullTreeSanitizer();

    void main() {
      // This Config() object is show with default args for illustration of
      // available options, and indeed passing a Config object is not
      // even required.
      MermaidApi.initialize(
          Config(
            securityLevel:SecurityLevel.Strict,
            theme:Theme.Forest,
            logLevel: LogLevel.Error,
            startOnLoad:false,
            arrowMarkerAbsolute:true,
            flowchart:FlowChartConfig(htmlLabels: true),
            sequence:SequenceDiagramConfig(),
            gnatt:GnattConfig(),
          )
        );

      final htmlDiv = document.getElementById('html');

      htmlDiv.setInnerHtml(
        md.markdownToHtml(testMarkdownWithMermaid,
            extensionSet: md.ExtensionSet.gitHubWeb,
            treeSanitizer: nullSanitizer_SVGCantBeInsertedWithoutIt,
        )
      );

      mermaidRender(htmlDiv.querySelectorAll('code.language-mermaid'));
    }

    /// This sanitizer filters NO node types, allowing an SVG file to be inserted
    /// using setInnerHtml.  Without it all the SVG nodes would be sanitized
    /// out of the SVG file.
    class NullTreeSanitizer implements NodeTreeSanitizer {
      @override
      void sanitizeTree(Node node) {}
    }
    ```

This example does not make user of any of the methods that accept a dart function to be used as a callback.  Please remember that when passing a Dart function as a callback, make sure to wrap it with `allowInterop()`.

Check the [Mermaid and API reference](https://mermaid-js.github.io/mermaid/#/) for detailed documentation.

To view the example, run `dart pub global run webdev serve example` from the root directory of this project (or shorter `webdev serve example`).
run `dart pub global activate webdev` to activate [webdev](https://dart.dev/tools/webdev) if needed.
