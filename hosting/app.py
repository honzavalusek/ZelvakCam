import os
import secrets
import time
from collections import defaultdict, deque
from functools import wraps

from dotenv import load_dotenv
from flask import (
    Flask, Response, flash, redirect, render_template, request, session, url_for,
)
from werkzeug.middleware.proxy_fix import ProxyFix

load_dotenv()

PASSWORD = os.environ.get('ZELVAKCAM_PASSWORD', '')
SECRET_KEY = os.environ.get('FLASK_SECRET_KEY', '')
BAD = ('', 'changeme')
if PASSWORD in BAD or SECRET_KEY in BAD:
    raise SystemExit('Set ZELVAKCAM_PASSWORD and FLASK_SECRET_KEY in .env (not empty / "changeme").')

app = Flask(__name__)
app.secret_key = SECRET_KEY
app.config.update(
    SESSION_COOKIE_SECURE=os.environ.get('INSECURE_COOKIES') != '1',
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE='Lax',
    PERMANENT_SESSION_LIFETIME=30 * 24 * 3600,
)
# Behind Caddy: trust one proxy hop for client IP / scheme.
app.wsgi_app = ProxyFix(app.wsgi_app, x_for=1, x_proto=1, x_host=1)

MAX_ATTEMPTS, WINDOW = 5, 60
_attempts = defaultdict(deque)


def rate_limited(ip):
    now = time.monotonic()
    q = _attempts[ip]
    while q and now - q[0] > WINDOW:
        q.popleft()
    if not q:
        _attempts.pop(ip, None)
        q = _attempts[ip]
    return len(q) >= MAX_ATTEMPTS


def login_required(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        if not session.get('authenticated'):
            return redirect(url_for('login'))
        return f(*args, **kwargs)
    return wrapper


@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        ip = request.remote_addr or '?'
        if rate_limited(ip):
            flash('Too many attempts. Try again in a minute.', 'error')
            return render_template('login.html'), 429
        given = request.form.get('password', '')
        if secrets.compare_digest(given.encode(), PASSWORD.encode()):
            _attempts.pop(ip, None)
            session.clear()
            session['authenticated'] = True
            session.permanent = True
            return redirect(url_for('index'))
        _attempts[ip].append(time.monotonic())
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


@app.route('/auth')
def auth():
    """Used by Caddy forward_auth to guard the stream endpoints."""
    return Response(status=204 if session.get('authenticated') else 401,
                    headers={'Cache-Control': 'no-store'})


if __name__ == '__main__':
    app.run(host='127.0.0.1', port=int(os.environ.get('FLASK_PORT', 8080)))
