from flask_mail import Message
import datetime


class EmailService:
    """class for sending email"""

    def __init__(self):
        self.template = open("server/instance/email_template.txt", "r")
        self.recipient_email = None
        self.title = ""
        self.date = datetime.datetime.now().strftime("%d, %A %Y")
        self.sender = 'zinando2000@gmail.com'  #  ('Pikanto', 'zinando2000@gmail.com')

    def prepare_email(self, body):

        email_body = self.template.read()
        mdate = self.date
        # emailBody=emailBody.replace('#title#',subject)
        email_body = email_body.replace('#title#', '')
        email_body = email_body.replace('#date#', mdate)
        email_body = email_body.replace('#body#', body)

        return email_body

    def sendmail(self, body):
        from server.extensions import mail
        try:
            msg = Message(self.title, sender=self.sender, recipients=[self.recipient_email])
            msg.html = body
            mail.send(msg)
        except Exception as e:
            return {"status": 2, "message": str(e)}

        return {"status": 1, "message": "message sent!"}


email_template = '''
    <!DOCTYPE html>
<html>

<head>
    <title>Pikanto | Waybill Information</title>
    <!-- Bootstrap CSS -->
    <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css" rel="stylesheet">
    <style>
        /* Additional custom styles if needed */
        img {
            max-width: 100%;
            height: auto;
        }

        /* Adjustments for mobile view */
        @media (max-width: 576px) {
            .img-fluid {
                max-width: 100%;
            }
        }
    </style>
</head>

<body>
    <div class="container">
        <div class="row">
            <!-- Logo -->
            <div class="col-md-12 text-center">
                <img src="https://i.imgur.com/iP3xtXj.png" alt="Company Logo" class="img-fluid">
            </div>
        </div>

        <div class="row">
            <div class="col-md-12">
                <p class="text-center">You have been requested to review the following information and to append your
                    approval of the waybill by providing your Pikanto app password using the below form.</p>
            </div>
        </div>

        <div class="row">
            <div class="col-md-12">
                <!-- Table 1 -->
                <h2>WEIGHBRIDGE SLIP</h2>
                <div class="table-responsive">
                    <table class="table">
                        {{table1_data | safe}}
                    </table>
                </div>

                <!-- Table 2 -->
                <hr class="my-4">
                <h2>WAYBILL DATA</h2>
                <div class="table-responsive">
                    <table class="table">
                        {{table2_data | safe}}
                    </table>
                </div>
                <hr class="my-4">
                <!-- Table 3 -->
                <h2>Products</h2>
                <div class="table-responsive">
                    <table class="table table-bordered">
                        <!-- Table 3 headers -->
                        <thead class="thead-dark">
                            <tr>
                                <th>Product Description</th>
                                <th>Product Code</th>
                                <th>No of Packages (Bags/Boxes)</th>
                                <th>Quantity (MT/NOs)</th>
                                <th>Accepted Quantity</th>
                                <th>Remarks</th>
                                <!-- Add more headers if needed -->
                            </tr>
                        </thead>
                        <tbody>
                            <!-- Populate table 3 data -->
                            {{table3_data | safe}}
                        </tbody>
                    </table>
                </div>

                <!-- Table 4 -->
                <h2>Bad Products</h2>
                <div class="table-responsive">
                    <table class="table table-bordered">
                        <!-- Table 4 headers -->
                        <thead class="thead-dark">
                            <tr>
                                <th>Product Description</th>
                                <th>Damaged Quantity</th>
                                <th>Shortage</th>
                                <th>Batch Number</th>
                                <!-- Add more headers if needed -->
                            </tr>
                        </thead>
                        <tbody>
                            <!-- Populate table 4 data -->
                            {{table4_data | safe}}
                        </tbody>
                    </table>
                </div>

                <!-- Password Form -->
                <div class="table-responsive">
                    <div style="color: #e97464">{{response}}</div>
                    <hr class="my-4">
                    <h3 class="text-center">Enter your password below to approve:</h3>
                    <form method="post" action="/approve?email={{email}}&wtlog_id={{weight_log_id}}">
                        <div class="form-group">
                            <label for="password">Enter Password:</label>
                            <input type="password" class="form-control" id="password" name="password">
                        </div>
                        <div class="text-center">
                            <button type="submit" class="btn btn-primary">Submit</button>
                        </div>
                    </form>
                </div>
            </div>
        </div>
    </div>

    <!-- Bootstrap JS -->
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
</body>
</html>

    '''

email_template2 = '''
<!DOCTYPE html>
<html>
    <head>
        <title>Pikanto | Waybill Information</title>
        <!-- Bootstrap CSS -->
        <link href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css" rel="stylesheet">
    </head>
    <body>
        <div class="container">
            <!-- Logo -->
            <div class="row justify-content-center">
                <div class="col-sm-8 col-md-6 text-center">
                    <img src="https://i.imgur.com/iP3xtXj.png" alt="Company Logo" class="img-fluid">
                </div>
            </div>        
    
            <p class="text-center">You have been requested to review the following information and to append your approval of the waybill by providing your Pikanto app password using the below form.</p>
    
            {% block content %}
            <!-- Table 1 -->
            <h2>WEIGHBRIDGE SLIP</h2>
            <div class="table-responsive">
                <table class="table">
                    {{table1_data | safe}}
                </table>
            </div>
    
            <!-- Table 2 -->
            <hr class="my-4">
            <h2>WAYBILL DATA</h2>
            <div class="table-responsive">
                <table class="table">
                    {{table2_data | safe}}
                </table>
            </div>
            <hr class="my-4">
            <!-- Table 3 -->
            <h2>Products</h2>
            <div class="table-responsive">
                <table class="table table-bordered">
                    <thead class="thead-dark">
                        <tr>
                            <th>Product Description</th>
                            <th>Product Code</th>
                            <th>No of Packages (Bags/Boxes)</th>
                            <th>Quantity (MT/NOs)</th>
                            <th>Accepted Quantity</th>
                            <th>Remarks</th>
                            <!-- Add more headers if needed -->
                        </tr>
                    </thead>
                    <tbody>
                        <!-- Populate table 3 data -->
                        {{table3_data | safe}}
                    </tbody>
                </table>
            </div>
    
            <!-- Table 4 -->
            <h2>Bad Products</h2>
            <div class="table-responsive">
                <table class="table table-bordered">
                    <thead class="thead-dark">
                        <tr>
                            <th>Product Description</th>
                            <th>Damaged Quantity</th>
                            <th>Shortage</th>
                            <th>Batch Number</th>
                            <!-- Add more headers if needed -->
                        </tr>
                    </thead>
                    <tbody>
                        <!-- Populate table 4 data -->
                        {{table4_data | safe}}
                    </tbody>
                </table>
            </div>
    
            <hr class="my-4">
            <!-- Password Form -->
            <div class="table-responsive">
                <div style="color: #e97464">{{response}}</div>
                <hr class="my-4">
                <h3 class="text-center">Enter your password below to approve:</h3>
                <form method="post" action="/approve?email={{email}}&wtlog_id={{weight_log_id}}">
                    <div class="form-group">
                        <label for="password">Enter Password:</label>
                        <input type="password" class="form-control" id="password" name="password">
                    </div>
                    <div class="text-center">
                        <button type="submit" class="btn btn-primary">Submit</button>
                    </div>
                </form>
            </div>
            {% endblock content %}
        </div>
    
        <!-- Bootstrap JS -->
        <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
    </body>
</html>
    '''