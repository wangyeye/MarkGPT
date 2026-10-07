#!/usr/bin/env python3
"""Loopback-only synthetic SSE provider for MarkGPT integration checks."""
import sys, json, time
from http.server import ThreadingHTTPServer, BaseHTTPRequestHandler
if sys.version_info < (3,9): raise SystemExit('Python 3.9+ required')
class Handler(BaseHTTPRequestHandler):
    def log_message(self,*args): pass
    def do_POST(self):
        obj=json.loads(self.rfile.read(int(self.headers['Content-Length'])))
        edit='complete revised document' in obj['messages'][0]['content']
        text='```markdown\n# Revised\n\nFixture edit.\n```' if edit else 'Fixture streaming reply.'
        self.send_response(200);self.send_header('Content-Type','text/event-stream');self.end_headers()
        for chunk in [text[:12],text[12:]]:
            self.wfile.write(('data: '+json.dumps({'choices':[{'delta':{'content':chunk}}]})+'\n\n').encode());self.wfile.flush();time.sleep(.15)
        self.wfile.write(b'data: [DONE]\n\n');self.wfile.flush()
server=ThreadingHTTPServer(('127.0.0.1',0),Handler)
from pathlib import Path
Path(sys.argv[1]).write_text(str(server.server_port))
server.serve_forever()
