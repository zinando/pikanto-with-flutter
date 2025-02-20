from flask import session, render_template, render_template_string, request, flash, redirect, url_for
from extensions import db, app, login_manager
from models import User, ReportLog, WeightLog
from werkzeug.security import check_password_hash, generate_password_hash
from sqlalchemy.sql import func
import os
import json
from appclass.email_class import EmailService


def shutdown_server():
    funck = request.environ.get("werkzeug.server.shutdown")
    if funck is None:
        raise RuntimeError("Flask app is not running with werkzeug server")
    funck()


@login_manager.user_loader 
def load_user(user_id):
    # since the user_id is just the primary key of our user table, use it in the query for the user
    return User.query.filter_by(id=user_id).first()


@app.get('/shutdown')
def shutdown():
    token = request.args.get('token')
    if token == '0170.0040.1989':
        shutdown_server()
        message = 'server is shutting down'
    else:
        message = 'Not authorized'
    print(message)
    return message


@app.route('/', methods=['POST', 'GET'])
def index():
    session['email'] = 'belovedsamex@yahoo.com'
    return render_template('email_template.html')
    return render_template_string("""
            {% if session['email'] %}
                <h3>Welcome {{ session['email'] }}! Please enter your password to approve this request.</h3>
            {% else %}
                <h3>Welcome! Please enter your password to approve this request</a></h3>
            {% endif %}
            <form method="POST" action="/xws_dse_xgde_dgbnxej_dhegs">
            <label for="email">Enter your password here.</label>
            <input type="password" id="password" name="password" required />
            <button type="submit">Submit</button
        </form>
        """)


@app.route('/xws_dse_xgde_dgbnxej_dhegs', methods=['POST'])
def approve_report():
    email = session['email']
    password = request.form['password']
    # user = db.session.query(User).filter(User.email == email).first()
    # if not check_password_hash(user.password, password):
    # flash("Wrong user credentials")
    # return redirect(url_for('index'))
    flash("successfully approved")
    return render_template_string("""     
                {% with messages = get_flashed_messages() %}
                {% if messages %}
                    <div class="notification is-danger">
                        {{ messages[0] }}. Go to <a href="{{ url_for('index') }}">Home Page</a>.
                    </div>
                {% endif %}
                {% endwith %}       
                <h3>Successfully approved</a></h3>            
        """)


@app.route('/send_email', methods=['POST'])
def send_email():
    email_server = EmailService()
    data = request.get_json()
    email_server.recipient_email = data['email']
    email_server.title = data['title']
    email_body = email_server.prepare_email(data['content'])
    response = email_server.sendmail(email_body)

    return json.dumps(response)


if __name__ == '__main__':
    app.run(host="0.0.0.0", port=8088)
