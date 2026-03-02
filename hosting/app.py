import os
import urllib.request
import urllib.error

from dotenv import load_dotenv
from flask import (
    Flask, flash, session, redirect, url_for,
    render_template, request, Response,
)
from functools import wraps

load_dotenv()

app = Flask(__name__)
app.secret_key = os.environ.get('FLASK_SECRET_KEY') or os.urandom(24)

ZELVAKCAM_PASSWORD = os.environ.get('ZELVAKCAM_PASSWORD', 'changeme')
SERVER_IP = os.environ.get('SERVER_IP', '127.0.0.1')
FLASK_PORT = int(os.environ.get('FLASK_PORT', 8080))

NGINX_HLS_BASE = 'http://127.0.0.1:8081/hls'


def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'authenticated' not in session:
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return decorated_function


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        if request.form['password'] == ZELVAKCAM_PASSWORD:
            session['authenticated'] = True
            return redirect(url_for('index'))
        flash('Invalid password.', 'error')
        return redirect(url_for('login'))

    return render_template('login.html')


@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))


@app.route('/')
@login_required
def index():
    return render_template('index.html')


@app.route('/hls/<path:filename>')
@login_required
def hls(filename):
    upstream_url = f'{NGINX_HLS_BASE}/{filename}'
    try:
        with urllib.request.urlopen(upstream_url) as resp:
            data = resp.read()
            content_type = resp.headers.get('Content-Type', 'application/octet-stream')
            return Response(data, content_type=content_type)
    except urllib.error.URLError:
        return Response('Stream unavailable', status=502)


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=FLASK_PORT)
