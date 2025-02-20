"""This is the db models module"""
from extensions import db
from sqlalchemy.sql import func
from sqlalchemy.dialects.mysql import ENUM
from flask_login import UserMixin
import datetime


class User(UserMixin, db.Model):
    """User class"""
    __tablename__ = "users"
    id = db.Column(db.Integer, primary_key=True)
    fname = db.Column(db.String(50), nullable=False)
    sname = db.Column(db.String(50), nullable=False)
    email = db.Column(db.String(50), unique=True)
    admin_type = db.Column(db.String(20), ENUM('approver', 'user', 'admin'),
                           default='user')
    password = db.Column(db.String(225), nullable=False)
    created = db.Column(db.DateTime, default=func.now())
    passresetcode = db.Column(db.String(255), nullable=True)
    last_login = db.Column(db.DateTime, default=func.now())
    last_password_reset = db.Column(db.String(50), nullable=True)
    activated = db.Column(db.Integer, default=0)
    activatecode = db.Column(db.String(255), nullable=True)
    last_activation_code_time = db.Column(db.DateTime(), nullable=True)

class Haulier(db.Model):
    __tablename__ = 'transport_company'

    hid = db.Column(db.Integer, primary_key=True)
    company_name = db.Column(db.String(50))
    address = db.Column(db.String(50))
    registration_number = db.Column(db.String(50))
    reg = db.Column(db.DateTime, default=func.now())
    transactions = db.relationship('WeightLog', backref='haulier', lazy='dynamic')


class WeightLog(db.Model):
    """this holds weight information for each weighing activity"""
    __tablename__ = "weight_log"

    wid = db.Column(db.Integer, primary_key=True)
    vehicle_id = db.Column(db.String(50), nullable=False, unique=True)  # plate number
    haulier_id = db.Column(db.Integer, db.ForeignKey('transport_company.hid'))
    vehicle_name = db.Column(db.String(50))
    driver_name = db.Column(db.String(50))
    initial_weight = db.Column(db.Integer, nullable=True)  # weight in grams
    initial_time = db.Column(db.DateTime(), default=func.now())
    final_weight = db.Column(db.Integer, nullable=True)  # weight in grams
    final_time = db.Column(db.DateTime())


class ReportLog(db.Model):
    """This is the report model"""

    __tablename__ = "report_log"

    rid = db.Column(db.Integer, primary_key=True)
    report_date = db.Column(db.DateTime(), default=func.now())
    weight_log_id = db.Column(db.Integer, nullable=True)
    net_weight = db.Column(db.Integer, nullable=True)
    draft_status = db.Column(db.Integer, default=0)
    approval_status = db.Column(db.String(20), ENUM('approved', 'pending'),
                                default='pending')
    approved_by = db.Column(db.String(50))  # approval's email
    approval_time = db.Column(db.DateTime())


class AppSettings(db.Model):
    __tablename__ = 'settings'

    sid = db.Column(db.Integer, primary_key=True)
    device_name = db.Column(db.String(50))
    port = db.Column(db.String(50))
    parity = db.Column(db.String(50))
    stopbits = db.Column(db.String(50))
    bytesize = db.Column(db.Integer)
    unit = db.Column(db.String(50))
    number_of_approver = db.Column(db.Integer)
    reg = db.Column(db.DateTime, default=func.now())

    def __repr__(self):
        return self.device_name
