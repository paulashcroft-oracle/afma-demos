# AFMA CAAB Agent Rich Response Rendering Design

Date: 2026-06-12

## Context

The AFMA CAAB Agent needs to answer natural-language questions over CSIRO CAAB data and, over time, present richer responses such as charts, maps, images, status highlights, and source-grounded tables.

The current implementation renders model Markdown safely enough for narrative answers, bullets, and tables. The next design question is whether richer model responses should move from Markdown to HTML.

## Options

### Option 1: Markdown-First

Use model-generated Markdown as the primary response format and render it in the browser.

Benefits:
- Simple prompt contract for models.
- Good for prose, bullets, headings, links, code snippets, and basic tables.
- Easy to inspect in logs and task notes.
- Lower implementation cost.

Limitations:
- Weak fit for maps, charts, layout, colour semantics, image galleries, legends, filters, drilldowns, and accessible interactive components.
- Tables vary by model and can be malformed.
- Visual output is hard to validate because the model controls format rather than intent.

Best use:
- Narrative explanation, simple tabular summaries, caveats, source notes, and lightweight fallback output.

### Option 2: Model-Generated HTML

Ask the model to return HTML and inject it into the response area after sanitisation.

Benefits:
- Expressive layout, colour, image, and rich formatting support.
- Fast to prototype visually impressive responses.

Risks:
- High XSS and prompt-injection risk if arbitrary HTML is accepted.
- Hard to enforce accessibility, responsive layout, APEX theme consistency, and safe image/link policies.
- Model-generated charts/maps are usually presentational markup rather than trustworthy data visualisations.
- Sanitisation can strip the very features that make HTML attractive.

Best use:
- Avoid as the primary model output contract.
- If used at all, restrict to a very small allowlist of tags and attributes, or generate HTML only from trusted server-side templates.

### Option 3: Structured Response Blocks

Ask the model to return a constrained JSON response plan, then render trusted APEX/client components from that plan.

Example block types:
- `markdown`: narrative text rendered with the existing safe Markdown path.
- `table`: columns, rows, source label, and optional row highlights.
- `chart`: chart type, title, series, labels, and values.
- `map`: region/location references, geometry source, layers, legend, and explanatory text.
- `metric`: label, value, colour intent, and source.
- `image`: approved source URL or generated/static asset reference, alt text, caption, and provenance.
- `recordGrid`: CAAB record ids or filter criteria rendered from deterministic database queries.

Benefits:
- Lets the model describe intent while the app controls rendering.
- Safer than raw HTML.
- Better for maps, graphs, images, colours, and reusable visual components.
- Easier to validate, test, log, and replay.
- Keeps CAAB data grounding deterministic because visual data can come from SQL queries or package-generated datasets.

Risks:
- Requires a response schema, validation, and renderer.
- The model can still propose unsupported or misleading visualisations unless the backend validates chart/map specs and data sources.

Best use:
- Rich AI responses in the AFMA demo, especially charts, maps, images, metrics, and complex CAAB summaries.

## Recommendation

Use a hybrid contract:

1. Keep Markdown for narrative text blocks.
2. Do not use arbitrary model-generated HTML as the primary response format.
3. Introduce structured response blocks for rich outputs.
4. Render HTML only from trusted APEX/PLSQL/JavaScript templates controlled by the application.
5. Require all chart/map/table data to be sourced from deterministic CAAB SQL queries or validated rows returned by the API.

This gives the model enough freedom to explain and recommend visuals, while the application keeps control of security, consistency, accessibility, and data grounding.

## Design Considerations

- Security: escape text by default, sanitise any optional HTML, whitelist links/images, and block inline scripts/events/styles from model output.
- Grounding: charts, maps, and record tables should reference CAAB records, query filters, or generated datasets rather than invented values.
- Accessibility: every chart/map/image needs alt text, captions or summaries, keyboard-friendly controls, and colour-independent meaning.
- APEX consistency: render visual blocks through APEX-compatible markup and theme classes rather than model-authored page layout.
- Maps: prefer known Australian fisheries/region geometry or named regions with deterministic lookup. Avoid model-invented coordinates.
- Images: allow only approved source URLs, generated/static demo assets, or future image services with explicit provenance and alt text.
- Performance: cap rows, series, and image sizes; lazy-load richer components.
- Auditability: persist both the original user prompt and the structured response plan so demo behaviour can be reviewed.
- Fallback: if JSON parsing or block validation fails, render a safe Markdown/text fallback with a clear note.

## Suggested Follow-Up Task

Create a DESIGN task for a rich response contract and renderer:

- Define the JSON schema for AI response blocks.
- Decide supported first-slice block types: `markdown`, `table`, `chart`, `metric`, and optionally `map`.
- Add schema validation before rendering.
- Keep the current Markdown renderer as the text-block renderer and fallback.
- Prototype one data-backed chart block and one CAAB table block before adding maps/images.
