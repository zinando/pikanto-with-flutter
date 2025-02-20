from datetime import date, datetime
#from flask import current_app as app
from flask import request, session
from . import socketio, app
from werkzeug.security import generate_password_hash, check_password_hash
from .models import (DeletedNotifications, User, Product, Haulier, Customer, WeightLog, 
                     WaybillLog, Notification, ReadNotifications, db, ApprovalRequest,
                     Approval, SecondaryApprover, AppSetting)
from . import resources as resource
from . import functions as myfunc
from . import action as act
from pikanto.appclass.approval_requestclass import ApprovalRequestClass
import json
from flask_socketio import emit

@app.route('/', methods=['GET', 'POST'])
def home():
    return "Hello, World!" 

@socketio.on('test')
def test(data):

    emit('response', f'I responded to your test: {data}')
    
@socketio.on('fetch_notifications')
def fetch_notifications(data):
    try:
        data = json.loads(data)
        resp = resource.send_notification(scope='specific', user_id=data['userId'])
        if not resp:
            raise Exception('Error fetching notifications for user: {}'.format(data['userId']))
    except Exception as e:
        pass

@socketio.on('update_notification')
def update_notification(data):
    try:
        data = json.loads(data)
        check = ReadNotifications.query.filter_by(user_id=data["userId"], notification_id=data["notificationId"]).first()
        if check is None:
            log = ReadNotifications()
            log.user_id = data["userId"]
            log.notification_id = data["notificationId"]
            db.session.add(log)
            db.session.commit()
            
        resp = resource.send_notification(scope='specific', user_id=data['userId'])
        if not resp:
            raise Exception('Error fetching notifications for user: {}'.format(data['userId']))
    except Exception as e:
        pass

@socketio.on('update_notifications')
def update_notifications(data):
    try:
        data = json.loads(data)
        notifications = data['notifications']
        for notification in notifications:
            check = ReadNotifications.query.filter_by(user_id=data["userId"], notification_id=notification['notificationId']).first()
            if check is None:
                log = ReadNotifications()
                log.user_id = data["userId"]
                log.notification_id = notification['notificationId']
                db.session.add(log)
                db.session.commit()
            
        resp = resource.send_notification(scope='specific', user_id=data['userId'])
        if not resp:
            raise Exception('Error fetching notifications for user: {}'.format(data['userId']))
    except Exception as e:
        pass

@socketio.on('delete_notifications')
def delete_notifications(data):
    try:
        data = json.loads(data)
        notifications = data['notifications']
        for notification in notifications:
            log = DeletedNotifications()
            log.user_id = data["userId"]
            log.notification_id = notification['notificationId']
            db.session.add(log)
            db.session.commit()
            
        resp = resource.send_notification(scope='specific', user_id=data['userId'])
        if not resp:
            raise Exception('Error fetching notifications for user: {}'.format(data['userId']))
    except Exception as e:
        pass

@socketio.on('save_app_settings')
def save_app_settings(data):
    try:
        data = json.loads(data)
        # check if there is existing record
        check = resource.fetch_app_settings(data['companyId'])
        if (isinstance(check, dict) and len(check.keys()) > 0) or data['companyId'] == 0:
            raise Exception(f'Settings already exist for company: {data["companyId"]} or companyId is invalid.')
        else:
            log = AppSetting()
            log.company_id = data['companyId']
            log.config = json.dumps(data['settings'])
            db.session.add(log)
            db.session.commit()
    except Exception as e:
        pass

@socketio.on('update_app_settings')
def update_app_settings(data):
    try:
        data = json.loads(data)
        # check if there is existing record
        check = resource.fetch_app_settings(data['companyId'])
        if isinstance(check, dict) and len(check.keys()) > 0:
            AppSetting.query.filter_by(company_id=data['companyId']).update({
                'config': json.dumps(data['settings'])
            })
            db.session.commit()
        else:
            raise Exception(f'Settings do not exist for company: {data["companyId"]}')
    except Exception as e:
        pass

@app.route('/api/v1/fetch_ip', methods = ['GET', 'POST'])
def fetch_ip_address():
    return myfunc.get_ip_address()

@app.route('/api/v1/user/<string:action>', methods=['GET', 'POST', 'PUT', 'DELETE'])
def user(action):
    if action == 'save_data':
        data = request.get_json()
        # Check that first_name, last_name, admin_type, email and password are not empty
        if not data['first_name'] or not data['last_name'] or not data['admin_type'] or not data['email'] or not data['password']:
            return json.dumps({'status': 2, 'data': data, 'message': 'First name, last name, admin type, email and password cannot be empty',
                               'error': ['First name, last name, admin type, email and password cannot be empty']}), 200

        # check if user already exists
        check = User.query.filter_by(email=data['email']).count()
        if check > 0:
            return json.dumps({'status': 2, 'data': data, 'message': 'Another account is using this email',
                               'error': ['Another account is using this email']}), 200
        
        # validate password
        check_password = myfunc.check_password_strength(data['password'])
        if check_password['status'] > 1:
            return json.dumps(check_password), 200

        # Addd user data
        log = User()
        log.fname = data['first_name'].title()
        log.sname = data['last_name'].title()
        log.email = data['email']
        log.admin_type = data['admin_type']
        log.password = generate_password_hash(data['password'])

        try:
            db.session.add(log)
            db.session.commit()
            user_id = log.id

            # log audit trail if 'actor' is in data and is not equal to 0
            if 'actor' in data and data['actor'] != 0:
                userId = data['actor']
                title = 'New user added.'
                msg = f'{data["firstName"]} {data["lastName"]} was registered.'
                act.log_audit_trail(user_id=userId, action=title,action_details=msg)
        except Exception as e:
            db.session.rollback()  # Rollback the changes in case of an error
            return json.dumps({'status': 2, 'data': data, 'message': 'Error adding user data', 'error': [str(e)]}), 200

        # fetch the data
        worker = resource.fetch_user_data(user_id)  # all users
        message = f"Information for {data['first_name']} has been added successfully."
        return json.dumps({'status': 1, 'data': worker, 'message': message, 'error': [None]}), 200

    elif action == 'edit_user_data':
        data = request.get_json()

        # check if given email already exists for another user
        check = db.session.query(User).filter(User.email == data['email'], User.id != data['userId']).count()
        if check > 0:
            return json.dumps({'status': 2, 'data': data, 'message': 'Another account is using this email',
                               'error': ['Another account is using this email']})

        try:
            db.session.query(User).filter(User.id == data['userId']).update({
                'fname': data['firstName'].title(),
                'sname': data['lastName'].title(),
                'email': data['email'],
                'admin_type': data['adminType']
            })
            if 'password' in data:
                if data['password']:
                    db.session.query(User).filter(User.id == data['userId']).update({
                        'password': generate_password_hash(data['password'])
                    })
            db.session.commit()

            # log audit trail if 'actor' is in data and is not equal to 0
            if 'actor' in data and data['actor'] != 0:
                userId = data['actor']
                title = 'User data updated.'
                msg = f'{data["firstName"]} {data["lastName"]}\'s data was updated.'
                act.log_audit_trail(user_id=userId, action=title,action_details=msg)
        except Exception as e:
            db.session.rollback()  # Rollback the changes in case of an error
            return json.dumps({'status': 2, 'data': data, 'message': f'Error updating user data:\n {e}', 'error': [str(e)]})

        # fetch the data
        worker = resource.fetch_user_data()  # all users
        message = f"Information for {data['firstName']} has been updated successfully."
        return json.dumps({'status': 1, 'data': worker, 'message': message, 'error': [None]})

    elif action == "signup-super-admin":
        # db.create_all()
        data = request.get_json()

        # check if super admin exists
        check = User.query.filter_by(admin_type="super").count()
        if check > 0:
            message = "Super admin already exists. Get a new account from super admin."
            return json.dumps({'status': 2, 'data': data, 'message': message, 'error': [message]})

        # check if email already exists
        check = User.query.filter_by(email=data['email']).count()
        if check > 0:
            message = "This email is already in use by another user."
            return json.dumps({'status': 2, 'data': data, 'message': message, 'error': [message]})

        # check password strength
        check_password = myfunc.check_password_strength(data['password'])
        if check_password['status'] > 1:
            return json.dumps(check_password)

        # save user data
        log = User()
        log.fname = data['firstName'].title()
        log.sname = data['lastName'].title()
        log.admin_type = "super"
        log.email = data['email']
        log.password = generate_password_hash(data['password'])

        try:
            db.session.add(log)
            db.session.commit()

            # log audit trail
            title = 'Super admin added.'
            msg = f'{data["firstName"]} {data["lastName"]} was registered as super admin.'
            act.log_audit_trail(user_id=log.id, action=title, action_details=msg)
        except Exception as e:
            db.session.rollback()  # Rollback the changes in case of an error
            return json.dumps({'status': 2, 'data': data, 'message': 'Error adding user data', 'error': [str(e)]})

        message = "Sign up was successful. Please login with your new credentials."
        return json.dumps({'status': 1, 'data': data, 'message': message, 'error': [None]})

    elif action == "login-user":
        data = request.get_json()

        # check if user exists
        check = User.query.filter_by(email=data['email']).first()
        if not check:
            message = "User not found."
            return json.dumps({'status': 2, 'data': data, 'message': message, 'error': [message]})

        # validate password
        if not check_password_hash(check.password, data['password']):
            message = "Wrong password."
            return json.dumps({'status': 2, 'data': data, 'message': message, 'error': [message]})

        if check.activated == 0:
            message = "user is not active, please contact super admin"
            return json.dumps({'status': 2, 'data': data, 'message': message, 'error': [message]})

        # fetch the data
        worker = resource.fetch_user_data(check.id)
        workers = resource.fetch_user_data()

        message = f'welcome {check.fname} {check.sname}. Please wait while the app loads...'
        return json.dumps({'status': 1, 'data': worker, 'users': workers, 'message': message, 'error': [None]})

    elif action == 'get-current-user':
        data = request.get_json()

        # check if user exists
        check = User.query.filter_by(id=data['user_id']).first()
        if check:
            worker = resource.fetch_user_data(check.id)
            return json.dumps({'status': 1, 'data': worker, 'message': 'success', 'error': [None]}), 200

        message = "User is not authenticated"
        return json.dumps({'status': 404, 'data': data, 'message': message, 'error': [message]}), 200
    
    elif action == 'fetch_users' and request.method == 'GET':
        #data = request.get_json()
        worker = resource.fetch_user_data()
        return json.dumps({'status':1, 'data':worker, 'message':'Success', 'error':[None]}), 200

    elif action == 'logout-user':
        data = request.get_json()

        # check if system ip is in session
        if data['ip'] in session:
            del session[data['ip']]

        message = "Logged out successfully"
        return json.dumps({'status': 1, 'data': None, 'message': message, 'error': [None]})

    elif action == 'delete_user' and request.method == 'DELETE':
        data = request.get_json()
        message = "User deleted successfully."
        status = 1
        error = None

        # check if user exists
        check = User.query.filter_by(id=data['userId']).first()

        if not check:
            message = 'user not found.'
            status = 2
            error = message
        else:
            User.query.filter_by(id=data['userId']).delete()
            db.session.commit()

            # log audit trail if 'actor' is in data and is not equal to 0
            if 'actor' in data and data['actor'] != 0:
                userId = data['actor']
                title = 'User deleted.'
                msg = f'{check.fname} {check.sname} was deleted.'
                act.log_audit_trail(user_id=userId, action=title,action_details=msg)
        users = resource.fetch_user_data()

        return json.dumps({'status': status, 'data': users, 'message': message, 'error': [error]})
    
    elif action == 'send_password_reset_code':
        data = request.get_json()
        status = 2
        message = "Email not regsitered."
        error = [message]

        # check that data contains email key
        if 'email' not in data:
            message = "Email not provided."
            return json.dumps({'status': status, 'data': data, 'message': message, 'error': [message]})
        # check if email exists
        check = User.query.filter_by(email=data['email']).first()
        if check:
            status = 1
            message = "Password reset code sent to email."
            code = myfunc.generate_random_numeric_codes(6)
            error = None

            # send password reset code to email
            msg = f'Your password reset code is: <b>{code}</b>'
            title = 'Reset Password.'
            recipient = data['email']
            copy_email = resource.fetch_recipient_email('super')

            resp = act.send_email_notification(message=msg,subject=title,recipient_email=recipient,copy_to=copy_email,app_id=data["appId"])
        return json.dumps({'status': status, 'data': code, 'message': message, 'error': error})
    
    elif action == 'change_password':
        data = request.get_json()
        status = 2
        message = "User not found."
        error = [message]

        # check if old_password matches with current password
        check = User.query.filter_by(email=data['email']).first()
        if check:
            if not check_password_hash(check.password, data['oldPassword']):
                # check if actor is super or approver
                if 'actor' in data:
                    check_again = User.query.filter_by(id=data['actor']).first()
                    if check_again and (check_again.admin_type != 'super' and check_again.admin_type != 'approver'):
                        message = "Action not authorized!"
                        return json.dumps({'status': status, 'data': data, 'message': message, 'error': [message]})
                else:        
                    message = "Old password is incorrect."
                    return json.dumps({'status': status, 'data': data, 'message': message, 'error': [message]})
            # check password strength
            check_password = myfunc.check_password_strength(data['newPassword'])
            if check_password['status'] > 1:
                return json.dumps(check_password)

            status = 1
            message = "Password changed successfully."
            error = None
            check.password = generate_password_hash(data['newPassword'])
            db.session.commit()

            # log audit trail
            userId = data['actor'] if 'actor' in data else check.id
            title = 'Password changed.'
            msg = f'{check.fname} {check.sname}\'s password was changed.'
            act.log_audit_trail(user_id=userId, action=title,action_details=msg)
        return json.dumps({'status': status, 'data': None, 'message': message, 'error': error}), 200

    message = "Request action not recognized"
    return json.dumps({'status': 2, 'data': None, 'message': message, 'error': [message]}), 200

@app.route('/api/v1/product/<string:action>', methods=['POST'])
def product(action):
    if action == 'add_new':
        data = request.get_json()

        # check if product already exists
        check = Product.query.filter_by(product_code=data['productCode']).count()
        if check > 0:
            return json.dumps({'status': 2, 'data': data, 'message': 'Product already exists',
                               'error': ['Product already exists']}), 200
        
        # check if productCode and productDescription are not empty
        if not data['productCode'] or not data['productDescription']:
            return json.dumps({'status': 2, 'data': data, 'message': 'Product code and or description cannot be empty',
                               'error': ['Product code and or description cannot be empty']}), 200

        log = Product()
        log.product_code = data['productCode']
        log.description = data['productDescription']
        log.count_per_case = data['countPerCase']
        log.weight_per_count = data['weightPerCount']

        try:
            db.session.add(log)
            db.session.commit()
            product_id = log.pid
            # log audit trail if 'actor' is in data and is not equal to 0
            if 'actor' in data and data['actor'] != 0:
                userId = data['actor']
                title = 'New product added.'
                msg = f'{data["productDescription"]} was registered.'
                act.log_audit_trail(user_id=userId, action=title,action_details=msg)
        except Exception as e:
            db.session.rollback()
            return json.dumps({'status': 2, 'data': data, 'message': f'Error adding product data:\n{e}', 'error': [str(e)]}), 200
        
        # fetch the data
        worker = resource.fetch_product_data(product_id)
        message = f"Product {data['productDescription']} has been added successfully."
        return json.dumps({'status': 1, 'data': worker, 'message': message, 'error': [None]}), 200
    
    elif action == 'fetch_products':
        products = resource.fetch_product_data()
        return json.dumps({'status': 1, 'data': products, 'message': 'success', 'error': [None]}), 200
    
    elif action == 'delete_product':
        data = request.get_json()
        message = "Product deleted successfully."
        status = 1
        error = None
        # check if product exists
        check = Product.query.filter_by(pid=data['productId']).first()
        if not check:
            message = 'Product not found.'
            status = 2
            error = message
        else:
            Product.query.filter_by(pid=data['productId']).delete()
            db.session.commit()
            # log audit trail if 'actor' is in data and is not equal to 0
            if 'actor' in data and data['actor'] != 0:
                userId = data['actor']
                title = 'Product deleted.'
                msg = f'{check.description} was deleted.'
                act.log_audit_trail(user_id=userId, action=title,action_details=msg)
        products = resource.fetch_product_data()
        return json.dumps({'status': status, 'data': products, 'message': message, 'error': [error]}), 200
    
    elif action == 'update_product':
        data = request.get_json()
        message = "Product updated successfully."
        status = 1
        error = None
        # check if product exists
        check = Product.query.filter_by(pid=data['productId']).first()
        if not check:
            message = 'Product not found.'
            status = 2
            error = message
            # check if productCode and productDescription are not empty
            if not data['productCode'] or not data['productDescription']:
                message = 'Product code and or description cannot be empty.'
                status = 2
                error = message

        else:
            Product.query.filter_by(pid=data['productId']).update({
                'product_code': data['productCode'],
                'description': data['productDescription'],
                'count_per_case': data['countPerCase'],
                'weight_per_count': data['weightPerCount']
            })
            db.session.commit()
            # log audit trail if 'actor' is in data and is not equal to 0
            if 'actor' in data and data['actor'] != 0:
                userId = data['actor']
                title = 'Product updated.'
                msg = f'{data["productDescription"]} was updated.'
                act.log_audit_trail(user_id=userId, action=title,action_details=msg)
        products = resource.fetch_product_data()
        return json.dumps({'status': status, 'data': products, 'message': message, 'error': [error]}), 200
    
    message = "Request action not recognized"
    return json.dumps({'status': 2, 'data': None, 'message': message, 'error': [message]}), 200

@app.route('/api/v1/haulier/<string:action>', methods=['GET', 'POST', 'PUT', 'DELETE'])
def haulier(action):
    if action == 'add_new' and request.method == 'POST':
        data = request.get_json()
        # check that registration number, company name and address are not empty
        if not data['registrationNumber'] or not data['companyName'] or not data['address']:
            return json.dumps({'status': 2, 'data': data, 'message': 'Registration number, company name and address cannot be empty',
                               'error': ['Registration number, company name and address cannot be empty']}), 200
        # check if registration number already exists
        check = Haulier.query.filter_by(registration_number=data['registrationNumber']).count()
        if check > 0:
            return json.dumps({'status': 2, 'data': data, 'message': 'Haulier already exists',
                               'error': ['Haulier already exists']}), 200
        # save haulier data
        log = Haulier()
        log.registration_number = data['registrationNumber']
        log.company_name = data['companyName']
        log.address = data['address']
        db.session.add(log)
        db.session.commit()
        haulier_id = log.hid

        # log audit trail if 'actor' is in data and is not equal to 0
        if 'actor' in data and data['actor'] != 0:
            userId = data['actor']
            title = 'New haulier added.'
            msg = f'{data["companyName"]} was registered.'
            act.log_audit_trail(user_id=userId, action=title,action_details=msg)

        # fetch the data
        worker = resource.fetch_haulier_data(haulier_id)
        message = f"Haulier {data['companyName']} has been added successfully."
        return json.dumps({'status': 1, 'data': worker, 'message': message, 'error': [None]}), 200
    
    elif action == 'fetch_hauliers' and request.method == 'GET':
        hauliers = resource.fetch_haulier_data()
        return json.dumps({'status': 1, 'data': hauliers, 'message': 'success', 'error': [None]}), 200
    
    elif action == 'delete_haulier' and request.method == 'DELETE':
        data = request.get_json()
        message = "Haulier deleted successfully."
        status = 1
        error = None
        # check if haulier exists
        check = Haulier.query.filter_by(hid=data['haulierId']).first()
        if not check:
            message = 'Haulier not found.'
            status = 2
            error = message
        else:
            Haulier.query.filter_by(hid=data['haulierId']).delete()
            db.session.commit()

            # log audit trail if 'actor' is in data and is not equal to 0
            if 'actor' in data and data['actor'] != 0:
                userId = data['actor']
                title = 'Haulier deleted.'
                msg = f'{check.company_name} was deleted.'
                act.log_audit_trail(user_id=userId, action=title,action_details=msg)
        hauliers = resource.fetch_haulier_data()
        return json.dumps({'status': status, 'data': hauliers, 'message': message, 'error': [error]}), 200
    
    elif action == 'update_haulier' and request.method == 'PUT':
        data = request.get_json()
        message = "Haulier updated successfully."
        status = 1
        error = None
        # check if haulier exists
        check = Haulier.query.filter_by(hid=data['haulierId']).first()
        if not check:
            message = 'Haulier not found.'
            status = 2
            error = message
            # check that registration number, company name and address are not empty
            if not data['registrationNumber'] or not data['companyName'] or not data['address']:
                message = 'Registration number, company name and address cannot be empty.'
                status = 2
                error = message
        else:
            Haulier.query.filter_by(hid=data['haulierId']).update({
                'registration_number': data['registrationNumber'],
                'company_name': data['companyName'],
                'address': data['address']
            })
            db.session.commit()

            # log audit trail if 'actor' is in data and is not equal to 0
            if 'actor' in data and data['actor'] != 0:
                userId = data['actor']
                title = 'Haulier updated.'
                msg = f'{data["companyName"]} was updated.'
                act.log_audit_trail(user_id=userId, action=title,action_details=msg)
        hauliers = resource.fetch_haulier_data()
        return json.dumps({'status': status, 'data': hauliers, 'message': message, 'error': [error]}), 200

    return json.dumps({'status': 2, 'data': None, 'message': 'Request action not recognized', 'error': ['Request action not recognized']}), 200

@app.route('/api/v1/customer/<string:action>', methods=['GET', 'POST', 'PUT', 'DELETE'])
def customer(action):
    if action == 'add_new' and request.method == 'POST':
        data = request.get_json()
        # check that customer name, registration number and address are not empty
        if not data['customerName'] or not data['registrationNumber'] or not data['address']:
            return json.dumps({'status': 2, 'data': data, 'message': 'Customer name, registration number and address cannot be empty',
                               'error': ['Customer name, registration number and address cannot be empty']}), 200
        # check if registration number already exists
        check = Customer.query.filter_by(registration_number=data['registrationNumber']).count()
        if check > 0:
            return json.dumps({'status': 2, 'data': data, 'message': 'Customer already exists',
                               'error': ['Customer already exists']}), 200
        # save customer data
        log = Customer()
        log.customer_name = data['customerName']
        log.registration_number = data['registrationNumber']
        log.address = data['address']
        db.session.add(log)
        db.session.commit()
        customer_id = log.cid

        # log audit trail if 'actor' is in data and is not equal to 0
        if 'actor' in data and data['actor'] != 0:
            userId = data['actor']
            title = 'New customer added.'
            msg = f'{data["customerName"]} was registered.'
            act.log_audit_trail(user_id=userId, action=title,action_details=msg)
        # fetch the data
        worker = resource.fetch_customer_data(customer_id)
        message = f"Customer {data['customerName']} has been added successfully."
        return json.dumps({'status': 1, 'data': worker, 'message': message, 'error': [None]}), 200
    
    elif action == 'fetch_customers' and request.method == 'GET':
        customers = resource.fetch_customer_data()
        return json.dumps({'status': 1, 'data': customers, 'message': 'success', 'error': [None]}), 200
    
    elif action == 'delete_customer' and request.method == 'DELETE':
        data = request.get_json()
        message = "Customer deleted successfully."
        status = 1
        error = None
        # check if customer exists
        check = Customer.query.filter_by(cid=data['customerId']).first()
        if not check:
            message = 'Customer not found.'
            status = 2
            error = message
        else:
            Customer.query.filter_by(cid=data['customerId']).delete()
            db.session.commit()

            # log audit trail if 'actor' is in data and is not equal to 0
            if 'actor' in data and data['actor'] != 0:
                userId = data['actor']
                title = 'Customer deleted.'
                msg = f'{check.customer_name} was deleted.'
                act.log_audit_trail(user_id=userId, action=title,action_details=msg)
        customers = resource.fetch_customer_data()
        return json.dumps({'status': status, 'data': customers, 'message': message, 'error': [error]}), 200
    
    elif action == 'update_customer' and request.method == 'PUT':
        data = request.get_json()
        message = "Customer updated successfully."
        status = 1
        error = None
        # check if customer exists
        check = Customer.query.filter_by(cid=data['customerId']).first()
        if not check:
            message = 'Customer not found.'
            status = 2
            error = message
            
        else:
            # check that customer name, registration number and address are not empty
            if not data['customerName'] or not data['registrationNumber'] or not data['address']:
                message = 'Customer name, registration number and address cannot be empty.'
                status = 2
                error = message
            else:
                Customer.query.filter_by(cid=data['customerId']).update({
                    'customer_name': data['customerName'],
                    'registration_number': data['registrationNumber'],
                    'address': data['address']
                })
                db.session.commit()

                # log audit trail if 'actor' is in data and is not equal to 0
                if 'actor' in data and data['actor'] != 0:
                    userId = data['actor']
                    title = 'Customer updated.'
                    msg = f'{data["customerName"]} was updated.'
                    act.log_audit_trail(user_id=userId, action=title,action_details=msg)
        customers = resource.fetch_customer_data()
        return json.dumps({'status': status, 'data': customers, 'message': message, 'error': [error]}), 200
    
    return json.dumps({'status': 2, 'data': None, 'message': 'Request action not recognized', 'error': ['Request action not recognized']}), 200


@app.route('/api/v1/weight_record/<string:action>', methods=['GET','POST', 'PUT', 'DELETE'])
def weight_record(action):
    if action == 'add_new' and request.method == 'POST':
        data = request.get_json()
        # check if vehicle has an existing uncompleted record
        check = WeightLog.query.filter_by(vehicle_id=data['vehicleId'], final_weight=None).count()
        if check > 0:
            return json.dumps({'status': 2, 'data': data, 'message': 'Vehicle has an uncompleted record. Please update or delete this record first.',
                               'error': ['Vehicle has an uncompleted record. Please update or delete this record first.']}), 200
        # add new record
        log = WeightLog()
        log.vehicle_id = data['vehicleId'].upper()
        log.customer_id = data['customerId']
        log.haulier_id = data['haulierId']
        log.destination = data['destination']
        log.product = data['product']
        log.order_number = data['orderNumber']
        log.vehicle_name = data['vehicleName'].title()
        log.driver_name = data['driverName'].title()
        log.operator_id = data['operatorId']  # userId
        log.driver_phone = data['driverPhone']
        log.initial_weight = float(data['initialWeight'])
        db.session.add(log)
        db.session.commit()
        weight_log_id = log.wid

        # log audit trail
        userId = data['operatorId']
        title = 'New weight record added.'
        msg = f'Weight record for vehicle {data["vehicleId"]} was registered.'
        act.log_audit_trail(user_id=userId, action=title,action_details=msg)

        # log notification and send to admins
        try:
            msg = f"Weight record for vehicle {data['vehicleId'].upper()} has been created. You can now create waybill record if needed."
            result = resource.log_notification(message=msg, recipient_id=0,scope='admin') 
        except Exception as e:
            pass
        
        # fetch the data
        worker = resource.fetch_weight_records(weight_log_id)
        message = f"Weight record for vehicle {data['vehicleId'].upper()} has been added successfully."
        return json.dumps({'status': 1, 'data': worker, 'message': message, 'error': [None]}), 200
    
    elif action == 'update_record' and request.method == 'PUT':
        data = request.get_json()
        message = "Weight record updated successfully."
        status = 1
        error = None
        # check if weight record exists
        check = WeightLog.query.filter_by(wid=data['weightRecordId']).count()
        if check == 0:
            message = 'Weight record not found.'
            status = 2
            error = message
            return json.dumps({'status': status, 'data': data, 'message': message, 'error': [error]}), 200
        
        # check if record has been approved
        check = resource.fetch_weight_records(data['weightRecordId'])
        if isinstance(check, dict) and check.get('approvalStatus') == 'approved':
            message = 'Weight record has been approved and cannot be updated.'
            status = 2
            error = message
        else:
            WeightLog.query.filter_by(wid=data['weightRecordId']).update({
                'customer_id': data['customerId'],
                'haulier_id': data['haulierId'],
                'destination': data['destination'],
                'product': data['product'],
                'order_number': data['orderNumber'],
                'vehicle_id': data['vehicleId'],
                'operator_id': data['operatorId'],
                'vehicle_name': data['vehicleName'].title(),
                'driver_name': data['driverName'].title(),
                'driver_phone': data['driverPhone'],
                'initial_weight': float(data['initialWeight'])
            })
            if data['finalWeight'] != '' and data['finalWeight'] != None and data['finalWeight'] != 'null':
                WeightLog.query.filter_by(wid=data['weightRecordId']).update({
                    'final_weight': float(data['finalWeight']),
                    'final_time': date.today()
                })
                # log notification and send to admins, also notify users that update was successful
                try:
                    # for admins
                    msg = f"Weight record for vehicle {data['vehicleId']} has been updated."
                    msg += "\nYou can now request for waybill approval if applicable."
                    result = resource.log_notification(message=msg, recipient_id=0,scope='admin')

                    # for users
                    msg =  f"Update on Weight record for vehicle {data['vehicleId']} was successful."
                    msg += "\nAdmins have been notified for further action if applicable."
                    result = resource.log_notification(message=msg, recipient_id=0,scope='user')
                except Exception as e:
                    pass
            db.session.commit()
            # log audit trail
            userId = data['operatorId']
            title = 'Weight record updated.'
            msg = f'Weight record for vehicle {data["vehicleId"]} was updated.'
            act.log_audit_trail(user_id=userId, action=title,action_details=msg)

        weight_log_id = data['weightRecordId']
        worker = resource.fetch_weight_records(weight_log_id)
        return json.dumps({'status': status, 'data': worker, 'message': message, 'error': [error]}), 200
    elif action == 'delete_record' and request.method == 'DELETE':
        data = request.get_json()
        # check if record exists
        check = WeightLog.query.filter_by(wid=data['weightRecordId']).first()
        if check is None:
            return json.dumps({'status':2, 'data': data, 'message':'Record not found!', 'error':['Record not found!']}), 200
        
        # delete record
        act.delete_weight_record(data['weightRecordId'])

        # log audit trail if 'actor' is in data and is not equal to 0
        if 'actor' in data and data['actor'] != 0:
            userId = data['actor']
            title = 'Weight record deleted.'
            msg = f'Weight record for vehicle {check.vehicle_id} was deleted.'
            act.log_audit_trail(user_id=userId, action=title,action_details=msg)

        # log notification and send to everyone
        try:
            msg = f"Weight record for vehicle {check.vehicle_id} has been deleted."
            result = resource.log_notification(message=msg, recipient_id=0,scope='all') 
        except Exception as e:
            pass

        message = "Weight record deleted successfully."
        error = [None]
        # fetch all records
        worker = resource.fetch_weight_records()
        return json.dumps({'status':1, 'data': worker, 'message':message, 'error':error}), 200
    
    return json.dumps({'status': 2, 'data': None, 'message': 'Request action not recognized', 'error': ['Request action not recognized']}), 200

@app.route('/api/v1/waybill/<string:action>', methods=['GET','POST','PUT','DELETE'])
def waybill(action):
    if action == 'add_new' and request.method == 'POST':
        data = request.get_json()

        # check if there is existing waybill info for the weight record
        check = WaybillLog.query.filter_by(weight_log_id=data['weightRecordId']).count()
        if check > 0:
            message = "Waybill record already exists for this ticket"
            return json.dumps({'status': 2, 'data': data, 'message': message, 'error': [message]}), 200

        haulier_info = Haulier.query.filter_by(hid=data['haulierId']).first()
        customer_info = Customer.query.filter_by(cid=data['customerId']).first()

        log = WaybillLog()
        log.waybill_number = data['waybillNumber']
        log.haulier_ref = haulier_info.registration_number if haulier_info else ''
        log.customer_ref = customer_info.registration_number if customer_info else ''
        log.customer_id = data['customerId']
        log.haulier_id = data['haulierId']
        log.weight_log_id = data['weightRecordId']
        log.delivery_address = data['deliveryAddress']
        log.product_info = json.dumps(data['goodProducts']) if len(data['goodProducts']) > 0 else None 
        log.product_condition = data['productCondition']
        log.bad_product_info = json.dumps(data['badProducts']) if len(data['badProducts']) > 0 else None  # if len(data['badProducts']) > 0 else None
        log.received_by = data['preparedBy']
        log.delivered_by = data['driverName']

        try:
            db.session.add(log)
            db.session.commit()
            waybill_id = log.wid

            # log audit trail if 'actor' is in data and is not equal to 0
            if 'actor' in data and data['actor'] != 0:
                userId = data['actor']
                title = 'New waybill added.'
                msg = f'Waybill record for vehicle {data["vehicleId"]} was registered.'
                act.log_audit_trail(user_id=userId, action=title,action_details=msg)

            # log notification and send to everyone
            msg = f"Waybill record for vehicle {data['vehicleId']} has been created."
            result = resource.log_notification(message=msg, recipient_id=0,scope='all')
        except Exception as e:
            db.session.rollback()  # Rollback the changes in case of an error
            return json.dumps({'status': 2, 'data': data, 'message': f'Error adding waybill data:\n{e}', 'error': [str(e)]}), 200

        # fetch the data
        worker = resource.fetch_weight_records(data['weightRecordId'])

        return json.dumps({'status': 1, 'data': worker, 'message': 'Waybill data logged successfully', 'error': [None]}), 200
    
    elif action == 'delete_record' and request.method == 'DELETE':
        data = request.get_json()
        # chech if waybill record exists
        check = WaybillLog.query.filter_by(weight_log_id=data['weightRecordId']).first()
        if check is None:
            message = 'Waybill record not found!'
            error = [message]
            return json.dumps({'status':2, 'data': data, 'message':message, 'error':error}), 200
        
        # check if waybill has been approved
        check_again = ApprovalRequest.query.filter_by(waybill_id=check.wid, status='approved').first()
        if check_again:
            message = 'Waybill record has been approved and cannot be deleted.'
            error = [message]
            return json.dumps({'status':2, 'data': data, 'message':message, 'error':error}), 200
        
        # delete record
        act.delete_waybill_record(data['weightRecordId'])

        # log audit trail if 'actor' is in data and is not equal to 0
        if 'actor' in data and data['actor'] != 0:
            userId = data['actor']
            title = 'Waybill record deleted.'
            msg = f'Waybill record for vehicle {check.vehicle_id} was deleted.'
            act.log_audit_trail(user_id=userId, action=title,action_details=msg)

        # log notification and send to everyone
        try:
            msg = f"Waybill record for vehicle {resource.get_vehicle_id(check.wid)} has been deleted."
            result = resource.log_notification(message=msg, recipient_id=0,scope='all') 
            print(f"Notification sent: {result}")
        except Exception as e:
            pass
        message = 'Waybill record deleted successfully.'
        error = [None]
        # fetch weight records
        worker = resource.fetch_weight_records()
        return json.dumps({'status':1, 'data': worker, 'message':message, 'error':error}), 200

    elif action == 'update_record' and request.method == 'PUT':
        data = request.get_json()

        # check if there is existing waybill info for the weight record
        check = WaybillLog.query.filter_by(weight_log_id=data['weightRecordId']).first()
        if not check:
            message = "Waybill record not found"
            return json.dumps({'status': 2, 'data': data, 'message': message, 'error': [message]}), 200
        
        # check if record has been approved
        check_again = ApprovalRequest.query.filter_by(waybill_id=check.wid, status='approved').first()
        if check_again:
            message = 'Waybill record has been approved and cannot be updated.'
            return json.dumps({'status': 2, 'data': data, 'message': message, 'error': [message]}), 200

        # Update waybill record
        #haulier_info = Haulier.query.filter_by(hid=data['haulierId']).first()
        #customer_info = Customer.query.filter_by(cid=data['customerId']).first()

        WaybillLog.query.filter_by(weight_log_id=data['weightRecordId']) \
            .update({
                'waybill_number': data['waybillNumber'],
                #'haulier_ref': haulier_info.registration_number,
                #'customer_ref': customer_info.registration_number,
                #'customer_id': data['customer_id'],
                #'haulier_id': data['haulier_id'],
                'weight_log_id': data['weightRecordId'],
                'delivery_address': data['deliveryAddress'],
                'product_info': json.dumps(data['goodProducts']) if len(data['goodProducts']) > 0 else None,
                'product_condition': data['productCondition'],
                'bad_product_info': json.dumps(data['badProducts']) if len(data['badProducts']) > 0 else None,
                'received_by': data['preparedBy'],
                'delivered_by': data['driverName']
            })
        try:
            db.session.commit() 
            waybill_id = check.wid

            # log audit trail if 'actor' is in data and is not equal to 0
            if 'actor' in data and data['actor'] != 0:
                userId = data['actor']
                title = 'Waybill updated.'
                msg = f'Waybill record for vehicle {data["vehicleId"]} was updated.'
                act.log_audit_trail(user_id=userId, action=title,action_details=msg)

            # check if waybill approval status is declined
            check_again = ApprovalRequest.query.filter_by(waybill_id=check.wid, status='declined').first()
            if check_again:
                # update approval request and approval record
                ApprovalRequest.query.filter_by(waybill_id=check.wid, status='declined').update({'status': 'pending'})
                db.session.commit()

                Approval.query.filter_by(approval_request_id=check_again.id, approval_status='declined').update({'approval_status':'pending', 'is_notified':False})
                db.session.commit()
            # log notification and send to everyone
            msg = f"Waybill record for vehicle {data['vehicleId']} has been updated."
            result = resource.log_notification(message=msg, recipient_id=0,scope='all') 
        except Exception as e:
            db.session.rollback()  # Rollback the changes in case of an error
            return json.dumps({'status': 2, 'data': data, 'message': f'Error adding waybill data:\n {str(e)}', 'error': [str(e)]}), 200

        # fetch the data
        worker = resource.fetch_weight_records(data['weightRecordId'])

        return json.dumps(
            {'status': 1, 'data': worker, 'message': 'Waybill data updated successfully', 'error': [None]}), 200

    elif action == 'save_file':
        vehicle_id = request.args.get('vehicle_id')
        waybill_id = request.args.get('waybill_id')
        destination_folder = "server/documents/waybill/{}".format(vehicle_id)
        saved_file_paths = []
        # process and save each file
        for key, file in request.files.items():
            if file.filename == '':
                message = f"File not uploaded."
                return json.dumps({'status': 2, 'data': None, 'message': message, 'error': [message]}), 400

            timestamp = datetime.now().strftime('%Y%m%d%H%M%S')  # Generate timestamp
            new_filename = f"{timestamp}_{file.filename}"  # Append timestamp to filename
            file_path = os.path.join(destination_folder, new_filename)
            if not os.path.exists(destination_folder):
                try:
                    os.makedirs(destination_folder)
                except OSError:
                    message = f'Could not create new folder in the path {destination_folder}'
                    return json.dumps({'status': 2, 'data': None, 'message': message, 'error': [message]}), 500

            try:
                file.save(file_path)

            except Exception as e:
                message = f'Error saving file: {str(e)}'
                return json.dumps({'status': 2, 'data': None, 'message': message, 'error': [message]}), 500

            saved_file_paths.append(file_path)

        # update waybill info with
        WaybillLog.query.filter_by(wid=waybill_id).update({'file_link': json.dumps(saved_file_paths)})
        db.session.commit()

        # fetch complete waybill data
        worker = resource.fetch_waybill_data(waybill_id)

        return json.dumps({'status': 1, 'data': worker, 'message': 'File saved successfully', 'error': [None]})

    elif action == "approve_waybill":
        data = request.get_json()

        # check if user is authorized to approve

        # approve waybill
        waybill = WaybillLog.query.filter_by(weight_log_id=data['weight_log_id']).first()

        if waybill:
            WaybillLog.query.filter_by(weight_log_id=data['weight_log_id']) \
                .update({'approval_status': 'approved', 'approval_time': datetime.now(),
                         "approved_by": data['approver']})
            db.session.commit()

            message = "Successfully Approved."
            return json.dumps({'status': 1, 'data': None, 'message': message, 'error': [None]})

        message = "Record Not Found."
        return json.dumps({'status': 2, 'data': None, 'message': message, 'error': [message]})

    message = "invalid request action"
    return json.dumps({'status': 2, 'data': None, 'message': message, 'error': [message]})


@app.route('/api/v1/waybill_approval/<string:action>', methods=['GET', 'POST', 'PUT', 'DELETE'])
def approval(action):
    status = 2
    message = "Request action not recognized"
    error = [message]

    if action == 'create_request' and request.method == 'POST':
        data = request.get_json()
        # check if waybill record exists
        check = WaybillLog.query.filter_by(wid=data['waybillId']).first()
        if not check:
            message = 'Waybill record not found.'
            return json.dumps({'status': status, 'data': data, 'message': message, 'error': [message]}), 200
        
        # log approval request
        log = ApprovalRequest()
        log.waybill_id = data['waybillId']
        log.created_by = data['createdBy']
        log.approval_flow_type = data['approvalFlowType']
        
        try:
            db.session.add(log)
            db.session.commit()
            approval_request_id = log.id

            # log audit trail if 'actor' is in data and is not equal to 0
            if 'actor' in data and data['actor'] != 0:
                userId = data['actor']
                title = 'Approval request created.'
                msg = f'Approval request for waybill with reference: {resource.get_vehicle_id(data["waybillId"])} was created.'
                act.log_audit_trail(user_id=userId, action=title,action_details=msg)

            msg = f"Approval request for waybill with reference: {resource.get_vehicle_id(data['waybillId'])} has been created. "
            
            # update waybill record with the primary approver
            WaybillLog.query.filter_by(wid=data['waybillId']).update({'primary_approver_id':data['primaryApprover']['userId']})
            db.session.commit()
            approvers = []
            primary_approver = data['primaryApprover']
            approvers.append(primary_approver['fullName'])
            
            # check if secondary approval list is not empty and log them
            if len(data['secondaryApprovers']) > 0:
                for approver in data['secondaryApprovers']:
                    log = SecondaryApprover()
                    log.approval_request_id = approval_request_id
                    log.approver_id = approver['userId']
                    log.rank = approver['rank']
                    db.session.add(log)

                    approvers.append(approver['fullName'])
            db.session.commit()

            msg += f'Required to approve are: {", ".join(approvers)}.'
            # log notification and send to users
            result = resource.log_notification(message=msg, recipient_id=0,scope='user', request_id=approval_request_id)

            # send requests to approvers
            arc = ApprovalRequestClass(approval_request_id)
            req = arc.send_approval_request()
            if req['status'] == 1:
                _message = ""
                error = [None]
            else:
                _message = req['message']
                error = [message]

            # fetch weight records
            #worker = resource.fetch_waybill_record(check.weight_log_id)
            worker = resource.fetch_weight_records()
            status = req['status']
            message = f"Approval request created successfully\n {_message}"
        except Exception as e:
            db.session.rollback()
            message = f"Error creating approval request: \n {str(e)}"
            error = [str(e)]
            worker = data
        return json.dumps({'status': status, 'data': worker, 'message': message, 'error': error}), 200
    
    elif action == 'update_request' and request.method == 'PUT':
        msg = ''
        approvers = []
        data = request.get_json()
        # check if waybill record exists
        check = WaybillLog.query.filter_by(wid=data['waybillId']).first()
        if not check:
            message = 'Waybill record not found.'
            return json.dumps({'status': status, 'data': data, 'message': message, 'error': [message]}), 200
        
        # check if approval request exists
        check = ApprovalRequest.query.filter_by(waybill_id=data['waybillId']).first()
        if not check:
            message = 'Approval request not found.'
            return json.dumps({'status': status, 'data': data, 'message': message, 'error': [message]}), 200
        
        # check if request has been approved
        if check.status == 'approved':
            message = 'Approval request has been approved and cannot be updated.'
            return json.dumps({'status': status, 'data': data, 'message': message, 'error': [message]}), 200
        
        # check if there is change in the approval flow type
        if check.approval_flow_type != data['approvalFlowType']:
            # update approval request record with the new approval flow type
            ApprovalRequest.query.filter_by(waybill_id=data['waybillId']).update({'approval_flow_type':data['approvalFlowType']})
            db.session.commit()

            # check if there are approval records in the approval table
            check_again = Approval.query.filter_by(approval_request_id=check.id, approval_status='declined').first()
            if check_again:
                Approval.query.filter_by(id=check_again.id).update({'approval_status':'pending', 'is_notified':False})
                db.session.commit()

                # update request status to pending
                ApprovalRequest.query.filter_by(id=check.id).update({'status':'pending'})
                db.session.commit()

        # compose notification message
        msg += f"Approval request for waybill with reference: {resource.get_vehicle_id(data['waybillId'])} has been update. "

        
        # check if there is a change in the primary approver
        if check.waybill.primary_approver_id != data['primaryApprover']['userId']:
            # update waybill record with the primary approver
            WaybillLog.query.filter_by(wid=data['waybillId']).update({'primary_approver_id':data['primaryApprover']['userId']})
            db.session.commit()

            primary_approver = data['primaryApprover']
            approvers.append(primary_approver['fullName'])

            # check if there are declined approval records in the approval table
            check_again = Approval.query.filter_by(approval_request_id=check.id, approval_status='declined').first()
            if check_again:
                Approval.query.filter_by(id=check_again.id).update({'approval_status':'pending', 'is_notified':False})
                db.session.commit()

                # update request status to pending
                ApprovalRequest.query.filter_by(id=check.id).update({'status':'pending'})
                db.session.commit()
        
        # check if there is a change in the secondary approvers
        if len(check.secondary_approvers) != len(data['secondaryApprovers']):
            # delete all records in the secondary approver table 
            SecondaryApprover.query.filter_by(approval_request_id=check.id).delete()
            db.session.commit()

            # also delete all approval records associated with request
            Approval.query.filter_by(approval_request_id=check.id).delete()
            db.session.commit()

            # delete all notifications associated with the request
            res = act.delete_notification_record(approval_request_id=check.id)

            # check if secondary approval list is not empty and log them
            if len(data['secondaryApprovers']) > 0:
                for approver in data['secondaryApprovers']:
                    log = SecondaryApprover()
                    log.approval_request_id = check.id
                    log.approver_id = approver['userId']
                    log.rank = approver['rank']
                    db.session.add(log)

                    approvers.append(approver['fullName'])
                db.session.commit()
            
            # update request status to pending
            ApprovalRequest.query.filter_by(id=check.id).update({'status':'pending'})
            db.session.commit()

        elif len(check.secondary_approvers) == len(data['secondaryApprovers']):
            # check if there is a change in the secondary approvers
            for approver in data['secondaryApprovers']:
                check_again = SecondaryApprover.query.filter_by(approval_request_id=check.id, approver_id=approver['userId'], rank=approver['rank']).first()
                if not check_again:
                    # delete all records in the secondary approver table and log new ones
                    SecondaryApprover.query.filter_by(approval_request_id=check.id).delete()
                    db.session.commit()

                    # also delete all approval records associated with request
                    Approval.query.filter_by(approval_request_id=check.id).delete()
                    db.session.commit()

                    # delete all notifications associated with the request
                    res = act.delete_notification_record(approval_request_id=check.id)
                    print(f'notifications deleted: {res}')

                    # check if secondary approval list is not empty and log them
                    if len(data['secondaryApprovers']) > 0:
                        for approver in data['secondaryApprovers']:
                            log = SecondaryApprover()
                            log.approval_request_id = check.id
                            log.approver_id = approver['userId']
                            log.rank = approver['rank']
                            db.session.add(log)

                            approvers.append(approver['fullName'])
                        db.session.commit()
                    
                    # update request status to pending
                    ApprovalRequest.query.filter_by(id=check.id).update({'status':'pending'})
                    db.session.commit()
                    break
            
            # check if there are declined approval records in the approval table
            check_again = Approval.query.filter_by(approval_request_id=check.id, approval_status='declined').first()
            if check_again:
                # update approval records to pending
                Approval.query.filter_by(id=check_again.id).update({'approval_status':'pending', 'is_notified':False})
                db.session.commit()

                # update request status to pending
                ApprovalRequest.query.filter_by(waybill_id=data['waybillId']).update({'status':'pending'})
                db.session.commit()
        
        # log audit trail if 'actor' is in data and is not equal to 0
        if 'actor' in data and data['actor'] != 0:
            userId = data['actor']
            title = 'Approval request updated.'
            msg = f'Approval request for waybill with reference: {resource.get_vehicle_id(data["waybillId"])} was updated.'
            act.log_audit_trail(user_id=userId, action=title,action_details=msg)

        # notify users
        msg += f'Changes were made to the list of approvers, and the new required to approve are: {", ".join(approvers)}.'
        if len(approvers) > 0:
            # log notification and send to users
            result = resource.log_notification(message=msg, recipient_id=0,scope='user') 

        # send requests to approvers
        try:
            arc = ApprovalRequestClass(check.id)
            req = arc.send_approval_request()
            if req['status'] != 1:
                raise Exception(req['message'])
            # fetch weight records
            worker = resource.fetch_weight_records()
            status = req['status']
            message = f"Approval request updated successfully."
        except Exception as e:
            db.session.rollback()
            message = f"Error updating approval request: \n {str(e)}"
            error = [str(e)]
            worker = data
        return json.dumps({'status': status, 'data': worker, 'message': message, 'error': error}), 200
    
    elif action == 'approve_request' and request.method == 'PUT':
        data = request.get_json()
        # get the approval request record
        check = ApprovalRequest.query.filter_by(id=data['approvalRequestId']).first()
        if not check:
            message = 'Approval request not found.'
            return json.dumps({'status': status, 'data': data, 'message': message, 'error': [message]}), 200
        
        # check if request has been approved
        if check.status == 'approved':
            message = f'Approval request has been approved by {check.waybill.primary_approver.sname} {check.waybill.primary_approver.fname} and cannot be updated.'
            return json.dumps({'status': status, 'data': data, 'message': message, 'error': [message]}), 200
        # check if request was rejected
        if check.status == 'declined':
            # get the approval record with declined status
            check_again = Approval.query.filter_by(approval_request_id=data['approvalRequestId'], approval_status='declined').first()
            if check_again:
                message = f'This request was declined by {check_again.approver.primary_approver.sname} {check_again.approver.primary_approver.fname} and cannot be updated.'
            else:
                message = f'This request was declined by {check.waybill.primary_approver.sname} {check.waybill.primary_approver.fname} and cannot be updated.'
            return json.dumps({'status': status, 'data': data, 'message': message, 'error': [message]}), 200
        
        # check if approver is primary approver, if yes, log approval for primary approver if not exist and mark request as approved
        if check.waybill.primary_approver_id == data['approverId']:
            # check if primary approver has been notified
            check_again = Approval.query.filter_by(approval_request_id=data['approvalRequestId'], approved_by=data['approverId']).first()
            if not check_again:
                # log approval
                log = Approval()
                log.approval_request_id = data['approvalRequestId']
                log.approved_by = data['approverId']
                log.approval_status = data['action']
                log.timestamp = datetime.now()
                log.comments = data['comments']
                log.is_primary = True
                log.is_notified = False
                db.session.add(log)
                db.session.commit()
            else:
                # update approval record
                Approval.query.filter_by(approval_request_id=data['approvalRequestId'], approved_by=data['approverId'])\
                .update({
                    'approval_status': data['action'], 
                    'timestamp':datetime.now(),
                    'comments': data['comments']
                    })
                db.session.commit()
            # update approval request record
            ApprovalRequest.query.filter_by(id=data['approvalRequestId']).update({'status':data['action']})
            db.session.commit()

            # send notification to everyone
            approver_data = resource.fetch_user_data(data['approverId'])
            if isinstance(approver_data, dict):
                approver_name = approver_data.get('fullName', 'Primary approver')
            else:
                approver_name = f'{check.waybill.primary_approver.sname} {check.waybill.primary_approver.fname}'

            if data['action'] == 'declined':
                msg = f"Approval request for waybill with reference: {resource.get_vehicle_id(check.waybill.wid)} has been {data['action']}. "
                msg += f'Reason for the action is stated below:\n\n\"{data["comments"]}\" ~ {approver_name}.'
                msg += "\n\nNOTE: You can edit waybill data whose approval request has been declined, and then resubmit the request for review and approval."
                response = resource.log_notification(message=msg, recipient_id=0,scope='all')
            else:
                msg = f"Approval request for waybill with reference: {resource.get_vehicle_id(check.waybill.wid)} has been {data['action']} by {approver_name}."
                response = resource.log_notification(message=msg, recipient_id=0,scope='all')

            # update weight record for everyone
            weight_records = resource.fetch_weight_records()
            socketio.emit('weight_record_response', json.dumps(weight_records))

            # log audit trail if 'actor' is in data and is not equal to 0
            if 'actor' in data and data['actor'] != 0:
                userId = data['actor']
                title = 'Approval request approved.'
                msg = f'Approval request for waybill with reference: {resource.get_vehicle_id(data["waybillId"])} was approved.'
                act.log_audit_trail(user_id=userId, action=title,action_details=msg)

            # send email notification to user
            email = resource.fetch_recipient_email('user')
            subject = f"Approval request for waybill with reference: {resource.get_vehicle_id(check.waybill.wid)}"
            msg = f"Your approval request for waybill with reference: {resource.get_vehicle_id(check.waybill.wid)} has been {data['action']} by {approver_name}."
            response = act.send_email_notification(subject=subject, message=msg, recipient_email=email, app_id=1)
            
            # fetch weight records
            worker = resource.fetch_weight_records()
            status = 1
            message = "Approval request approved successfully."
            return json.dumps({'status': status, 'data': worker, 'message': message, 'error': error}), 200
        
        # check if approver has been notified
        # if yes, update approval record's status
        # send approval notification to the next approver
        check_again = Approval.query.filter_by(approval_request_id=data['approvalRequestId'], approved_by=data['approverId'], approval_status='pending').first()
        if not check_again:
            message = 'You have not been authorized to approve this request yet'
            return json.dumps({'status': status, 'data': data, 'message': message, 'error': error}), 200
        
        # update approval record
        Approval.query.filter_by(approval_request_id=data['approvalRequestId'], approved_by=data['approverId'])\
        .update({
            'approval_status': data['action'], 
            'timestamp':datetime.now(),
            'comments': data['comments']
            })
        db.session.commit()

        # check if actione is declined
        if data['action'] == 'declined':
            # update approval request record
            ApprovalRequest.query.filter_by(id=data['approvalRequestId']).update({'status':data['action']})
            db.session.commit()

            # send notification to everyone
            approver_data = resource.fetch_user_data(data['approverId'])
            if isinstance(approver_data, dict):
                approver_name = approver_data.get('fullName', 'Secondary approver')
            else:
                approver_name = f'{check.waybill.primary_approver.sname} {check.waybill.primary_approver.fname}'

            msg = f"Approval request for waybill with reference: {resource.get_vehicle_id(check.waybill.wid)} has been {data['action']}. "
            msg += f'Reason for the action is stated below:\n\n\"{data["comments"]}\" ~ {approver_name}.'
            msg += "\n\nNOTE: You can edit waybill data whose approval request has been declined, and then resubmit the request for review and approval."
            response = resource.log_notification(message=msg, recipient_id=0,scope='all')

            # update weight record for everyone
            weight_records = resource.fetch_weight_records()
            socketio.emit('weight_record_response', json.dumps(weight_records))

            # log audit trail if 'actor' is in data and is not equal to 0
            if 'actor' in data and data['actor'] != 0:
                userId = data['actor']
                title = 'Approval request declined.'
                msg = f'Approval request for waybill with reference: {resource.get_vehicle_id(data["waybillId"])} was declined.'
                act.log_audit_trail(user_id=userId, action=title,action_details=msg)
            
            # send email notification to user
            email = resource.fetch_recipient_email('user')
            subject = f"Approval declined: {resource.get_vehicle_id(check.waybill.wid)}"
            msg = f"Your approval request for waybill with reference: {resource.get_vehicle_id(check.waybill.wid)} has been {data['action']} by {approver_name}."
            response = act.send_email_notification(subject=subject, message=msg, recipient_email=email, app_id=1)
            
            # fetch weight records
            worker = resource.fetch_weight_records()
            status = 1
            message = "Approval request declined successfully."
            return json.dumps({'status': status, 'data': worker, 'message': message, 'error': error}), 200
        
        # log audit trail if 'actor' is in data and is not equal to 0
        if 'actor' in data and data['actor'] != 0:
            userId = data['actor']
            title = 'Approval request approved.'
            msg = f'Approval request for waybill with reference: {resource.get_vehicle_id(data["waybillId"])} was approved.'
            act.log_audit_trail(user_id=userId, action=title,action_details=msg)

        # send notification to the next approver
        arc = ApprovalRequestClass(data['approvalRequestId'])
        req = arc.send_approval_request()
        if req['status'] == 1:
            message = 'Your approval was successfully logged and the next approver has been notified successfully.'
            error = [None]
        else:
            message = 'Your approval was successfully logged but the next approver could not be notified. Please talk to an admin.'
            error = [message]
        
        # fetch weight records
        worker = resource.fetch_weight_records()
        status = 1
        return json.dumps({'status': status, 'data': worker, 'message': message, 'error': error}), 200

    return json.dumps({'status': status, 'data': None, 'message': message, 'error': error}), 200

@app.route('/api/v1/fetch_resources/<string:item>', methods=['GET', 'POST'])
def fetch_resources(item):
    if item == 'weight_records' and request.method == 'GET':
        # fetch huliers, customers and products lists
        hauliers = resource.fetch_haulier_data()
        customers = resource.fetch_customer_data()
        products = resource.fetch_product_data()

        # fetch the data
        data = resource.fetch_weight_records()
        status = 1
        message = "Weight records fetched successfully"
        return json.dumps({'status': status, 'data': data, 'customers': customers, 'hauliers': hauliers, 'products': products, 'message': message, 'error': [message]}), 200
    
    elif item == 'weight_record':
        data = request.get_json()
        # fetch huliers, customers and products lists
        hauliers = resource.fetch_haulier_data()
        customers = resource.fetch_customer_data()
        products = resource.fetch_product_data()
        # return error if any of the lists is empty
        if len(hauliers) == 0 or len(customers) == 0 or len(products) == 0:
            message = ''
            if len(hauliers) == 0:
                message += 'hauliers list is empty'
            if len(customers) == 0:
                message += '\ncustomers list is empty'
            if len(products) == 0:
                message += '\nproducts list is empty'
            return json.dumps({'status': 2, 'data': data, 'message': message, 'error':[message]}), 200
        
        # check if vehicle record exists
        check = WeightLog.query.filter_by(vehicle_id=data['vehicleId'].upper()).count()
        if check == 0:
            status = 3  # new record need to be created
            message = "Vehicle record not found"
            return json.dumps({'status': status, 'data': data, 'customers': customers, 'hauliers': hauliers, 'products': products, 'message': message, 'error': [message]}), 200
        
        # fetch the data based on the data scope
        if 'scope' in data:
            if data['scope'] == 'last_uncompleted':
                
                # check if there is a record without final weight
                check = WeightLog.query.filter_by(vehicle_id=data['vehicleId'].upper(), final_weight=None).count()
                if check > 0:
                    data = resource.fetch_weight_record(data['vehicleId'])
                    status = 1
                    message = "data fetched successfully"
                    return json.dumps({'status':status, 'data': data, 'customers': customers, 'hauliers': hauliers, 'products': products, 'message': message, 'error': [message]}), 200
                else:
                    status = 3  # new record need to be created
                    message = "no uncompleted record for this vehicle"
                    return json.dumps({'status': status, 'data': data, 'customers': customers, 'hauliers': hauliers, 'products': products, 'message': message, 'error': [message]}), 200
        
    elif item == 'all':
        # fetch the data
        customers = resource.fetch_customer_data()
        hauliers = resource.fetch_haulier_data()
        users = resource.fetch_user_data()
        status = 1
        message = "Resources fetched successfully"
        return json.dumps({'status': status, 'data': None, 'customers': customers,
                           'hauliers': hauliers, 'message': message, 'error': [message],
                           'users': users})

    elif item == 'email_data':
        data = request.get_json()

        # fetch the data
        ticket_data = WeightLog.query.filter_by(wid=data['weight_log_id']).first()
        waybill_data = WaybillLog.query.filter_by(weight_log_id=data['weight_log_id']).first()

        processed_mass = myfunc.process_mass(ticket_data)

        # format data
        slip = {}
        slip['id'] = ticket_data.wid
        slip['date'] = ticket_data.initial_time.strftime('%A, %dth of %B, %Y  %I:%M:%S %p')
        slip['vehicle id'] = ticket_data.vehicle_id
        slip['customer'] = ticket_data.customer.customer_name if ticket_data.customer else "No Name"
        slip['haulier'] = ticket_data.haulier.company_name if ticket_data.haulier else 'No Name'
        slip['destination'] = ticket_data.destination
        slip['product'] = ticket_data.product
        slip['ticket number'] = ''
        slip['delivery number'] = ''
        slip['order number'] = ticket_data.order_number
        slip['gross mass'] = processed_mass['gross_mass']
        slip['tare mass'] = processed_mass['tare_mass']
        slip['net mass'] = processed_mass['net_mass']
        slip['driver'] = ticket_data.driver_name

        # waybill initial info
        wb_data = {}
        product_list = []
        bad_product_list = []
        files = []
        approvals_data = {}

        if waybill_data:
            wb_data['id'] = waybill_data.wid
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

            # approvals data
            approvals_data['approval_status'] = waybill_data.approval_status
            approvals_data['received_by'] = waybill_data.received_by
            approvals_data['approval_date'] = waybill_data.approval_time.strftime(
                "%d-%m-%Y %I:%M:%S %p") if waybill_data.approval_time else ""
            approvals_data['approver'] = waybill_data.approved_by
            approvals_data['delivered_by'] = waybill_data.delivered_by
            approvals_data['received_date'] = waybill_data.reg_date.strftime("%d-%m-%Y %I:%M:%S %p")

        status = 1
        message = "Resources fetched successfully"
        return json.dumps({'status': status, 'data': None, 'products': product_list,
                           'bad_products': bad_product_list, 'message': message, 'error': [message],
                           'waybill_data': wb_data, 'ticket_data': slip, 'files': files,
                           'approvals_data': approvals_data})

    return json.dumps({'status': 2, 'data': None, 'message': 'Request action not recognized', 'error': ['Request action not recognized']}), 200

