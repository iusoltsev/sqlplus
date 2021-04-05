drop TABLE DEPARTMENTS
/
CREATE TABLE DEPARTMENTS 
    ( 
     DEPARTMENT_ID NUMBER (4)  NOT NULL , 
     DEPARTMENT_NAME VARCHAR2 (30 BYTE)  NOT NULL , 
     MANAGER_ID NUMBER (6) , 
     LOCATION_ID NUMBER (4) 
    ) LOGGING 
;



COMMENT ON COLUMN DEPARTMENTS.DEPARTMENT_ID IS 'Primary key column of departments table.' 
;

COMMENT ON COLUMN DEPARTMENTS.DEPARTMENT_NAME IS 'A not null column that shows name of a department. Administration,
Marketing, Purchasing, Human Resources, Shipping, IT, Executive, Public
Relations, Sales, Finance, and Accounting. ' 
;

COMMENT ON COLUMN DEPARTMENTS.MANAGER_ID IS 'Manager_id of a department. Foreign key to employee_id column of employees table. The manager_id column of the employee table references this column.' 
;

COMMENT ON COLUMN DEPARTMENTS.LOCATION_ID IS 'Location id where a department is located. Foreign key to location_id column of locations table.' 
;

CREATE INDEX DEPT_LOCATION_IX ON DEPARTMENTS 
    ( 
     LOCATION_ID ASC 
    ) 
    LOGGING 
    NOCOMPRESS 
    NOPARALLEL 
;

CREATE UNIQUE INDEX DEPT_ID_PKX ON DEPARTMENTS 
    ( 
     DEPARTMENT_ID ASC 
    ) 
;

ALTER TABLE DEPARTMENTS 
    ADD CONSTRAINT DEPT_ID_PK PRIMARY KEY ( DEPARTMENT_ID ) ;



drop TABLE EMPLOYEES
/
CREATE TABLE EMPLOYEES 
    ( 
     EMPLOYEE_ID NUMBER (6)  NOT NULL , 
     FIRST_NAME VARCHAR2 (20 BYTE) , 
     LAST_NAME VARCHAR2 (25 BYTE)  NOT NULL , 
     EMAIL VARCHAR2 (25 BYTE)  NOT NULL , 
     PHONE_NUMBER VARCHAR2 (20 BYTE) , 
     HIRE_DATE DATE  NOT NULL , 
     JOB_ID VARCHAR2 (10 BYTE)  NOT NULL , 
     SALARY NUMBER (8,2) , 
     COMMISSION_PCT NUMBER (2,2) , 
     MANAGER_ID NUMBER (6) , 
     DEPARTMENT_ID NUMBER (4) 
    ) LOGGING 
;



ALTER TABLE EMPLOYEES 
    ADD CONSTRAINT EMP_SALARY_MIN 
    CHECK ( salary > 0) 
;


COMMENT ON COLUMN EMPLOYEES.EMPLOYEE_ID IS 'Primary key of employees table.' 
;

COMMENT ON COLUMN EMPLOYEES.FIRST_NAME IS 'First name of the employee. A not null column.' 
;

COMMENT ON COLUMN EMPLOYEES.LAST_NAME IS 'Last name of the employee. A not null column.' 
;

COMMENT ON COLUMN EMPLOYEES.EMAIL IS 'Email id of the employee' 
;

COMMENT ON COLUMN EMPLOYEES.PHONE_NUMBER IS 'Phone number of the employee; includes country code and area code' 
;

COMMENT ON COLUMN EMPLOYEES.HIRE_DATE IS 'Date when the employee started on this job. A not null column.' 
;

COMMENT ON COLUMN EMPLOYEES.JOB_ID IS 'Current job of the employee; foreign key to job_id column of the
jobs table. A not null column.' 
;

COMMENT ON COLUMN EMPLOYEES.SALARY IS 'Monthly salary of the employee. Must be greater
than zero (enforced by constraint emp_salary_min)' 
;

COMMENT ON COLUMN EMPLOYEES.COMMISSION_PCT IS 'Commission percentage of the employee; Only employees in sales
department elgible for commission percentage' 
;

COMMENT ON COLUMN EMPLOYEES.MANAGER_ID IS 'Manager id of the employee; has same domain as manager_id in
departments table. Foreign key to employee_id column of employees table.
(useful for reflexive joins and CONNECT BY query)' 
;

COMMENT ON COLUMN EMPLOYEES.DEPARTMENT_ID IS 'Department id where employee works; foreign key to department_id
column of the departments table' 
;

CREATE INDEX EMP_DEPARTMENT_IX ON EMPLOYEES 
    ( 
     DEPARTMENT_ID ASC 
    ) 
    LOGGING 
    NOCOMPRESS 
    NOPARALLEL 
;

CREATE INDEX EMP_JOB_IX ON EMPLOYEES 
    ( 
     JOB_ID ASC 
    ) 
    LOGGING 
    NOCOMPRESS 
    NOPARALLEL 
;

CREATE INDEX EMP_MANAGER_IX ON EMPLOYEES 
    ( 
     MANAGER_ID ASC 
    ) 
    LOGGING 
    NOCOMPRESS 
    NOPARALLEL 
;

CREATE INDEX EMP_NAME_IX ON EMPLOYEES 
    ( 
     LAST_NAME ASC , 
     FIRST_NAME ASC 
    ) 
    LOGGING 
    NOCOMPRESS 
    NOPARALLEL 
;

CREATE UNIQUE INDEX EMP_EMP_ID_PKX ON EMPLOYEES 
    ( 
     EMPLOYEE_ID ASC 
    ) 
;

ALTER TABLE EMPLOYEES 
    ADD CONSTRAINT EMP_EMP_ID_PK PRIMARY KEY ( EMPLOYEE_ID ) ;

ALTER TABLE EMPLOYEES 
    ADD CONSTRAINT EMP_EMAIL_UK UNIQUE ( EMAIL ) ;
