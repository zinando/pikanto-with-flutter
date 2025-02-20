import eventlet
eventlet.monkey_patch()
from pikanto import create_app

app, socketio = create_app()

if __name__ == '__main__':
    app.logger.info("Starting the Flask-SocketIO app...")
    socketio.run(app, host='0.0.0.0', port=8088, debug=False, log_output=True, use_reloader=False)
    
