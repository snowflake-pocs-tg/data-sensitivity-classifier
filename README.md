# Snowflake AI Data Sensitivity Classifier

An automated data sensitivity classification solution using Snowflake's Cortex AI to identify and categorize PII, PHI, and financial data across your database schemas.

## Overview

This solution demonstrates how to leverage Snowflake's `AI_CLASSIFY` function to automatically scan and classify database columns based on a customizable sensitivity framework. It addresses the critical need for data governance, regulatory compliance, and security auditing in modern data platforms.

## Key Features

- **Automated Discovery**: Scan entire database schemas to identify sensitive data columns
- **Customizable Framework**: Define your own sensitivity categories (PII, PHI, Financial, etc.)
- **Compliance Support**: Support for GDPR, HIPAA, SOX, and other regulatory requirements
- **Actionable Insights**: Generate reports with recommended security actions for each data type
- **Schema Metadata Extraction**: Built-in stored procedure for efficient metadata retrieval

## Use Cases

1. **Data Governance**: Automatically identify and catalog sensitive data across your Snowflake environment
2. **Compliance Auditing**: Demonstrate regulatory compliance by identifying protected data
3. **Security Assessment**: Prioritize security controls based on data sensitivity
4. **Access Control Planning**: Determine which columns require encryption, masking, or restricted access
5. **Risk Management**: Quantify and track sensitive data exposure across tables

## Prerequisites

- Snowflake account with Cortex AI functions enabled
- Access to `INFORMATION_SCHEMA` views
- Appropriate permissions to create stored procedures

## Getting Started

### Clone as a Snowflake Workspace

1. **Sign in to Snowsight**
2. **Navigate to Projects → Workspaces**
3. **Select "From Git repository"**
4. **Enter the repository URL**
5. **Configure Authentication** (OAuth for GitHub, PAT, or public repo)
6. **Select or create an API Integration** (admin setup may be required)
7. **Click "Create"** to create your workspace

## How It Works

The solution uses a three-step process:

1. **Metadata Extraction**: Stored procedure retrieves schema information
2. **AI Classification**: Snowflake's `AI_CLASSIFY` analyzes columns based on your framework
3. **Report Generation**: Creates actionable insights for data governance

### Workflow Overview

```
┌─────────────────┐
│  Your Database  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│  GET_SCHEMA_DETAILS()   │ ← Extracts metadata
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  AI_CLASSIFY()          │ ← Applies your framework
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Classification Results │
├─────────────────────────┤
│ • PII Detection         │
│ • PHI Identification    │
│ • Financial Data        │
│ • Compliance Actions    │
└─────────────────────────┘
```

## Configuration

### Sensitivity Framework

Define what constitutes sensitive data in your organization:

- **PII**: SSN, credit card numbers, email addresses, phone numbers
- **PHI**: Medical records, health conditions, diagnoses (HIPAA)
- **Financial**: Salary, compensation, account balances (SOX)
- **Public**: Non-sensitive, publicly available information

### Classification Categories

Customizable labels for different sensitivity levels:
- `SENSITIVE_PII` - Personal Identifiable Information
- `SENSITIVE_PHI` - Protected Health Information  
- `SENSITIVE_FINANCIAL` - Financial data
- `PUBLIC` - Non-sensitive information

## Implementation

The `example.sql` file provides:

1. **Stored Procedure**: `GET_SCHEMA_DETAILS` for metadata extraction
2. **Framework Setup**: Customizable sensitivity definitions
3. **Classification Examples**: Four practical use cases
4. **Report Templates**: Summary and detailed views

## Output Format

The AI_CLASSIFY function returns JSON with classification labels. Results can be filtered, aggregated, and formatted for compliance reporting.

## Sample Results

- **Column-Level**: Individual column classifications with recommended actions
- **Table-Level**: Summary statistics showing sensitivity distribution
- **Compliance View**: Filtered results for specific regulatory requirements
- **Risk Assessment**: Prioritized list of high-sensitivity data locations

## Best Practices

1. **Regular Scanning**: Schedule periodic scans to detect new sensitive data
2. **Framework Updates**: Regularly update your sensitivity framework based on regulatory changes
3. **Result Validation**: Review AI classifications and adjust the framework for improved accuracy
4. **Access Control**: Limit access to classification results as they reveal sensitive data locations
5. **Documentation**: Maintain documentation of your classification criteria and decisions

## Limitations

- Maximum of 500 unique classification categories
- Classification accuracy depends on column naming conventions and metadata quality
- AI_CLASSIFY requires Cortex AI to be enabled in your Snowflake region
- Results should be reviewed by data governance teams for accuracy

## Support

For questions or support:
- Open an issue in the GitHub repository
- Contact your Snowflake account team
- Review Snowflake Cortex AI documentation

## Disclaimer

**IMPORTANT**: This script is provided as an example demonstration only. By using this script, you acknowledge that:

- You are using this code AT YOUR OWN RISK
- This is example code intended to demonstrate Snowflake's AI classification capabilities
- You should thoroughly test and validate this code in a non-production environment
- You are responsible for ensuring compliance with your organization's data governance policies
- AI classifications should be reviewed and validated by your data governance team

## License

MIT License - see LICENSE file for details.

## Acknowledgments

Built with Snowflake Cortex AI - leveraging advanced language models for intelligent data classification.