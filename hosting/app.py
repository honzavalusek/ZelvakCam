from flask import Flask, session, redirect, url_for, render_template, send_from_directory, request
from functools import wraps

app = Flask(__name__)
app.secret_key = 'super secret key'

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
        if request.form['password'] == 'zelvik':
            session['authenticated'] = True
            return redirect(url_for('index'))
        return 'Invalid Password'


    return render_template('login.html')

@app.route('/')
@login_required
def index():
    return render_template('index.html')

@app.route('/hls/<path:filename>')
@login_required
def hls(filename):
    return send_from_directory('static/hls', filename)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
