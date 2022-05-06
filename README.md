Mermaid (Dart)
================================================================================

Dart JS interop for [Mermaid](https://github.com/mermaid-js/mermaid) - Javascript library that makes use of a markdown based syntax to render customizable diagrams, charts and visualizations..

The usage is very simple.  Mermaid diagrams are placed within 

```
``​`mermaid

...diagram source...

``​`
```

blocks within the markdown source.  The markdown is then converted to HTML using the `markdownToHtml()` method from the [Markdown](https://pub.dev/packages/markdown) package.  This html is placed within a div on the html page.  The Markdown package will create `<code></code>` elements with the class `'language-mermaid'` for each of the mermaid blocks within the original markdown source.
Here is where the Mermaid package comes into play.  The Mermaid package is initialized with a call to `MermaidApi.initialize()`, the mermaid theme and other configurations options can be set in this call.
The next step is to simply call `mermaidRender()` with one of the following - a W3C selector for the html elements containing mermaid source, a `List<Element>` of elements containing mermaid source, or a single html `Element` containing mermaid diagram source.

There are other ways to invoke the conversion that the example [`app.dart`](https://github.com/timmaffett/mermaid.dart/blob/master/example/app.dart) illustrates.  These include methods that return the SVG code directly.  
Note that the Mermaid javascript library requires a browser dom to create the SVG, so it is not possible to create SVG from Mermaid diagram source outside of the browser environment (ie. server side), although it may be possible using something like [JSDom](https://www.npmjs.com/package/jsdom) or [puppeteer](https://github.com/puppeteer/puppeteer) that allows dom use by javascript on the server.  Such a server side project remains outside the scope of Mermaid.dart.

## Usage

1. Register the Dart package in your `pubspec.yaml`:

    ```yaml
    dependencies:
      mermaid: ^0.9.2
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
