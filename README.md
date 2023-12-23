# Real Estate Database Project
This repository contains example SQL script to create and manage a comprehensive database for a real estate agency. The project is organized into 11 tables, each serving a specific purpose in the real estate management ecosystem.  
The creation process begins with tables that have no foreign key dependencies, followed by tables with references to other tables. Constraints are then added, ensuring data integrity. The tables are finally populated with sample data to facilitate testing and development.
## Table Structure
- Property

| Field Name        | Field Description                     | Data Type |
|-------------------|---------------------------------------|-----------|
| property_id       | Unique identifier for a property, PK  | Serial    |
| address           | Address of the property                | Varchar   |
| property_type     | Type of the property                   | Varchar   |
| bedrooms_num      | Number of bedrooms in the property     | Int       |
| bathrooms_num     | Number of bathrooms in the property    | Int       |
| price             | Price of the property                  | Decimal   |
| is_for_sale       | Indicates whether the property is for sale | Boolean |
| is_for_rent       | Indicates whether the property is for rent | Boolean |

- Clients

| Field Name           | Field Description                              | Data Type |
|----------------------|-------------------------------------------------|-----------|
| client_id            | Unique identifier for a client, PK              | Serial    |
| client_type          | Type of the client                              | Varchar   |
| client_firstname     | First name of the client                        | Varchar   |
| client_lastname      | Last name of the client                         | Varchar   |
| client_fullname      | Full name of the client                          | Varchar   |
| client_phone         | Phone number of the client                      | Varchar   |
| client_email         | Email address of the client                     | Varchar   |
| pre_approval_status  | Pre-approval status for buyers                  | Varchar   |
| listing_status       | Listing status for sellers                      | Varchar   |
| rental_budget        | Budget for tenants to rent properties           | Decimal   |

- Agents

| Field Name      | Field Description               | Data Type |
|-----------------|----------------------------------|-----------|
| agent_id        | Unique identifier for an agent, PK | Serial    |
| agent_firstname | First name of the agent           | Varchar   |
| agent_lastname  | Last name of the agent            | Varchar   |
| agent_fullname  | Full name of the agent            | Varchar   |
| agent_email     | Email address of the agent        | Varchar   |
| agent_phone     | Phone number of the agent         | Varchar   |

- Agencies

| Field Name      | Field Description                                | Data Type  |
|-----------------|---------------------------------------------------|------------|
| agency_id       | Unique identifier for an agency, PK              | Serial     |
| agency_name     | Name of the real estate agency                    | Varchar    |
| license_num     | License number of the agency                      | Varchar    |
| agency_address  | Physical location of the agency                   | Varchar    |
| website         | URL of the agency's website                       | Varchar    |
| agency_email    | Contact email address for the agency              | Varchar    |
| agency_phone    | Contact phone number for the agency               | Varchar    |

- Staff

| Field Name         | Field Description                               | Data Type |
|--------------------|--------------------------------------------------|-----------|
| staff_id           | Unique identifier for a staff member, PK         | Serial    |
| staff_firstname    | First name of the staff member                   | Varchar   |
| staff_lastname     | Last name of the staff member                    | Varchar   |
| staff_fullname     | Full name of the staff member                    | Varchar   |
| agency_id          | Identifies the agency associated with the staff member, FK | Int       |
| position           | Position of the staff member                     | Varchar   |
| staff_email        | Email address of the staff member                | Varchar   |
| staff_phone        | Phone number of the staff member                 | Varchar   |

- Expense

| Field Name    | Field Description                                   | Data Type  |
|---------------|------------------------------------------------------|------------|
| expense_id    | Unique identifier for an expense, PK                | Serial     |
| staff_id      | Identifies the staff member responsible for the expense, FK | Int  |
| cost          | Cost amount of the expense                           | Decimal    |
| description   | Description of the expense                           | Varchar    |
| expense_date  | Date when the expense was incurred                   | Date       |

- Transactions

| Field Name            | Field Description                                       | Data Type  |
|-----------------------|----------------------------------------------------------|------------|
| transaction_id        | Unique identifier for a transaction, PK                  | Serial     |
| property_id           | Identifies the property involved in the transaction, FK   | Int        |
| client_id             | Identifies the client involved in the transaction        | Int        |
| agent_id              | Identifies the agent involved in the transaction         | Int        |
| transaction_tmstmp    | Timestamp indicating the date and time of the transaction| Timestamp  |
| transaction_type      | Type of the transaction                                  | Varchar    |
| transaction_amount    | Amount involved in the transaction                       | Decimal    |

- Fees

| Field Name      | Field Description                                   | Data Type  |
|-----------------|------------------------------------------------------|------------|
| fee_id          | Unique identifier for a fee, PK                     | Serial     |
| transaction_id  | Identifies the transaction associated with the fee, FK | Int      |
| fee_type        | Type of the fee                                      | Varchar    |
| fee_amount      | Amount of the fee                                    | Decimal    |

- Market_Data

| Field Name          | Field Description                                       | Data Type  |
|---------------------|----------------------------------------------------------|------------|
| market_data_id      | Unique identifier for market data, PK                   | Serial     |
| property_id         | Identifies the property associated with the market data, FK | Int      |
| market_trend        | Market trend information                                | Varchar    |
| pricing_history     | Array of text containing pricing history information    | Text[]     |
| neighborhood_stats  | Neighborhood statistics information                     | Varchar    |

- Property_Client_Interest

| Field Name                   | Field Description                                       | Data Type  |
|------------------------------|----------------------------------------------------------|------------|
| property_id                  | Identifies the property of interest, PK, FK             | Int        |
| client_id                    | Identifies the client expressing interest, PK, FK       | Int        |
| interest_level               | Level of interest expressed by the client for the property | Int      |
| interest_level_transcription | Level of interest transcription                          | Varchar    |

- Property_Agent_Assignment

| Field Name       | Field Description                                   | Data Type  |
|------------------|------------------------------------------------------|------------|
| assignment_id    | Unique identifier for an assignment, PK             | Serial     |
| property_id      | Identifies the property assigned to the agent, FK    | Int        |
| agent_id         | Identifies the agent assigned to the property, FK    | Int        |
| assignment_date  | Date when the assignment was made                    | Date       |

## Examples Included
- An example function demonstrating data updates in one of the tables.
- Another example function showcasing the addition of a new transaction to the transactions table.
- A sample view providing analytics for the most recently added quarter in the database.
- A read-only role tailored for managerial access.
