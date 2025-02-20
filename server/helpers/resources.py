import datetime
import json


def fetch_waybill_data(wid: int = None):
    """Fetches waybill information from the database.

    Args:
        wid (int, optional): Waybill ID. If provided, retrieves data for the specific waybill with this ID.
                             If not provided (default), retrieves information for all waybills.

    Returns:
        list or dict: If wid is None, returns a list of dictionaries, each containing waybill details
                      with keys: 'waybill_id', 'waybill_number', 'company_ref', 'address', 'description',
                      'vehicle_id', 'item_code', 'product_count', 'product_weight', 'accepted_qty',
                      'damaged_qty', 'shortage', 'attachments', 'batch_number', 'receiver',
                      'delivered_by', 'remarks', 'weight_log_id', 'product_condition', 'customer_id'.
                      If wid is provided and a waybill exists with that ID, returns a dictionary
                      containing waybill details with the same keys.
                      Returns an empty list if no waybills are found when wid is None.
                      Returns an empty dictionary if no waybill is found for the provided wid.
    """
    from extensions import db, WaybillLog, WeightLog

    if wid is None:
        # Fetch information for all waybills
        data = WaybillLog.query.all()
        waybill_list = []
        if data:
            for waybill in data:
                mr = {}
                mr['waybill_id'] = waybill.wid
                mr['waybill_number'] = waybill.waybill_number
                mr['haulier_ref'] = waybill.haulier_ref
                mr['customer_ref'] = waybill.customer_ref
                mr['customer_id'] = waybill.customer_id
                mr['haulier_id'] = waybill.haulier_id
                mr['weight_log_id'] = waybill.weight_log_id
                mr['address'] = waybill.delivery_address
                mr['product_info'] = json.loads(waybill.product_info)
                mr['product_condition'] = waybill.product_condition
                mr['bad_product_info'] = waybill.bad_product_info
                mr['received_by'] = waybill.received_by
                mr['delivered_by'] = waybill.delivered_by
                mr['attachments'] = [] if waybill.file_link is None else json.loads(waybill.file_link)
                # get ticket info as well
                weight_log = WeightLog.query.filter_by(wid=waybill.weight_log_id).first()
                mr['vehicle_id'] = weight_log.vehicle_id if weight_log else None
                waybill_list.append(mr)
            return waybill_list
        else:
            return waybill_list

    # Fetch information for a specific waybill with provided wid
    waybill = WaybillLog.query.filter_by(wid=wid).first()
    mr = {}
    if waybill:
        mr['waybill_id'] = waybill.wid
        mr['waybill_number'] = waybill.waybill_number
        mr['haulier_ref'] = waybill.haulier_ref
        mr['customer_ref'] = waybill.customer_ref
        mr['customer_id'] = waybill.customer_id
        mr['haulier_id'] = waybill.haulier_id
        mr['weight_log_id'] = waybill.weight_log_id
        mr['address'] = waybill.delivery_address
        mr['product_info'] = json.loads(waybill.product_info)
        mr['product_condition'] = waybill.product_condition
        mr['bad_product_info'] = waybill.bad_product_info
        mr['received_by'] = waybill.received_by
        mr['delivered_by'] = waybill.delivered_by
        mr['attachments'] = [] if waybill.file_link is None else json.loads(waybill.file_link)
        # get ticket info as well
        weight_log = WeightLog.query.filter_by(wid=waybill.weight_log_id).first()
        mr['vehicle_id'] = weight_log.vehicle_id if weight_log else None

    return mr


def fetch_customer_data(cid: int = None):
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
    from extensions import db, Customer

    if cid is None:
        # Fetch information for all customers
        data = Customer.query.all()
        mylist = []
        count = 1
        if data:
            for item in data:
                mr = {}
                mr['count'] = count
                mr['customer_id'] = item.cid
                mr['customer_name'] = item.customer_name
                mr['customer_ref'] = item.registration_number
                mr['customer_address'] = item.address
                mylist.append(mr)
                count += 1
        return mylist

    # Fetch information for a specific customer with provided cid
    data = Customer.query.filter_by(cid=cid).first()
    mr = {}
    if data:
        mr['customer_id'] = data.cid
        mr['customer_name'] = data.customer_name
        mr['customer_ref'] = data.registration_number
        mr['customer_address'] = data.address

    return mr


def fetch_haulier_data(hid: int = None):
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
    from extensions import db, Haulier

    if hid is None:
        # Fetch information for all hauliers
        data = Haulier.query.all()
        mylist = []
        count = 1
        if data:
            for item in data:
                mr = {}
                mr['count'] = count
                mr['haulier_id'] = item.hid
                mr['haulier_name'] = item.company_name
                mr['haulier_ref'] = item.registration_number
                mr['haulier_address'] = item.address
                mylist.append(mr)
                count += 1
        return mylist

    # Fetch information for a specific haulier with provided hid
    data = Haulier.query.filter_by(hid=hid).first()
    mr = {}
    if data:
        mr['haulier_id'] = data.hid
        mr['haulier_name'] = data.company_name
        mr['haulier_ref'] = data.registration_number
        mr['haulier_address'] = data.address

    return mr


def fetch_user_data(user_id: int = None):
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
    from extensions import db, User

    if user_id is None:
        # Fetch information for all users
        data = User.query.all()
        user_list = []
        count = 1
        if data:
            for user in data:
                user_info = {}
                user_info['count'] = count
                user_info['user_id'] = user.id
                user_info['first_name'] = user.fname
                user_info['last_name'] = user.sname
                user_info['full_name'] = f"{user.sname} {user.fname}"
                user_info['email'] = user.email
                user_info['admin_type'] = user.admin_type
                user_info['activated'] = user.activated
                user_list.append(user_info)
                count += 1
        return user_list


    # Fetch information for a specific user with provided user_id
    data = User.query.filter_by(id=user_id).first()
    user_info = {}
    if data:
        user_info['user_id'] = data.id
        user_info['first_name'] = data.fname
        user_info['last_name'] = data.sname
        user_info['full_name'] = f"{data.sname} {data.fname}"
        user_info['email'] = data.email
        user_info['admin_type'] = data.admin_type
        user_info['activated'] = data.activated
        return user_info

    return user_info  # Returns an empty dictionary if no user is found for the provided user_id


def fetch_weight_records(weight_log_id=None):
    from extensions import db, WeightLog, Haulier, WaybillLog
    if weight_log_id is None:
        recs = db.session.query(WeightLog).order_by(WeightLog.wid.desc()).all()
        data = []
        if recs:
            for worker in recs:
                tym = worker.initial_time.strftime('%I:%M:%S %p') if worker.initial_time else ""
                date = worker.initial_time.strftime('%d-%m-%Y') if worker.initial_time else ""
                tym2 = worker.final_time.strftime('%I:%M:%S %p') if worker.final_time else ""
                date2 = worker.final_time.strftime('%d-%m-%Y') if worker.final_time else ""
                if 0 < worker.haulier_id < 3:
                    haulier_info = Haulier.query.filter_by(hid=worker.haulier_id).first()
                else:
                    haulier_info = Haulier.query.filter_by(hid=1).first()
                haulier_name = haulier_info.company_name
                haulier_id = haulier_info.hid

                mr = {'product': worker.product, 'order_number': worker.order_number, 'destination': worker.destination,
                      'vehicle_name': worker.vehicle_name, 'vehicle_id': worker.vehicle_id,
                      'driver_phone': worker.driver_phone, 'driver_name': worker.driver_name,
                      'customer_id': worker.customer_id, 'haulier': haulier_name,
                      'initial_weight': worker.initial_weight,
                      'initial_time': f"{date}\n{tym}", 'final_weight': worker.final_weight,
                      'final_time': f"{date2}\n{tym2}", 'id': worker.wid, 'haulier_id': haulier_id,
                      'ticket_ready': True if worker.final_weight else False,
                      'waybill_ready': True if WaybillLog.query.filter_by(weight_log_id=worker.wid).first() else False,
                      'approval_status': 'approved' if WaybillLog.query \
                          .filter_by(weight_log_id=worker.wid, approval_status='approved').first() else 'pending',
                      'customers': fetch_customer_data(), 'users': fetch_user_data()}
                data.append(mr)
    else:
        recs = db.session.query(WeightLog).filter_by(wid=weight_log_id).first()
        data = {}
        worker = recs

        tym = worker.initial_time.strftime('%I:%M:%S %p') if worker.initial_time else ""
        date = worker.initial_time.strftime('%d-%m-%Y') if worker.initial_time else ""
        tym2 = worker.final_time.strftime('%I:%M:%S %p') if worker.final_time else ""
        date2 = worker.final_time.strftime('%d-%m-%Y') if worker.final_time else ""
        if 0 < worker.haulier_id < 3:
            haulier_info = Haulier.query.filter_by(hid=worker.haulier_id).first()
        else:
            haulier_info = Haulier.query.filter_by(hid=1).first()
        haulier_name = haulier_info.company_name
        haulier_id = haulier_info.hid

        mr = {'product': worker.product, 'order_number': worker.order_number, 'destination': worker.destination,
              'vehicle_name': worker.vehicle_name, 'vehicle_id': worker.vehicle_id,
              'driver_phone': worker.driver_phone, 'driver_name': worker.driver_name,
              'customer_id': worker.customer_id, 'haulier': haulier_name,
              'initial_weight': worker.initial_weight, 'haulier_id': haulier_id,
              'initial_time': f"{date}\n{tym}", 'final_weight': worker.final_weight,
              'final_time': f"{date2}\n{tym2}", 'id': worker.wid,
              'ticket_ready': True if worker.final_weight else False,
              'customers': fetch_customer_data()}
        data.update(mr)

    return data


def fetch_table_data(weight_log_id):
    """ prepares data to be used to populate waybill table"""
    from extensions import db, WeightLog, Haulier, WaybillLog
    from helpers import myfunctions as func

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
