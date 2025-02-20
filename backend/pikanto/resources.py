import json
from datetime import datetime
from . import socketio
from . import functions as func
from sqlalchemy import or_
from .models import (
    db, User, WeightLog, WaybillLog, Customer, Haulier, 
    Product, ApprovalRequest, Approval, SecondaryApprover,
    Notification, ReadNotifications, DeletedNotifications, AppSetting)

def fetch_waybill_record(weight_log_id: int) ->dict:
    """Fetches waybill information for a given weight record id.
    """
    
    waybill = WaybillLog.query.filter_by(weight_log_id=weight_log_id).first()
    mr = {}
    if waybill:
        mr['waybillId'] = waybill.wid
        mr['waybillNumber'] = waybill.waybill_number
        mr['date'] = waybill.reg_date.strftime('%d-%m-%Y %I:%M:%S %p')
        mr['haulierRef'] = waybill.haulier_ref
        mr['customerRef'] = waybill.customer_ref
        mr['customerId'] = waybill.customer_id
        mr['customerName'] = waybill.customer.customer_name if waybill.customer else ''
        mr['haulierId'] = waybill.haulier_id
        mr['weightRecordId'] = waybill.weight_log_id
        mr['deliveryAddress'] = waybill.delivery_address
        mr['goodProducts'] = json.loads(waybill.product_info) if waybill.product_info else []
        mr['productCondition'] = waybill.product_condition
        mr['badProducts'] = json.loads(waybill.bad_product_info) if waybill.bad_product_info else []
        mr['preparedBy'] = waybill.received_by
        mr['driverName'] = waybill.delivered_by
        mr['attachments'] = [] if waybill.file_link is None else json.loads(waybill.file_link)
        # get ticket info as well
        weight_log = WeightLog.query.filter_by(wid=waybill.weight_log_id).first()
        mr['vehicleId'] = weight_log.vehicle_id if weight_log else None
        mr['haulierName'] = weight_log.haulier.company_name if weight_log else ''
        
        # deduce the approval status and records

        # 1. check if waybill has an approval request or not
        # 2. If it has, get the primary approver
        # 3. If it has secondary approvers, get them as well
        # 4. Check if the waybill has been approved or not
        # 5. If it has, get the approval status, the approver and the time of approval

        approval_request = ApprovalRequest.query.filter_by(waybill_id=waybill.wid).first()
        if approval_request:
            mr['currentSecondaryApprover'] = fetch_current_secondary_approver(approval_request.id)
            mr['approvalRequestId'] = approval_request.id
            mr['approvalRequested'] = True
            mr['primaryApprover'] = fetch_user_data(waybill.primary_approver_id)
            mr['secondaryApprovers'] = fetch_secondary_approvers(approval_request.id)
            mr['approvalStatus'] = approval_request.status
            if approval_request.status != 'pending':
                # check if item was approved or declined
                if approval_request.status == 'approved':
                    # request was approved, hence get the primary approver who approved the request
                    approval = Approval.query.filter_by(approval_request_id=approval_request.id, approved_by=waybill.primary_approver_id).first()
                    mr['approvedBy'] = f'{approval.approver.sname} {approval.approver.fname}' if approval else ''
                    mr['approvalTime'] = approval.timestamp.strftime('%d-%m-%Y %I:%M:%S %p') if approval else ''
                    mr['remarks'] = approval.comments if approval else ''
                else:
                    # request was declined, hence get the approver who declined the request
                    approval = Approval.query.filter_by(approval_request_id=approval_request.id, approval_status='declined').first()
                    mr['approvedBy'] = f'{approval.approver.sname} {approval.approver.fname}' if approval else ''
                    mr['approvalTime'] = approval.timestamp.strftime('%d-%m-%Y %I:%M:%S %p') if approval else ''
                    mr['remarks'] = approval.comments if approval else ''
            else:
                mr['approvedBy'] = ''
                mr['approvalTime'] = ''
                mr['remarks'] = ''
        else:
            mr['currentSecondaryApprover'] = 0
            mr['approvalRequestId'] = 0
            mr['approvalRequested'] = False
            mr['primaryApprover'] = {}
            mr['secondaryApprovers'] = []
            mr['approvalStatus'] = 'pending'
            mr['approvedBy'] = ''
            mr['approvalTime'] = ''
            mr['remarks'] = ''

        #print(mr['goodProducts'])
    return mr

def fetch_current_secondary_approver(approval_request_id:int) ->int:
    # 1. get the approval request
    # 2. check if the request has secondary approvers
    # 3. if it has, get the id of the next secondary approver who has been notified but is yet to approve the request, if None return 0
    # 4. if it does not have, return 0
    
    approval_request = ApprovalRequest.query.filter_by(id=approval_request_id).first()
    if approval_request:
        if approval_request.secondary_approvers:
            secondary_approvers = SecondaryApprover.query.filter_by(approval_request_id=approval_request_id).order_by(SecondaryApprover.rank).all()
            for secondary_approver in secondary_approvers:
                if Approval.query.filter_by(approval_request_id=approval_request_id, approved_by=secondary_approver.approver_id, approval_status='pending').first():
                    return secondary_approver.approver_id
    return 0

def fetch_secondary_approvers(approval_request_id:int) ->list:
    approversList = []
    approvers = SecondaryApprover.query.filter_by(approval_request_id=approval_request_id).all()
    if approvers:
        for approver in approvers:
            user_data = fetch_user_data(approver.approver_id)
            if isinstance(user_data, dict):
                user_data['rank'] = approver.rank
            approversList.append(user_data)
    print(f'approversList: {approversList}')
    return approversList


def fetch_customer_data(cid: int = 0):
    """Fetches customer information from the database.

    Args:
        cid (int, optional): Customer ID. If provided, fetches data for the specific customer.
                             If not provided (default), retrieves information for all customers.

    Returns:
        list or dict: If cid is None, returns a list of dictionaries containing details of all customers
                      with keys: 'customer_id', 'customer_name', 'customer_ref', 'customer_address'.
                      If cid is provided and a customer exists with that ID, returns a dictionary
                      containing details of that customer with the same keys.
                      Returns an empty list if no customers are found when cid is None.
                      Returns an empty dictionary if no customer is found for the provided cid.
    """
    
    if cid == 0:
        # Fetch information for all customers
        data = Customer.query.all()
        mylist = []
        
        if data:
            for item in data:
                mr = {}
                mr['customerId'] = item.cid
                mr['customerName'] = item.customer_name
                mr['registrationNumber'] = item.registration_number
                mr['address'] = item.address
                mr['deleteFlag'] = item.delete_flag
                mylist.append(mr)
                
        return mylist

    # Fetch information for a specific customer with provided cid
    data = Customer.query.filter_by(cid=cid).first()
    mr = {}
    if data:
        mr['customerId'] = data.cid
        mr['customerName'] = data.customer_name
        mr['registrationNumber'] = data.registration_number
        mr['address'] = data.address
        mr['deleteFlag'] = data.delete_flag

    return mr


def fetch_haulier_data(hid: int = 0):
    """Fetches haulier information from the database.

    Args:
        hid (int, optional): Haulier ID. If provided, fetches data for the specific haulier.
                             If not provided (default), retrieves information for all hauliers.

    Returns:
        list or dict: If hid is None, returns a list of dictionaries containing details of all hauliers
                      with keys: 'haulier_id', 'haulier_name', 'haulier_ref', 'haulier_address'.
                      If hid is provided and a haulier exists with that ID, returns a dictionary
                      containing details of that haulier with the same keys.
                      Returns an empty list if no hauliers are found when hid is None.
                      Returns an empty dictionary if no haulier is found for the provided hid.
    """
    if hid == 0:
        # Fetch information for all hauliers
        data = Haulier.query.all()
        mylist = []
        
        if data:
            for item in data:
                mr = {}
                mr['haulierId'] = item.hid
                mr['companyName'] = item.company_name
                mr['registrationNumber'] = item.registration_number
                mr['address'] = item.address
                mr['deleteFlag'] = item.delete_flag
                mylist.append(mr)
                
        return mylist

    # Fetch information for a specific haulier with provided hid
    data = Haulier.query.filter_by(hid=hid).first()
    mr = {}
    if data:
        mr['haulierId'] = data.hid
        mr['companyName'] = data.company_name
        mr['registrationNumber'] = data.registration_number
        mr['address'] = data.address
        mr['deleteFlag'] = data.delete_flag

    return mr


def fetch_user_data(user_id: int = 0):
    """Fetches user information from the database.

    Args:
        user_id (int, optional): User ID. If provided, fetches data for the specific user.
                                 If not provided (default), retrieves information for all users.

    Returns:
        list or dict: If user_id is None, returns a list of dictionaries, each containing user details
                      with keys: 'user_id', 'first_name', 'last_name', 'full_name', 'email',
                      'admin_type', 'activated'.
                      If user_id is provided and a user exists with that ID, returns a dictionary
                      containing user details with the same keys.
                      Returns an empty list if no users are found when user_id is None.
                      Returns an empty dictionary if no user is found for the provided user_id.
    """
    #from extensions import db, User

    if user_id == 0:
        # Fetch information for all users
        data = User.query.all()
        user_list = []
        if data:
            for user in data:
                user_info = {}
                user_info['userId'] = user.id
                user_info['firstName'] = user.fname
                user_info['lastName'] = user.sname
                user_info['fullName'] = f"{user.sname} {user.fname}"
                user_info['email'] = user.email
                user_info['adminType'] = user.admin_type
                user_info['activated'] = user.activated
                user_info['permissions'] = user_permissions(user.admin_type)
                user_list.append(user_info)
        return user_list


    # Fetch information for a specific user with provided user_id
    data = User.query.filter_by(id=user_id).first()
    user_info = {}
    if data:
        user_info['userId'] = data.id
        user_info['firstName'] = data.fname
        user_info['lastName'] = data.sname
        user_info['fullName'] = f"{data.sname} {data.fname}"
        user_info['email'] = data.email
        user_info['adminType'] = data.admin_type
        user_info['activated'] = data.activated
        user_info['permissions'] = user_permissions(data.admin_type)
        return user_info

    return user_info  # Returns an empty dictionary if no user is found for the provided user_id


def fetch_weight_records(weight_log_id: int = 0):
    
    if weight_log_id == 0:
        recs = db.session.query(WeightLog).order_by(WeightLog.wid.desc()).all()
        data = []
        if recs:
            for worker in recs:
                tym = worker.initial_time.strftime('%I:%M:%S %p') if worker.initial_time else ""
                date = worker.initial_time.strftime('%d-%m-%Y') if worker.initial_time else ""
                tym2 = worker.final_time.strftime('%I:%M:%S %p') if worker.final_time else ""
                date2 = worker.final_time.strftime('%d-%m-%Y') if worker.final_time else ""
                # get haulier info
                haulier_info = Haulier.query.filter_by(hid=worker.haulier_id).first()
                haulier_name = haulier_info.company_name if haulier_info else ''
                haulier_id = worker.haulier_id
                # get customer info
                customer_info = Customer.query.filter_by(cid=worker.customer_id).first()
                customer_name = customer_info.customer_name if customer_info else ''

                mr = {'product': worker.product, 'orderNumber': worker.order_number, 'destination': worker.destination,
                      'vehicleName': worker.vehicle_name, 'vehicleId': worker.vehicle_id,
                      'driverPhone': worker.driver_phone, 'driverName': worker.driver_name,
                      'customerId': worker.customer_id, 'haulierName': haulier_name,
                      'customerName': customer_name,
                      'initialWeight': float(worker.initial_weight),
                      'initialTime': f"{date} {tym}", 'finalWeight': float(worker.final_weight) if isinstance(worker.final_weight,int) else None,
                      'finalTime': f"{date2} {tym2}", 'weightRecordId': worker.wid, 'haulierId': haulier_id,
                      'ticketReady': True if worker.final_weight else False,
                      'waybillReady': True if WaybillLog.query.filter_by(weight_log_id=worker.wid).first() else False,
                      #'approvalStatus': 'approved' if WaybillLog.query \
                          #.filter_by(weight_log_id=worker.wid, approval_status='approved').first() else 'pending',
                      }
                mr['waybillRecord'] = fetch_waybill_record(worker.wid)
                mr['approvalStatus'] = mr['waybillRecord']['approvalStatus'] if mr['waybillRecord'] != {} else 'pending'
                
                #print("WaybillReady?: ",mr['waybillReady'])
                data.append(mr)
    else:
        worker = db.session.query(WeightLog).filter_by(wid=weight_log_id).first()
        data = {}

        if worker:
            tym = worker.initial_time.strftime('%I:%M:%S %p') if worker.initial_time else ""
            date = worker.initial_time.strftime('%d-%m-%Y') if worker.initial_time else ""
            tym2 = worker.final_time.strftime('%I:%M:%S %p') if worker.final_time else ""
            date2 = worker.final_time.strftime('%d-%m-%Y') if worker.final_time else ""
            # get haulier info
            haulier_info = Haulier.query.filter_by(hid=worker.haulier_id).first()
            haulier_name = haulier_info.company_name if haulier_info else ''
            haulier_id = worker.haulier_id
            # get customer info
            customer_info = Customer.query.filter_by(cid=worker.customer_id).first()
            customer_name = customer_info.customer_name if customer_info else ''

            mr = {
                    'product': worker.product, 'orderNumber': worker.order_number, 'destination': worker.destination,
                    'vehicleName': worker.vehicle_name, 'vehicleId': worker.vehicle_id,
                    'driverPhone': worker.driver_phone, 'driverName': worker.driver_name,
                    'customerId': worker.customer_id, 'haulierName': haulier_name,
                    'customerName': customer_name,
                    'initialWeight': float(worker.initial_weight), 'haulierId': haulier_id,
                    'initialTime': f"{date} {tym}", 'finalWeight': float(worker.final_weight) if isinstance(worker.final_weight,int) else None,
                    'finalTime': f"{date2} {tym2}", 'weightRecordId': worker.wid,
                    'ticketReady': True if worker.final_weight else False,
                    'waybillReady': True if WaybillLog.query.filter_by(weight_log_id=worker.wid).first() else False,
                    #'approvalStatus': 'approved' if WaybillLog.query \
                        #.filter_by(weight_log_id=worker.wid, approval_status='approved').first() else 'pending',
                }
            mr['waybillRecord'] = fetch_waybill_record(worker.wid)
            mr['approvalStatus'] = mr['waybillRecord']['approvalStatus'] if mr['waybillRecord'] != {} else 'pending'

            #print("WaybillReady?: ",mr['waybillReady'])

            data.update(mr)

    return data

def fetch_weight_record(vehicle_id: int) -> dict:
    """
    This function will fetch data for the last uncompleted (with final_weight == null) weight record for given vehicle id
    if no record is found, it returns an empty dictionary.
    """
    mr = {}
    worker = WeightLog.query.filter_by(vehicle_id=vehicle_id).order_by(WeightLog.wid.desc()).first()
    if worker:
        # convert the datetime objects into strings
        tym = worker.initial_time.strftime('%I:%M:%S %p') if worker.initial_time else ""
        date = worker.initial_time.strftime('%d-%m-%Y') if worker.initial_time else ""
        tym2 = worker.final_time.strftime('%I:%M:%S %p') if worker.final_time else ""
        date2 = worker.final_time.strftime('%d-%m-%Y') if worker.final_time else ""
        
        # get haulier information
        haulier_info = Haulier.query.filter_by(hid=worker.haulier_id).first()
        haulier_name = haulier_info.company_name if haulier_info else ''
        haulier_id = haulier_info.hid if haulier_info else 0

        # compute weight record data
        mr = {'product': worker.product, 'orderNumber': worker.order_number, 'destination': worker.destination,
              'vehicleName': worker.vehicle_name, 'vehicleId': worker.vehicle_id,
              'driverPhone': worker.driver_phone, 'driverName': worker.driver_name,
              'customerId': worker.customer_id, 'haulierName': haulier_name,
              'initialWeight': worker.initial_weight, 'haulierId': haulier_id,
              'initialTime': f"{date}\n{tym}", 'finalWeight': worker.final_weight,
              'finalTime': f"{date2}\n{tym2}", 'weightRecordId': worker.wid,
              'ticketReady': True if worker.final_weight else False,
              }
    return mr


def fetch_product_data(product_id:int=0):
    
    if product_id == 0:
        recs = db.session.query(Product).order_by(Product.pid.desc()).all()
        
        data = []
        if recs:
            for product in recs:
                mr = {'productId': product.pid, 
                      'productCode': product.product_code, 'productDescription': product.description,
                      'countPerCase': product.count_per_case, 'weightPerCount': product.weight_per_count,
                      'registrationDate': product.reg_date.strftime('%Y-%m-%dT%H:%M:%S'), 'deleteFlag': product.delete_flag}
                data.append(mr)
    else:
        recs = db.session.query(Product).filter_by(pid=product_id).first()
        data = {}
        if recs:
            product = recs
            mr = {'productId': product.pid, 'productCode': product.product_code, 'productDescription': product.description,
                    'countPerCase': product.count_per_case, 'weightPerCount': product.weight_per_count,
                    'registrationDate': product.reg_date.strftime('%Y-%m-%dT%H:%M:%S'), 'deleteFlag': product.delete_flag}
            data.update(mr)

    return data


def fetch_table_data(weight_log_id):
    """ prepares data to be used to populate waybill table"""

    ticket_data = WeightLog.query.filter_by(wid=weight_log_id).first()
    waybill_data = WaybillLog.query.filter_by(weight_log_id=weight_log_id).first()

    # format data
    slip = {}
    slip['date'] = ticket_data.initial_time.strftime('%A, %dth of %B, %Y  %I:%M:%S %p')
    slip['vehicle id'] = ticket_data.vehicle_id
    slip['customer'] = ticket_data.customer.customer_name if ticket_data.customer else "No Name"
    slip['haulier'] = ticket_data.haulier.company_name if ticket_data.haulier else 'No Name'
    slip['destination'] = ticket_data.destination
    slip['product'] = ticket_data.product
    slip['ticket number'] = ''
    slip['delivery number'] = ''
    slip['order number'] = ticket_data.order_number
    slip['gross mass'] = (f"{ticket_data.final_weight} {func.get_unit()}  | "
                          f"{ticket_data.final_time.strftime('%A, %dth of %B, %Y  %I:%M:%S %p')}")
    slip['tare mass'] = (f"{ticket_data.initial_weight} {func.get_unit()}  | "
                         f"{ticket_data.initial_time.strftime('%A, %dth of %B, %Y  %I:%M:%S %p')}")
    slip['net mass'] = ticket_data.final_weight - ticket_data.initial_weight
    slip['driver'] = ticket_data.driver_name

    # waybill initial info
    wb_data = {}
    wb_data['waybill number'] = waybill_data.waybill_number
    wb_data['date'] = waybill_data.reg_date.strftime('%A, %dth of %B, %Y  %I:%M:%S %p')
    wb_data['location'] = ''
    wb_data['ugee ref number'] = 'D844'
    wb_data['customer ref number'] = waybill_data.customer.registration_number
    wb_data['customer name'] = waybill_data.customer.customer_name if waybill_data.customer else 'No Name'
    wb_data['delivery address'] = waybill_data.delivery_address
    wb_data['vehicle id'] = ticket_data.vehicle_id
    wb_data['transporter'] = waybill_data.customer.customer_name if waybill_data.customer else 'No Name'

    # product
    product_list = json.loads(waybill_data.product_info)

    # bad products
    bad_product_list = json.loads(waybill_data.bad_product_info)

    # files
    if waybill_data.file_link:
        files = json.loads(waybill_data.file_link)
    else:
        files = []

    ticket_data = slip  # dict
    waybill_data = wb_data  # dict
    products = product_list  # list
    bad_products = bad_product_list  # list

    # format table1-data: weighbridge slip
    ticket_list = [x.title() for x in ticket_data.keys()]
    html = ''
    for item in ticket_list:
        html += '<tr>'
        html += f'<th>{item}</ht>'
        html += f"<td>{ticket_data.get(item.lower())}</td>"
        html += '</tr>'
    table1_data = html

    # format table2-data: waybill data
    waybill_list = [x.title() for x in waybill_data.keys()]
    html = ''
    for item in waybill_list:
        html += '<tr>'
        html += f'<th>{item}</th>'
        html += f"<td>{waybill_data.get(item.lower())}</td>"
        html += '</tr>'
    table2_data = html

    # format table3-data: product data
    html = ''
    if len(products) > 0:
        for item in products:
            html += '<tr>'
            html += f"<td>{item['description']}</td>"
            html += f"<td>{item['code']}</td>"
            html += f"<td>{item['count']}</td>"
            html += f"<td>{item['weight']}</td>"
            html += f"<td>{item['quantity']}</td>"
            html += f"<td>{item['remarks']}</td>"
            html += '</tr>'
    table3_data = html

    # format table4-data: product data
    html = ''
    if len(bad_products) > 0:
        for item in bad_products:
            html += '<tr>'
            html += f"<td>{item['description']}</td>"
            html += f"<td>{item['damage']}</td>"
            html += f"<td>{item['shortage']}</td>"
            html += f"<td>{item['batch_number']}</td>"
            html += '</tr>'
    table4_data = html

    return table1_data, table2_data, table3_data, table4_data

# create a function that sends notifications to users
def send_notification(scope:str, user_id:int=0) -> bool:
    result = False
    """ if scope is 'all', send notification to all users
        Approach:
            1. query all users in user table
            2. for each user, query all notifications applicable to him/her
            3. create a notification message for each notification and add to a list
            4. send the notification list to user via socketio communication
    """
    users = None
    if scope == "all":
        users = User.query.all()
    elif scope == "specific":
        users = User.query.filter_by(id=user_id).all()
    else:
        users = User.query.filter_by(admin_type=scope).all()

    if users is not None:
        for user in users:
            notifs = Notification.query.filter(
                                            or_(
                                                Notification.recipient_id == user.id,
                                                Notification.message_scope == user.admin_type,
                                                Notification.message_scope == 'all'
                                            )
                                        ).order_by(Notification.created_at.desc()).all()
            if notifs:
                notifications = []
                for notif in notifs:
                    # check if notification has been marked deleted by user
                    deleted = DeletedNotifications.query.filter_by(notification_id=notif.id, user_id=user.id).first()
                    if deleted is None:
                        status = 'read' if notif.read else 'unread'
                        notification = func.create_notification(notif.id, notif.message, notif.created_at, status)
                        notifications.append(notification)
                # emit notifications to user
                socketio.emit(f'notification_response_{user.id}', json.dumps(notifications))
            
        result= True

    return result

# create a function that logs notifications
def log_notification(message:str, recipient_id:int, scope:str='all', request_id=None) -> bool:
    result = False
    """ Approach:
            1. create a new notification record in the notification table
            2. send the notification to the recipient
    """
    new_notif = Notification()
    new_notif.approval_request_id=request_id
    new_notif.message=message
    new_notif.recipient_id=recipient_id
    new_notif.message_scope=scope
    new_notif.created_at=datetime.now()

    db.session.add(new_notif)
    db.session.commit()
    #print(f"Notification time {new_notif.created_at.strftime('%d-%m-%Y %I:%M:%S %p')}")
    # send notification to recipient
    send_notification(scope, recipient_id)
    result = True
    return result

def get_vehicle_id(waybill_id:int) -> str:
    """ fetches the vehicle id from the weight log table using the waybill id
    """
    waybill = WaybillLog.query.filter_by(wid=waybill_id).first()
    if waybill:
        weight_record = WeightLog.query.filter_by(wid=waybill.weight_log_id).first()
        if weight_record:
            return weight_record.vehicle_id
        
    return '#VehicleId'

def fetch_app_settings(company_id:int=0)->dict:
    """ fetches the application settings for the company
    """
    settings = {}
    if company_id != 0:
        config = AppSetting.query.filter_by(company_id=company_id).first()
        print(f"Config: {config}")
        if config:
            settings.update(json.loads(config.config))
    return settings

def fetch_recipient_email(scope:str,user_id:int=0)->str:
    if scope=='all':
        users = User.query.all()
    elif scope=='one':
        users = User.query.filter_by(id=user_id).all()
    else:
        users = User.query.filter_by(admin_type=scope).all()
    
    emails = []
    if users:
        for user in users:
            emails.append(user.email)
    return ";".join(emails)

def user_permissions(admin_type: str)->dict:
    """ returns the permissions for the user based on the admin type
    """
    permissions = {}
    user    = {'canAddUser': False, 'canEditUser': False, 'canDeleteUser': False, 'canViewUser': True, 
               'canAddProduct': False, 'canEditProduct': False, 'canDeleteProduct': False, 'canViewProduct': True,
               'canAddCustomer': False, 'canEditCustomer': False, 'canDeleteCustomer': False, 'canViewCustomer': True,
               'canAddHaulier': False, 'canEditHaulier': False, 'canDeleteHaulier': False, 'canViewHaulier': True,
               'canAddWeightRecord': True, 'canEditWeightRecord': True, 'canDeleteWeightRecord': False, 'canViewWeightRecord': True,
               'canAddWaybill': False, 'canEditWaybill': False, 'canDeleteWaybill': False, 'canViewWaybill': True,
               'canApproveWaybill': False, 'canDeclineWaybill': False,
               'canCreateApprovalRequest': False, 'canViewApprovalRequest': True, 'canDeleteApprovalRequest': False,
               'canChangeUserPassword': False, 'canViewNotifications': True, 'canDeleteNotifications': True,
               'canViewDeletedNotifications': False, 'canViewAppSettings': True,
               'canEditAppSettings': False, 'canViewSecondaryApprovers': True, 'canAddSecondaryApprovers': False,
               'canEditSecondaryApprovers': False, 'canDeleteSecondaryApprovers': False,
               'canViewAuditTrail': False, 'canEditAuditTrail': False, 'canDeleteAuditTrail': False, 'canExportAuditTrail': False,
               'canPrintWaybill': True, 'canPrintTicket': True}
    super  = {'canAddUser': True, 'canEditUser': True, 'canDeleteUser': True, 'canViewUser': True,
                'canAddProduct': True, 'canEditProduct': True, 'canDeleteProduct': True, 'canViewProduct': True,
                'canAddCustomer': True, 'canEditCustomer': True, 'canDeleteCustomer': True, 'canViewCustomer': True,
                'canAddHaulier': True, 'canEditHaulier': True, 'canDeleteHaulier': True, 'canViewHaulier': True,
                'canAddWeightRecord': True, 'canEditWeightRecord': True, 'canDeleteWeightRecord': True, 'canViewWeightRecord': True,
                'canAddWaybill': True, 'canEditWaybill': True, 'canDeleteWaybill': True, 'canViewWaybill': True,
                'canApproveWaybill': True, 'canDeclineWaybill': True,
                'canCreateApprovalRequest': True, 'canViewApprovalRequest': True, 'canDeleteApprovalRequest': True,
                'canChangeUserPassword': True, 'canViewNotifications': True, 'canDeleteNotifications': True,
                'canViewDeletedNotifications': True, 'canViewAppSettings': True,
                'canEditAppSettings': True, 'canViewSecondaryApprovers': True, 'canAddSecondaryApprovers': True,
                'canEditSecondaryApprovers': True, 'canDeleteSecondaryApprovers': True,
                'canViewAuditTrail': True, 'canEditAuditTrail': True, 'canDeleteAuditTrail': True, 'canExportAuditTrail': True,
                'canPrintWaybill': True, 'canPrintTicket': True}
    approver = {'canAddUser': False, 'canEditUser': False, 'canDeleteUser': False, 'canViewUser': True,
                'canAddProduct': False, 'canEditProduct': False, 'canDeleteProduct': False, 'canViewProduct': True,
                'canAddCustomer': False, 'canEditCustomer': False, 'canDeleteCustomer': False, 'canViewCustomer': True,
                'canAddHaulier': False, 'canEditHaulier': False, 'canDeleteHaulier': False, 'canViewHaulier': True,
                'canAddWeightRecord': False, 'canEditWeightRecord': False, 'canDeleteWeightRecord': False, 'canViewWeightRecord': True,
                'canAddWaybill': False, 'canEditWaybill': False, 'canDeleteWaybill': False, 'canViewWaybill': True,
                'canApproveWaybill': True, 'canDeclineWaybill': True,
                'canCreateApprovalRequest': False, 'canViewApprovalRequest': True, 'canDeleteApprovalRequest': False,
                'canChangeUserPassword': True, 'canViewNotifications': True, 'canDeleteNotifications': True,
                'canViewDeletedNotifications': False, 'canViewAppSettings': True,
                'canEditAppSettings': False, 'canViewSecondaryApprovers': True, 'canAddSecondaryApprovers': False,
                'canEditSecondaryApprovers': False, 'canDeleteSecondaryApprovers': False,
                'canViewAuditTrail': False, 'canEditAuditTrail': False, 'canDeleteAuditTrail': False, 'canExportAuditTrail': False,
                'canPrintWaybill': True, 'canPrintTicket': True}
    admin = {'canAddUser': False, 'canEditUser': False, 'canDeleteUser': False, 'canViewUser': True,
                'canAddProduct': True, 'canEditProduct': True, 'canDeleteProduct': True, 'canViewProduct': True,
                'canAddCustomer': True, 'canEditCustomer': True, 'canDeleteCustomer': True, 'canViewCustomer': True,
                'canAddHaulier': True, 'canEditHaulier': True, 'canDeleteHaulier': True, 'canViewHaulier': True,
                'canAddWeightRecord': False, 'canEditWeightRecord': True, 'canDeleteWeightRecord': False, 'canViewWeightRecord': True,
                'canAddWaybill': True, 'canEditWaybill': True, 'canDeleteWaybill': True, 'canViewWaybill': True,
                'canApproveWaybill': False, 'canDeclineWaybill': False,
                'canCreateApprovalRequest': True, 'canViewApprovalRequest': True, 'canDeleteApprovalRequest': True,
                'canChangeUserPassword': False, 'canViewNotifications': True, 'canDeleteNotifications': True,
                'canViewDeletedNotifications': False, 'canViewAppSettings': True,
                'canEditAppSettings': False, 'canViewSecondaryApprovers': True, 'canAddSecondaryApprovers': True,
                'canEditSecondaryApprovers': True, 'canDeleteSecondaryApprovers': True,
                'canViewAuditTrail': False, 'canEditAuditTrail': False, 'canDeleteAuditTrail': False, 'canExportAuditTrail': False,
                'canPrintWaybill': True, 'canPrintTicket': True}
    if admin_type == 'user':
        permissions = user
    elif admin_type == 'super':
        permissions = super
    elif admin_type == 'approver':
        permissions = approver
    elif admin_type == 'admin':
        permissions = admin

    return permissions

            
    

