/* AFMA app 101. Markdown is rendered by APEX_MARKDOWN on the server. */
(function (apex) {
  "use strict";

  // Optional diagrams only; native APEX Markdown remains the response renderer.
  // Release/API: github.com/mermaid-js/mermaid/releases/tag/mermaid@11.17.2
  const mermaidUrl = "https://cdn.jsdelivr.net/npm/mermaid@11.17.2/dist/mermaid.esm.min.mjs";
  const svgNamespace = "http://www.w3.org/2000/svg";
  let mermaidLoader;
  let diagramCount = 0;

  function diagramSourceAllowed(source) {
    if (!source || source.length > 3000 || source.split(/\r?\n/).length > 40 ||
        source.split(/[;\n]/).length > 80) { return false; }
    if (!/^(?:(?:flowchart|graph)\s+(?:TB|TD|BT|RL|LR)(?=[\s;]|$)|pie(?:\s+showData)?(?=[\s;]|$))/.test(source)) { return false; }
    // Exclude configuration, interaction, rich labels, assets, and encoded markup
    // before Mermaid performs its temporary layout in the document.
    return !/(%%|^\s*---|:::|[<&#@$`\\]|[\u0000-\u0008\u000b\u000c\u000e-\u001f]|:\/\/|\b(?:click|href|callback|call|link|linkStyle|style|classDef|class|css|config|init|image|img|icon|javascript|data|url|htmlLabels)\b)/im.test(source);
  }

  function withinDiagramDeadline(promise) {
    let timer;
    return Promise.race([
      promise,
      new Promise(function (_, reject) {
        timer = setTimeout(function () { reject(new Error("Diagram preview timed out.")); }, 10000);
      })
    ]).finally(function () { clearTimeout(timer); });
  }

  function loadMermaid() {
    if (!mermaidLoader) {
      mermaidLoader = withinDiagramDeadline(import(mermaidUrl).then(function (module) {
        const mermaid = module.default;
        mermaid.initialize({
          startOnLoad: false, securityLevel: "strict", htmlLabels: false,
          suppressErrorRendering: true, maxTextSize: 3000, maxEdges: 60,
          fontFamily: "Arial, sans-serif", theme: "default", arrowMarkerAbsolute: false,
          flowchart: { htmlLabels: false, useMaxWidth: true, defaultRenderer: "dagre-wrapper" },
          secure: ["securityLevel", "startOnLoad", "htmlLabels", "maxTextSize", "maxEdges", "suppressErrorRendering", "flowchart"]
        });
        return mermaid;
      }));
    }
    return mermaidLoader;
  }

  function safeDiagramSvg(markup) {
    if (typeof markup !== "string" || markup.length > 250000) { throw new Error("Invalid diagram output."); }
    const template = document.createElement("template");
    template.innerHTML = markup;
    const svg = template.content.firstElementChild;
    if (!svg || svg.localName !== "svg" || svg.namespaceURI !== svgNamespace ||
        template.content.children.length !== 1 || svg.querySelectorAll("*").length > 1000 ||
        !svg.getAttribute("viewBox")) {
      throw new Error("Invalid diagram output.");
    }
    // Mermaid 11.17.2 strict mode owns sanitization (DOMPurify) and scoped CSS.
    // This final inert-DOM guard only enforces our no-interaction/no-assets policy.
    const tags = new Set(["svg", "style", "g", "defs", "marker", "path", "rect", "circle", "ellipse", "line", "polyline", "polygon", "text", "tspan", "title", "desc", "clipPath"]);
    const nodes = [svg].concat(Array.from(svg.querySelectorAll("*")));
    const ids = new Set(nodes.map(function (node) { return node.getAttribute("id"); }));
    function checkResources(value) {
      const remaining = value.replace(/url\(\s*['"]?#([\w:.-]+)['"]?\s*\)/gi, function (reference, id) {
        return ids.has(id) ? "" : reference;
      });
      if (/[\\]|\/\*|\/\/|@(?:import|font-face)\b|\b(?:url|image|image-set|src)\s*\(|\b(?:https?|data|javascript|file|ftp):/i.test(remaining)) {
        throw new Error("Diagram resource references are not allowed.");
      }
    }
    nodes.forEach(function (node) {
      if (node.namespaceURI !== svgNamespace || !tags.has(node.localName) ||
          (node !== svg && node.localName === "svg")) {
        throw new Error("Interactive diagram markup is not allowed.");
      }
      if (node.localName === "style") { checkResources(node.textContent); }
      Array.from(node.attributes).forEach(function (attribute) {
        if (/^on|(?:^|:)(?:href|src)$|^xml:base$/i.test(attribute.name)) {
          throw new Error("Diagram interaction is not allowed.");
        }
        if (!/^xmlns(?::xlink)?$/.test(attribute.name)) { checkResources(attribute.value); }
      });
    });
    svg.setAttribute("role", "img");
    svg.setAttribute("aria-label", "CAAB diagram. The diagram source is available below.");
    svg.setAttribute("width", "100%");
    svg.removeAttribute("height");
    return svg;
  }

  function enhanceDiagrams(scope) {
    const blocks = Array.from(scope.querySelectorAll("pre > code.language-mermaid, pre > code.mermaid"));
    blocks.forEach(function (code, index) {
      const pre = code.parentElement;
      if (pre.dataset.caabDiagram) { return; }
      const source = code.textContent.trim();
      pre.dataset.caabDiagram = "source";
      if (index >= 2 || diagramCount >= 12 || !diagramSourceAllowed(source)) { return; }
      diagramCount += 1;
      const id = "caabDiagram" + Date.now() + "_" + diagramCount;
      // This owned container is for bounded layout, not the answer surface.
      const staging = document.createElement("div");
      staging.setAttribute("aria-hidden", "true");
      staging.style.cssText = "position:absolute;left:-10000px;top:0;width:800px;visibility:hidden;pointer-events:none";
      loadMermaid().then(function (mermaid) {
        if (!pre.isConnected) { throw new Error("Answer is no longer displayed."); }
        document.body.append(staging);
        return withinDiagramDeadline(mermaid.render(id, source, staging));
      }).then(function (result) {
        if (!pre.isConnected) { return; }
        const svg = safeDiagramSvg(result.svg);
        const panel = document.createElement("div");
        panel.className = "afma-caab-mermaid";
        const details = document.createElement("details");
        const summary = document.createElement("summary");
        summary.textContent = "Diagram source";
        pre.replaceWith(panel);
        details.append(summary, pre);
        panel.append(svg, details);
        pre.dataset.caabDiagram = "rendered";
        // Deliberately never call Mermaid bindFunctions: diagrams are inert.
      }).catch(function () {
        pre.title = "Diagram preview unavailable; the source remains readable.";
      }).finally(function () { staging.remove(); });
    });
  }

  function responseContent(html) {
    const template = document.createElement("template");
    template.innerHTML = html || "";
    // Keep model-provided remote images inert, including before DOM insertion.
    template.content.querySelectorAll("img").forEach(function (image) {
      image.replaceWith(document.createTextNode(image.alt || "[Image omitted]"));
    });
    template.content.querySelectorAll("a").forEach(function (link) {
      const href = link.getAttribute("href") || "";
      if (!/^https?:\/\//i.test(href)) {
        link.removeAttribute("href");
      } else {
        link.target = "_blank";
        link.rel = "noopener noreferrer";
      }
    });
    return template.content;
  }

  function init() {
    const shell = document.querySelector(".afma-caab-agent");
    if (!shell || shell.dataset.initialized) { return; }
    const prompt = shell.querySelector("#afmaCaabPrompt");
    const send = shell.querySelector("#afmaCaabSend");
    const model = shell.querySelector("#afmaCaabModel");
    const thread = shell.querySelector("#afmaCaabThread");
    const status = shell.querySelector("#afmaCaabStatus");
    const counts = shell.querySelector("#afmaCaabCounts");
    if (!prompt || !send || !model || !thread || !status) { return; }
    shell.dataset.initialized = "true";

    function add(user, text) {
      const message = document.createElement("section");
      message.className = "afma-caab-message" + (user ? " afma-caab-message--user" : "");
      const label = document.createElement("div");
      label.className = "afma-caab-label";
      label.textContent = user ? "You" : "CSIRO CAAB Agent";
      const body = document.createElement("div");
      body.className = "afma-caab-markdown";
      body.textContent = text;
      message.append(label, body);
      thread.append(message);
      thread.scrollTop = thread.scrollHeight;
      return { label: label, body: body };
    }

    function setBusy(busy) {
      send.disabled = busy;
      model.disabled = busy;
      if (counts) { counts.disabled = busy; }
      thread.setAttribute("aria-busy", String(busy));
    }

    function ask(question) {
      const q = question || prompt.value.trim();
      if (!q || send.disabled) { return; }
      if (q.length > 3000) {
        status.textContent = "Please keep the question within 3,000 characters.";
        return;
      }
      add(true, q);
      if (!question) { prompt.value = ""; }
      const answer = add(false, "Finding catalogue evidence…");
      setBusy(true);
      status.textContent = "Answer in progress.";
      Promise.resolve(apex.server.process("CSIRO_CAAB_AGENT_ASK", { x01: q, x02: model.value }, { dataType: "json" }))
        .then(function (result) {
          if (!result || !result.success) {
            answer.body.textContent = (result && result.message) || "The answer could not be prepared. Please try again.";
            if (result && result.requestId) {
              const reference = document.createElement("small");
              reference.textContent = "Reference: " + result.requestId;
              answer.body.append(reference);
            }
            status.textContent = "The answer could not be prepared.";
            return;
          }
          let label;
          if (result.mode === "APEX_AI") {
            label = "AI answer · " + (result.resolvedModelId || result.resolvedServiceName || "Resolved AI service");
          } else if (result.mode === "DETERMINISTIC") {
            label = "Catalogue data · AI not used";
          } else {
            label = "Data-only answer · AI unavailable";
          }
          answer.label.textContent = label;
          answer.body.replaceChildren(responseContent(result.answerHtml));
          if (result.mode === "DETERMINISTIC_FALLBACK") {
            const reason = document.createElement("p");
            reason.textContent = result.fallbackReason || "The selected AI service could not answer. Catalogue evidence is shown below.";
            answer.body.prepend(reason);
          }
          if (result.supportingHtml) {
            const details = document.createElement("details");
            details.className = "afma-caab-section";
            const summary = document.createElement("summary");
            summary.textContent = "Catalogue evidence used for this answer";
            details.append(summary, responseContent(result.supportingHtml));
            answer.body.append(details);
          }
          if (result.requestId) {
            const reference = document.createElement("small");
            reference.textContent = "Reference: " + result.requestId;
            answer.body.append(reference);
          }
          status.textContent = label + ". Answer ready.";
          thread.scrollTop = thread.scrollHeight;
          enhanceDiagrams(answer.body);
        })
        .catch(function () {
          answer.body.textContent = "The request could not be completed. Please try again.";
          status.textContent = "The request could not be completed.";
        })
        .finally(function () {
          setBusy(false);
          prompt.focus();
        });
    }

    prompt.addEventListener("keydown", function (event) {
      if (event.key === "Enter" && !event.shiftKey && !event.isComposing) {
        event.preventDefault();
        ask();
      }
    });
    send.addEventListener("click", function () { ask(); });
    if (counts) { counts.addEventListener("click", function () { ask("CAAB catalogue counts"); }); }
  }

  apex.jQuery(init);
})(apex);
