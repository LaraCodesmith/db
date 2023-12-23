-- At the beginning, it is necessary to create a DB and a schema in it by the next steps:

	-- Step 1 - run the command:
-- CREATE DATABASE realestate;

	-- Step 2 - create a new connection with the name of DB: realestate

	-- Step 3 - make sure that SQL editior opens in created realestate DB

	-- Step 4 - create an empty schema in DB and refresh after executing:
-- CREATE SCHEMA realestate_data;

	-- Step 5 - set the search path for the current session to the created schema and check it (so you can refer to tables without specifying the schema):
SET search_path TO realestate_data;
SHOW search_path;

-- Then, tables can be created and populated with data

-- 11 tables will be created: 1) property, 2) clients, 3) agents, 4) agencies, 5) staff, 6) expense, 7) transactions, 8) fees, 9) market_data, 10) property_client_interest, 11) property_agent_assignment.
-- Creation process will start from tables that doesn't have any foreign key references to other tables and next, tables that has foreign key dependencies will be created.
-- After creating, constraints will be addead and tables will be populated with sample data.

-- Creating Property table
CREATE TABLE IF NOT EXISTS property (
    property_id SERIAL PRIMARY KEY,
    address VARCHAR(100) NOT NULL,
    property_type VARCHAR(20) NOT NULL,
    bedrooms_num INT,
    bathrooms_num INT,
    price DECIMAL(10,2) NOT NULL,
    is_for_sale BOOLEAN,
    is_for_rent BOOLEAN
);

DO $$ 
BEGIN
    BEGIN
        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conname = 'check_property_type' 
              AND connamespace = 'public'::regnamespace
        ) THEN
            ALTER TABLE property 
            ADD CONSTRAINT check_property_type 
            CHECK (property_type IN ('House', 'Apartment', 'Condo', 'Townhouse'));
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE NOTICE 'An exception occurred: %', SQLERRM;
    END;
END $$;

WITH property_data (address, property_type, bedrooms_num, bathrooms_num, price, is_for_sale, is_for_rent) AS (
	VALUES
    	('123 Main St', 'House', 3, 2, 250000.00, TRUE, FALSE),
    	('456 Oak Ave', 'Apartment', 2, 1, 120000.00, TRUE, TRUE),
    	('789 Pine Rd', 'Condo', 1, 1, 90000.00, TRUE, FALSE),
    	('101 Elm St', 'Townhouse', 4, 2, 320000.00, TRUE, FALSE),
    	('202 Maple Dr', 'House', 3, 3, 300000.00, TRUE, FALSE),
    	('303 Cedar Ln', 'Apartment', 2, 2, 150000.00, FALSE, TRUE),
    	('404 Birch Blvd', 'Condo', 1, 1, 85000.00, TRUE, FALSE),
    	('505 Walnut Ct', 'Townhouse', 4, 3, 350000.00, TRUE, FALSE),
    	('606 Oakley St', 'House', 3, 2, 280000.00, TRUE, FALSE),
    	('707 Pinehurst Ave', 'Apartment', 2, 1, 130000.00, FALSE, TRUE)
)
INSERT INTO property(address, property_type, bedrooms_num, bathrooms_num, price, is_for_sale, is_for_rent)
SELECT * FROM property_data
WHERE NOT EXISTS (
    SELECT 1
    FROM property
    WHERE property.address = property_data.address
)
RETURNING property_id;

-- Creating Clients table
CREATE TABLE IF NOT EXISTS clients (
    client_id SERIAL PRIMARY KEY,
    client_type VARCHAR(10) NOT NULL,
    client_firstname VARCHAR(30) NOT NULL,
    client_lastname VARCHAR(30) NOT NULL,
    client_fullname VARCHAR(60) GENERATED ALWAYS AS (client_firstname || ' ' || client_lastname) STORED,
    client_phone VARCHAR(10),
    client_email VARCHAR(100),
    pre_approval_status VARCHAR(20) NOT NULL,
    listing_status VARCHAR(20) DEFAULT 'Inactive' NOT NULL,
    rental_budget DECIMAL (10,2) DEFAULT 0.00 NOT NULL
);

DO $$ 
BEGIN
    BEGIN
        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conname = 'check_client_type' 
              AND connamespace = 'public'::regnamespace
        ) THEN
            ALTER TABLE clients 
            ADD CONSTRAINT check_client_type 
            CHECK (client_type IN ('Buyer', 'Seller', 'Landlord', 'Tenant'));
        END IF;

        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conname = 'unique_client_email' 
              AND connamespace = 'public'::regnamespace
        ) THEN
            ALTER TABLE clients 
            ADD CONSTRAINT unique_client_email 
            UNIQUE (client_email);
        END IF;

        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conname = 'client_email_check' 
              AND connamespace = 'public'::regnamespace
        ) THEN
            ALTER TABLE clients 
            ADD CONSTRAINT client_email_check 
            CHECK (client_email LIKE '%@%');
        END IF;

        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conname = 'check_pre_approval_status' 
              AND connamespace = 'public'::regnamespace
        ) THEN
            ALTER TABLE clients 
            ADD CONSTRAINT check_pre_approval_status 
            CHECK (pre_approval_status IN ('Approved', 'Not Applicable', 'Pending'));
        END IF;

        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conname = 'check_listing_status' 
              AND connamespace = 'public'::regnamespace
        ) THEN
            ALTER TABLE clients 
            ADD CONSTRAINT check_listing_status 
            CHECK (listing_status IN ('Active', 'Inactive'));
        END IF;

    EXCEPTION
        WHEN others THEN
            RAISE NOTICE 'An exception occurred: %', SQLERRM;
    END;
END $$;

WITH client_data (client_type, client_firstname, client_lastname, client_phone, client_email, pre_approval_status, listing_status, rental_budget) AS (
    VALUES
        ('Buyer', 'John', 'Doe', '+234567890', 'john.doe@email.com', 'Approved', 'Active', 2000.00),
        ('Seller', 'Jane', 'Smith', '+876543210', 'jane.smith@email.com', 'Not Applicable', 'Active', 0.00),
        ('Landlord', 'Bob', 'Johnson', '+551234567', 'bob.johnson@email.com', 'Not Applicable', 'Inactive', 0.00),
        ('Tenant', 'Alice', 'Williams', '+890123456', 'alice.williams@email.com', 'Not Applicable', 'Active', 1500.00),
        ('Buyer', 'Charlie', 'Brown', '+112223333', 'charlie.brown@email.com', 'Pending', 'Active', 3000.00),
        ('Seller', 'Diana', 'Miller', '+445556666', 'diana.miller@email.com', 'Not Applicable', 'Active', 0.00),
        ('Landlord', 'Evan', 'Davis', '+778889999', 'evan.davis@email.com', 'Not Applicable', 'Inactive', 0.00),
        ('Tenant', 'Fiona', 'Wilson', '+887776666', 'fiona.wilson@email.com', 'Not Applicable', 'Active', 2000.00),
        ('Buyer', 'George', 'Anderson', '+998887777', 'george.anderson@email.com', 'Approved', 'Active', 2500.00),
        ('Seller', 'Holly', 'Turner', '+223334444', 'holly.turner@email.com', 'Not Applicable', 'Active', 0.00)
)
INSERT INTO clients (client_type, client_firstname, client_lastname, client_phone, client_email, pre_approval_status, listing_status, rental_budget)
SELECT * FROM client_data
WHERE NOT EXISTS (
    SELECT 1
    FROM clients
    WHERE clients.client_email = client_data.client_email
)
RETURNING client_id;

-- Creating Agents table
CREATE TABLE IF NOT EXISTS agents (
    agent_id SERIAL PRIMARY KEY,
    agent_firstname VARCHAR(30),
    agent_lastname VARCHAR(30),
    agent_fullname VARCHAR(60) GENERATED ALWAYS AS (agent_firstname || ' ' || agent_lastname) STORED,
    agent_email VARCHAR(100),
    agent_phone VARCHAR(10)
);

DO $$ 
BEGIN
    BEGIN
        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conname = 'unique_agent_email' 
              AND connamespace = 'public'::regnamespace
        ) THEN
            ALTER TABLE agents 
            ADD CONSTRAINT unique_agent_email 
            UNIQUE (agent_email);
        END IF;

        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conname = 'agent_email_check' 
              AND connamespace = 'public'::regnamespace
        ) THEN
            ALTER TABLE agents 
            ADD CONSTRAINT agent_email_check 
            CHECK (agent_email LIKE '%@%');
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE NOTICE 'An exception occurred: %', SQLERRM;
    END;
END $$;

WITH agent_data (agent_firstname, agent_lastname, agent_email, agent_phone) AS (
    VALUES
        ('Michael', 'Johnson', 'michael.johnson@email.com', '+234567890'),
        ('Emma', 'Smith', 'emma.smith@email.com', '+876543210'),
        ('Daniel', 'Williams', 'daniel.williams@email.com', '+551234567'),
        ('Olivia', 'Jones', 'olivia.jones@email.com', '+890123456'),
        ('William', 'Davis', 'william.davis@email.com', '+112223333'),
        ('Sophia', 'Brown', 'sophia.brown@email.com', '+445556666'),
        ('Alexander', 'Miller', 'alexander.miller@email.com', '+778889999'),
        ('Ava', 'Wilson', 'ava.wilson@email.com', '+887776666'),
        ('James', 'Anderson', 'james.anderson@email.com', '+998887777'),
        ('Lily', 'Turner', 'lily.turner@email.com', '+223334444')
)
INSERT INTO agents (agent_firstname, agent_lastname, agent_email, agent_phone)
SELECT * FROM agent_data
WHERE NOT EXISTS (
    SELECT 1
    FROM agents
    WHERE agents.agent_email = agent_data.agent_email
)
RETURNING agent_id;

-- Creating Agencies table
CREATE TABLE IF NOT EXISTS agencies (
    agency_id SERIAL PRIMARY KEY,
    agent_id INT NOT NULL REFERENCES agents(agent_id),
    agency_name VARCHAR(30),
    license_num VARCHAR(20),
    agency_address VARCHAR(100),
    website VARCHAR(200),
    agency_email VARCHAR(200) GENERATED ALWAYS AS (
        'info@' || SUBSTRING(website FROM POSITION('https://www.' IN website) + LENGTH('https://www.') FOR LENGTH(website))
    ) STORED,
    agency_phone VARCHAR(10)
);

DO $$ 
BEGIN
    BEGIN
        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conname = 'unique_agency_name' 
              AND connamespace = 'public'::regnamespace
        ) THEN
            ALTER TABLE agencies 
            ADD CONSTRAINT unique_agency_name 
            UNIQUE (agency_name);
        END IF;

        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conname = 'unique_license_num' 
              AND connamespace = 'public'::regnamespace
        ) THEN
            ALTER TABLE agencies 
            ADD CONSTRAINT unique_license_num 
            UNIQUE (license_num);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RAISE NOTICE 'An exception occurred: %', SQLERRM;
    END;
END $$;

WITH agency_data (agent_fullname, agency_name, license_num, agency_address, website, agency_phone) AS (
    VALUES
        ('James Anderson', 'Agency A', 'License123', '123 Main St, Cityville', 'https://www.agencya.com', '+551112222'),
        ('Michael Johnson', 'Agency B', 'License456', '456 Oak Ave, Townburg', 'https://www.agencyb.com', '+778889999'),
        ('Daniel Williams', 'Agency C', 'License789', '789 Pine Rd, Villagetown', 'https://www.agencyc.com', '+990001111'),
        ('Ava Wilson', 'Agency D', 'License012', '456 Elm St, Countryside', 'https://www.agencyd.com', '+112223333'),
        ('Lily Turner', 'Agency E', 'License345', '789 Maple Dr, Suburbia', 'https://www.agencye.com', '+334445555'),
        ('William Davis', 'Agency F', 'License678', '101 Oakley St, Metropolis', 'https://www.agencyf.com', '+556667777'),
        ('Sophia Brown', 'Agency G', 'License901', '202 Pinehurst Ave, Downtown', 'https://www.agencyg.com', '+778889999'),
        ('Olivia Jones', 'Agency H', 'License234', '303 Birch Blvd, Uptown', 'https://www.agencyh.com', '+990001111'),
        ('Alexander Miller', 'Agency I', 'License567', '404 Walnut Ct, Outskirts', 'https://www.agencyi.com', '+112223333'),
        ('Emma Smith', 'Agency J', 'License890', '505 Cedar Ln, Countryside', 'https://www.agencyj.com', '+334445555')
)
INSERT INTO agencies (agent_id, agency_name, license_num, agency_address, website, agency_phone)
SELECT
    agents.agent_id,
    agency_data.agency_name,
    agency_data.license_num,
    agency_data.agency_address,
    agency_data.website,
    agency_data.agency_phone
FROM
    agents
INNER JOIN agency_data ON agents.agent_fullname = agency_data.agent_fullname
WHERE NOT EXISTS (
    SELECT 1
    FROM agencies
    WHERE agencies.agency_name = agency_data.agency_name
)
RETURNING agency_id;

-- Creating Staff table
CREATE TABLE IF NOT EXISTS staff (
    staff_id SERIAL PRIMARY KEY,
    staff_firstname VARCHAR(30),
    staff_lastname VARCHAR(30),
    staff_fullname VARCHAR(60) GENERATED ALWAYS AS (staff_firstname || ' ' || staff_lastname) STORED,
    agency_id INT NOT NULL REFERENCES agencies(agency_id),
    staff_position VARCHAR(100),
    staff_email VARCHAR(100),
    staff_phone VARCHAR(10)
);

DO $$ 
BEGIN
    BEGIN
        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conname = 'staff_email_check' 
              AND connamespace = 'public'::regnamespace
        ) THEN
            ALTER TABLE staff 
            ADD CONSTRAINT staff_email_check 
            CHECK (staff_email LIKE '%@%');
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE NOTICE 'An exception occurred: %', SQLERRM;
    END;
END $$;

WITH staff_data (staff_firstname, staff_lastname, agency_name, staff_position, staff_email, staff_phone) AS (
    VALUES
        ('John', 'Doe', 'Agency A', 'Agent', 'john.doe@example.com', '+551112222'),
        ('Jane', 'Smith', 'Agency B', 'Manager', 'jane.smith@example.com', '+778889999'),
        ('Robert', 'Johnson', 'Agency C', 'Assistant', 'robert.johnson@example.com', '+990001111'),
        ('Emily', 'Brown', 'Agency D', 'Coordinator', 'emily.brown@example.com', '+112223333'),
        ('Michael', 'Williams', 'Agency E', 'Agent', 'michael.williams@example.com', '+334445555'),
        ('Sophia', 'Davis', 'Agency F', 'Manager', 'sophia.davis@example.com', '+556667777'),
        ('Oliver', 'Miller', 'Agency G', 'Assistant', 'oliver.miller@example.com', '+778889999'),
        ('Emma', 'Jones', 'Agency H', 'Coordinator', 'emma.jones@example.com', '+990001111'),
        ('Daniel', 'Wilson', 'Agency I', 'Agent', 'daniel.wilson@example.com', '+112223333'),
        ('Ava', 'Turner', 'Agency J', 'Manager', 'ava.turner@example.com', '+334445555')
)
INSERT INTO staff (staff_firstname, staff_lastname, agency_id, staff_position, staff_email, staff_phone)
SELECT
    staff_data.staff_firstname,
    staff_data.staff_lastname,
    agencies.agency_id,
    staff_data.staff_position,
    staff_data.staff_email,
    staff_data.staff_phone
FROM
    staff_data
INNER JOIN agencies ON staff_data.agency_name = agencies.agency_name
WHERE NOT EXISTS (
    SELECT 1
    FROM staff
    WHERE staff.staff_firstname = staff_data.staff_firstname
        AND staff.staff_lastname = staff_data.staff_lastname
)
RETURNING staff_id;

-- Creating Expense table
CREATE TABLE IF NOT EXISTS expense (
    expense_id SERIAL PRIMARY KEY,
    staff_id INT REFERENCES staff(staff_id),
    costs DECIMAL(10,2),
    description VARCHAR(255),
    expense_date DATE
);

DO $$ 
BEGIN
    BEGIN
        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conname = 'check_expense_date' 
              AND connamespace = 'public'::regnamespace
        ) THEN
            ALTER TABLE expense 
            ADD CONSTRAINT check_expense_date 
            CHECK (expense_date >= '2023-10-20');
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE NOTICE 'An exception occurred: %', SQLERRM;
    END;
END $$;

WITH expense_data (staff_fullname, costs, description, expense_date) AS (
    VALUES
        ('Robert Johnson', 500.00, 'Office Supplies', '2023-11-01'::DATE),
        ('Jane Smith', 2000.00, 'Marketing Campaign', '2023-11-02'::DATE),
        ('Emily Brown', 750.00, 'Travel Expenses', '2023-11-03'::DATE),
        ('Emma Jones', 1200.00, 'IT Services', '2023-11-04'::DATE),
        ('Sophia Davis', 600.00, 'Training Materials', '2023-11-05'::DATE),
        ('Ava Turner', 300.00, 'Miscellaneous', '2023-11-06'::DATE),
        ('Michael Williams', 1000.00, 'Business Development', '2023-11-07'::DATE),
        ('Oliver Miller', 450.00, 'Equipment Maintenance', '2023-11-08'::DATE),
        ('John Doe', 800.00, 'Employee Benefits', '2023-11-09'::DATE),
        ('Daniel Wilson', 650.00, 'Client Entertainment', '2023-11-10'::DATE)
)
INSERT INTO expense (staff_id, costs, description, expense_date)
SELECT
    staff.staff_id,
    expense_data.costs,
    expense_data.description,
    expense_data.expense_date
FROM
    expense_data
INNER JOIN staff ON staff.staff_fullname = expense_data.staff_fullname
WHERE NOT EXISTS (
    SELECT 1
    FROM expense
    WHERE expense.staff_id = staff.staff_id
        AND expense.costs = expense_data.costs
        AND expense.description = expense_data.description
        AND expense.expense_date = expense_data.expense_date
)
RETURNING expense_id;

-- Creating Transactions table
CREATE TABLE IF NOT EXISTS transactions (
    transaction_id SERIAL PRIMARY KEY,
    property_id INT REFERENCES property(property_id),
    client_id INT REFERENCES clients(client_id),
    agent_id INT REFERENCES agents(agent_id),
    transaction_tmstmp TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    transaction_type VARCHAR(4),
    transaction_amount DECIMAL(10,2)
);

DO $$ 
BEGIN
    BEGIN
        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conname = 'check_transaction_tmstmp' 
              AND connamespace = 'public'::regnamespace
        ) THEN
            ALTER TABLE transactions 
            ADD CONSTRAINT check_transaction_tmstmp 
            CHECK (transaction_tmstmp >= '2023-10-20');
        END IF;

        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conname = 'check_transaction_type' 
              AND connamespace = 'public'::regnamespace
        ) THEN
            ALTER TABLE transactions 
            ADD CONSTRAINT check_transaction_type 
            CHECK (transaction_type ILIKE ANY(ARRAY['Sale', 'Rent']));
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE NOTICE 'An exception occurred: %', SQLERRM;
    END;
END $$;

WITH transaction_data (property_address, client_fullname, agency_name, transaction_type, transaction_amount) AS (
    VALUES
        ('123 Main St', 'Fiona Wilson', 'Agency A', 'Sale', 200000.00),
        ('456 Oak Ave', 'Jane Smith', 'Agency B', 'Rent', 1200.00),
        ('789 Pine Rd', 'Charlie Brown', 'Agency C', 'Sale', 90000.00),
        ('101 Elm St', 'John Doe', 'Agency D', 'Sale', 320000.00),
        ('202 Maple Dr', 'Holly Turner', 'Agency E', 'Sale', 300000.00),
        ('303 Cedar Ln', 'Alice Williams', 'Agency F', 'Rent', 1500.00),
        ('404 Birch Blvd', 'Bob Johnson', 'Agency G', 'Sale', 85000.00),
        ('505 Walnut Ct', 'Evan Davis', 'Agency H', 'Sale', 350000.00),
        ('606 Oakley St', 'Diana Miller', 'Agency I', 'Sale', 280000.00),
        ('707 Pinehurst Ave', 'George Anderson', 'Agency J', 'Rent', 1300.00)
)
INSERT INTO transactions (property_id, client_id, agent_id, transaction_type, transaction_amount)
SELECT
    p.property_id,
    c.client_id,
    a.agent_id,
    td.transaction_type,
    td.transaction_amount
FROM
    transaction_data td
INNER JOIN property p ON p.address = td.property_address
INNER JOIN clients c ON c.client_fullname = td.client_fullname
INNER JOIN agencies ag ON ag.agency_name = td.agency_name
INNER JOIN agents a ON a.agent_id = ag.agent_id
WHERE NOT EXISTS (
    SELECT 1
    FROM transactions t
    WHERE t.property_id = p.property_id
      AND t.client_id = c.client_id
      AND t.agent_id = a.agent_id
      AND t.transaction_type = td.transaction_type
      AND t.transaction_amount = td.transaction_amount
)
RETURNING transaction_id;

-- Creating Fees table
CREATE TABLE IF NOT EXISTS fees (
    fee_id SERIAL PRIMARY KEY,
    transaction_id INT REFERENCES transactions(transaction_id) NOT NULL,
    fee_type VARCHAR(20),
    fee_amount DECIMAL(10,2) NOT NULL
);

DO $$ 
BEGIN
    BEGIN
        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conname = 'check_fee_type' 
              AND connamespace = 'public'::regnamespace
        ) THEN
            ALTER TABLE fees 
            ADD CONSTRAINT check_fee_type 
            CHECK (fee_type ILIKE ANY(ARRAY['commission', 'closing_costs', 'tax', 'notary_fee', 'other']));
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE NOTICE 'An exception occurred: %', SQLERRM;
    END;
END $$;

WITH fee_data (fee_type, fee_amount) AS (
    VALUES
        ('commission', 5000.00),
        ('closing_costs', 1000.00),
        ('tax', 200.00),
        ('notary_fee', 150.00),
        ('other', 300.00),
        ('commission', 4500.00),
        ('closing_costs', 800.00),
        ('tax', 180.00),
        ('notary_fee', 120.00),
        ('other', 250.00)
)
INSERT INTO fees (transaction_id, fee_type, fee_amount)
SELECT
    ROUND(RANDOM() * 9 + 1)::INT,
    fd.fee_type,
    fd.fee_amount
FROM fee_data fd
RETURNING fee_id;

-- Creating Market Data table
CREATE TABLE IF NOT EXISTS market_data (
    market_data_id SERIAL PRIMARY KEY,
    property_id INT REFERENCES property(property_id),
    market_trend VARCHAR(10),
    pricing_history TEXT[] NOT NULL,
    neighborhood_stats VARCHAR(255)
);

-- Creating a trigger and a function to check pricing_history values for being non-negative (PostgreSQL does not allow subqueries in check constraints directly)

CREATE OR REPLACE FUNCTION check_pricing_history_non_negative()
RETURNS TRIGGER AS $$
BEGIN
    IF (
        SELECT TRUE
        FROM UNNEST(NEW.pricing_history) price
        WHERE price::NUMERIC < 0
    ) THEN
        RAISE NOTICE 'Pricing history must not contain negative values.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$ 
BEGIN
    -- Check if the trigger already exists
    IF NOT EXISTS (
        SELECT 1
        FROM pg_trigger
        WHERE tgname = 'trg_check_pricing_history_non_negative'
    ) THEN
        -- Create the trigger only if it doesn't exist
        CREATE TRIGGER trg_check_pricing_history_non_negative
            BEFORE INSERT OR UPDATE
            ON market_data
            FOR EACH ROW
            EXECUTE FUNCTION check_pricing_history_non_negative();
    END IF;
END $$;

WITH market_data_info (property_address, market_trend, pricing_history, neighborhood_stats) AS (
    VALUES
        ('123 Main St', 'Up', ARRAY['200000.00', '210000.00', '220000.00'], 'Good'),
        ('456 Oak Ave', 'Stable', ARRAY['120000.00', '125000.00', '130000.00'], 'Average'),
        ('789 Pine Rd', 'Down', ARRAY['90000.00', '88000.00', '86000.00'], 'Poor'),
        ('101 Elm St', 'Up', ARRAY['320000.00', '330000.00', '340000.00'], 'Excellent'),
        ('202 Maple Dr', 'Stable', ARRAY['300000.00', '305000.00', '310000.00'], 'Good'),
        ('303 Cedar Ln', 'Down', ARRAY['150000.00', '145000.00', '140000.00'], 'Average'),
        ('404 Birch Blvd', 'Up', ARRAY['85000.00', '87000.00', '89000.00'], 'Poor'),
        ('505 Walnut Ct', 'Up', ARRAY['350000.00', '360000.00', '370000.00'], 'Excellent'),
        ('606 Oakley St', 'Down', ARRAY['280000.00', '270000.00', '260000.00'], 'Good'),
        ('707 Pinehurst Ave', 'Stable', ARRAY['130000.00', '135000.00', '140000.00'], 'Average')
)
INSERT INTO market_data (property_id, market_trend, pricing_history, neighborhood_stats)
SELECT
    p.property_id,
    mdi.market_trend,
    mdi.pricing_history,
    mdi.neighborhood_stats
FROM market_data_info mdi
JOIN property p ON p.address = mdi.property_address
WHERE NOT EXISTS (
    SELECT 1
    FROM market_data md
    WHERE md.property_id = p.property_id
)
RETURNING market_data_id;

-- Creating Property_Client_Interest table
CREATE TABLE IF NOT EXISTS property_client_interest (
    property_id INT REFERENCES property(property_id),
    client_id INT REFERENCES clients(client_id),
    interest_level INTEGER NOT NULL,
    interest_level_transcription VARCHAR(20) GENERATED ALWAYS AS (
    CASE
        WHEN interest_level > 8 THEN 'High'
        WHEN interest_level > 5 AND interest_level <= 8 THEN 'Medium'
        WHEN interest_level > 2 AND interest_level <= 5 THEN 'Low'
        WHEN interest_level >= 0 AND interest_level <= 2 THEN 'Not Interested'
        ELSE 'Not Interested'
    END
	) STORED,
    PRIMARY KEY (property_id, client_id)
);

DO $$ 
BEGIN
    BEGIN
        IF NOT EXISTS (
            SELECT 1 
            FROM pg_constraint 
            WHERE conname = 'check_interest_level_range' 
              AND connamespace = 'public'::regnamespace
        ) THEN
            ALTER TABLE property_client_interest 
            ADD CONSTRAINT check_interest_level_range 
            CHECK (interest_level >= 0 AND interest_level <= 10);
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE NOTICE 'An exception occurred: %', SQLERRM;
    END;
END $$;

WITH property_client_interest_info (property_address, client_fullname) AS (
    VALUES
        ('123 Main St', 'Fiona Wilson'),
        ('456 Oak Ave', 'Jane Smith'),
        ('789 Pine Rd', 'Charlie Brown'),
        ('101 Elm St', 'John Doe'),
        ('202 Maple Dr', 'Holly Turner'),
        ('303 Cedar Ln', 'Alice Williams'),
        ('404 Birch Blvd', 'Bob Johnson'),
        ('505 Walnut Ct', 'Evan Davis'),
        ('606 Oakley St', 'Diana Miller'),
        ('707 Pinehurst Ave', 'George Anderson')
)
INSERT INTO property_client_interest (property_id, client_id, interest_level)
SELECT
    p.property_id,
    c.client_id,
    ROUND(RANDOM() * 10)
FROM property_client_interest_info pci
JOIN property p ON p.address = pci.property_address
JOIN clients c ON c.client_fullname = pci.client_fullname
WHERE NOT EXISTS (
    SELECT 1
    FROM property_client_interest pci_existing
    WHERE pci_existing.property_id = p.property_id
      AND pci_existing.client_id = c.client_id
)
RETURNING property_id, client_id;

-- Creating Property_Agent_Assignment table
CREATE TABLE IF NOT EXISTS property_agent_assignment (
    assignment_id SERIAL PRIMARY KEY,
    property_id INT REFERENCES property(property_id),
    agent_id INT REFERENCES agents(agent_id),
    assignment_date DATE DEFAULT CURRENT_DATE NOT NULL
);

DO $$ 
BEGIN
    BEGIN
        -- Check if the constraint already exists
        IF NOT EXISTS (
            SELECT 1
            FROM pg_constraint
            WHERE conname = 'check_assignment_date'
              AND connamespace = 'public'::regnamespace
        ) THEN
            -- Create the constraint only if it doesn't exist
            EXECUTE 'ALTER TABLE property_agent_assignment ADD CONSTRAINT check_assignment_date CHECK (assignment_date >= ''2023-10-20'')';
        END IF;
    EXCEPTION
        WHEN others THEN
            RAISE NOTICE 'An exception occurred: %', SQLERRM;
    END;
END $$;

WITH property_agent_assignment_info (property_address, agent_fullname) AS (
    VALUES
        ('123 Main St', 'James Anderson'),
        ('456 Oak Ave', 'Michael Johnson'),
        ('789 Pine Rd', 'Daniel Williams'),
        ('101 Elm St', 'Ava Wilson'),
        ('202 Maple Dr', 'Lily Turner'),
        ('303 Cedar Ln', 'William Davis'),
        ('404 Birch Blvd', 'Sophia Brown'),
        ('505 Walnut Ct', 'Olivia Jones'),
        ('606 Oakley St', 'Alexander Miller'),
        ('707 Pinehurst Ave', 'Emma Smith')
)
INSERT INTO property_agent_assignment (property_id, agent_id)
SELECT
    p.property_id,
    a.agent_id
FROM property_agent_assignment_info paai
JOIN property p ON p.address = paai.property_address
JOIN agents a ON a.agent_fullname = paai.agent_fullname
WHERE NOT EXISTS (
    SELECT 1
    FROM property_agent_assignment paa_existing
    WHERE paa_existing.property_id = p.property_id
      AND paa_existing.agent_id = a.agent_id
)
RETURNING assignment_id, property_id, agent_id, assignment_date;

-- Example function that updates data in one of tables

CREATE OR REPLACE FUNCTION update_table_data(
    IN p_table_name VARCHAR,
    IN p_primary_key_value INT,
    IN p_column_name VARCHAR,
    IN p_new_value VARCHAR
)
RETURNS VOID
LANGUAGE plpgsql

AS $$
DECLARE
    v_primary_key_column VARCHAR;
BEGIN
    -- Dynamically determines the primary key column
    SELECT column_name
    INTO v_primary_key_column
    FROM information_schema.columns
    WHERE table_name = p_table_name
        AND column_name LIKE '%id%'
    LIMIT 1;

    EXECUTE 'UPDATE ' || p_table_name ||
            ' SET ' || p_column_name || ' = $1' ||
            ' WHERE ' || v_primary_key_column || ' = $2'
    USING p_new_value, p_primary_key_value;
END;
$$;

-- Example usage:
-- Updating the address of the property with property_id = 1
SELECT update_table_data('property', 1, 'address', '404 Birch St');

-- Example function that adds a new transaction to transaction table

CREATE OR REPLACE FUNCTION add_transaction(
    IN p_property_id INT,
    IN p_client_id INT,
    IN p_agent_id INT,
    IN p_transaction_tmstmp TIMESTAMP,
    IN p_transaction_type VARCHAR(4),
    IN p_transaction_amount DECIMAL(10,2)
)
RETURNS VOID
LANGUAGE plpgsql

AS $$
BEGIN
	IF EXISTS (
        SELECT 1
        FROM transactions
        WHERE property_id = p_property_id
          AND client_id = p_client_id
          AND agent_id = p_agent_id
          AND transaction_tmstmp = p_transaction_tmstmp
    ) THEN
        RAISE NOTICE 'Transaction already exists for the given property, client, agent, and timestamp';
    ELSE
    	INSERT INTO transactions (
        	property_id,
        	client_id,
        	agent_id,
        	transaction_tmstmp,
        	transaction_type,
        	transaction_amount
    	)
    	VALUES (
        	p_property_id,
        	p_client_id,
        	p_agent_id,
        	p_transaction_tmstmp,
        	p_transaction_type,
        	p_transaction_amount
    	);

    	RAISE NOTICE 'New transaction was added to the database successfully.';
    END IF;
END;
$$;

-- Example usage:
SELECT add_transaction(1, 2, 3, '2023-12-01 12:00:00'::TIMESTAMP, 'Sale', 250000.00);

-- Example view that presents analytics for the most recently added quarter in database

CREATE OR REPLACE VIEW recent_quarter_analytics AS
SELECT
    t.property_id,
    p.address AS property_address,
    c.client_id,
   	c.client_fullname,
    a.agent_id,
    a.agent_fullname,
    t.transaction_type,
    t.transaction_amount,
    md.market_trend,
    md.pricing_history,
    SUM(t.transaction_amount) AS total_transaction_amount
FROM transactions t
INNER JOIN property p ON t.property_id = p.property_id
INNER JOIN clients c ON t.client_id = c.client_id
INNER JOIN agents a ON t.agent_id = a.agent_id
LEFT JOIN market_data md ON t.property_id = md.property_id
WHERE
    EXTRACT(QUARTER FROM t.transaction_tmstmp) = EXTRACT(QUARTER FROM CURRENT_DATE)
    AND EXTRACT(YEAR FROM t.transaction_tmstmp) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY
    t.property_id,
    p.address,
    c.client_id,
    c.client_firstname,
    c.client_lastname,
    a.agent_id,
    a.agent_firstname,
    a.agent_lastname,
    t.transaction_type,
    t.transaction_amount,
    md.market_trend,
    md.pricing_history
ORDER BY MAX(t.transaction_tmstmp) DESC;

-- Example usage:
SELECT * FROM recent_quarter_analytics;

-- Example read-only role for the manager

-- Checking if the current user is a superuser that has the ability create users and assign permissions
SELECT rolsuper FROM pg_roles WHERE rolname = CURRENT_USER;

CREATE OR REPLACE FUNCTION create_manager_readonly_role(passwd VARCHAR(20))
RETURNS VOID
LANGUAGE plpgsql

AS $$
BEGIN
	
	IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'manager_readonly')
		THEN
    		EXECUTE 'CREATE ROLE manager_readonly LOGIN PASSWORD ' || quote_literal(passwd) || ' NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE NOREPLICATION VALID UNTIL ''2023-12-31 23:59:59''';
    		EXECUTE 'GRANT USAGE ON SCHEMA realestate_data TO manager_readonly';
    		EXECUTE 'GRANT SELECT ON ALL TABLES IN SCHEMA realestate_data TO manager_readonly';
   	ELSE
        RAISE NOTICE 'Role manager_readonly already exists';
    END IF;
   
END;
$$;

-- Example usage:
SELECT create_manager_readonly_role('SeCuRe_123!');