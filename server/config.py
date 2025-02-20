# Pikanto app configuration settings
import os

# SECRET_KEY = os.environ.get('SECRETE_KEY')
SQLALCHEMY_DATABASE_URI = "sqlite:///pikanto_db.sqlite"
SQLALCHEMY_TRACK_MODIFICATIONS = False

# cors 
CORS_HEADERS = "Content-Type"

# flask_session
#SESSION_PERMANENT = False
#SESSION_TYPE = "filesystem"

#  MAIL SETTINGS
MAIL_SERVER = "smtp.gmail.com"
MAIL_PORT = 465
MAIL_USE_SSL = True
MAIL_USERNAME = os.environ.get('MAIL_USERNAME')
MAIL_PASSWORD = os.environ.get('MAIL_PASSWORD')
MAIL_DEFAULT_SENDER = "Pikanto"
MAIL_DEBUG = False

# ngrok
NGROK_AUTHTOKEN = os.environ.get('NGROK_AUTHTOKEN')

APP_ROOT = os.path.dirname(os.path.abspath(__file__))  # refers to application_top