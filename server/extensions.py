""" this module will help create instances of extensions such as db"""
from flask import Flask, session, render_template, render_template_string, request, flash
from werkzeug.security import check_password_hash, generate_password_hash
from appclass.file_class import FileHandler
from sqlalchemy.sql import func
import json
from helpers import myfunctions as myfunc
from appclass.email_class import EmailService, email_template
from flask_sqlalchemy import SQLAlchemy
from flask_login import LoginManager
from flask_migrate import Migrate
from flask_cors import CORS
# from flask_session import Session
import os
from datetime import datetime
from flask_mail import Mail
from sqlalchemy.dialects.mysql import ENUM
from flask_login import UserMixin

app = Flask(__name__, template_folder='templates')
secret_key = "xm/msh>ek$woan348n9#DkgviCn<mi3n@ij+3mWhr83nI3ni4dh453kjh4jn*re"
app.secret_key = secret_key
app.config.from_pyfile('config.py')
cors = CORS(app)

# Session(app)
mail = Mail(app)

db = SQLAlchemy(app)
login_manager = LoginManager(app)
migrate = Migrate(app, db)


#  MODELS

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
    delete_flag = db.Column(db.Integer, default=0)

    def __repr__(self):
        return self.device_name


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
    approval_status = db.Column(db.String(50), ENUM('approved', 'pending'), default='pending')
    approved_by = db.Column(db.String(50))
    approval_time = db.Column(db.DateTime())
    reg_date = db.Column(db.DateTime(), default=func.now())
    delete_flag = db.Column(db.Integer, default=0)

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


#  Functions and Routes

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
    return message


@app.route('/', methods=['POST', 'GET'])
def index():
    db.create_all()
    return json.dumps({'status': 1, 'data': None, 'message': 'operation was successful', 'error': None})

@app.route('/test', methods=['POST', 'GET'])
def indx():
    db.create_all()
    return json.dumps({'status': 1, 'data': None, 'message': 'this is a test url', 'error': None})


@app.route('/approve', methods=['GET', 'POST'])
def approve():
    from helpers import resources as resource
    response = ''
    email = request.args.get('email')
    weight_log_id = request.args.get('wtlog_id')

    if not email or not weight_log_id:
        return render_template_string("""
                        <h3>Sorry, you are not authorized to view this page.</h3>            
                """)

    table1_data, table2_data, table3_data, table4_data = resource.fetch_table_data(weight_log_id)

    if request.method == "POST":
        password = request.form['password']

        # check if user is authenticated
        user = User.query.filter_by(email=email, admin_type='approver').first()
        if not user:
            response = "You are not authorized for this action"
            return render_template_string(email_template, table1_data=table1_data, table2_data=table2_data,
                                          table3_data=table3_data, table4_data=table4_data, email=email,
                                          weight_log_id=weight_log_id, response=response)

        if not check_password_hash(user.password, password):
            response = "Wrong password. Please try again."
            return render_template_string(email_template, table1_data=table1_data, table2_data=table2_data,
                                          table3_data=table3_data, table4_data=table4_data, email=email,
                                          weight_log_id=weight_log_id, response=response)
        # approve waybill
        check = WaybillLog.query.filter_by(weight_log_id=weight_log_id, approval_status='approved').count()
        if check > 0:
            response = "This waybill info has been approved before now."
            return render_template_string(email_template, table1_data=table1_data, table2_data=table2_data,
                                          table3_data=table3_data, table4_data=table4_data, email=email,
                                          weight_log_id=weight_log_id, response=response)
        WaybillLog.query.filter_by(weight_log_id=weight_log_id) \
            .update({'approval_status': 'approved',
                     'approval_time': datetime.now(),
                     'approved_by': f"{user.sname} {user.fname}"})
        db.session.commit()
        response = "Successfully approved!"

    return render_template_string(email_template, table1_data=table1_data, table2_data=table2_data,
                                  table3_data=table3_data, table4_data=table4_data, email=email,
                                  weight_log_id=weight_log_id, response=response)


@app.route('/save_records', methods=['POST'])
def records():
    data = request.get_json()
    # check if record exists for this vehicle id
    check = db.session.query(WeightLog).filter(WeightLog.vehicle_id == data['vehicle_id'],
                                               WeightLog.final_weight.is_(None)).count()
    if check > 0:
        return json.dumps({'status': 2, 'data': None,
                           'message': 'There is a pending weight record for this vehicle'})

    log = WeightLog()
    log.product = data['product']
    log.order_number = data['order_number']
    log.destination = data['destination']
    log.vehicle_name = data['vehicle_name'].title()
    log.vehicle_id = data['vehicle_id']
    log.driver_phone = data['driver_phone']
    log.driver_name = data['driver_name'].title()
    log.operator_id = data['operator']  # userId
    log.customer_id = data['customer']
    log.haulier_id = data['haulier']
    log.initial_weight = data['weight_1']
    db.session.add(log)
    db.session.commit()
    return json.dumps({'status': 1, 'data': None, 'message': 'Records was saved successfully.'})


@app.route('/update_records', methods=['POST'])
def update_records():
    data = request.get_json()
    if 'action' in data:
        if data['action'] == 'edit':
            # check if waybil exists and have been approved
            check = WaybillLog.query.filter_by(weight_log_id=data['weight_log_id']).first()
            if check:
                if check.approval_status == "approved":
                    message = 'This item has been approved. You cannot make changes to the records.'
                    error = message
                    return json.dumps({'status': 2, 'data': None, 'message': message, 'error': [error]})

            db.session.query(WeightLog) \
                .filter(WeightLog.wid == data['weight_log_id']) \
                .update({
                    'product': data['product'],
                    'order_number': data['order_number'],
                    'destination': data['destination'],
                    'vehicle_name': data['vehicle_name'].title(),
                    'vehicle_id': data['vehicle_id'],
                    'driver_phone': data['driver_phone'],
                    'driver_name': data['driver_name'].title(),
                    'operator_id': data['operator'],
                    'customer_id': data['customer'],
                    'haulier_id': data['haulier'],
                    'initial_weight': data['weight_1'],
                    'final_weight': data['weight_2'],
                    'final_time': datetime.now()
                })
    else:
        db.session.query(WeightLog) \
            .filter(WeightLog.vehicle_id == data['vehicle_id'], WeightLog.final_weight.is_(None)) \
            .update({
                'final_weight': data['weight_2'],
                'final_time': datetime.now()
            })
    db.session.commit()

    return json.dumps({'status': 1, 'data': None, 'message': 'Records was updated successfully.', 'error': [None]})


@app.route('/create_waybill', methods=['POST'])
def waybill():
    action = request.args.get('action')
    if action == 'save_data':
        data = request.get_json()

        # check if there is existing waybill info for the weight record
        check = WaybillLog.query.filter_by(weight_log_id=data['weight_log_id']).count()
        if check > 0:
            message = "Waybill record already exists for this ticket"
            return json.dumps({'status': 300, 'data': data, 'message': message, 'error': [message]})

        haulier_info = Haulier.query.filter_by(hid=data['haulier_id']).first()
        customer_info = Customer.query.filter_by(cid=data['customer_id']).first()

        log = WaybillLog()
        log.waybill_number = data['waybill_number']
        log.haulier_ref = haulier_info.registration_number
        log.customer_ref = customer_info.registration_number
        log.customer_id = data['customer_id']
        log.haulier_id = data['haulier_id']
        log.weight_log_id = data['weight_log_id']
        log.delivery_address = data['address']
        log.product_info = json.dumps(data['products'])
        log.product_condition = data['product_condition']
        log.bad_product_info = json.dumps(data['bad_products'])
        log.received_by = data['received_by']
        log.delivered_by = data['driver']

        try:
            db.session.add(log)
            db.session.commit()
            waybill_id = log.wid
        except Exception as e:
            db.session.rollback()  # Rollback the changes in case of an error
            return json.dumps({'status': 2, 'data': data, 'message': 'Error adding waybill data', 'error': [str(e)]})

        # fetch the data
        from helpers import resources as resource
        worker = resource.fetch_waybill_data(waybill_id)

        return json.dumps({'status': 1, 'data': worker, 'message': 'Waybill data logged successfully', 'error': [None]})

    elif action == 'edit_data':
        data = request.get_json()

        # check if there is existing waybill info for the weight record
        check = WaybillLog.query.filter_by(weight_log_id=data['weight_log_id']).first()
        if not check:
            message = "Waybill record not found"
            return json.dumps({'status': 2, 'data': data, 'message': message, 'error': [message]})

        haulier_info = Haulier.query.filter_by(hid=data['haulier_id']).first()
        customer_info = Customer.query.filter_by(cid=data['customer_id']).first()

        WaybillLog.query.filter_by(weight_log_id=data['weight_log_id']) \
            .update({
                'waybill_number': data['waybill_number'],
                'haulier_ref': haulier_info.registration_number,
                'customer_ref': customer_info.registration_number,
                'customer_id': data['customer_id'],
                'haulier_id': data['haulier_id'],
                'weight_log_id': data['weight_log_id'],
                'delivery_address': data['address'],
                'product_info': json.dumps(data['products']),
                'product_condition': data['product_condition'],
                'bad_product_info': json.dumps(data['bad_products']),
                'received_by': data['received_by'],
                'delivered_by': data['driver']
            })
        try:
            db.session.commit()
            waybill_id = check.wid
        except Exception as e:
            db.session.rollback()  # Rollback the changes in case of an error
            return json.dumps({'status': 2, 'data': data, 'message': 'Error adding waybill data', 'error': [str(e)]})

        # fetch the data
        from helpers import resources as resource
        worker = resource.fetch_waybill_data(waybill_id)

        return json.dumps(
            {'status': 1, 'data': worker, 'message': 'Waybill data updated successfully', 'error': [None]})

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
        from helpers import resources as resource
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


@app.route('/customer', methods=['POST'])
def customer():
    action = request.args.get('action')
    if action == 'save_data':
        data = request.get_json()

        # check if reg number already exists
        check = Customer.query.filter_by(registration_number=data['ref']).count()
        if check > 0:
            message = "This registration number is already in use by another customer."
            return json.dumps({'status': 2, 'data': data, 'message': message, 'error': [message]})

        log = Customer()
        log.customer_name = data['name']
        log.registration_number = data['ref']
        log.address = data['address']

        try:
            db.session.add(log)
            db.session.commit()
            customer_id = log.cid
        except Exception as e:
            db.session.rollback()  # Rollback the changes in case of an error
            return json.dumps({'status': 2, 'data': data, 'message': 'Error adding customer data', 'error': [str(e)]})

        # fetch the data
        from helpers import resources as resource
        worker = resource.fetch_customer_data()
        message = f"Information for {data['name']} has been added successfully."
        return json.dumps({'status': 1, 'data': worker, 'message': message, 'error': [None]})

    elif action == 'edit_customer_data':
        data = request.get_json()

        # check if reg number already exists
        check = db.session.query(Customer).filter(Customer.registration_number == data['ref'],
                                                  Customer.cid != data['id']).count()
        if check > 0:
            message = "This registration number is already in use by another customer."
            return json.dumps({'status': 2, 'data': data, 'message': message, 'error': [message]})

        try:
            db.session.query(Customer).filter(Customer.cid == data['id']).update({
                'customer_name': data['name'],
                'registration_number': data['ref'],
                'address': data['address']
            })
            db.session.commit()
        except Exception as e:
            db.session.rollback()  # Rollback the changes in case of an error
            return json.dumps({'status': 2, 'data': data, 'message': 'Error updating customer data', 'error': [str(e)]})

        # fetch the data
        from helpers import resources as resource
        worker = resource.fetch_customer_data()  # all users
        message = f"Information for {data['name']} has been updated successfully."
        return json.dumps({'status': 1, 'data': worker, 'message': message, 'error': [None]})

    elif action == 'delete_customer':
        data = request.get_json()
        message = "Customer deleted successfully."
        status = 1
        error = None

        # check if customer exists
        check = Customer.query.filter_by(cid=data['id']).first()

        if not check:
            message = 'customer not found.'
            status = 2
            error = message
        else:
            Customer.query.filter_by(cid=data['id']).delete()
            db.session.commit()

        from helpers import resources as resource
        worker = resource.fetch_customer_data()

        return json.dumps({'status': status, 'data': worker, 'message': message, 'error': [error]})

    message = "Request action not recognized"
    return json.dumps({'status': 2, 'data': None, 'message': message, 'error': [message]})


@app.route('/haulier', methods=['POST'])
def haulier():
    action = request.args.get('action')
    if action == 'save_data':
        data = request.get_json()

        # check if reg number already exists
        check = Haulier.query.filter_by(registration_number=data['ref']).count()
        if check > 0:
            message = "This registration number is already use by another haulier."
            return json.dumps({'status': 2, 'data': data, 'message': message, 'error': [message]})

        log = Haulier()
        log.company_name = data['name']
        log.registration_number = data['ref']
        log.address = data['address']

        try:
            db.session.add(log)
            db.session.commit()
            haulier_id = log.hid
        except Exception as e:
            db.session.rollback()  # Rollback the changes in case of an error
            return json.dumps({'status': 2, 'data': data, 'message': 'Error adding haulier data', 'error': [str(e)]})

        # fetch the data
        from helpers import resources as resource
        worker = resource.fetch_haulier_data()
        message = f"Information for {data['name']} has been added successfully."
        return json.dumps({'status': 1, 'data': worker, 'message': message, 'error': [None]})

    elif action == 'edit_haulier_data':
        data = request.get_json()

        # check if reg number already exists
        check = db.session.query(Haulier).filter(Haulier.registration_number == data['ref'],
                                                 Haulier.hid != data['id']).count()
        if check > 0:
            message = "This registration number is already in use by another haulier."
            return json.dumps({'status': 2, 'data': data, 'message': message, 'error': [message]})

        try:
            db.session.query(Haulier).filter(Haulier.hid == data['id']).update({
                'company_name': data['name'],
                'registration_number': data['ref'],
                'address': data['address']
            })
            db.session.commit()
        except Exception as e:
            db.session.rollback()  # Rollback the changes in case of an error
            return json.dumps({'status': 2, 'data': data, 'message': 'Error updating haulier data', 'error': [str(e)]})

        # fetch the data
        from helpers import resources as resource
        worker = resource.fetch_haulier_data()  # all users
        message = f"Information for {data['name']} has been updated successfully."
        return json.dumps({'status': 1, 'data': worker, 'message': message, 'error': [None]})

    elif action == 'delete_haulier':
        data = request.get_json()
        message = "Haulier deleted successfully."
        status = 1
        error = None

        # check if customer exists
        check = Haulier.query.filter_by(hid=data['id']).first()

        if not check:
            message = 'haulier not found.'
            status = 2
            error = message
        else:
            Haulier.query.filter_by(hid=data['id']).delete()
            db.session.commit()

        from helpers import resources as resource
        worker = resource.fetch_haulier_data()

        return json.dumps({'status': status, 'data': worker, 'message': message, 'error': [error]})

    message = "Request action not recognized"
    return json.dumps({'status': 2, 'data': None, 'message': message, 'error': [message]})


@app.route('/api/v1/user/<string:action>', methods=['POST'])
def user(action):
    # action = request.args.get('action')
    if action == 'save_data':
        data = request.get_json()

        # check if user already exists
        check = User.query.filter_by(email=data['email']).count()
        if check > 0:
            return json.dumps({'status': 2, 'data': data, 'message': 'Another account is using this email',
                               'error': ['Another account is using this email']})

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
        except Exception as e:
            db.session.rollback()  # Rollback the changes in case of an error
            return json.dumps({'status': 2, 'data': data, 'message': 'Error adding user data', 'error': [str(e)]})

        # fetch the data
        from helpers import resources as resource
        worker = resource.fetch_user_data()  # all users
        message = f"Information for {data['first_name']} has been added successfully."
        return json.dumps({'status': 1, 'data': worker, 'message': message, 'error': [None]})

    elif action == 'edit_user_data':
        data = request.get_json()

        # check if given email already exists for another user
        check = db.session.query(User).filter(User.email == data['email'], User.id != data['id']).count()
        if check > 0:
            return json.dumps({'status': 2, 'data': data, 'message': 'Another account is using this email',
                               'error': ['Another account is using this email']})

        try:
            db.session.query(User).filter(User.id == data['id']).update({
                'fname': data['first_name'].title(),
                'sname': data['last_name'].title(),
                'email': data['email'],
                'admin_type': data['admin_type']
            })
            if data['password']:
                db.session.query(User).filter(User.id == data['id']).update({
                    'password': generate_password_hash(data['password'])
                })
            db.session.commit()
        except Exception as e:
            db.session.rollback()  # Rollback the changes in case of an error
            return json.dumps({'status': 2, 'data': data, 'message': 'Error updating user data', 'error': [str(e)]})

        # fetch the data
        from helpers import resources as resource
        worker = resource.fetch_user_data()  # all users
        message = f"Information for {data['first_name']} has been updated successfully."
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

        # validate password
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
        except Exception as e:
            db.session.rollback()  # Rollback the changes in case of an error
            return json.dumps({'status': 2, 'data': data, 'message': 'Error adding user data', 'error': [str(e)]})

        message = "Sign up was successful. Please login with your new credentials."
        return json.dumps({'status': 1, 'data': data, 'message': message, 'error': [None]})

    elif action == "login-user":
        # db.create_all()
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
        from helpers import resources as resource
        worker = resource.fetch_user_data(check.id)

        message = f'welcome {check.fname} {check.sname}. Please wait while the app loads...'
        return json.dumps({'status': 1, 'data': worker, 'message': message, 'error': [None]})

    elif action == 'get-current-user':
        data = request.get_json()

        # check if user exists
        check = User.query.filter_by(id=data['user_id']).first()
        if check:
            from helpers import resources as resource
            worker = resource.fetch_user_data(check.id)
            return json.dumps({'status': 1, 'data': worker, 'message': 'success', 'error': [None]})

        message = "User is not authenticated"
        return json.dumps({'status': 404, 'data': data, 'message': message, 'error': [message]})

    elif action == 'logout-user':
        data = request.get_json()

        # check if system ip is in session
        if data['ip'] in session:
            del session[data['ip']]

        message = "Logged out successfully"
        return json.dumps({'status': 1, 'data': None, 'message': message, 'error': [None]})

    elif action == 'delete_user':
        data = request.get_json()
        message = "User deleted successfully."
        status = 1
        error = None

        # check if user exists
        check = User.query.filter_by(id=data['id']).first()

        if not check:
            message = 'user not found.'
            status = 2
            error = message
        else:
            User.query.filter_by(id=data['id']).delete()
            db.session.commit()

        from helpers import resources as resource
        users = resource.fetch_user_data()

        return json.dumps({'status': status, 'data': users, 'message': message, 'error': [error]})

    message = "Request action not recognized"
    return json.dumps({'status': 2, 'data': None, 'message': message, 'error': [message]})


@app.route('/fetch_resources/<item>', methods=['POST'])
def fetch_resources(item):
    data = None
    status = 2
    message = "No record fetched"
    if item == 'weight_records':
        # fetch the data
        from helpers import resources as resource
        data = resource.fetch_weight_records()
        status = 1
        message = "Weight records fetched successfully"
        return json.dumps({'status': status, 'data': data, 'message': message, 'error': [message]})

    elif item == 'all':
        # fetch the data
        from helpers import resources as resource
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
        from helpers import resources as resource
        from helpers import myfunctions as myfunc

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

    return json.dumps({'status': status, 'data': data, 'message': message, 'error': [message]})


@app.route('/search/<action>', methods=['POST'])
def search(action):
    if action == 'existing_weight_record':
        data = request.get_json()

        # fetch the customer and haulier data
        from helpers import resources as resource
        customers = resource.fetch_customer_data()
        hauliers = resource.fetch_haulier_data()
        users = resource.fetch_user_data()

        # fetch weight_log data
        if 'weight_log_id' in data:
            # check if waybill exists and have been approved
            check = WaybillLog.query.filter_by(weight_log_id=data['weight_log_id']).first()
            if check:
                if check.approval_status == "approved":
                    message = 'This item has been approved. You cannot make changes to the records.'
                    error = message
                    return json.dumps({'status': 2, 'data': None, 'message': message, 'error': [error]})
            worker = db.session.query(WeightLog).filter(WeightLog.wid == data['weight_log_id']).first()
        else:
            worker = db.session.query(WeightLog).filter(WeightLog.vehicle_id == data['vehicle_id'],
                                                        WeightLog.final_weight.is_(None)).first()
        if worker:
            mr = {}
            mr['id'] = worker.wid
            mr['product'] = worker.product
            mr['order_number'] = worker.order_number
            mr['destination'] = worker.destination
            mr['vehicle_name'] = worker.vehicle_name
            mr['vehicle_id'] = worker.vehicle_id
            mr['driver_phone'] = worker.driver_phone
            mr['driver_name'] = worker.driver_name
            mr['customer_id'] = worker.customer_id
            mr['haulier_id'] = worker.haulier_id
            mr['initial_weight'] = worker.initial_weight
            mr['initial_time'] = worker.initial_time.strftime("%d-%m-%Y %I:%M:%S %p")
            mr['final_weight'] = worker.final_weight if worker.final_weight else ''

            message = 'Existing records was found for this vehicle.'
            return json.dumps({'status': 1, 'data': mr, 'customers': customers, 'hauliers': hauliers,
                               'users': users, 'message': message, 'error': None})

        message = 'No records were found for this vehicle'
        return json.dumps({'status': 2, 'data': None, 'customers': customers, 'hauliers': hauliers,
                           'users': users, 'message': message, 'error': [message]})

    elif action == "fetch_vehicle_records":
        data = request.get_json()
        # check if record exists for the vehicle id
        check = WeightLog.query.filter_by(vehicle_id=data['vehicle_id']).count()
        if check == 0:
            status = 2
            message = "Weight records not found."
            error = message
            worker = data
        else:
            # fetch records
            from helpers import resources as resource
            info = resource.fetch_weight_records()
            worker = [x for x in info if x['vehicle_id'] == data['vehicle_id']]
            status = 1
            error = None
            message = "Weight records fetched successfully"
        return json.dumps({'status': status, 'data': worker, 'message': message, 'error': [error]})

    message = "Request action not recognized"
    return json.dumps({'status': 2, 'data': None, 'message': message, 'error': [message]})


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
