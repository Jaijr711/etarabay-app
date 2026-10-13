# -*- coding: utf-8 -*-
"""Serve build/web on the local network for testing on a phone.

`python -m http.server` sends no Cache-Control, so the browser guesses how
long a file stays fresh from how old it is — days, for a picture last touched
months ago. A coloring page redrawn under the same name (paint4.png) went on
showing the old picture without the browser ever asking for it again. Here
every response says `no-cache`: the browser keeps its copy but checks it
each time, and an unchanged file still costs only a 304.

    python tool/serve_web.py [port]
"""
import functools
import http.server
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WEB = os.path.join(ROOT, 'build', 'web')


class NoCacheHandler(http.server.SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('Cache-Control', 'no-cache')
        super().end_headers()


if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8081
    handler = functools.partial(NoCacheHandler, directory=WEB)
    with http.server.ThreadingHTTPServer(('0.0.0.0', port), handler) as httpd:
        print('serving %s on port %d (no-cache)' % (WEB, port), flush=True)
        httpd.serve_forever()
