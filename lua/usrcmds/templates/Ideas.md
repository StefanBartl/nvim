# Template-Ideen für Markdown-Dokumentation

## Strukturelle Templates

### Section mit Anker
```lua
---@module 'usrcmds.templates.html.section_template'
--- HTML Section Template with Anchor
```
```html
<section id="sec-">
  <h2></h2>

</section>
```

### Aside/Sidebar
```lua
---@module 'usrcmds.templates.html.aside_template'
--- HTML Aside Template for Sidebar Content
```
```html
<aside id="aside-" style="border-left: 3px solid #ddd; padding-left: 1em; margin: 1em 0;">
  <strong>Note:</strong>
</aside>
```

### Details/Summary (Collapsible)
```lua
---@module 'usrcmds.templates.html.details_template'
--- HTML Details Template for Collapsible Content
```
```html
<details id="details-">
  <summary></summary>

</details>
```

## Admonition/Callout Templates

### Warning Box
```lua
---@module 'usrcmds.templates.html.warning_template'
--- HTML Warning Box Template
```
```html
<div id="warn-" style="border: 2px solid #f0ad4e; background-color: #fcf8e3; padding: 1em; margin: 1em 0; border-radius: 4px;">
  <strong>⚠ Warning:</strong>
</div>
```

### Info Box
```lua
---@module 'usrcmds.templates.html.info_template'
--- HTML Info Box Template
```
```html
<div id="info-" style="border: 2px solid #5bc0de; background-color: #d9edf7; padding: 1em; margin: 1em 0; border-radius: 4px;">
  <strong>ⓘ Info:</strong>
</div>
```

### Danger/Error Box
```lua
---@module 'usrcmds.templates.html.danger_template'
--- HTML Danger Box Template
```
```html
<div id="danger-" style="border: 2px solid #d9534f; background-color: #f2dede; padding: 1em; margin: 1em 0; border-radius: 4px;">
  <strong>⚡ Danger:</strong>
</div>
```

### Success Box
```lua
---@module 'usrcmds.templates.html.success_template'
--- HTML Success Box Template
```
```html
<div id="success-" style="border: 2px solid #5cb85c; background-color: #dff0d8; padding: 1em; margin: 1em 0; border-radius: 4px;">
  <strong>✓ Success:</strong>
</div>
```

### Tip Box
```lua
---@module 'usrcmds.templates.html.tip_template'
--- HTML Tip Box Template
```
```html
<div id="tip-" style="border: 2px solid #17a2b8; background-color: #d1ecf1; padding: 1em; margin: 1em 0; border-radius: 4px;">
  <strong>💡 Tip:</strong>
</div>
```

## Code-bezogene Templates

### Code mit Syntax Highlighting und Zeilennummern
```lua
---@module 'usrcmds.templates.html.code_numbered_template'
--- HTML Code Template with Line Numbers
```
```html
<figure id="code-">
  <pre style="counter-reset: line;"><code class="" style="display: block;">
<span style="display: block; counter-increment: line;"></span>
  </code></pre>
  <figcaption><strong>Listing:</strong> </figcaption>
</figure>
```

### Diff/Comparison Code
```lua
---@module 'usrcmds.templates.html.code_diff_template'
--- HTML Code Diff Template
```
```html
<figure id="diff-">
  <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 1em;">
    <div>
      <strong>Before:</strong>
      <pre><code class="">
      </code></pre>
    </div>
    <div>
      <strong>After:</strong>
      <pre><code class="">
      </code></pre>
    </div>
  </div>
  <figcaption><strong>Diff:</strong> </figcaption>
</figure>
```

### Terminal/Shell Output
```lua
---@module 'usrcmds.templates.html.terminal_template'
--- HTML Terminal Output Template
```
```html
<figure id="term-">
  <pre style="background-color: #1e1e1e; color: #d4d4d4; padding: 1em; border-radius: 4px;"><code>$
  </code></pre>
  <figcaption><strong>Terminal:</strong> </figcaption>
</figure>
```

## Tabellen-Templates

### Comparison Table
```lua
---@module 'usrcmds.templates.html.comparison_table_template'
--- HTML Comparison Table Template
```
```html
<figure id="tbl-">
  <table style="border-collapse: collapse; width: 100%;">
    <caption><strong>Tabelle:</strong> Vergleich</caption>
    <thead>
      <tr>
        <th style="border: 1px solid #ddd; padding: 8px;">Feature</th>
        <th style="border: 1px solid #ddd; padding: 8px;">Option A</th>
        <th style="border: 1px solid #ddd; padding: 8px;">Option B</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td style="border: 1px solid #ddd; padding: 8px;"></td>
        <td style="border: 1px solid #ddd; padding: 8px;"></td>
        <td style="border: 1px solid #ddd; padding: 8px;"></td>
      </tr>
    </tbody>
  </table>
</figure>
```

### API Reference Table
```lua
---@module 'usrcmds.templates.html.api_table_template'
--- HTML API Reference Table Template
```
```html
<figure id="tbl-api-">
  <table style="border-collapse: collapse; width: 100%;">
    <caption><strong>API Reference:</strong> </caption>
    <thead>
      <tr style="background-color: #f0f0f0;">
        <th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Method</th>
        <th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Parameters</th>
        <th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Return</th>
        <th style="border: 1px solid #ddd; padding: 8px; text-align: left;">Description</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td style="border: 1px solid #ddd; padding: 8px;"><code></code></td>
        <td style="border: 1px solid #ddd; padding: 8px;"></td>
        <td style="border: 1px solid #ddd; padding: 8px;"></td>
        <td style="border: 1px solid #ddd; padding: 8px;"></td>
      </tr>
    </tbody>
  </table>
</figure>
```

### Status/Progress Table
```lua
---@module 'usrcmds.templates.html.status_table_template'
--- HTML Status Table Template
```
```html
<figure id="tbl-status-">
  <table style="border-collapse: collapse; width: 100%;">
    <caption><strong>Status:</strong> </caption>
    <thead>
      <tr>
        <th style="border: 1px solid #ddd; padding: 8px;">Task</th>
        <th style="border: 1px solid #ddd; padding: 8px; text-align: center;">Status</th>
        <th style="border: 1px solid #ddd; padding: 8px;">Notes</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td style="border: 1px solid #ddd; padding: 8px;"></td>
        <td style="border: 1px solid #ddd; padding: 8px; text-align: center;">○</td>
        <td style="border: 1px solid #ddd; padding: 8px;"></td>
      </tr>
    </tbody>
  </table>
</figure>
```

## Diagramm-bezogene Templates

### Mermaid Diagram Wrapper
```lua
---@module 'usrcmds.templates.html.mermaid_template'
--- HTML Mermaid Diagram Template
```
```html
<figure id="dia-">
  <div class="mermaid">
graph TD
    A[] --> B[]
  </div>
  <figcaption><strong>Diagramm:</strong> </figcaption>
</figure>
```

### SVG Container
```lua
---@module 'usrcmds.templates.html.svg_template'
--- HTML SVG Container Template
```
```html
<figure id="svg-" style="text-align: center;">
  <svg width="" height="" viewBox="0 0  " xmlns="http://www.w3.org/2000/svg">

  </svg>
  <figcaption><strong>SVG:</strong> </figcaption>
</figure>
```

## Listen-Templates

### Checklist
```lua
---@module 'usrcmds.templates.html.checklist_template'
--- HTML Checklist Template
```
```html
<div id="checklist-">
  <strong>Checklist:</strong>
  <ul style="list-style: none; padding-left: 0;">
    <li>☐ </li>
    <li>☐ </li>
    <li>☐ </li>
  </ul>
</div>
```

### Ordered Steps
```lua
---@module 'usrcmds.templates.html.steps_template'
--- HTML Ordered Steps Template
```
```html
<div id="steps-">
  <strong>Steps:</strong>
  <ol>
    <li><strong>Step 1:</strong> </li>
    <li><strong>Step 2:</strong> </li>
    <li><strong>Step 3:</strong> </li>
  </ol>
</div>
```

### Definition List
```lua
---@module 'usrcmds.templates.html.definition_template'
--- HTML Definition List Template
```
```html
<dl id="def-" style="margin: 1em 0;">
  <dt style="font-weight: bold;"></dt>
  <dd style="margin-left: 2em; margin-bottom: 0.5em;"></dd>

  <dt style="font-weight: bold;"></dt>
  <dd style="margin-left: 2em; margin-bottom: 0.5em;"></dd>
</dl>
```

## Spezielle Content-Templates

### Two-Column Layout
```lua
---@module 'usrcmds.templates.html.two_column_template'
--- HTML Two Column Layout Template
```
```html
<div id="cols-" style="display: grid; grid-template-columns: 1fr 1fr; gap: 2em; margin: 1em 0;">
  <div>
    <h3></h3>

  </div>
  <div>
    <h3></h3>

  </div>
</div>
```

### Card/Panel
```lua
---@module 'usrcmds.templates.html.card_template'
--- HTML Card/Panel Template
```
```html
<div id="card-" style="border: 1px solid #ddd; border-radius: 8px; padding: 1.5em; margin: 1em 0; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
  <h3 style="margin-top: 0;"></h3>

</div>
```

### Quote/Blockquote mit Quelle
```lua
---@module 'usrcmds.templates.html.quote_template'
--- HTML Quote with Citation Template
```
```html
<figure id="quote-">
  <blockquote style="border-left: 4px solid #ddd; padding-left: 1em; margin: 1em 0; font-style: italic;">

  </blockquote>
  <figcaption style="text-align: right;">— </figcaption>
</figure>
```

### Timeline Entry
```lua
---@module 'usrcmds.templates.html.timeline_template'
--- HTML Timeline Entry Template
```
```html
<div id="timeline-" style="border-left: 3px solid #ddd; padding-left: 1.5em; margin: 1em 0; position: relative;">
  <div style="position: absolute; left: -8px; top: 0; width: 12px; height: 12px; border-radius: 50%; background-color: #5bc0de; border: 2px solid white;"></div>
  <strong></strong>
  <p style="color: #666; font-size: 0.9em; margin: 0.2em 0;"></p>
  <p></p>
</div>
```

### Accordion Item
```lua
---@module 'usrcmds.templates.html.accordion_template'
--- HTML Accordion Item Template
```
```html
<details id="accordion-" style="border: 1px solid #ddd; border-radius: 4px; padding: 0.5em 1em; margin: 0.5em 0;">
  <summary style="cursor: pointer; font-weight: bold; user-select: none;">

  </summary>
  <div style="margin-top: 1em;">

  </div>
</details>
```

## Mathematik/Wissenschaft Templates

### Equation
```lua
---@module 'usrcmds.templates.html.equation_template'
--- HTML Equation Template
```
```html
<figure id="eq-" style="text-align: center; margin: 1.5em 0;">
  <div style="font-size: 1.2em; padding: 1em;">
    $$

    $$
  </div>
  <figcaption><strong>Gleichung:</strong> </figcaption>
</figure>
```

### Formula Table
```lua
---@module 'usrcmds.templates.html.formula_table_template'
--- HTML Formula Table Template
```
```html
<figure id="tbl-formula-">
  <table style="border-collapse: collapse; width: 100%;">
    <caption><strong>Formeln:</strong> </caption>
    <thead>
      <tr>
        <th style="border: 1px solid #ddd; padding: 8px;">Name</th>
        <th style="border: 1px solid #ddd; padding: 8px;">Formula</th>
        <th style="border: 1px solid #ddd; padding: 8px;">Variables</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td style="border: 1px solid #ddd; padding: 8px;"></td>
        <td style="border: 1px solid #ddd; padding: 8px;">$  $</td>
        <td style="border: 1px solid #ddd; padding: 8px;"></td>
      </tr>
    </tbody>
  </table>
</figure>
```

## Badge/Label Templates

### Inline Badge
```lua
---@module 'usrcmds.templates.html.badge_template'
--- HTML Inline Badge Template
```
```html
<span style="background-color: #5bc0de; color: white; padding: 0.2em 0.6em; border-radius: 3px; font-size: 0.85em; font-weight: bold;"></span>
```

### Version Badge
```lua
---@module 'usrcmds.templates.html.version_badge_template'
--- HTML Version Badge Template
```
```html
<span style="background-color: #5cb85c; color: white; padding: 0.2em 0.6em; border-radius: 3px; font-size: 0.85em; font-weight: bold;">v</span>
```

### Status Badge
```lua
---@module 'usrcmds.templates.html.status_badge_template'
--- HTML Status Badge Template
```
```html
<span style="background-color: #f0ad4e; color: white; padding: 0.2em 0.6em; border-radius: 3px; font-size: 0.85em; font-weight: bold;">●  </span>
```

## Navigation Templates

### Table of Contents
```lua
---@module 'usrcmds.templates.html.toc_template'
--- HTML Table of Contents Template
```
```html
<nav id="toc" style="border: 1px solid #ddd; padding: 1em; margin: 1em 0; background-color: #f9f9f9;">
  <strong>Table of Contents</strong>
  <ul style="margin-top: 0.5em;">
    <li><a href="#"></a></li>
    <li><a href="#"></a></li>
    <li><a href="#"></a></li>
  </ul>
</nav>
```

### Breadcrumb Navigation
```lua
---@module 'usrcmds.templates.html.breadcrumb_template'
--- HTML Breadcrumb Navigation Template
```
```html
<nav id="breadcrumb-" style="margin: 1em 0;">
  <a href="#">Home</a> →
  <a href="#"></a> →
  <strong></strong>
</nav>
```

### Pagination
```lua
---@module 'usrcmds.templates.html.pagination_template'
--- HTML Pagination Template
```
```html
<nav id="pagination-" style="text-align: center; margin: 2em 0;">
  <a href="#" style="padding: 0.5em 1em; margin: 0 0.2em; border: 1px solid #ddd; text-decoration: none;">← Previous</a>
  <a href="#" style="padding: 0.5em 1em; margin: 0 0.2em; border: 1px solid #ddd; text-decoration: none;">Next →</a>
</nav>
```

Diese Templates decken die häufigsten Anwendungsfälle in der technischen Dokumentation ab und können als Basis für eigene, projektspezifische Templates dienen.
