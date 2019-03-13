#!/bin/bash

LOCAL_SOURCE_DIR=/tmp/src

# Resulting WAR files will be deployed to /opt/eap/standalone/deployments
DEPLOY_DIR=$JBOSS_HOME/standalone/deployments

CONFIG_FILE=${JBOSS_HOME}/standalone/configuration/standalone-openshift.xml

function find_env() {
  var=${!1}
  echo "${var:-$2}"
}

function install_deployments(){
  if [ $# != 1 ]; then
    echo "Usage: Directory parameter required"
    return
  fi
  install_dirs=$1

  for install_dir in $(echo $install_dirs | sed "s/,/ /g"); do
    cp -rf ${install_dir}/* $DEPLOY_DIR
  done
}

function install_modules(){
  if [ $# != 1 ]; then
    echo "Usage: Directory parameter required"
    return
  fi
  install_dirs=$1

  for install_dir in $(echo $install_dirs | sed "s/,/ /g"); do
    cp -rf ${install_dir}/* $JBOSS_HOME/modules
  done
}

function configure_drivers(){
  (
    if [ $# == 1 ] && [ -f "$1" ]; then
      source $1
    fi

    drivers=
    if [ -n "$DRIVERS" ]; then
      for driver_prefix in $(echo $DRIVERS | sed "s/,/ /g"); do
	    # If the prefix is one of our standard ones, set up default values
	    # for things that would otherwise have to be by env vars
	    case "$db" in
		    "mysql")
                # TODO mysql values
                standard_module=""
                standard_driver_name=""
                standard_driver_class=""
                standard_driver_artifact=""
		     ;;
		    "postgresql")
                # TODO postgres values
                standard_module=""
                standard_driver_name=""
                standard_driver_class=""
                standard_driver_artifact=""
		    ;;
		    "mongodb")
                # TODO mongodb values
                standard_module=""
                standard_driver_name=""
                standard_driver_class=""
                standard_driver_artifact=""
		    ;;
		    *)
                standard_module=""
                standard_driver_name=""
                standard_driver_class=""
                standard_driver_artifact=""
		    ;;
		esac
		
        driver_module=$(find_env "${driver_prefix}_DRIVER_MODULE")
        if [ -z "$driver_module" ]; then
          if [ -n "$standard_module" ]; then
            driver_module=$(standard_module)
          else
            echo "Warning - ${driver_prefix}_DRIVER_MODULE is missing from driver configuration. Driver will not be configured"
            continue
          fi
        fi
      
        driver_name=$(find_env "${driver_prefix}_DRIVER_NAME")
        if [ -z "$driver_name" ]; then
          if [ -n "$standard_driver_name" ]; then
            driver_name=$(standard_driver_name)
          else
            echo "Warning - ${driver_prefix}_DRIVER_NAME is missing from driver configuration. Driver will not be configured"
            continue
          fi
        fi

        driver_class=$(find_env "${driver_prefix}_DRIVER_CLASS")
        datasource_class=$(find_env "${driver_prefix}_XA_DATASOURCE_CLASS")
        if [ -z "$driver_class" ] && [ -z "$datasource_class" ]; then
          if [ -n "$standard_driver_class" ]; then
            driver_name=$(standard_driver_class)
          else
            echo "Warning - ${driver_prefix}_DRIVER_NAME and ${driver_prefix}_XA_DATASOURCE_CLASS is missing from driver configuration. At least one is required. Driver will not be configured"
            continue
          fi
        fi
 
        driver_artifacts=$(find_env "${driver_prefix}_DRIVER_ARTIFACTS")
        if [ -n "$driver_artifacts" ] || [ -n "$standard_driver_artifact" ]; then
          # Fetch the driver artifacts and create a module for them
          configure_driver_module $driver_module $driver_artifacts $standard_driver_artifact
        fi
	
        drivers="${drivers} <driver name=\"$driver_name\" module=\"$driver_module\">"
        if [ -n "$datasource_class" ]; then
          drivers="${drivers}<xa-datasource-class>${datasource_class}</xa-datasource-class>"
        fi

        if [ -n "$driver_class" ]; then
          drivers="${drivers}<driver-class>${driver_class}</driver-class>"
        fi
        drivers="${drivers}</driver>"
      
      done

      if [ -n "$drivers" ]; then
        sed -i "s|<!-- ##DRIVERS## -->|${drivers}<!-- ##DRIVERS## -->|" $CONFIG_FILE
      fi
    fi
  )
}

configure_driver_module(){
  local driver_module="${1}"
  local driver_artifacts="${2}"
  local standard_driver_artifact="${3}"
  # TODO 
  # See if there's a module dir corresponding to driver_module. If not create.
  # See if there's a module.xml; if not create a standard one
  # If we created the module.xml and driver_artifacts is empty, set it to standard_driver_artifact (to fetch the default)
  # For each element in driver_artifacts, use mvn dependency:get and mvn dependency:copy to fetch the artifact and put it in the module
  # For each element in driver_artifacts, insert a <resource> entry in the module.xml
}

