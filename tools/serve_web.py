#!/usr/bin/env python3
"""Serve o build web do FMF com os cabeçalhos COOP/COEP.

Uso: python3 tools/serve_web.py [porta]   (padrão: 8060)
Depois abra http://localhost:8060 — ou http://<IP-deste-PC>:8060 no celular.
"""
import http.server
import os
import sys

PORT = int(sys.argv[1]) if len(sys.argv) > 1 else 8060
ROOT = os.path.join(os.path.dirname(__file__), "..", "build", "web")


class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=ROOT, **kwargs)

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


if __name__ == "__main__":
    print(f"Servindo {os.path.abspath(ROOT)} em http://0.0.0.0:{PORT}")
    http.server.ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
