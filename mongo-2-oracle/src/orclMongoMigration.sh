#!/bin/bash
#
#
#===================================================================================
#
#         FILE: orclMongoMigration.sh 
#
#        USAGE: ./orclMongoMigration.sh [start|stop|restart|bash|root|sql|ords|mongoapi|help]
#
#  DESCRIPTION: Migration demo container moving MongoDB to Oracle
#      OPTIONS: See menu or command line arguments
# REQUIREMENTS: Podman, internet connection
#       AUTHOR: Matt DeMarco (matthew.demarco@oracle.com)
#      CREATED: 04.01.2025
#      VERSION: 1.1
#
#===================================================================================

# Copyright (c) 2025 Oracle and/or its affiliates.

# The Universal Permissive License (UPL), Version 1.0

# Subject to the condition set forth below, permission is hereby granted to any
# person obtaining a copy of this software, associated documentation and/or data
# (collectively the "Software"), free of charge and under any and all copyright
# rights in the Software, and any and all patent rights owned or freely
# licensable by each licensor hereunder covering either (i) the unmodified
# Software as contributed to or provided by such licensor, or (ii) the Larger
# Works (as defined below), to deal in both

# (a) the Software, and
# (b) any piece of software and/or hardware listed in the lrgrwrks.txt file if
# one is included with the Software (each a "Larger Work" to which the Software
# is contributed by such licensors),

# without restriction, including without limitation the rights to copy, create
# derivative works of, display, perform, and distribute the Software and make,
# use, sell, offer for sale, import, export, have made, and have sold the
# Software and the Larger Work(s), and to sublicense the foregoing rights on
# either these or other terms.

# This license is subject to the following condition:
# The above copyright notice and either this complete permission notice or at
# a minimum a reference to the UPL must be included in all copies or
# substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# Global variables
ORACLE_USER="<--->"
ORACLE_PASS="<--->"
ORACLE_SYS_PASS="<--->"
ORACLE_CONTAINER="<--->"
ORACLE_PDB="FREEPDB1"
NETWORK_NAME="demonet" #set network
CONTAINER_PORT_MAP="-p 1521:1521 -p 3000:3000 -p 5902:5902 -p 5500:5500 -p 8000:8000 -p 8080:8080 -p 8443:8443 -p 27017:27017 -p 23456:23456"
MAX_INVALID=3
INVALID_COUNT=0

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color



#===========================
# Helper Functions
#===========================

logInfo() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

logWarning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

logError() {
    echo -e "${RED}[ERROR]${NC} $1"
}

logSuccess() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Display formatted menu
displayMenu() {
    clear
    echo -e "${CYAN}===========================================================================${NC}"
    echo -e "${CYAN}          Oracle Database & MongoDB Migration Demo Toolkit                 ${NC}"
    echo -e "${CYAN}===========================================================================${NC}"
    
    echo -e "\n${GREEN}Container Management:${NC}"
    echo "  1) Start Oracle container          6) Install utilities"
    echo "  2) Stop Oracle container           7) Copy file into container"
    echo "  3) Bash access                     8) Copy file out of container"
    echo "  4) Root access                     9) Clean unused volumes"
    echo "  5) Remove Oracle container         10) Exit script"
    
    echo -e "\n${GREEN}Database Access & Utilities:${NC}"
    echo "  11) SQL*Plus nolog connection      14) Setup ORDS"
    echo "  12) SQL*Plus user connection       15) Start ORDS service"
    echo "  13) SQL*Plus SYSDBA connection     16) Check MongoDB API connection"
    
    echo -e "\n${GREEN}MongoDB Operations:${NC}"
    echo "  17) Start MongoDB instance         19) mongosh to MongoDB"
    echo "  18) mongosh to MongoDB API"
    
    echo -e "\n${GREEN}Application & Migration:${NC}"
    echo "  20) Run Registration Demo App      22) Migrate data"
    echo "  21) Add demo data"

    echo -e "\n${CYAN}===========================================================================${NC}"
    read -p "Please enter your choice [1-22]: " menuChoice
    export menuChoice=$menuChoice
}

# Check if podman is installed and running
checkPodman() {
    if ! command -v podman > /dev/null 2>&1; then
        logError "Podman is not installed on your system."

        read -p "Would you like to install Podman and its dependencies? (y/n): " choice
        if [[ "$choice" =~ ^[Yy]$ ]]; then
            logInfo "Installing Podman and dependencies..."

            # Install Homebrew if it's not installed
            if ! command -v brew > /dev/null 2>&1; then
                logInfo "Homebrew is not installed. Installing Homebrew first..."
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
                export PATH="/usr/local/bin:$PATH"  # For Intel Macs
                export PATH="/opt/homebrew/bin:$PATH"  # For Apple Silicon
            fi

            # Install Podman, QEMU, and vfkit
            brew tap cfergeau/crc
            brew install vfkit qemu podman podman-desktop

            # Initialize Podman machine
            logInfo "Initializing Podman machine..."
            podman machine init --cpus 8 --memory 16384 --disk-size 550

            logInfo "Starting Podman machine..."
            podman machine start

            logSuccess "Podman installation complete!"
        else
            logError "Podman is required to run this script. Exiting..."
            exit 1
        fi
    fi

    # Verify Podman is running
    if ! podman ps > /dev/null 2>&1; then
        logInfo "Podman is installed but not running. Starting Podman machine..."
        podman machine start
    fi
}

# Create podman network if it doesn't exist
createPodnet() {
    if ! podman network inspect $NETWORK_NAME &>/dev/null; then
        logInfo "Creating podman network '$NETWORK_NAME'..."
        podman network create -d bridge $NETWORK_NAME
    fi
}

# Get running container ID/name
getContainerId() {
    export orclRunning=$(podman ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i $ORACLE_CONTAINER | awk '{print $2}')
    echo $orclRunning
}

# Countdown timer
countDown() {
    message=${1:-"Please wait..."}
    seconds=${2:-3}
    
    logInfo "$message"
    for (( i=$seconds; i>=1; i-- )); do
        echo -ne "\rStarting in $i seconds..."
        sleep 1
    done
    echo -e "\rStarting now!                  "
}

# Handle invalid menu choice
badChoice() {
    # Increment the invalid choice counter
    ((INVALID_COUNT++))

    logWarning "Invalid choice, please try again..."
    logWarning "Attempt $INVALID_COUNT of $MAX_INVALID."

    # Check if invalid attempts exceed the max allowed
    if [ "$INVALID_COUNT" -ge "$MAX_INVALID" ]; then
        logError "Too many invalid attempts. Exiting the script..."
        exit 1
    fi

    sleep 2
}

#===========================
# Core Functions
#===========================

# Exit function
doNothing() {
    logWarning "You want to quit...yes?"
    read -p "Enter yes or no: " doWhat
    if [[ $doWhat = yes ]]; then
        logInfo "Bye! ¯\\_(ツ)_/¯"
        exit 0
    else
        return
    fi
}

# List container ports
listPorts() {
    container_id=$(getContainerId)
    if [ -n "$container_id" ]; then
        logInfo "Container ports:"
        podman port "$container_id"

        logInfo "Container IP address:"
        podman inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_id"
    else
        logError "No running container found."
    fi
}

# Start Oracle container
startOracle() {
    checkPodman
    createPodnet
    
    # Check if container is already running
    export orclRunning=$(getContainerId)
    export orclPresent=$(podman container ls -a --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i $ORACLE_CONTAINER | awk '{print $2}')

    if [ "$orclRunning" == "$ORACLE_CONTAINER" ]; then
        logWarning "Oracle podman container is already running."
        listPorts
        return
    elif [ "$orclPresent" == "$ORACLE_CONTAINER" ]; then
        logInfo "Oracle podman container found, restarting..."
        podman restart $orclPresent
        countDown "Waiting for Oracle to start" 3
        serveORDS
    else
        echo "Please choose the Oracle Database container version:"
        echo "1. Lite Version (Good for general database development)"
        echo "2. Full Version (Required for the MongoDB API)"
        read -p "Enter your choice [1/2]: " choice

        case $choice in
            1)
                image="container-registry.oracle.com/database/free:23.5.0.0-lite"
                ;;
            2)
                image="container-registry.oracle.com/database/free:latest"
                ;;
            *)
                logWarning "Invalid choice. Defaulting to Full version."
                image="container-registry.oracle.com/database/free:latest"
                ;;
        esac

        logInfo "Provisioning new Oracle container with image: $image"
        podman run -d --network="podmannet" $CONTAINER_PORT_MAP -it --name $ORACLE_CONTAINER $image

        if [ $? -ne 0 ]; then
            logError "Failed to start Oracle container."
            return 1
        fi

        logSuccess "Oracle container started successfully."
        countDown "Waiting for Oracle to initialize" 3
        installUtils
    fi
    listPorts
}

# Stop Oracle container
stopOracle() {
    checkPodman
    export stopOrcl=$(podman ps --no-trunc | grep -i oracle | awk '{print $1}')
    
    if [ -z "$stopOrcl" ]; then
        logWarning "No Oracle containers are running."
        return
    fi

    for i in $stopOrcl; do
        logInfo "Stopping container: $i"
        podman stop $i
        if [ $? -eq 0 ]; then
            logSuccess "Container stopped successfully."
        else
            logError "Failed to stop container."
        fi
    done

    cleanVolumes
}

# Clean unused volumes
cleanVolumes() {
    logInfo "Cleaning unused volumes..."
    podman volume prune -f
    logSuccess "Volumes cleaned."
}

# Remove container
removeContainer() {
    stopOracle
    logInfo "Removing Oracle container..."
    podman rm $(podman ps -a | grep $ORACLE_CONTAINER | awk '{print $1}')
    if [ $? -eq 0 ]; then
        logSuccess "Container removed successfully."
    else
        logError "Failed to remove container."
    fi
}

# Get bash access to container
bashAccess() {
    checkPodman
    export orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi
    
    logInfo "Opening bash shell in container..."
    podman exec -it $orclImage /bin/bash
}

# Get root access to container
rootAccess() {
    checkPodman
    export orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi
    
    logInfo "Opening root shell in container..."
    podman exec -it -u 0 $orclImage /bin/bash
}

# Get SQLPlus nolog access
sqlPlusNolog() {
    checkPodman
    export orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi
    
    logInfo "Opening SQLPlus session (no login)..."
    podman exec -it $orclImage bash -c "source /home/oracle/.bashrc; sqlplus /nolog"
}

# Get SYSDBA access
sysDba() {
    checkPodman
    export orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi
    
    logInfo "Opening SQLPlus session as SYSDBA..."
    podman exec -it $orclImage bash -c "source /home/oracle/.bashrc; /home/oracle/sqlcl/bin/sql sys/$ORACLE_SYS_PASS@'(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=$ORACLE_PDB)))' as sysdba"
}

# Create user account
createUser() {
    checkPodman
    export orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi
    
    logInfo "Creating user account..."
    podman exec -it $orclImage bash -c "source /home/oracle/.bashrc; /home/oracle/sqlcl/bin/sql sys/$ORACLE_SYS_PASS@'(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=$ORACLE_PDB)))' as sysdba <<EOF
    grant sysdba,dba to $ORACLE_USER identified by $ORACLE_PASS;
    exit;
EOF"
}

# Get SQLPlus user access
sqlPlusUser() {
    checkPodman
    export orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi
    
    createUser
    logInfo "Opening SQLPlus session as $ORACLE_USER..."
    podman exec -it $orclImage bash -c "source /home/oracle/.bashrc; /home/oracle/sqlcl/bin/sql $ORACLE_USER/$ORACLE_PASS@'(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=$ORACLE_PDB)))'"
}

# Set Oracle password
setOrclPwd() {
    checkPodman
    export orclRunning=$(getContainerId)
    
    if [ -z "$orclRunning" ]; then
        logError "Oracle container is not running."
        return 1
    fi
    
    logInfo "Setting Oracle password..."
    podman exec $orclRunning /home/oracle/setPassword.sh $ORACLE_SYS_PASS
}

# Install MongoDB tools
installMongoTools() {
    export orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi
    
    logInfo "Installing MongoDB tools..."
    podman exec -i -u 0 $orclImage /usr/bin/bash -c "echo '[mongodb-org-8.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/8/mongodb-org/8.0/aarch64/
gpgcheck=1
enabled=1
gpgkey=https://pgp.mongodb.com/server-8.0.asc' >>/etc/yum.repos.d/mongodb-org-8.0.repo"

    podman exec -i -u 0 $orclImage /usr/bin/yum install -y mongodb-mongosh
    logSuccess "MongoDB tools installed successfully."
}

# Start MongoDB inside the Oracle container
startMongoDB() {
    export container_id=$(getContainerId)

    if [ -z "$container_id" ]; then
        logError "Oracle container is not running."
        return 1
    fi

    logInfo "Checking if MongoDB is already running..."
    podman exec -i $container_id pgrep mongod >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        logInfo "MongoDB is already running in the container."
        return 0
    fi

    logInfo "MongoDB is not running. Installing MongoDB..."

    podman exec -i -u 0 $container_id /usr/bin/yum install -y mongodb-org

    logInfo "Configuring MongoDB on port 23456..."
    podman exec -i -u 0 $container_id /usr/bin/bash -c "
        sed -i 's|bindIp: 127.0.0.1|bindIp: 0.0.0.0|' /etc/mongod.conf
        sed -i 's|port: 27017|port: 23456|' /etc/mongod.conf
    "

    logInfo "Starting MongoDB instance..."

    # No Replica set config
    podman exec -d -u 0 $orclImage /usr/bin/mongod --bind_ip_all --config /etc/mongod.conf 

    # Replica set configuration
    #podman exec -d -u 0 $container_id /usr/bin/mongod --bind_ip_all --replSet myReplSet --config /etc/mongod.conf 

    # get IP address for setting replica set use
    # rsIPAddr=$(podman inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_id")
    # echo $rsIPAddr

    # 1 member
    # rsConfig="{_id: 'myReplSet',members: [{ _id: 0, host: '${rsIPAddr}:23456' }]}"

    # 2 members
    # rsConfig="{_id: 'myReplSet',members: [{ _id: 0, host: '${rsIPAddr}:23456' },{ _id: 1, host: 'localhost:23456' }]}"
    # echo $rsConfig

    sleep 1
    # start replSet for GG CDC
    # podman exec -u 0 $container_id mongosh --port 23456 --eval "rs.initiate(${rsConfig});rs.status();"

    # podman exec -u 0 $container_id mongosh --port 23456 --eval "rs.reconfig({_id: 'myReplSet',members: [{ _id: 0, host: '${rsIPAddr}:23456' }]}, { force: true });rs.status();"
    

    # Verify it started
    sleep 2
    podman exec -i $container_id pgrep mongod >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        logSuccess "MongoDB started successfully."
    else
        logError "MongoDB failed to start."
        return 1
    fi
}

# Install utilities
installUtils() {
    logInfo "Installing useful tools after provisioning container..."
    logWarning "Please be patient as this can take time given network latency."

    checkPodman
    export container_id=$(getContainerId)
    
    if [ -z "$container_id" ]; then
        logError "Oracle container is not running."
        return 1
    fi
    
    # workaround for ol repo issues
    logInfo "Configuring YUM repositories..."
    podman exec -it -u 0 $container_id /bin/bash -c "/usr/bin/touch /etc/yum/vars/ociregion"
    podman exec -it -u 0 $container_id /bin/bash -c "/usr/bin/echo > /etc/yum/vars/ociregion"

    # Add sudo access for oracle user
    podman exec -it -u 0 $container_id /bin/bash -c "/usr/bin/echo 'oracle ALL=(ALL) NOPASSWD: ALL' >>/etc/sudoers"

    # Install EPEL repository
    logInfo "Installing EPEL repository..."
    podman exec -it -u 0 $container_id /usr/bin/rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
    podman exec -it -u 0 $container_id /usr/bin/yum update -y

    # Install required packages
    logInfo "Installing required packages..."
    podman exec -it -u 0 $container_id /usr/bin/yum install -y sudo which java-17-openjdk wget htop lsof zip unzip rlwrap git python3.12 python3-pip

    # Install pip for Python 3.12
    logInfo "Installing pip for Python 3.12..."
    podman exec -it -u 0 $container_id /bin/bash -c "curl https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py; python3.12 /tmp/get-pip.py"

    # Install Node.js
    logInfo "Installing Node.js..."
    podman exec -it -u 0 $container_id bash -c "curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - && yum install -y nodejs"
   
    # Download and install ORDS
    logInfo "Downloading and installing ORDS..."
    podman exec $container_id /usr/bin/wget -O /home/oracle/ords.zip https://download.oracle.com/otn_software/java/ords/ords-latest.zip
    podman exec $container_id /usr/bin/unzip /home/oracle/ords.zip -d /home/oracle/ords/


    # Download and install SQLcl
    logInfo "Downloading and installing SQLcl..."
    podman exec $container_id /usr/bin/wget -O /home/oracle/sqlcl.zip https://download.oracle.com/otn_software/java/sqldeveloper/sqlcl-latest.zip
    podman exec $container_id /usr/bin/unzip /home/oracle/sqlcl.zip -d /home/oracle/
    # add alias for sqlcl to be invoked by sqlplus
    podman exec -i -u 0 $container_id /bin/bash -c "echo 'alias sqlplus=/home/oracle/sqlcl/bin/sql' >> /home/oracle/.bashrc"

    
    # Install MongoDB tools
    installMongoTools

    # Install personal tools
    logInfo "Installing personal tools..."
    podman exec $container_id /usr/bin/wget -O /tmp/PS1.sh https://raw.githubusercontent.com/mattdee/orclDocker/main/PS1.sh
    podman exec $container_id /bin/bash /tmp/PS1.sh
    podman exec $container_id /usr/bin/wget -O /opt/oracle/product/23ai/dbhomeFree/sqlplus/admin/glogin.sql https://raw.githubusercontent.com/mattdee/orclDocker/main/glogin.sql
    
    # Set Oracle password
    setOrclPwd
    
    logSuccess "Utilities installation complete!"
}

# Copy file into container
copyIn() {
    checkPodman
    export orclRunning=$(getContainerId)
    
    if [ -z "$orclRunning" ]; then
        logError "Oracle container is not running."
        return 1
    fi
    
    read -p "Please enter the ABSOLUTE PATH to the file you want copied: " thePath
    read -p "Please enter the FILE NAME you want copied: " theFile
    
    logInfo "Copying file: $thePath/$theFile into container..."
    podman cp $thePath/$theFile $orclRunning:/tmp
    
    if [ $? -eq 0 ]; then
        logSuccess "File copied successfully to /tmp/$theFile in the container."
    else
        logError "Failed to copy file into container."
    fi
}

# Copy file out of container
copyOut() {
    checkPodman
    export orclRunning=$(getContainerId)
    
    if [ -z "$orclRunning" ]; then
        logError "Oracle container is not running."
        return 1
    fi
    
    read -p "Please enter the ABSOLUTE PATH in the CONTAINER to the file you want copied to host: " thePath
    read -p "Please enter the FILE NAME in the CONTAINER you want copied: " theFile
    
    logInfo "Copying file: $orclRunning:$thePath/$theFile to host..."
    podman cp $orclRunning:$thePath/$theFile /tmp/
    
    if [ $? -eq 0 ]; then
        logSuccess "File copied successfully to /tmp/$theFile on your host."
    else
        logError "Failed to copy file from container."
    fi
}

# Setup ORDS
setupORDS() {
    checkPodman
    export orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi
    
    # Create temp password file
    logInfo "Creating temporary password file..."
    podman exec -i -u 0 $orclImage /bin/bash -c "echo '$ORACLE_SYS_PASS' > /tmp/orclpwd"

    logInfo "Configuring ORDS..."

    # Create user for ORDS
    createUser
    
    # ORDS silent setup
    logInfo "Installing ORDS..."
    podman exec -i $orclImage /bin/bash -c "/home/oracle/ords/bin/ords --config /home/oracle/ords_config install --admin-user SYS --db-hostname localhost --db-port 1521 --db-servicename $ORACLE_PDB --log-folder /tmp/ --feature-sdw true --feature-db-api true --feature-rest-enabled-sql true --password-stdin </tmp/orclpwd"
    
    # Set MongoDB API configs
    logInfo "Configuring MongoDB API settings..."
    podman exec -it $orclImage /home/oracle/ords/bin/ords --config /home/oracle/ords_config config set mongo.enabled true
    podman exec -it $orclImage /home/oracle/ords/bin/ords --config /home/oracle/ords_config config set mongo.port 27017
    
    # Display MongoDB API settings
    podman exec -it $orclImage /home/oracle/ords/bin/ords --config /home/oracle/ords_config config info mongo.enabled
    podman exec -it $orclImage /home/oracle/ords/bin/ords --config /home/oracle/ords_config config info mongo.port
    podman exec -it $orclImage /home/oracle/ords/bin/ords --config /home/oracle/ords_config config info mongo.tls

    # Make sure ORDS account is unlocked
    podman exec -it $orclImage bash -c "source /home/oracle/.bashrc; sqlplus sys/$ORACLE_SYS_PASS@'(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=$ORACLE_PDB)))' as sysdba <<EOF
    ALTER USER "ORDS_PUBLIC_USER" ACCOUNT UNLOCK;
    exit;
EOF"

    # Start ORDS
    serveORDS

    # Set database privileges for user
    logInfo "Setting database privileges..."
    podman exec -it $orclImage bash -c "source /home/oracle/.bashrc; sqlplus sys/$ORACLE_SYS_PASS@'(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=$ORACLE_PDB)))' as sysdba <<EOF
    grant soda_app, create session, create table, create view, create sequence, create procedure, create job, unlimited tablespace to $ORACLE_USER;
    exit;
EOF"
    
    # Enable ORDS for user schema
    logInfo "Enabling ORDS for $ORACLE_USER schema..."
    podman exec -it $orclImage bash -c "source /home/oracle/.bashrc; sqlplus $ORACLE_USER/$ORACLE_PASS@'(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=$ORACLE_PDB)))'<<EOF
    exec ords.enable_schema(true);
    exit;
EOF"

    logSuccess "ORDS setup complete!"
}

# Serve ORDS
serveORDS() {
    logInfo "Starting ORDS in container..."
    export orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi
    
    # Set database privileges
    podman exec -it $orclImage bash -c "source /home/oracle/.bashrc; sqlplus sys/$ORACLE_SYS_PASS@'(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=$ORACLE_PDB)))' as sysdba <<EOF
    grant soda_app, create session, create table, create view, create sequence, create procedure, create job, unlimited tablespace to $ORACLE_USER;
    exit;
EOF"
    
    # Enable ORDS for schema
    podman exec -it $orclImage bash -c "source /home/oracle/.bashrc; sqlplus $ORACLE_USER/$ORACLE_PASS@'(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=127.0.0.1)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=$ORACLE_PDB)))'<<EOF
    exec ords.enable_schema(true);
    exit;
EOF"

    # Start ORDS service
    podman exec -d $orclImage /bin/bash -c "/home/oracle/ords/bin/ords --config /home/oracle/ords_config serve > /dev/null 2>&1; sleep 10"
    sleep 5
    
    # Verify ORDS is running
    podman exec $orclImage /bin/bash -c "/usr/bin/ps -ef | grep -i ords"
    
    logSuccess "ORDS started successfully!"
}

# Stop ORDS
stopORDS() {
    export orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi
    
    logInfo "Stopping ORDS..."
    podman exec $orclImage /bin/bash -c "for i in $(ps -ef | grep ords | awk '{print $2}'); do echo $i; kill -9 $i; done"
    logSuccess "ORDS stopped successfully!"
}

# Check MongoDB API
checkMongoAPI() {
    # Test MongoDB connections in the container
    logInfo "Checking MongoDB API health..."
    export orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi
    
    # run disableTelemetry()
    logInfo "Creating test collection..."
    podman exec -it $orclImage bash -c "mongosh --tlsAllowInvalidCertificates 'mongodb://$ORACLE_USER:$ORACLE_PASS@127.0.0.1:27017/$ORACLE_USER?authMechanism=PLAIN&ssl=true&retryWrites=false&loadBalanced=true'<<EOF
    disableTelemetry();
    db.createCollection('test123');
EOF"
    
    logInfo "Inserting test document..."
    podman exec -it $orclImage bash -c "mongosh --tlsAllowInvalidCertificates 'mongodb://$ORACLE_USER:$ORACLE_PASS@127.0.0.1:27017/$ORACLE_USER?authMechanism=PLAIN&ssl=true&retryWrites=false&loadBalanced=true'<<EOF
    db.test123.insertOne({ name: 'Matt DeMarco', email: 'matthew.demarco@oracle.com', notes: 'It is me' });
EOF"

    logInfo "Reading test document..."
    podman exec -it $orclImage bash -c "mongosh --tlsAllowInvalidCertificates 'mongodb://$ORACLE_USER:$ORACLE_PASS@127.0.0.1:27017/$ORACLE_USER?authMechanism=PLAIN&ssl=true&retryWrites=false&loadBalanced=true'<<EOF
    db.test123.find().pretty();
EOF"
    
    logSuccess "MongoDB API check complete!"
}

# mongosh to ORDS
mongoshORDS() {
    logInfo "Connecting to Oracle Database API for MongoDB..."
    orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi

    podman exec -it "$orclImage" bash -c "mongosh --tlsAllowInvalidCertificates \
    \"mongodb://$ORACLE_USER:$ORACLE_PASS@localhost:27017/$ORACLE_USER?authMechanism=PLAIN&authSource=%24external&tls=true&retryWrites=false&loadBalanced=true\""
}

# mongosh to MongoDB
mongoshMongoDB() {
    logInfo "Connecting to MongoDB..."
    orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi

    # Start/install MongoDB
    startMongoDB

    # run disableTelemetry()
    podman exec -it "$orclImage" mongosh --port 23456 --eval "disableTelemetry();"
    podman exec -it "$orclImage" bash -c "mongosh --port 23456"
}

# Get demo app
getDemoApp() {
    export orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi

    logInfo "Cloning registration-app into container..."
    podman exec "$orclImage" bash -c '[ -d /home/oracle/registration-app ] && echo "Repo already cloned." || git clone https://github.com/oramatt/registration-app.git /home/oracle/registration-app'
    
    if [ $? -eq 0 ]; then
        logSuccess "Demo app cloned successfully!"
    fi
}

# Run demo app
runDemoApp() {
    export orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi

    getDemoApp

    logInfo "Checking Node.js installation..."
    podman exec -u 0 $orclImage bash -c "command -v node || (curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - ; yum install -y nodejs)"

    logInfo "Installing dependencies inside the container..."
    podman exec $orclImage bash -c "/usr/bin/npm install dotenv pug express mongoose body-parser express-validator http-auth; /usr/bin/npm install /home/oracle/registration-app/"

    logInfo "Ensuring nodemon is installed globally..."
    podman exec -u 0 $orclImage bash -c "/usr/bin/npm list -g nodemon || /usr/bin/npm install -g nodemon"

    logInfo "Making runApp.sh executable..."
    podman exec $orclImage bash -c "chmod +x /home/oracle/registration-app/runApp.sh"

    logInfo "Running demo app..."
    logWarning "CTRL-C to kill app and restart!"
    podman exec -it "$orclImage" bash -c "cd /home/oracle/registration-app/; /home/oracle/registration-app/runApp.sh"
}

# Add demo data
addData() {
    export orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi

    # Check if registration app exists
    podman exec $orclImage bash -c "[ -d /home/oracle/registration-app ]" || {
        logWarning "Registration app not found. Cloning repository first..."
        getDemoApp
    }

    logInfo "Installing required Python libraries..."
    podman exec $orclImage bash -c "/usr/local/bin/pip3.12 install -r /home/oracle/registration-app/sample_data/requirements.txt"
    
    # Create the geodata directory in the right location
    logInfo "Setting up geodata directory..."
    podman exec $orclImage bash -c "mkdir -p /home/oracle/registration-app/sample_data/geodata"
    
    # Download necessary shapefile if it doesn't exist
    logInfo "Checking for required shapefiles..."
    podman exec $orclImage bash -c "[ -f /home/oracle/registration-app/sample_data/geodata/ne_110m_admin_0_countries.shp ]" || {
        logInfo "Downloading required shapefile..."
        podman exec $orclImage bash -c "cd /home/oracle/registration-app/sample_data && \
            wget -q https://naciscdn.org/naturalearth/110m/cultural/ne_110m_admin_0_countries.zip -O /tmp/countries.zip && \
            unzip -o /tmp/countries.zip -d geodata/ && \
            rm /tmp/countries.zip"
    }

    # Start interactive bash session to run the Python script
    logInfo "Starting interactive session to run the Python script..."
    logInfo "Follow the prompts to generate test data."
    logInfo "For basic testing, enter '10' for number of records and '3' for no images."
    
    podman exec -it $orclImage bash -c "cd /home/oracle/registration-app/sample_data && \
        echo -e '${CYAN}=== Running Data Generation Script ===${NC}'; python3.12 makeJSONData_OPTIONALPICS_wGeoData.py"
    
    if [ $? -eq 0 ]; then
        logSuccess "Demo data generation process completed."
    else
        logError "There may have been issues with data generation. Check the output above."
    fi
}

# Migrate data
migrateData() {
    export orclImage=$(getContainerId)
    
    if [ -z "$orclImage" ]; then
        logError "Oracle container is not running."
        return 1
    fi

    # Check if MongoDB is running
    podman exec $orclImage bash -c "ps -ef | grep -v grep | grep -q mongod"
    if [ $? -ne 0 ]; then
        logWarning "MongoDB does not appear to be running in the container."
        read -p "Would you like to start MongoDB now? (y/n): " startMongo
        if [[ "$startMongo" =~ ^[Yy]$ ]]; then
            logInfo "Starting MongoDB..."
            startMongoDB
        else
            logError "MongoDB must be running for migration. Exiting migration process."
            return 1
        fi
    fi

    # Check if mongotools repository exists
    podman exec $orclImage bash -c "[ -d /home/oracle/mongotools ]" || {
        logInfo "MongoDB tools repository not found. Cloning repository..."
        podman exec $orclImage bash -c "git clone https://github.com/oramatt/mongotools.git /home/oracle/mongotools || echo 'Repository already exists'"
    }

    # Ensure MongoDB dump script is executable
    logInfo "Setting execute permissions on migration script..."
    podman exec $orclImage bash -c "chmod +x /home/oracle/mongotools/mongoDump.sh"
    
    # Display migration information
    logInfo "Starting interactive MongoDB to Oracle migration process..."
    
    # Show a summary of what will be migrated
    echo
    echo -e "${CYAN}===========================================================================${NC}"
    echo -e "${CYAN}                       MongoDB to Oracle Migration                         ${NC}"
    echo -e "${CYAN}===========================================================================${NC}"
    echo
    echo "This process will:"
    echo "  1. Connect to MongoDB on port 23456"
    echo "  2. Export collections from MongoDB"
    echo "  3. Import collections into Oracle Database"
    echo
    echo "You will see the progress in real-time and can interact with the migration tool."
    echo
    read -p "Press Enter to start the migration process or Ctrl+C to cancel..." dummy
    echo
    
    # Run the migration script in interactive mode
    podman exec -it $orclImage bash -c "cd /home/oracle/mongotools && bash -c './mongoDump.sh'"
    
    # Check the result
    if [ $? -eq 0 ]; then
        logSuccess "Migration process completed. Check the output above for details."
        
        # Offer to connect to Oracle to verify the migration
        read -p "Would you like to connect to Oracle SQL*Plus to verify the migration? (y/n): " verifySql
        if [[ "$verifySql" =~ ^[Yy]$ ]]; then
            echo
            echo -e "${CYAN}===========================================================================${NC}"
            echo -e "${CYAN}                   Verifying Migration in Oracle                          ${NC}"
            echo -e "${CYAN}===========================================================================${NC}"
            echo
            echo "Common verification commands:"
            echo "  - SELECT COUNT(*) FROM registrations;"
            echo "  - SELECT * FROM registrations WHERE ROWNUM <= 5;"
            echo "  - DESC registrations;"
            echo
            # Connect to SQLPlus
            sqlPlusUser
        fi
    else
        logError "Migration process may have encountered issues. Check the output above."
    fi
}

#===========================
# Main Program
#===========================

# Process arguments to bypass the menu
case "$1" in
    "start")
        logInfo "Starting container..."
        startOracle
        exit 0
        ;;
    "stop")
        logInfo "Stopping container..."
        stopOracle
        exit 0
        ;;
    "restart")
        logInfo "Restarting container..."
        stopOracle
        startOracle
        exit 0
        ;;
    "bash")
        logInfo "Attempting bash access..."
        bashAccess
        exit 0
        ;;
    "root")
        logInfo "Attempting root access..."
        rootAccess
        exit 0
        ;;
    "remove")
        logInfo "Removing Oracle container..."
        removeContainer
        exit 0
        ;;
    "utils")
        logInfo "Installing utilities..."
        installUtils
        exit 0
        ;;
    "copyin")
        logInfo "Copying file into container..."
        copyIn
        exit 0
        ;;
    "copyout")
        logInfo "Copying file out of container..."
        copyOut
        exit 0
        ;;
    "clean")
        logInfo "Cleaning unused volumes..."
        cleanVolumes
        exit 0
        ;;
    "sqlnolog")
        logInfo "Opening SQL*Plus nolog connection..."
        sqlPlusNolog
        exit 0
        ;;
    "sqluser")
        logInfo "Opening SQL*Plus user connection..."
        sqlPlusUser
        exit 0
        ;;
    "sqlsys")
        logInfo "Opening SQL*Plus SYSDBA connection..."
        sysDba
        exit 0
        ;;
    "setupords")
        logInfo "Setting up ORDS..."
        setupORDS
        exit 0
        ;;
    "ords")
        logInfo "Starting ORDS service..."
        serveORDS
        exit 0
        ;;
    "mongoapi")
        logInfo "Checking MongoDB API connection..."
        checkMongoAPI
        exit 0
        ;;
    "mongodb")
        logInfo "Starting MongoDB instance..."
        startMongoDB
        exit 0
        ;;
    "mongoords")
        logInfo "Connecting to MongoDB via Oracle API..."
        mongoshORDS
        exit 0
        ;;
    "mongo")
        logInfo "Connecting to MongoDB directly..."
        mongoshMongoDB
        exit 0
        ;;
    "demoapp")
        logInfo "Running registration demo app..."
        runDemoApp
        exit 0
        ;;
    "demodata")
        logInfo "Adding demo data..."
        addData
        exit 0
        ;;
    "migrate")
        logInfo "Migrating data..."
        migrateData
        exit 0
        ;;
    "status")
        logInfo "Port listing and IP address:"
        listPorts
        exit 0
        ;;
    "help")
        echo -e "${CYAN}===========================================================================${NC}"
        echo -e "${CYAN}          Oracle Database & MongoDB Migration Demo Toolkit                 ${NC}"
        echo -e "${CYAN}===========================================================================${NC}"
        echo 
        echo "Usage: $0 [command]"
        echo 
        echo "Container Management Commands:"
        echo "  start     - Start Oracle container"
        echo "  stop      - Stop Oracle container"
        echo "  restart   - Restart Oracle container"
        echo "  bash      - Bash access to container"
        echo "  root      - Root access to container"
        echo "  remove    - Remove Oracle container"
        echo "  utils     - Install utilities"
        echo "  copyin    - Copy file into container"
        echo "  copyout   - Copy file out of container"
        echo "  clean     - Clean unused volumes"
        echo 
        echo "Database Access Commands:"
        echo "  sqlnolog  - SQL*Plus nolog connection"
        echo "  sqluser   - SQL*Plus user connection"
        echo "  sqlsys    - SQL*Plus SYSDBA connection"
        echo "  setupords - Setup ORDS"
        echo "  ords      - Start ORDS service"
        echo "  mongoapi  - Check MongoDB API connection"
        echo 
        echo "MongoDB Commands:"
        echo "  mongodb   - Start MongoDB instance"
        echo "  mongoords - Connect to MongoDB via Oracle API for MongoDB"
        echo "  mongo     - Connect to MongoDB directly"
        echo 
        echo "Application Commands:"
        echo "  demoapp   - Run Registration Demo App"
        echo "  demodata  - Add demo data"
        echo "  migrate   - Migrate data"
        echo "  help      - Show this help message"
        echo 
        echo "If no command is provided, the script will start in interactive menu mode."
        echo "Suggestions for improvement ==> matthew.demarco@oracle.com "
        echo -e "${BLUE}===========================================================================${NC}"
        exit 0
        ;;
    "")
        logInfo "No args provided. Starting menu interface..."
        ;;
    *)
        logError "Invalid argument: $1"
        logInfo "Run '$0 help' for usage information."
        exit 1
        ;;
esac

# Main menu loop
while true; do
    displayMenu
    
    case $menuChoice in
        1) 
            startOracle
            ;;
        2) 
            stopOracle
            ;;
        3)
            bashAccess
            ;;   
        4)
            rootAccess
            ;;
        5) 
            removeContainer
            ;;
        6)
            installUtils
            ;;
        7)
            copyIn
            ;;
        8)
            copyOut
            ;;
        9)  
            cleanVolumes
            ;;
        10)
            doNothing
            ;;
        11)
            sqlPlusNolog
            ;;
        12)
            sqlPlusUser
            ;;
        13)
            sysDba
            ;;
        14)
            setupORDS
            ;;
        15)
            serveORDS
            ;;
        16)
            checkMongoAPI
            ;;
        17)
            startMongoDB
            ;;
        18)
            mongoshORDS
            ;;
        19)
            mongoshMongoDB
            ;;
        20) 
            runDemoApp
            ;;
        21)
            addData
            ;;
        22)
            migrateData
            ;;
        23)
            listPorts
            ;;
        *) 
            badChoice
            ;;
    esac
    
    # Reset count after a valid choice
    if [[ $menuChoice =~ ^[1-9]|1[0-9]|2[0-2]$ ]]; then
        INVALID_COUNT=0
    fi
    
    # Pause after each operation to view results
    if [[ $menuChoice != 10 && $menuChoice =~ ^[1-9]|1[0-9]|2[0-2]$ ]]; then
        echo
        read -p "Press Enter to continue..." dummy
    fi
done