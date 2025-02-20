import eventlet
eventlet.monkey_patch()
from flask import Flask
from flask_socketio import SocketIO
from .config import Config
from .extensions import migrate, cors, jwt, login_manager
from .models import db
import logging
from logging import FileHandler, Formatter
#from sqlalchemy import inspect

socketio = SocketIO()
app = Flask(__name__)

def create_app():
    app.config.from_object(Config)
    db.init_app(app)
    socketio.init_app(app, async_mode='eventlet')
    migrate.init_app(app, db)
    cors.init_app(app)
    jwt.init_app(app)
    login_manager.init_app(app)

    # Setup logging
    if not app.debug:
        # Create a file handler to log to a file
        file_handler = FileHandler('app.log')
        file_handler.setLevel(logging.INFO)
        file_handler.setFormatter(Formatter('%(asctime)s - %(levelname)s - %(message)s'))
        app.logger.addHandler(file_handler)

    with app.app_context():
        from . import routes
        #inspector = inspect(db.engine)
        #tables = inspector.get_table_names()
        #print(tables)
        db.create_all()


    return app, socketio


