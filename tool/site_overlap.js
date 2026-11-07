// Overlap check for site/: copy next to index.html, open from a page that
// loads it (served, ?w=390&lang=fil), and read <pre id="overlap-result">.
// Runs in the harness page: lays the preview out in an iframe of a true
// phone width, tall enough for the whole page, then looks for boxes that
// cover each other or run off the screen — counting only what is visible,
// so text clipped away under "Higit pa" does not count.
(function () {
  var q = new URLSearchParams(location.search);
  var w = +q.get('w') || 390, lang = q.get('lang') || 'fil';
  var f = document.createElement('iframe');
  f.style.cssText = 'border:0;width:' + w + 'px;height:7000px';
  f.src = 'index.html?lang=' + lang + (q.get('v') ? '&v=' + q.get('v') : '');
  document.body.appendChild(f);
  f.onload = function () { setTimeout(check, 2500); };

  function visibleRect(e, win) {
    var r = e.getBoundingClientRect();
    var box = { l: r.left, t: r.top, r: r.right, b: r.bottom };
    for (var p = e.parentElement; p; p = p.parentElement) {
      var cs = win.getComputedStyle(p);
      if (cs.overflowX !== 'visible' || cs.overflowY !== 'visible') {
        var pr = p.getBoundingClientRect();
        box.l = Math.max(box.l, pr.left); box.t = Math.max(box.t, pr.top);
        box.r = Math.min(box.r, pr.right); box.b = Math.min(box.b, pr.bottom);
      }
    }
    return box;
  }

  function check() {
    var win = f.contentWindow, doc = f.contentDocument, out = [];
    var W = win.innerWidth;
    out.push('width=' + W + ' scrollWidth=' + doc.documentElement.scrollWidth + (doc.documentElement.scrollWidth > W ? '  <-- SIDEWAYS SCROLL' : ''));
    var els = Array.prototype.filter.call(doc.querySelectorAll('body *'), function (e) {
      if (e.closest('[hidden]') || e.closest('.dock') || e.closest('.player') || e.closest('.zoom')) return false;
      var cs = win.getComputedStyle(e);
      if (cs.visibility === 'hidden' || cs.display === 'none' || +cs.opacity === 0) return false;
      var hasText = Array.prototype.some.call(e.childNodes, function (n) { return n.nodeType === 3 && n.textContent.trim(); });
      if (!(hasText || /^(IMG|VIDEO|svg)$/.test(e.tagName))) return false;
      var v = visibleRect(e, win);
      return v.r - v.l > 2 && v.b - v.t > 2;
    });
    function label(e) { return e.tagName + ' "' + (e.textContent || e.alt || '').trim().replace(/\s+/g, ' ').slice(0, 34) + '"'; }
    els.forEach(function (e) {
      if (e.closest('.media') || e.closest('.facts')) return;   // sideways scrollers, on purpose
      var r = e.getBoundingClientRect();
      if (r.right > W + 1 || r.left < -1) out.push('OFF-SCREEN ' + label(e) + ' ' + Math.round(r.left) + '..' + Math.round(r.right));
    });
    for (var i = 0; i < els.length; i++) for (var j = i + 1; j < els.length; j++) {
      var a = els[i], b = els[j];
      if (a.contains(b) || b.contains(a)) continue;
      // A play mark drawn on its own picture is meant to sit on it.
      if (a.parentElement === b.parentElement && /tut-play|trailer/.test(a.parentElement.className)) continue;
      var ra = visibleRect(a, win), rb = visibleRect(b, win);
      var x = Math.min(ra.r, rb.r) - Math.max(ra.l, rb.l), y = Math.min(ra.b, rb.b) - Math.max(ra.t, rb.t);
      if (x > 1 && y > 1) out.push('OVERLAP ' + label(a) + ' / ' + label(b) + ' ' + Math.round(x) + 'x' + Math.round(y));
    }
    var pre = document.createElement('pre'); pre.id = 'overlap-result'; pre.textContent = out.join('\n');
    document.body.appendChild(pre);
  }
})();
