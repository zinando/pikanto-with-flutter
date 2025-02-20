"""This module will hold functions that perform critical actions for the app"""
from .models import (db, User, WaybillLog, WeightLog, Approval, ApprovalRequest, AppSetting, AuditTrail, SecondaryApprover,
                     Haulier, Customer, Product, Notification, ReadNotifications, DeletedNotifications)
from . import socketio, app
import json
from datetime import datetime
import requests

# create a function that deletes weight record
def delete_weight_record(weight_log_id: int):
    """ 1. delete weigth record
        2. delete associated waybill record if any
    """
    # fetch the weight record
    record= WeightLog.query.filter_by(wid=weight_log_id).first()
    if record:
        weight_record_id = record.wid
        # delete the waybill record
        resp = delete_waybill_record(weight_record_id)
        print(f'waybill deleted: {resp}')

        # delete the weight record
        db.session.delete(record)
        db.session.commit()

        return True
    return False

# create a function that deletes deleted notification records
def delete_deleted_notification_record(notification_id: int, user_id: int = 0):
    """ 1. delete all deleted notification record
    """
    if user_id == 0:
        # fetch the notification record
        records = DeletedNotifications.query.filter_by(notification_id=notification_id).all()
        if records:
            DeletedNotifications.query.filter_by(notification_id=notification_id).delete()
            db.session.commit()
            return True
    else:
        # fetch the notification record
        records = DeletedNotifications.query.filter_by(notification_id=notification_id, user_id=user_id).all()
        if records:
            DeletedNotifications.query.filter_by(notification_id=notification_id, user_id=user_id).delete()
            db.session.commit()
            return True
    return False

# create a function that deletes audit secondary approver records
def delete_secondary_approver_record(approer_request_id: int):
    """ 1. delete all secondary approver record
    """
    # fetch the secondary approver record
    records = SecondaryApprover.query.filter_by(approval_request_id=approer_request_id).all()
    if records:
        SecondaryApprover.query.filter_by(approval_request_id=approer_request_id).delete()
        db.session.commit()
        return True
    return False

# create a function that deletes approval records
def delete_approval_record(approval_request_id: int):
    """ 1. delete all approval record
    """
    # fetch the approval record
    records = Approval.query.filter_by(approval_request_id=approval_request_id).all()
    if records:
        Approval.query.filter_by(approval_request_id=approval_request_id).delete()
        db.session.commit()
        return True
    return

# create a function that deletes approval request records
def delete_approval_request_record(waybill_id: int):
    """ 1. delete all approval request record
    """
    # fetch the approval request record
    records = ApprovalRequest.query.filter_by(waybill_id=waybill_id).all()
    if records:
        for record in records:
            # delete secondary approver records
            resp = delete_secondary_approver_record(record.id)
            print(f'secondary approver deleted: {resp}')

            # delete approval records
            resp = delete_approval_record(record.id)
            print(f'approval record deleted: {resp}')

            # delete notification records
            resp = delete_notification_record(approval_request_id=record.id)
            print(f'notification record deleted: {resp}')

            # delete the approval request record
            db.session.delete(record)
            db.session.commit()

        return True
    return False

# create a function that deletes waybill records
def delete_waybill_record(weight_log_id: int):
    """ 1. delete all waybill record
    """
    # fetch the waybill record
    record = WaybillLog.query.filter_by(weight_log_id=weight_log_id).first()
    if record:
        # delete the approval request record
        resp = delete_approval_request_record(record.wid)
        print(f'approval request deleted: {resp}')

        # delete the waybill record
        db.session.delete(record)
        db.session.commit()
        
        return True
    return False

# create a function that deletes readnotification records
def delete_read_notification_record(notification_id: int, user_id: int = 0):
    """ 1. delete all read notification record
    """
    if user_id == 0:
        # fetch the notification record
        records = ReadNotifications.query.filter_by(notification_id=notification_id).all()
        if records:
            ReadNotifications.query.filter_by(notification_id=notification_id).delete()
            db.session.commit()
            return True
    else:
        # fetch the notification record
        records = ReadNotifications.query.filter_by(notification_id=notification_id, user_id=user_id).all()
        if records:
            ReadNotifications.query.filter_by(notification_id=notification_id, user_id=user_id).delete()
            db.session.commit()
            return True
    return False

# create a function that deletes notification records
def delete_notification_record(id: int = 0, recipient_id: int = 0, message_scope: str = '', approval_request_id: int = 0):
    """ delete by:
        1. notification id if id is not 0
        2. recipient id if recipient_id is not 0
        3. message scope if message_scope is not empty
        4. approval request id if approval_request_id is not 0
    """
    if id != 0:
        # fetch the notification record
        record = Notification.query.filter_by(id=id).first()
        if record:
            # delete the notification record
            # delete readnotifications
            resp = delete_read_notification_record(record.id)
            print(f'read notifications deleted: {resp}')

            # delete deletednotifications
            resp = delete_deleted_notification_record(record.id)
            print(f'read notificatios deleted: {resp}')

            db.session.delete(record)
            db.session.commit()
            return True
    elif recipient_id != 0:
        # fetch the notification record
        records = Notification.query.filter_by(recipient_id=recipient_id).all()
        if records:
            for record in records:
                # delete readnotifications
                resp = delete_read_notification_record(record.id)
                print(f'read notifications deleted: {resp}')

                # delete deletednotifications
                resp = delete_deleted_notification_record(record.id)
                print(f'read notificatios deleted: {resp}')


                # delete the notification record
                db.session.delete(record)
                db.session.commit()
            return True
    elif message_scope != '':
        # fetch the notification record
        records = Notification.query.filter_by(message_scope=message_scope).all()
        if records:
            for record in records:
                # delete readnotifications
                resp = delete_read_notification_record(record.id)
                print(f'read notifications deleted: {resp}')

                # delete deletednotifications
                resp = delete_deleted_notification_record(record.id)
                print(f'read notificatios deleted: {resp}')


                # delete the notification record
                db.session.delete(record)
                db.session.commit()
            return True
    elif approval_request_id != 0:
        # fetch the notification record
        records = Notification.query.filter_by(approval_request_id=approval_request_id).all()
        if records:
            for record in records:
                # delete readnotifications
                resp = delete_read_notification_record(record.id)
                print(f'read notifications deleted: {resp}')

                # delete deletednotifications
                resp = delete_deleted_notification_record(record.id)
                print(f'read notificatios deleted: {resp}')


                # delete the notification record
                db.session.delete(record)
                db.session.commit()
            return True
    return False

# create a function that deletes all records in listed tables
def delete_all_records():
    return
    DeletedNotifications.query.delete()
    ReadNotifications.query.delete()
    Approval.query.delete()
    SecondaryApprover.query.delete()
    Notification.query.delete()
    WaybillLog.query.delete()
    #WeightLog.query.delete()
    #User.query.delete()
    #Product.query.delete()
    #Haulier.query.delete()
    #Customer.query.delete()
    db.session.commit()
    return

# create a function that logs audit trail
def log_audit_trail(user_id: int, action: str, action_details: str, action_time: datetime = datetime.now()):
    """ 1. log audit trail
    """
    # create audit trail record
    audit_trail = AuditTrail()
    audit_trail.user_id = user_id
    audit_trail.action = action
    audit_trail.details = action_details
    audit_trail.timestamp = action_time

    db.session.add(audit_trail)
    db.session.commit

    return

# create a function that triggers a MS Power Automate flow to send email
def send_email_notification(message: str, subject: str, recipient_email: str, copy_to: str = '', app_id=0) -> bool:
    """ 1. send email notification
    """
    # fetch the app setting
    app_setting = AppSetting.query.filter_by(company_id=app_id).first()
    if app_setting:
        app_config = json.loads(app_setting.config)
        # fetch the MS Power Automate flow URL from the app config
        trigger_url = app_config['email_trigger_url']

        # create the payload
        payload = {
            "message": message,
            "subject": subject,
            "recipient_email": recipient_email,
            "copy_to": copy_to
        }
        # send the payload to the MS Power Automate flow
        if trigger_url != '' and trigger_url is not None:
            response = requests.post(trigger_url, json=payload)
            if response.status_code == 200:
                return True
    return False

