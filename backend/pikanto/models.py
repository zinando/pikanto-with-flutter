from enum import unique
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy import null
from sqlalchemy.sql import func
from flask_login import UserMixin
import json
from datetime import datetime
from sqlalchemy.dialects.mysql import ENUM

db = SQLAlchemy()

class User(UserMixin, db.Model): 
    """User class"""
    __tablename__ = "users"
    id = db.Column(db.Integer, primary_key=True)
    fname = db.Column(db.String(50), nullable=False)
    sname = db.Column(db.String(50), nullable=False)
    email = db.Column(db.String(50), unique=True)
    admin_type = db.Column(db.String(20), ENUM('approver', 'user', 'admin', 'super'),
                           default='user')
    password = db.Column(db.String(225), nullable=False)
    created = db.Column(db.DateTime, default=func.now())
    passresetcode = db.Column(db.String(255), nullable=True)
    last_login = db.Column(db.DateTime, default=func.now())
    last_password_reset = db.Column(db.String(50), nullable=True)
    activated = db.Column(db.Integer, default=1)
    activatecode = db.Column(db.String(255), nullable=True)
    last_activation_code_time = db.Column(db.DateTime(), nullable=True)
    transactions = db.relationship('WeightLog', backref='operator', lazy='dynamic')
    delete_flag = db.Column(db.Integer, default=0)

    read_notification = db.relationship('ReadNotifications', backref='user', uselist=False)
    deleted_notification = db.relationship('DeletedNotifications', backref='user', uselist=False)


class Haulier(db.Model):
    __tablename__ = 'transport_company'

    hid = db.Column(db.Integer, primary_key=True)
    company_name = db.Column(db.String(50))
    address = db.Column(db.String(50))
    registration_number = db.Column(db.String(50))  # ref
    reg = db.Column(db.DateTime, default=func.now())
    transactions = db.relationship('WeightLog', backref='haulier', lazy='dynamic')
    waybills = db.relationship('WaybillLog', backref='haulier', lazy='dynamic')
    delete_flag = db.Column(db.Integer, default=0)


class Customer(db.Model):
    __tablename__ = 'customer'

    cid = db.Column(db.Integer, primary_key=True)
    customer_name = db.Column(db.String(50))
    address = db.Column(db.String(50))
    registration_number = db.Column(db.String(50))  # ref number
    reg = db.Column(db.DateTime, default=func.now())
    transactions = db.relationship('WeightLog', backref='customer', lazy='dynamic')
    waybills = db.relationship('WaybillLog', backref='customer', lazy='dynamic')
    delete_flag = db.Column(db.Integer, default=0)


class WeightLog(db.Model):
    """this holds weight information for each weighing activity"""
    __tablename__ = "weight_log"

    wid = db.Column(db.Integer, primary_key=True)
    vehicle_id = db.Column(db.String(50), nullable=False)  # plate number
    haulier_id = db.Column(db.Integer, db.ForeignKey('transport_company.hid'))
    customer_id = db.Column(db.Integer, db.ForeignKey('customer.cid'))
    vehicle_name = db.Column(db.String(50))
    driver_name = db.Column(db.String(50))
    driver_phone = db.Column(db.String(50))
    operator_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    destination = db.Column(db.String(50))
    order_number = db.Column(db.String(50))
    product = db.Column(db.String(50))
    initial_weight = db.Column(db.Integer, nullable=True)  # weight in grams
    initial_time = db.Column(db.DateTime(), default=func.now())
    final_weight = db.Column(db.Integer, nullable=True)  # weight in grams
    final_time = db.Column(db.DateTime())
    delete_flag = db.Column(db.Integer, default=0)


class ReportLog(db.Model):
    """This is the waybill ticket model"""

    __tablename__ = "ticket"

    rid = db.Column(db.Integer, primary_key=True)
    ticket_number = db.Column(db.String(50), unique=True)
    report_date = db.Column(db.DateTime(), default=func.now())
    weight_log_id = db.Column(db.Integer, nullable=True)
    net_weight = db.Column(db.Integer, nullable=True)
    draft_status = db.Column(db.Integer, default=0)
    approval_status = db.Column(db.String(20), ENUM('approved', 'pending'),
                                default='pending')
    approved_by = db.Column(db.String(50))  # approval's email
    approval_time = db.Column(db.DateTime())
    delete_flag = db.Column(db.Integer, default=0)


class AppSetting(db.Model):
    __tablename__ = 'settings'

    sid = db.Column(db.Integer, primary_key=True)
    company_id = db.Column(db.Integer, unique=True)
    config = db.Column(db.String(6550), nullable=False)
    created_at = db.Column(db.DateTime, default=func.now())
    delete_flag = db.Column(db.Integer, default=0)

    def __repr__(self):
        return json.loads(self.config)


class WaybillLog(db.Model):
    __tablename__ = 'waybill_log'

    wid = db.Column(db.Integer, primary_key=True)
    waybill_number = db.Column(db.String(50))
    haulier_ref = db.Column(db.String(50))
    customer_ref = db.Column(db.String(50))
    customer_id = db.Column(db.Integer, db.ForeignKey('customer.cid'))
    haulier_id = db.Column(db.Integer, db.ForeignKey('transport_company.hid'))
    weight_log_id = db.Column(db.Integer)
    delivery_address = db.Column(db.String(120))
    product_info = db.Column(db.String(650), default=json.dumps([]))  # list of dicts
    product_condition = db.Column(db.String(50), ENUM('good', 'bad'), default='good')
    bad_product_info = db.Column(db.String(650), default=json.dumps([]))  # list of dicts
    file_link = db.Column(db.String(650))  # string list
    received_by = db.Column(db.String(50))
    delivered_by = db.Column(db.String(50))
    reg_date = db.Column(db.DateTime(), default=func.now())
    delete_flag = db.Column(db.Integer, default=0)
    primary_approver_id = db.Column(db.Integer, db.ForeignKey('users.id'))
    
    primary_approver = db.relationship('User', backref='primary_approved_waybills')
    approval_request = db.relationship('ApprovalRequest', back_populates='waybill')

    def __repr__(self):
        return self.waybill_number


class Product(db.Model):
    __tablename__ = 'product'
    pid = db.Column(db.Integer, primary_key=True)
    product_code = db.Column(db.String(50))
    description = db.Column(db.String(60))
    count_per_case = db.Column(db.Integer)
    weight_per_count = db.Column(db.Integer)  # e.g 400g, 2000g
    reg_date = db.Column(db.DateTime(), default=func.now())
    delete_flag = db.Column(db.Integer, default=0)

class ApprovalRequest(db.Model):
    __tablename__ = 'approval_requests'
    id = db.Column(db.Integer, primary_key=True)
    waybill_id = db.Column(db.Integer, db.ForeignKey('waybill_log.wid'), nullable=False)
    created_by = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    approval_flow_type = db.Column(db.String(50), ENUM('parallel','sequence'), default='sequence')  # Parallel, Sequential
    status = db.Column(db.String(50), ENUM('approved', 'pending','declined'), default='pending')  # Pending, Approved, Rejected, etc.
    created_at = db.Column(db.DateTime, default=datetime.now())
    is_escalated = db.Column(db.Boolean, default=False)

    waybill = db.relationship('WaybillLog', back_populates='approval_request')
    created_by_user = db.relationship('User', backref='created_approval_requests')
    approvals = db.relationship('Approval', back_populates='approval_request')
    secondary_approvers = db.relationship('SecondaryApprover', back_populates='approval_request')

class SecondaryApprover(db.Model):
    __tablename__ = 'secondary_approvers'
    id = db.Column(db.Integer, primary_key=True)
    approval_request_id = db.Column(db.Integer, db.ForeignKey('approval_requests.id'), nullable=False)
    approver_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    rank = db.Column(db.Integer, nullable=False)  # Rank order of the approvers
    
    approval_request = db.relationship('ApprovalRequest', back_populates='secondary_approvers')
    approver = db.relationship('User', backref='secondary_approved_requests')

class Approval(db.Model):
    __tablename__ = 'approvals'
    id = db.Column(db.Integer, primary_key=True)
    approval_request_id = db.Column(db.Integer, db.ForeignKey('approval_requests.id'), nullable=False)
    approved_by = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    approval_status = db.Column(db.String(50), ENUM('approved', 'pending','declined'), default='pending')
    timestamp = db.Column(db.DateTime, default=datetime.now())  # shoulb be changed when the user approves
    is_primary = db.Column(db.Boolean, default=False)  # True if primary approver
    is_notified = db.Column(db.Boolean, default=True)  # True if the user has been notified
    comments = db.Column(db.Text, nullable=True)  # Optional comments for declined requests

    approval_request = db.relationship('ApprovalRequest', back_populates='approvals')
    approver = db.relationship('User', backref='approvals')

class Notification(db.Model):
    __tablename__ = 'notifications'

    id = db.Column(db.Integer, primary_key=True)
    recipient_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    message_scope = db.Column(db.String(50), ENUM('all', 'approver', 'user', 'admin', 'super','specific'), default='all')
    message = db.Column(db.String(500), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.now())
    is_read = db.Column(db.Boolean, default=False)  # Track whether the notification has been read
    approval_request_id = db.Column(db.Integer, db.ForeignKey('approval_requests.id'), nullable=True)

    recipient = db.relationship('User', backref='notifications')
    approval_request = db.relationship('ApprovalRequest', backref='related_notifications')
    read = db.relationship('ReadNotifications', backref='notification', uselist=False)
    deleted = db.relationship('DeletedNotifications', backref='notification', uselist=False)


class ReadNotifications(db.Model):
    """This model will hold record of notifications that have been read by users"""
    __tablename__ = 'read_notifications'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    notification_id = db.Column(db.Integer, db.ForeignKey('notifications.id'), nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.now())

    #notification = db.relationship('Notification', backref='read', uselist=False)
    #user = db.relationship('User', backref='read_notifications')

class DeletedNotifications(db.Model):
    """This model will hold record of notifications that have been deleted by users"""
    __tablename__ = 'deleted_notifications'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    notification_id = db.Column(db.Integer, db.ForeignKey('notifications.id'), nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.now())

    #notification = db.relationship('Notification', backref='deleted')
    #user = db.relationship('User', backref='deleted_notifications')

class AuditTrail(db.Model):
    __tablename__ = 'audit_trail'
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
    action = db.Column(db.String(255), nullable=False)
    weight_log_id = db.Column(db.Integer, db.ForeignKey('weight_log.wid'), nullable=True)
    approval_request_id = db.Column(db.Integer, db.ForeignKey('approval_requests.id'), nullable=True)
    timestamp = db.Column(db.DateTime, default=datetime.now())
    details = db.Column(db.Text, nullable=True)  # Optional field for extra information

    user = db.relationship('User', backref='audit_trails')
    weight_log = db.relationship('WeightLog', backref='audit_trails')
    approval_request = db.relationship('ApprovalRequest', backref='audit_trails')

