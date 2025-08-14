 -- ============================================================================
-- DATA SENSITIVITY CLASSIFICATION WITH SNOWFLAKE AI
-- ============================================================================
-- 
-- PURPOSE:
-- This script demonstrates how to use Snowflake's AI_CLASSIFY function to 
-- automatically identify and classify sensitive data columns in your database
-- based on a customizable sensitivity framework.
--
-- USE CASES:
-- 1. Data Governance: Automatically identify PII, PHI, and financial data
-- 2. Compliance: Support GDPR, HIPAA, SOX, and other regulatory requirements
-- 3. Security Audits: Scan databases for sensitive columns requiring protection
-- 4. Access Control: Determine which columns need encryption or masking
-- 5. Risk Assessment: Prioritize security efforts based on data sensitivity
--
-- HOW IT WORKS:
-- 1. Define your sensitivity framework (what constitutes PII, PHI, etc.)
-- 2. Use the stored procedure to extract schema metadata
-- 3. Apply AI_CLASSIFY to analyze column names, types, and comments
-- 4. Filter and report on sensitive data discoveries
--
-- CUSTOMER SCENARIO:
-- "Can I provide a document describing my data classification system and have
-- AI automatically flag columns that might be sensitive according to my framework?
-- I want to run this over information_schema.columns and get classification labels."
--
-- REQUIREMENTS:
-- - Snowflake account with AI functions enabled (Cortex)
-- - Access to INFORMATION_SCHEMA views
-- - Appropriate permissions to create procedures and run AI functions
--
-- ============================================================================

CREATE OR REPLACE PROCEDURE GET_SCHEMA_DETAILS(DATABASE_NAME STRING, SCHEMA_NAME STRING)
RETURNS TABLE (
    TABLE_NAME STRING,
    COLUMN_NAME STRING,
    DATA_TYPE STRING,
    IS_NULLABLE STRING,
    CHARACTER_MAXIMUM_LENGTH NUMBER,
    ORDINAL_POSITION NUMBER,
    COMMENT STRING
)
LANGUAGE SQL
AS
DECLARE
    result_set RESULTSET;
    query_string STRING;
BEGIN
    -- Build the query dynamically to use the correct database's INFORMATION_SCHEMA
    query_string := 'SELECT 
            TABLE_NAME,
            COLUMN_NAME,
            CASE 
                WHEN DATA_TYPE LIKE ''NUMBER%'' THEN 
                    DATA_TYPE || ''('' || COALESCE(NUMERIC_PRECISION::STRING, '''') || '','' || COALESCE(NUMERIC_SCALE::STRING, '''') || '')''
                WHEN DATA_TYPE LIKE ''VARCHAR%'' OR DATA_TYPE LIKE ''CHAR%'' THEN 
                    DATA_TYPE || ''('' || COALESCE(CHARACTER_MAXIMUM_LENGTH::STRING, '''') || '')''
                ELSE DATA_TYPE
            END AS DATA_TYPE,
            IS_NULLABLE,
            CHARACTER_MAXIMUM_LENGTH,
            ORDINAL_POSITION,
            COMMENT
        FROM ' || UPPER(:DATABASE_NAME) || '.INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = ''' || UPPER(:SCHEMA_NAME) || '''
          AND TABLE_CATALOG = ''' || UPPER(:DATABASE_NAME) || '''
        ORDER BY TABLE_NAME, ORDINAL_POSITION';
    
    result_set := (EXECUTE IMMEDIATE :query_string);
    
    RETURN TABLE(result_set);
END;


-- ============================================================================
-- DATA SENSITIVITY CLASSIFICATION FRAMEWORK
-- ============================================================================

  -- Set your data sensitivity framework as a variable
  SET sensitivity_framework = 'PII includes: SSN, credit card numbers, bank accounts, email addresses, phone numbers,
  dates of birth, driver license numbers.
  PHI includes: medical record numbers, health conditions, prescriptions, diagnoses.
  Financial includes: salary, compensation, stock grants, account balances.
  Public data includes: company names, job titles, publicly available information.';

  -- Set your classification labels
  SET classification_categories = '[
      {''label'': ''SENSITIVE_PII'',
       ''description'': ''Personal Identifiable Information that requires protection''},
      {''label'': ''SENSITIVE_PHI'',
       ''description'': ''Protected Health Information under HIPAA''},
      {''label'': ''SENSITIVE_FINANCIAL'',
       ''description'': ''Financial or compensation data''},
      {''label'': ''PUBLIC'',
       ''description'': ''Non-sensitive, publicly available information''}
  ]';


-- ============================================================================
-- EXAMPLE 1: CALL STORED PROCEDURE TO GET SCHEMA METADATA
-- ============================================================================

  -- Example 1: Call the stored procedure to get schema metadata
  -- Replace 'YOUR_DATABASE' and 'YOUR_SCHEMA' with your actual database and schema names
  CALL GET_SCHEMA_DETAILS('YOUR_DATABASE', 'YOUR_SCHEMA');
  
  /* Sample output from stored procedure:
  TABLE_NAME         | COLUMN_NAME         | DATA_TYPE        | IS_NULLABLE | CHARACTER_MAX_LENGTH| ORDINAL_POSITION | COMMENT
  -------------------|---------------------|------------------|-------------|---------------------|------------------|----------
  CUSTOMERS          | CUSTOMER_ID         | NUMBER(38,0)     | NO          | NULL                | 1                | Primary key
  CUSTOMERS          | SSN                 | VARCHAR(11)      | YES         | 11                  | 2                | Social Security Number
  CUSTOMERS          | EMAIL               | VARCHAR(255)     | YES         | 255                 | 3                | Customer email
  CUSTOMERS          | SALARY              | NUMBER(10,2)     | YES         | NULL                | 4                | Annual salary
  EMPLOYEES          | EMPLOYEE_ID         | NUMBER(38,0)     | NO          | NULL                | 1                | Employee identifier
  EMPLOYEES          | MEDICAL_RECORD_NUM  | VARCHAR(20)      | YES         | 20                  | 2                | Medical record
  EMPLOYEES          | DIAGNOSIS_CODE      | VARCHAR(10)      | YES         | 10                  | 3                | ICD-10 code
  */


-- ============================================================================
-- EXAMPLE 2: APPLY SENSITIVITY CLASSIFICATION TO PROCEDURE RESULTS
-- ============================================================================
--
-- Note: AI_CLASSIFY returns a JSON object with a 'labels' array containing 
-- the classification results. The response structure is:
-- {
--   "labels": ["classification_label"]
-- }
-- 
-- For single-label classification (default), the labels array contains one element.
-- For multi-label classification (with 'output_mode': 'multi'), it may contain multiple elements.
--
  -- Example 2: Apply sensitivity classification to the stored procedure results
  -- Replace 'YOUR_DATABASE' and 'YOUR_SCHEMA' with your actual database and schema names
  WITH schema_metadata AS (
      SELECT * FROM TABLE(GET_SCHEMA_DETAILS('YOUR_DATABASE', 'YOUR_SCHEMA'))
  )
  SELECT
      TABLE_NAME,
      COLUMN_NAME,
      DATA_TYPE,
      COMMENT,
      AI_CLASSIFY(
          CONCAT('Column name: ', COLUMN_NAME,
                 ' Data type: ', DATA_TYPE,
                 ' Comment: ', COALESCE(COMMENT, 'No comment'),
                 ' Context: ', $sensitivity_framework),
          PARSE_JSON($classification_categories),
          {
              'task_description': 'Classify this database column based on the sensitivity framework provided'
          }
      ) AS classification_result,
      classification_result:labels[0]::STRING AS primary_classification
  FROM schema_metadata
  ORDER BY 
      TABLE_NAME, 
      ORDINAL_POSITION;

  /* Sample output for Example 2:
  TABLE_NAME | COLUMN_NAME       | DATA_TYPE    | COMMENT                | PRIMARY_CLASSIFICATION 
  -----------|-------------------|--------------|------------------------|----------------------
  CUSTOMERS  | CUSTOMER_ID       | NUMBER(38,0) | Primary key            | PUBLIC               
  CUSTOMERS  | SSN               | VARCHAR(11)  | Social Security Number | SENSITIVE_PII        
  CUSTOMERS  | EMAIL             | VARCHAR(255) | Customer email         | SENSITIVE_PII        
  CUSTOMERS  | SALARY            | NUMBER(10,2) | Annual salary          | SENSITIVE_FINANCIAL  
  EMPLOYEES  | EMPLOYEE_ID       | NUMBER(38,0) | Employee identifier    | PUBLIC               
  EMPLOYEES  | MEDICAL_RECORD_NUM| VARCHAR(20)  | Medical record         | SENSITIVE_PHI        
  EMPLOYEES  | DIAGNOSIS_CODE    | VARCHAR(10)  | ICD-10 code            | SENSITIVE_PHI
  */


-- ============================================================================
-- EXAMPLE 3: FILTER FOR SENSITIVE COLUMNS WITH HIGH CONFIDENCE
-- ============================================================================

  -- Example 3: Filter for only sensitive columns with high confidence
  WITH classified_columns AS (
      SELECT 
          TABLE_NAME,
          COLUMN_NAME,
          DATA_TYPE,
          COMMENT,
          AI_CLASSIFY(
              CONCAT('Column name: ', COLUMN_NAME,
                     ' Data type: ', DATA_TYPE,
                     ' Comment: ', COALESCE(COMMENT, ''),
                     ' Context: ', $sensitivity_framework),
              PARSE_JSON($classification_categories),
              {'task_description': 'Classify sensitivity based on column metadata'}
          ) AS classification
      FROM TABLE(GET_SCHEMA_DETAILS('YOUR_DATABASE', 'YOUR_SCHEMA'))
  )
  SELECT 
      TABLE_NAME,
      COLUMN_NAME,
      classification:labels[0]::STRING AS sensitivity_type,
      CASE 
          WHEN classification:labels[0]:label::STRING = 'SENSITIVE_PII' THEN 'Requires encryption and access controls'
          WHEN classification:labels[0]:label::STRING = 'SENSITIVE_PHI' THEN 'HIPAA compliance required'
          WHEN classification:labels[0]:label::STRING = 'SENSITIVE_FINANCIAL' THEN 'SOX compliance may apply'
          ELSE 'Standard handling'
      END AS recommended_action
  FROM classified_columns
  WHERE classification:labels[0]::STRING != 'PUBLIC'
  ORDER BY TABLE_NAME, COLUMN_NAME;

  /* Sample output for Example 3 (only sensitive columns with confidence > 0.7):
  TABLE_NAME | COLUMN_NAME        | SENSITIVITY_TYPE    | RECOMMENDED_ACTION
  -----------|--------------------|---------------------|-----------------------------------------
  CUSTOMERS  | EMAIL              | SENSITIVE_PII       | Requires encryption and access controls
  CUSTOMERS  | SALARY             | SENSITIVE_FINANCIAL | SOX compliance may apply
  CUSTOMERS  | SSN                | SENSITIVE_PII       | Requires encryption and access controls
  EMPLOYEES  | DIAGNOSIS_CODE     | SENSITIVE_PHI       | HIPAA compliance required
  EMPLOYEES  | MEDICAL_RECORD_NUM | SENSITIVE_PHI       | HIPAA compliance required
  */


-- ============================================================================
-- EXAMPLE 4: CREATE SUMMARY REPORT OF SENSITIVITY BY TABLE
-- ============================================================================

  -- Example 4: Create a summary report of sensitivity by table
  WITH classified_data AS (
      SELECT 
          TABLE_NAME,
          COLUMN_NAME,
          AI_CLASSIFY(
              CONCAT('Column: ', COLUMN_NAME, ' Type: ', DATA_TYPE, ' Comment: ', COALESCE(COMMENT, ''), ' Context: ', $sensitivity_framework),
              PARSE_JSON($classification_categories),
              {'task_description': 'Classify sensitivity'}
          ):labels[0]::STRING AS classification
      FROM TABLE(GET_SCHEMA_DETAILS('YOUR_DATABASE', 'YOUR_SCHEMA'))
  )
  SELECT 
      TABLE_NAME,
      COUNT(*) AS total_columns,
      SUM(CASE WHEN classification = 'SENSITIVE_PII' THEN 1 ELSE 0 END) AS pii_columns,
      SUM(CASE WHEN classification = 'SENSITIVE_PHI' THEN 1 ELSE 0 END) AS phi_columns,
      SUM(CASE WHEN classification = 'SENSITIVE_FINANCIAL' THEN 1 ELSE 0 END) AS financial_columns,
      SUM(CASE WHEN classification = 'PUBLIC' THEN 1 ELSE 0 END) AS public_columns,
      CASE 
          WHEN SUM(CASE WHEN classification IN ('SENSITIVE_PII', 'SENSITIVE_PHI', 'SENSITIVE_FINANCIAL') THEN 1 ELSE 0 END) > 0 
          THEN 'HIGH SENSITIVITY'
          ELSE 'LOW SENSITIVITY'
      END AS table_sensitivity_level
  FROM classified_data
  GROUP BY TABLE_NAME
  ORDER BY table_sensitivity_level DESC, TABLE_NAME;

  /* Sample output for Example 4 (summary by table):
  TABLE_NAME | TOTAL_COLUMNS | PII_COLUMNS | PHI_COLUMNS | FINANCIAL_COLUMNS | PUBLIC_COLUMNS | TABLE_SENSITIVITY_LEVEL
  -----------|---------------|-------------|-------------|-------------------|----------------|------------------------
  CUSTOMERS  | 4             | 2           | 0           | 1                 | 1              | HIGH SENSITIVITY
  EMPLOYEES  | 3             | 0           | 2           | 0                 | 1              | HIGH SENSITIVITY
  */