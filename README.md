# ldr_oracle

# daas_db

## Project

Refrence of DaaS Project - https://github.com/nealrout/daas_docs
## Description

This project contains the liquibase scripts to build and underlying PostgreSQL daas database.  This database stores facility, asset, etc. information for DaaS that will be fetched through Django apis.  We are adding functions and procedures so we can control the CRUD operations at the DBMS level.


## Table of Contents

- [Requirements](#requirements)
- [Miscellaneous](#miscellaneous)
- [Usage](#usage)
- [Features](#features)
- [Contact](#contact)

## Requirements
Liquibase CLI (open source)- https://www.liquibase.com/download
## Miscellaneous


## Usage
If the DaaS database does not exist yet, you must create it with a password that you must update. 

  CREATE USER DAAS IDENTIFIED BY UPDATEME;

  GRANT CONNECT, RESOURCE TO DAAS;
  GRANT CREATE SESSION TO DAAS;
  GRANT CREATE TABLE TO DAAS;
  GRANT CREATE VIEW TO DAAS;
  GRANT CREATE SEQUENCE TO DAAS;
  GRANT CREATE SYNONYM TO DAAS;
  GRANT CREATE PROCEDURE TO DAAS;
  GRANT CREATE TRIGGER TO DAAS;
  GRANT CREATE MATERIALIZED VIEW TO DAAS;
  GRANT QUERY REWRITE TO DAAS;
  GRANT UNLIMITED TABLESPACE TO DAAS;

  ALTER SESSION SET CURRENT_SCHEMA = DAAS;
  ALTER USER DAAS DEFAULT TABLESPACE users;



#
    Initialization
        liquibase update --url=jdbc:oracle:thin:@localhost:1521/XEPDB1 --contexts=init --username=DAAS --password=UPDATEME

    Migration
        liquibase update --contexts=update --username=UPDATEME --password=UPDATEME


## Features
- Facility table
- Asset table and functions to allow DBMS control over CRUD operations.

## Contact
Neal Routson  
nroutson@gmail.com
