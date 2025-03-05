# ldr_oracle

## Description
This project was created as a way to learn Oracle, and build a tool that can be a fully generic loader.  Currently we have 10 of each input tables, which can be scalled to as many as we need.  These tables have 50 columns of type CLOB, so they can accept any input at all thrown at them.

The LOAD_CONFIG table controls how data moves between the STG_INPUT > ERR_VALIDATION > STG_Map > STG_TRASNFORM > OUT tables.

Here are some sample records thus far in my POC

[ROW_LOAD_CONFIG](https://github.com/nealrout/ldr_oracle/blob/develop/sql/row/ROW_LOAD_CONFIG.sql) 

These configurations currently include validating data, mapping data, in line transformations, and aggregate transformations.  The OUT is still a work in progress, and will be completed shortly.


## Table of Contents

- [Requirements](#requirements)
- [Miscellaneous](#miscellaneous)
- [Usage](#usage)
- [Features](#features)
- [Contact](#contact)

## Requirements
Oracle Express Edition - https://www.oracle.com/database/technologies/xe-downloads.html  
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
To run liquibase migrations:

    Initialization
        liquibase update --url=jdbc:oracle:thin:@localhost:1521/XEPDB1 --contexts=init --username=DAAS --password=UPDATEME

    Migration
        liquibase update --contexts=update --username=UPDATEME --password=UPDATEME

## Features
## Overview


![My Project Logo](LDR_ORACLE.png)

## Contact
Neal Routson  
nroutson@gmail.com
