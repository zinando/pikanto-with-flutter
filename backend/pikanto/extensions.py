#from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_cors import CORS
from flask_jwt_extended import JWTManager
from flask_login import LoginManager

#db = SQLAlchemy()
migrate = Migrate()
cors = CORS()
jwt = JWTManager()
login_manager = LoginManager()
