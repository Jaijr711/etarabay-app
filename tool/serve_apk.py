# -*- coding: utf-8 -*-
"""Hand a test APK to a phone on the same WiFi.

    python tool/serve_apk.py [port] [folder]

Defaults: port 8097, folder ../test-apk (beside the project).

Open http://<this PC>:<port>/ on the phone, or open it on the PC and scan
the QR code with the phone. The page lists the APKs, newest first, with one
big download button each.

Why not `python -m http.server`:
- It sent the APK as "application/octet-stream". Some phones saved it
  as a file they would not open, rather than offering to install it.
- It had no resume. A 117 MB download that dropped (a link opened inside
  Messenger, a screen that went to sleep) started over from nothing.
- A link shared through Messenger comes back with "?fbclid=..." on the
  end. Here the query is ignored.
"""
import html
import http.server
import os
import socket
import sys
import time
import urllib.parse

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APK_TYPE = 'application/vnd.android.package-archive'


def lan_addresses():
    found = []
    try:
        for info in socket.getaddrinfo(socket.gethostname(), None, socket.AF_INET):
            ip = info[4][0]
            if not ip.startswith('127.') and ip not in found:
                found.append(ip)
    except OSError:
        pass
    # The address the PC really uses to reach the network, first.
    try:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(('8.8.8.8', 80))
        main = s.getsockname()[0]
        s.close()
        if main in found:
            found.remove(main)
        found.insert(0, main)
    except OSError:
        pass
    return found


def size_text(n):
    return '%.0f MB' % (n / 1024 / 1024)


PAGE = """<!doctype html>
<html lang="fil"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>E-Tarabay test APK</title>
<style>
 body{{margin:0;font-family:system-ui,Roboto,sans-serif;background:#f3f2fb;color:#1e2340}}
 main{{max-width:520px;margin:0 auto;padding:24px 16px 48px}}
 h1{{color:#5c52e5;font-size:26px;margin:0 0 4px}}
 .sub{{color:#5d6385;margin:0 0 20px}}
 .apk{{background:#fff;border:1px solid #e1e0f0;border-radius:18px;padding:16px;margin-bottom:12px}}
 .name{{font-weight:700;word-break:break-all}}
 .meta{{color:#5d6385;font-size:14px;margin:2px 0 12px}}
 .new{{display:inline-block;background:#2e9e5b;color:#fff;font-size:12px;font-weight:700;
   border-radius:99px;padding:2px 9px;margin-left:6px;vertical-align:2px}}
 a.btn{{display:block;text-align:center;background:#5c52e5;color:#fff;text-decoration:none;
   font-weight:800;font-size:18px;padding:14px;border-radius:14px}}
 ol{{padding-left:20px;line-height:1.5}}
 .box{{background:#fff;border-radius:18px;padding:4px 16px 8px;margin-top:20px;border:1px solid #e1e0f0}}
 #qr{{text-align:center;margin-top:20px}} #qr img{{width:200px;height:200px}}
 .warn{{background:#fff4e0;border:1px solid #f5c26b;border-radius:14px;padding:10px 14px;margin-bottom:16px;display:none}}
</style></head><body><main>
<h1>E-Tarabay test APK</h1>
<p class="sub">Para sa pagsubok lang. Hindi ito ang opisyal na release.</p>
<div class="warn" id="inapp"><b>Nasa loob ka ng Messenger/Facebook.</b> Pindutin ang &#8942;
 sa itaas, saka ang <b>"Buksan sa Chrome"</b> (Open in browser), para tuloy-tuloy ang download.</div>
{items}
<div class="box"><ol>
 <li>Pindutin ang <b>I-download</b>. Hintayin hanggang matapos.</li>
 <li>Buksan ang na-download na file.</li>
 <li>Kapag tinanong, payagan ang <b>"Install unknown apps"</b> para sa Chrome.</li>
 <li>Pindutin ang <b>Install</b> (o <b>Update</b>). Hindi kailangang i-uninstall ang luma.</li>
</ol></div>
<div id="qr"></div>
</main>
<script>
 if (/FBAN|FBAV|FB_IAB|Messenger|Instagram/i.test(navigator.userAgent))
   document.getElementById('inapp').style.display = 'block';
 // On the PC: a code for the phone to scan. Drawn only with internet.
 if (!/Android|iPhone/i.test(navigator.userAgent)) {{
   var s = document.createElement('script');
   s.src = 'https://cdn.jsdelivr.net/npm/qrcode-generator@1.4.4/qrcode.js';
   s.onload = function () {{
     var q = qrcode(0, 'M'); q.addData({url}); q.make();
     document.getElementById('qr').innerHTML =
       '<p class="sub">I-scan gamit ang phone:</p>' + q.createImgTag(6, 8);
   }};
   document.head.appendChild(s);
 }}
</script></body></html>"""


class Handler(http.server.BaseHTTPRequestHandler):
    folder = '.'
    page_url = ''

    def log_message(self, fmt, *args):
        sys.stdout.write('%s %s\n' % (self.client_address[0], fmt % args))
        sys.stdout.flush()

    def apks(self):
        files = [f for f in os.listdir(self.folder) if f.lower().endswith('.apk')]
        files.sort(key=lambda f: os.path.getmtime(os.path.join(self.folder, f)),
                   reverse=True)
        return files

    def do_HEAD(self):
        self.do_GET(head=True)

    def do_GET(self, head=False):
        path = urllib.parse.unquote(urllib.parse.urlsplit(self.path).path)
        if path in ('/', '/index.html'):
            return self.send_page(head)
        name = os.path.basename(path)
        full = os.path.join(self.folder, name)
        if not name.lower().endswith('.apk') or not os.path.isfile(full):
            self.send_error(404, 'Walang ganitong file')
            return
        self.send_apk(full, name, head)

    def send_page(self, head):
        items = []
        for i, f in enumerate(self.apks()):
            st = os.stat(os.path.join(self.folder, f))
            when = time.strftime('%b %d, %I:%M %p', time.localtime(st.st_mtime))
            items.append(
                '<div class="apk"><div class="name">%s%s</div>'
                '<div class="meta">%s · %s</div>'
                '<a class="btn" href="/%s">I-download</a></div>' % (
                    html.escape(f), '<span class="new">Pinakabago</span>' if i == 0 else '',
                    size_text(st.st_size), when, urllib.parse.quote(f)))
        if not items:
            items.append('<div class="apk">Wala pang APK sa folder.</div>')
        body = PAGE.format(items='\n'.join(items),
                           url=repr(self.page_url)).encode('utf-8')
        self.send_response(200)
        self.send_header('Content-Type', 'text/html; charset=utf-8')
        self.send_header('Cache-Control', 'no-cache')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        if not head:
            self.wfile.write(body)

    def send_apk(self, full, name, head):
        size = os.path.getsize(full)
        start, end = 0, size - 1
        rng = self.headers.get('Range', '')
        partial = False
        if rng.startswith('bytes='):
            try:
                a, b = rng[6:].split(',')[0].split('-')
                if a:
                    start = int(a)
                    end = int(b) if b else size - 1
                else:
                    start = max(0, size - int(b))
                end = min(end, size - 1)
                partial = start <= end
            except ValueError:
                partial = False
            if not partial:
                self.send_response(416)
                self.send_header('Content-Range', 'bytes */%d' % size)
                self.end_headers()
                return
        self.send_response(206 if partial else 200)
        self.send_header('Content-Type', APK_TYPE)
        self.send_header('Content-Disposition', 'attachment; filename="%s"' % name)
        self.send_header('Accept-Ranges', 'bytes')
        self.send_header('Content-Length', str(end - start + 1))
        if partial:
            self.send_header('Content-Range', 'bytes %d-%d/%d' % (start, end, size))
        self.end_headers()
        if head:
            return
        try:
            with open(full, 'rb') as f:
                f.seek(start)
                left = end - start + 1
                while left > 0:
                    chunk = f.read(min(1 << 20, left))
                    if not chunk:
                        break
                    self.wfile.write(chunk)
                    left -= len(chunk)
        except (ConnectionResetError, ConnectionAbortedError, BrokenPipeError):
            # The phone stopped (screen off, Messenger's preview). It can
            # pick up where it left off.
            self.log_message('naputol ang download ng %s', name)


if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8097
    folder = os.path.abspath(sys.argv[2] if len(sys.argv) > 2
                             else os.path.join(ROOT, '..', 'test-apk'))
    ips = lan_addresses()
    Handler.folder = folder
    Handler.page_url = 'http://%s:%d/' % (ips[0] if ips else 'localhost', port)
    with http.server.ThreadingHTTPServer(('0.0.0.0', port), Handler) as httpd:
        print('APK folder: %s' % folder)
        for ip in ips:
            print('Sa phone (parehong WiFi): http://%s:%d/' % (ip, port))
        print('Sa PC (may QR code): http://localhost:%d/' % port, flush=True)
        httpd.serve_forever()
