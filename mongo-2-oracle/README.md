# MongoDB to Oracle Database 23ai Migration

**Summary:** Contained herein is a  bash script for demonstrating and managing MongoDB to Oracle Database migration in a containerized environment. The `orclMongoMigration.sh` script provides a full-featured environment for demonstrating how to migrate data from MongoDB to Oracle Database. It handles container management, database setup, MongoDB configuration, and the complete migration process in an interactive, user-friendly way.

## Key Features

**Container Management:**
* Start/stop Oracle Database containers
* Automatic configuration and environment setup
* Interactive menu system with color-coded output
* Comprehensive command-line interface for automation
* File transfer between host and container
* Volume and resource management

**Database Setup and Access:**
* Automatic Oracle Database configuration
* Multiple SQL*Plus access modes (nolog, user, SYSDBA)
* ORDS (Oracle REST Data Services) setup and management
* MongoDB initialization and configuration
* MongoDB API compatibility for Oracle

**MongoDB and Migration:**
* MongoDB instance setup and configuration
* MongoDB shell access via mongosh
* Oracle Database MongoDB API connectivity
* Complete data migration workflow from MongoDB to Oracle
* Sample data generation and import
* Interactive migration process with step-by-step guidance
Demo Application
* Registration demo app deployment
* Sample data generation with geographic features
* Data visualization and testing

## Prerequisites
* Podman installed (script can install it if not present)
* macOS or Linux operating system
* Internet connection
* 8GB+ RAM recommended for running the Oracle Database container

## Installation

1. Download the script

    ```bash
    wget https://github.com/oracle-devrel/devo.tutorials/blob/mongo-2-oracle-migration/mongo-2-oracle/src/orclMongoMigration.sh
    ```

2. Change permissions to make the script executable

    ```bash
    chmod +x orclMongoMigration.sh
    ```

3. Set the global variables within the script file.

    >NOTE: See [the step by step guide](step-by-step-guide.md) for details on setting global variables.

4. Run the script without arguments to display a user-friendly menu with the following sections:

    ```bash
    ./orclMongoMigration.sh
    ```

    * **Container Management:** - Start/stop Oracle container - Bash and root access - Install utilities and manage volumes - Copy files in and out
    * **Database Access & Utilities:** - SQL*Plus connections (nolog, user, SYSDBA) - ORDS setup and management - MongoDB API connectivity
    * **MongoDB Operations:** - Start MongoDB instance - mongosh to ORDS or MongoDB
    * **Application & Migration:** - Run registration demo app - Add demo data - Migrate data from MongoDB to Oracle

5. For a comprehensive walkthru, please visit the [step-by-step guide](step-by-step-guide.md).

## Available Commandline Arguments

* Container Management:

    ```bash
    start     - Start Oracle container
    stop      - Stop Oracle container
    restart   - Restart Oracle container
    bash      - Bash access to container
    root      - Root access to container
    remove    - Remove Oracle container
    utils     - Install utilities
    copyin    - Copy file into container
    copyout   - Copy file out of container
    clean     - Clean unused volumes
    ```

* Database Access:

    ```bash
    sqlnolog  - SQL*Plus nolog connection
    sqluser   - SQL*Plus user connection
    sqlsys    - SQL*Plus SYSDBA connection
    setupords - Setup ORDS
    ords      - Start ORDS service
    mongoapi  - Check MongoDB API connection
    ```

* MongoDB Commands:

    ```bash
    mongodb   - Start MongoDB instance
    mongoords - Connect to MongoDB via ORDS
    mongo     - Connect to MongoDB directly
    ```

* Application Commands:

    ```bash
    demoapp   - Run Registration Demo App
    demodata  - Add demo data
    migrate   - Migrate data
    help      - Show help message
    ```

## Migration Workflow Example
Here’s a typical workflow for demonstrating MongoDB to Oracle migration:
1.	Start the container:

    ```bash
 	./orclMongoMigration.sh start
    ```
2.	Start MongoDB instance:
    ```bash
 	./orclMongoMigration.sh mongodb
    ```
3.	Generate demo data:
    ```bash
 	./orclMongoMigration.sh demodata
    ```
4.	Perform the migration:
    ```bash
 	./orclMongoMigration.sh migrate
    ```
5.	Verify the migrated data in Oracle: (The script will offer to connect you to SQL*Plus after migration)

## Container Details
* **Image:** Oracle Database Free (container-registry.oracle.com/database/free)
* **Default Credentials:**
* SYS/SYSTEM password: Oradoc_db1
* Created user: matt with password matt
* **Exposed Ports:**
* 1521: Oracle Database listener
* 3000: Node.js demonstration app
* 5500: Enterprise Manager Express
* 8080/8443: ORDS (Oracle REST Data Services)
* 27017: MongoDB API compatibility
* 23456: MongoDB native port

## Troubleshooting
* If the Oracle container fails to start, try running ./orclMongoMigration.sh clean to remove unused volumes
* For migration issues, check that both MongoDB and ORDS are running
* If demo data generation fails, ensure Python libraries are installed correctly
* Check container logs for Oracle Database startup issues


## Acknowledgments
* Created by Matt DeMarco (matthew.demarco@oracle.com)
* Oracle Database Free images provided by Oracle


