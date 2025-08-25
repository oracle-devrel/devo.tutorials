# MongoDB-2-Oracle Migration: Step-by-step runbook

This detailed runbook will guide you through the process of using the `orclMongoMigration.sh` script to demonstrate migrating data from MongoDB to Oracle Database.


## Prerequisites
Before you begin, ensure your system meets these requirements:
* **Operating System**: macOS or Linux
* **Hardware**:
    * At least 8GB RAM (16GB recommended)
    * At least 20GB free disk space
* **Internet Connection**: Required for downloading container images and dependencies
* **Terminal Access**: You’ll be working in the command line

## Getting Started

### Step 1: Make the Script Executable
1.	Open your terminal application
2.	Navigate to the directory containing the script:

    ```bash
 	cd </path/to/script/directory>
    ```
3.	Make the script executable:

    ```bash
 	chmod +x orclMongoMigration.sh
    ```
### Step 2: Understanding the Script’s Interface and global variables
There are two ways to interact with the script:
1.	**Interactive Menu**: Run the script without arguments
2.	**Command Line Arguments**: Run specific commands directly

    >NOTE: For this runbook, we’ll primarily use the interactive menu for clarity, with command examples where helpful.

3. Before running the script, it is important to update the global variables to match your environment. Edit the following items:

    ```bash
    # Global variables
    ORACLE_USER="<your user in quotes>"
    ORACLE_PASS="<your password in quotes>"
    ORACLE_SYS_PASS="<oracle SYS password in quotes>"
    ORACLE_CONTAINER="<name for your container in quotes>"
    ORACLE_PDB="FREEPDB1"
    NETWORK_NAME="demonet" #set network
    // Do not change the settings below this line
    CONTAINER_PORT_MAP="-p 1521:1521 -p 3000:3000 -p 5902:5902 -p 5500:5500 -p 8000:8000 -p 8080:8080 -p 8443:8443 -p 27017:27017 -p 23456:23456"
    MAX_INVALID=3
    INVALID_COUNT=0
    ```

4. Save the script and mvoe to the next step.

## Container Management

### Step 3: Starting the Oracle Container
1.	Run the script without arguments to access the menu:

    ```bash
 	./orclMongoMigration.sh
    ```

2.	You’ll see a color-coded menu with several sections
3.	Press 1 to start the Oracle container
4.	If Podman is not installed, the script will offer to install it for you:
    * Type y and press Enter if prompted to install Podman
    * The script will install Homebrew (if needed) and then Podman
    * This process may take several minutes
5.	Choose the Oracle Database version:
    * Type 2 and press Enter to select the Full Version (required for MongoDB API)
6.	The script will download and start the Oracle container:
    * This is a large download (several GB) and may take time depending on your internet connection
    * Be patient during the initial download
    * After downloading, the container will initialize (this takes several minutes)
7.	The script will automatically install utilities in the container:
    * Various Linux utilities
    * Python 3.12
    * Node.js
    * MongoDB tools
    * ORDS (Oracle REST Data Services)
8.	When complete, you’ll see a list of mapped ports and a success message
9.	Press Enter to return to the main menu

### Step 4: Checking Container Status
1.	You can verify the container is running with option 3 (Bash access)
2.	This will open a shell inside the container
3.	Type exit to return to the script menu

## Database Setup

### Step 5: Setting Up ORDS (Oracle REST Data Services)
1.	From the main menu, press 14 to set up ORDS
2.	The script will:
    * Create necessary users
    * Configure database settings
    * Enable the MongoDB API
    * Start the ORDS service
3.	Wait for the “ORDS setup complete!” message
4.	Press Enter to return to the main menu

### Step 6: Starting MongoDB
1.	From the main menu, press 17 to start MongoDB instance
2.	The script will:
    * Install MongoDB if needed
    * Configure MongoDB to listen on port 23456
    * Start the MongoDB service
3.	Wait for the “MongoDB started successfully” message
4.	Press Enter to return to the main menu

## Working with MongoDB

### Step 7: Connecting to MongoDB
1.	From the main menu, press 19 to connect to MongoDB directly
2.	This will open the MongoDB shell (mongosh)
3.	Try some basic MongoDB commands:

    ```bash
 	// Show databases
    show dbs

    // Create a new database
    use testdb

    // Create a collection and insert a document
    db.testcollection.insertOne({ name: "Test User", email: "test@example.com" })

    // Query the collection
    db.testcollection.find()
    ```

4.	Type exit to exit the MongoDB shell and return to the script menu

## Running the Demo Application

### Step 8: Getting the Demo Application
1.	From the main menu, press 20 to run the Registration Demo App
2.	The script will:
    * Clone the application repository if needed
    * Install Node.js dependencies
    * Prompt the user as to what datastore to use for the application
        * 1 will use MongoDB
        * 2 will use the Oracle Database API for MongoDB
        * 3 will use Autonomous JSON database (still in development)
    * Start the application on port 3000
3.	Access the application in your web browser at:
 	http://localhost:3000
4.	The demo application allows you to register users
5.	Press Ctrl+C in your terminal to stop the application and return to the script

### Step 9: Adding Demo Data
1.	From the main menu, press 21 to add demo data
2.	The script will:
    * Install required Python libraries
    * Set up the geodata directory
    * Download necessary shapefiles
    * Start an interactive session to run the data generation script
3.	When prompted:
    * Enter 10 for the number of fake records
    * Enter 3 for “No images” option (simpler)
4.	The script will generate fake data with geospatial coordinates within the shapefiles
5.	Press Enter to return to the main menu

## Data Migration Process

### Step 10: Migrating Data from MongoDB to Oracle
1.	From the main menu, press 22 to start the migration process
2.	Read the migration information displayed
3.	Press Enter to start the interactive migration tool
4.	In the migration tool menu:
    * Choose option 3 for “Both Export & Import”
5.	For MongoDB export (source) settings:
    * Enter localhost:23456/test as your MongoDB endpoint
    * Leave the authentication fields blank (press Enter)
    * Type no for SSL/TLS connection
    * Press Enter to export all collections (or specify a collection)
    * Press Enter to use default parallel collections
    * Enter /tmp/moveit as the export location
6.	For Oracle MongoDB API (target) settings:
    * Enter matt as the username
    * Enter matt as the password
    * Enter localhost as the hostname
    * Enter matt as the schema name
    * Enter /tmp/moveit as the import location
7.	The script will:
    * Export data from MongoDB to files
    * Import data into Oracle Database via the MongoDB API
    * Show progress in real-time
8.	When the migration completes, you’ll be asked if you want to verify the migration
    * Type y and press Enter to open SQL*Plus for verification
9.	In SQL*Plus, run verification commands:

    ```bash
 	-- List tables
    SELECT table_name FROM user_tables;

    -- Count records in the migrated collection
    SELECT COUNT(*) FROM testcollection;

    -- View sample data
    SELECT * FROM testcollection WHERE ROWNUM <= 5;

    -- Exit SQL*Plus
    EXIT
    ```

10.	Press Enter to return to the main 

## Verification and Troubleshooting

### Step 11: Checking MongoDB API Connection
1.	From the main menu, press 16 to check MongoDB API connection
2.	The script will:
    * Create a test collection
    * Insert a test document
    * Read back the test document
3.	If successful, you’ll see the test document data displayed
4.	Press Enter to return to the main menu

## Step 12: Connecting to Oracle via MongoDB API
1.	From the main menu, press 18 to connect to Oracle via MongoDB API (mongosh ORDS)
2.	This opens a MongoDB shell connected to Oracle’s MongoDB API
3.	Try some commands:
 	
    ```bash
    // Show collections
    show collections

    // Query the migrated collection
    db.testcollection.find()

    // Create a new collection in Oracle via MongoDB API
    db.newcollection.insertOne({ name: "Oracle API Test", value: 42 })

    // Verify it was created
    db.newcollection.find()
    ```

4.	Type exit to exit the shell and return to the script menu

## Shutting Down

### Step 13: Stopping the Container
1.	From the main menu, press 2 to stop the Oracle container
2.	The script will stop all running Oracle containers
3.	Press Enter to return to the main menu
4.	Press 10 to exit the script

## Command Reference
For advanced users or automation, you can run specific commands directly:

### Container Management
    
    ```bash
    ./orclMongoMigration.sh start     # Start Oracle container
    ./orclMongoMigration.sh stop      # Stop Oracle container
    ./orclMongoMigration.sh bash      # Bash access to container
    ./orclMongoMigration.sh root      # Root access to container
    ```

### Database Operations
    
    ```
    ./orclMongoMigration.sh sqluser   # SQL*Plus user connection
    ./orclMongoMigration.sh sqlsys    # SQL*Plus SYSDBA connection
    ./orclMongoMigration.sh ords      # Start ORDS service
    MongoDB Operations
    ./orclMongoMigration.sh mongodb   # Start MongoDB instance
    ./orclMongoMigration.sh mongo     # Connect to MongoDB directly
    ./orclMongoMigration.sh mongoords # Connect to MongoDB via ORDS
    ```

### Application and Migration

    ```bash
    ./orclMongoMigration.sh demoapp   # Run Registration Demo App
    ./orclMongoMigration.sh demodata  # Add demo data
    ./orclMongoMigration.sh migrate   # Migrate data
    Help and Information
    ./orclMongoMigration.sh help      # Show all available commands
    ```

## Summary
________________________________________
This runbook covers the basic workflow for demonstrating MongoDB to Oracle migration. You can explore additional features and options as you become more familiar with the script.
