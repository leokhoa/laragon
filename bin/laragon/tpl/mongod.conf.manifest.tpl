storage:
  dbPath: mongodb  # Path to store database files
systemLog:
  destination: file
  path: mongod.log  # Log file path
  logAppend: true
net:
  bindIp: 127.0.0.1  # Only allow local connections
  port: 27017        # Default MongoDB port
security:
  authorization: disabled  # Disable authentication for minimal setup
