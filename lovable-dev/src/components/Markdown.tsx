// Tiny, dependency-free markdown renderer for the Memory / Docs panes.
// Handles: # headings, **bold**, *italic*, `code`, --- rules, - lists, blockquotes, paragraphs.
import { Fragment } from "react";

function inline(text: string) {
  // Escape HTML
  const esc = text
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
  const html = esc
    .replace(/`([^`]+)`/g, '<code class="rounded bg-muted px-1 py-0.5 font-mono text-[0.85em]">$1</code>')
    .replace(/\*\*([^*]+)\*\*/g, '<strong class="text-foreground">$1</strong>')
    .replace(/(^|\W)\*([^*]+)\*/g, '$1<em>$2</em>');
  return <span dangerouslySetInnerHTML={{ __html: html }} />;
}

export function Markdown({ source }: { source: string }) {
  const lines = source.split("\n");
  const blocks: React.ReactNode[] = [];
  let listBuf: string[] = [];
  const flushList = () => {
    if (listBuf.length) {
      blocks.push(
        <ul key={blocks.length} className="my-2 ml-5 list-disc space-y-1 text-sm text-foreground/85">
          {listBuf.map((l, i) => <li key={i}>{inline(l)}</li>)}
        </ul>
      );
      listBuf = [];
    }
  };

  lines.forEach((raw, i) => {
    const line = raw.trimEnd();
    if (/^- /.test(line)) {
      listBuf.push(line.replace(/^- /, ""));
      return;
    }
    flushList();
    if (line === "") return;
    if (line === "---") {
      blocks.push(<hr key={i} className="my-4 border-border" />);
      return;
    }
    let m;
    if ((m = line.match(/^(#{1,6})\s+(.*)$/))) {
      const level = m[1].length;
      const text = m[2];
      const sizes = ["text-xl", "text-lg", "text-base", "text-sm", "text-sm", "text-sm"];
      blocks.push(
        <div key={i} className={`mt-4 mb-2 font-bold text-foreground ${sizes[level - 1]}`}>
          {inline(text)}
        </div>
      );
      return;
    }
    if (line.startsWith("> ")) {
      blocks.push(
        <blockquote key={i} className="my-2 border-l-2 border-violet/60 pl-3 text-sm text-muted-foreground italic">
          {inline(line.slice(2))}
        </blockquote>
      );
      return;
    }
    blocks.push(
      <p key={i} className="my-2 text-sm leading-relaxed text-foreground/90">
        {inline(line)}
      </p>
    );
  });
  flushList();
  return <Fragment>{blocks}</Fragment>;
}
