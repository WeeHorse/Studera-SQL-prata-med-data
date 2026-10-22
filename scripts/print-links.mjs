/** Expand external Markdown links only for the physical print edition. */
export function expandPrintUrls(source) {
  const escapeHtml = s => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/"/g, '&quot;');
  let fenced = false;
  return source.split('\n').map(line => {
    if (/^\s*(?:```|~~~)/.test(line)) { fenced = !fenced; return line; }
    if (fenced) return line;
    return line.replace(/(!?)\[([^\]\n]+)\]\((https?:\/\/(?:[^()\s]|\([^()]*\))+?)\)/g,
      (whole, image, label, url) => {
        if (image || label.trim() === url) return whole;
        return `[${label}](${url}) <span class="print-link-url">(${escapeHtml(url)})</span>`;
      });
  }).join('\n');
}
