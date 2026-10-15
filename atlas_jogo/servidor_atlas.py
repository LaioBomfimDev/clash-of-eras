import http.server
import socketserver
import os
import json
import urllib.parse
from datetime import datetime

PORT = 8090
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FEEDBACK_FILE = os.path.join(BASE_DIR, "atlas_jogo", "feedbacks.json")

class AtlasRequestHandler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=BASE_DIR, **kwargs)

    def end_headers(self):
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/api/feedbacks":
            self.handle_get_feedbacks()
        else:
            super().do_GET()

    def do_POST(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/api/feedback":
            self.handle_post_feedback()
        else:
            self.send_error(404, "Endpoint não encontrado")

    def do_DELETE(self):
        parsed = urllib.parse.urlparse(self.path)
        if parsed.path == "/api/feedback":
            self.handle_delete_feedback(parsed.query)
        else:
            self.send_error(404, "Endpoint não encontrado")

    def handle_get_feedbacks(self):
        feedbacks = {}
        if os.path.isfile(FEEDBACK_FILE):
            try:
                with open(FEEDBACK_FILE, "r", encoding="utf-8") as f:
                    feedbacks = json.load(f)
            except Exception as e:
                print("Erro ao ler feedbacks.json:", e)
                feedbacks = {}

        data = json.dumps(feedbacks, ensure_ascii=False, indent=2).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def handle_post_feedback(self):
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length).decode("utf-8")
        try:
            payload = json.loads(body)
        except Exception as e:
            self.send_error(400, f"JSON inválido: {e}")
            return

        item_id = payload.get("id") or f"{payload.get('categoria')}_{payload.get('item_id')}"
        if not item_id:
            self.send_error(400, "Identificador 'id' é obrigatório")
            return

        payload["id"] = item_id
        payload["timestamp"] = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        feedbacks = {}
        if os.path.isfile(FEEDBACK_FILE):
            try:
                with open(FEEDBACK_FILE, "r", encoding="utf-8") as f:
                    feedbacks = json.load(f)
            except Exception as e:
                print("Erro ao ler feedbacks.json:", e)
                feedbacks = {}

        feedbacks[item_id] = payload

        try:
            with open(FEEDBACK_FILE, "w", encoding="utf-8") as f:
                json.dump(feedbacks, f, ensure_ascii=False, indent=2)
        except Exception as e:
            self.send_error(500, f"Erro ao salvar arquivo: {e}")
            return

        res = json.dumps({
            "status": "ok",
            "message": "Feedback gravado com sucesso no projeto!",
            "id": item_id,
            "total_feedbacks": len(feedbacks)
        }, ensure_ascii=False).encode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(res)))
        self.end_headers()
        self.wfile.write(res)

    def handle_delete_feedback(self, query):
        qs = urllib.parse.parse_qs(query)
        item_id = qs.get("id", [None])[0]
        if not item_id:
            self.send_error(400, "Parâmetro 'id' ausente")
            return

        feedbacks = {}
        if os.path.isfile(FEEDBACK_FILE):
            try:
                with open(FEEDBACK_FILE, "r", encoding="utf-8") as f:
                    feedbacks = json.load(f)
            except Exception as e:
                feedbacks = {}

        if item_id in feedbacks:
            del feedbacks[item_id]
            with open(FEEDBACK_FILE, "w", encoding="utf-8") as f:
                json.dump(feedbacks, f, ensure_ascii=False, indent=2)

        res = json.dumps({"status": "ok", "message": "Feedback removido"}, ensure_ascii=False).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(res)))
        self.end_headers()
        self.wfile.write(res)

def run():
    socketserver.TCPServer.allow_reuse_address = True
    with socketserver.TCPServer(("", PORT), AtlasRequestHandler) as httpd:
        print(f"Servidor Atlas Visual rodando na porta {PORT}...")
        print(f"Raiz: {BASE_DIR}")
        print(f"Arquivo de feedbacks: {FEEDBACK_FILE}")
        httpd.serve_forever()

if __name__ == "__main__":
    run()
