"""This class will take approval requet id and return a dictionary of approval request details"""
from pikanto.models import db, ApprovalRequest, Approval, Notification, SecondaryApprover
from pikanto import functions as func
from pikanto import resources as resource
from datetime import datetime
from pikanto import action as act

class ApprovalRequestClass:
    def __init__(self, approval_request_id):
        self.approval_request_id = approval_request_id
        # check if approval request exists
        self.approval_request = ApprovalRequest.query.filter_by(id=self.approval_request_id).first()
        self.waybill_id = 0
        if not self.approval_request:
            raise ValueError('Approval request not found [source: ApprovalRequestClass]')
        else:
            self.waybill_id = self.approval_request.waybill_id
        
    # method that checks if item is pending or not
    def _is_pending(self):
        if self.approval_request and self.approval_request.status == 'pending':
            return True
        return False
    
    def _waybill(self):
        if self.approval_request:
            if self.approval_request.waybill:
                waybill = resource.fetch_waybill_record(self.approval_request.waybill.weight_log_id)
                if len(waybill) > 0:
                    return waybill
        return None
    
    # method that checks if item is approved or not
    def _is_approved(self):
        if self.approval_request and self.approval_request.status == 'approved':
            return True
        return False
    
    # method that checks if item has secondary approvers or not
    def _has_secondary_approvers(self):
        if self.approval_request and self.approval_request.secondary_approvers:
            return True
        return False
    
    # method that checks if an approver has approved the item in the Approval table or not
    def _has_approved(self, approver_id):
        if Approval.query.filter(
            Approval.approval_request_id == self.approval_request_id,
            Approval.approved_by == approver_id,
            Approval.approval_status != 'pending'
        ).first():
            return True
        return False
    
    # method that checks if an approver has been notified or not
    def _is_notified(self, approver_id):
        if Approval.query.filter_by(
            approval_request_id=self.approval_request_id, 
            approved_by=approver_id, 
            approval_status='pending'
        ).first():
            return True
        return False

    # method that fetches the next secondary approver
    def _fetch_next_secondary_approver(self):
        # 1. check if the item has secondary approvers
        # 2. fetch all secondary approvers and order them by rank begining with the one with the lowest rank
        # for each secondary approver, check if they have approved the item
        # if they have not approved the item, return the secondary approver
        # if all secondary approvers have approved the item, return None

        if self._has_secondary_approvers():
            secondary_approvers = SecondaryApprover.query.filter_by(approval_request_id=self.approval_request_id).order_by(SecondaryApprover.rank).all()
            for secondary_approver in secondary_approvers:
                if not self._has_approved(secondary_approver.approver_id):
                    return secondary_approver.approver_id
        return None
    
    # method that fetches the primary approver
    def _fetch_primary_approver(self):
        
        if self.approval_request:
            #approver = WaybillLog.query.filter_by(wid=self.approval_request.waybill_id).first()
            #if approver:
            #return approver.primary_approver_id
            #print("primary approver id: ",self.approval_request.waybill.primary_approver_id)
            return self.approval_request.waybill.primary_approver_id
            
        return None
    
    # method that creates an approval notification
    def _create_approval_notification(self, approver_id):
        # 1. check if the approver has previously been notified
        # 2. if the approver has not been notified, create an Approval record and notification for the approver
        # 3. if the approver has been notified, create a reminder notification for the approver

        vehicle_id = resource.get_vehicle_id(self.waybill_id)
        approver = resource.fetch_user_data(approver_id)
        approver_email = ''
        if isinstance(approver, dict):
            approver_name = approver.get('fullName', '')
            approver_email = approver.get('email', '')
        else:
            approver_name = ''
        message = f'REMINDER: Dear {approver_name}, you have a waybill approval request for a waybill with vehicle reference number: {vehicle_id}.'
        mesg = f'A reminder notification for approval of Waybill with reference: {vehicle_id} has been sent to {approver_name}.'

        if not self._is_notified(approver_id):
            message = f'Dear {approver_name}, you have a waybill approval request for a waybill with vehicle reference number: {vehicle_id}.'
            mesg = f'Waybill with reference: {vehicle_id} has been sent to {approver_name} for approval.'
            
            approval = Approval()
            approval.approval_request_id = self.approval_request_id
            approval.approved_by = approver_id
            approval.approval_status = 'pending'
            approval.is_primary = self._is_primary_approver(approver_id)
            approval.is_notified = True
            db.session.add(approval)
            db.session.commit()
        
        # create notification
        notification = Notification()
        notification.recipient_id=approver_id
        notification.message = message
        notification.approval_request_id = self.approval_request_id
        notification.created_at = datetime.now()
        
        db.session.add(notification)
        db.session.commit()

        # send notification to approver
        resource.send_notification(scope='specific', user_id=approver_id)

        # send email notification to approver
        act.send_email_notification(message=message, subject='Waybill Approval Request', recipient_email=approver_email, app_id=1)
        
        # also notify users
        resource.log_notification(message=mesg, recipient_id=0, scope='user',request_id=self.approval_request_id)
        return
    
    # method that checks if an approver is primary approver or not
    def _is_primary_approver(self, approver_id):
        if self.approval_request and self.approval_request.waybill.primary_approver_id == approver_id:
            return True
        return False
    
    # method that sends approval request to approvers
    def send_approval_request(self) -> dict:
        # 1. check if item is pending approval or not
        # 2. if item is pending approval, fetch the next secondary approver
        # 3. if there is a secondary approver, create a notification for the secondary approver
        # 4. fetch the primary approver and create a notification for the primary approver
        # 5. return a dictionary of the status of the operation
        # 6. if item is not pending approval, return a dictionary of the status of the operation

        if self._is_pending():
            # check the approval flow type
            if self.approval_request and self.approval_request.approval_flow_type == 'sequence':
                next_secondary_approver = self._fetch_next_secondary_approver()
                if next_secondary_approver is not None:
                    self._create_approval_notification(next_secondary_approver)
                else:
                    primary_approver = self._fetch_primary_approver()
                    self._create_approval_notification(primary_approver)
            else:
                # fetch all secondary approvers and create notifications for them at once
                if self._has_secondary_approvers():
                    secondary_approvers = SecondaryApprover.query.filter_by(approval_request_id=self.approval_request_id).all()
                    for secondary_approver in secondary_approvers:
                        # check if the secondary approver has approved the item
                        if not self._has_approved(secondary_approver.approver_id):
                            self._create_approval_notification(secondary_approver.approver_id)
                    # if all secondary approvers have approved the item, notify the primary approver
                    next_secondary_approver = self._fetch_next_secondary_approver()
                    if next_secondary_approver is None:
                        primary_approver = self._fetch_primary_approver()
                        self._create_approval_notification(primary_approver)
                else:
                    primary_approver = self._fetch_primary_approver()
                    self._create_approval_notification(primary_approver)
        else:
            return {'status': 2, 'message': f'Approval request has been {self.approval_request.status if self.approval_request else "not found"}.'}
        return {'status': 1, 'message': 'Approval request sent successfully'}
    