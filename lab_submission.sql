-- (i) A Procedure called PROC_LAB5
-- Define the delimiter to allow for multiple statements in the procedure
DELIMITER $$

-- Create the PROC_TOTAL_STOCK_BY_CATEGORY procedure in the inventory database
CREATE DEFINER=retail_user@% PROCEDURE inventory.PROC_TOTAL_STOCK_BY_CATEGORY()
BEGIN
    -- Variable declarations
    DECLARE finished INT DEFAULT 0;                 -- Flag to indicate when cursor fetching is done
    DECLARE category_stock_info TEXT DEFAULT '';     -- Variable to store concatenated category stock information
    DECLARE cat_name VARCHAR(255);                  -- Variable to hold the category name fetched from cursor
    DECLARE total_stock INT;                        -- Variable to hold the total stock fetched from cursor
    DECLARE start_time DATETIME DEFAULT NOW();      -- Capture the start time of procedure execution
    DECLARE end_time DATETIME;                      -- Variable to hold end time of procedure execution

    -- Declare a cursor to fetch category names and their total stock
    DECLARE CURSOR category_cursor CURSOR FOR
        SELECT c.category_name, SUM(p.stock_quantity) AS total_stock
        FROM categories c
        JOIN products p ON c.category_id = p.category_id
        GROUP BY c.category_name;

    -- Handler to set finished flag when no more rows are found
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished = 1;

    -- Open the cursor to start fetching data
    OPEN category_cursor;

    -- Loop to fetch each row from the cursor
    LOOP
        FETCH category_cursor INTO cat_name, total_stock;
        IF finished THEN
            LEAVE LOOP;
        END IF;
        -- Concatenate the category name and total stock to the category_stock_info variable
        SET category_stock_info = CONCAT(category_stock_info, cat_name, ': ', total_stock, CHAR(10));
    END LOOP;

    -- Close the cursor after fetching all data
    CLOSE category_cursor;

    -- Capture the end time after processing
    SET end_time = NOW();
    
    -- Log the execution details into the procedure_log table
    INSERT INTO procedure_log (procedure_name, execution_time, execution_duration) 
    VALUES ('PROC_TOTAL_STOCK_BY_CATEGORY', end_time, TIMESTAMPDIFF(MICROSECOND, start_time, end_time) / 1000);

    -- Return the concatenated category stock information
    SELECT category_stock_info AS "Category Total Stock Information";
END $$

-- Reset the delimiter back to the default
DELIMITER ;


-- (ii) A Function called FUNC_LAB5
CREATE DEFINER=retail_user@% FUNCTION inventory.FUNC_CHECK_STOCK_LEVEL(product_id INT) 
RETURNS VARCHAR(255) 
DETERMINISTIC
BEGIN
    DECLARE stock_level INT;

    -- Retrieve the stock level for the specified product ID
    SELECT stock_quantity INTO stock_level
    FROM products
    WHERE product_id = product_id;

    -- Check if stock_level is NULL or insufficient
    IF stock_level IS NULL THEN
        RETURN 'Invalid product ID or no stock found.';
    ELSEIF stock_level < 10 THEN
        RETURN CONCAT('Low stock: ', stock_level);
    ELSE
        RETURN CONCAT('Stock level: ', stock_level);
    END IF;
END;


-- (iii) A View called VIEW_LAB5
DELIMITER //

CREATE DEFINER=retail_user@% VIEW inventory.VIEW_PRODUCT_STOCK_STATUS AS
SELECT 
    p.product_id,
    p.product_name,
    c.category_name,
    p.stock_quantity,
    (SELECT MAX(stock_quantity) FROM products WHERE category_id = p.category_id) AS max_stock,
    (SELECT MIN(stock_quantity) FROM products WHERE category_id = p.category_id) AS min_stock
FROM 
    products p
JOIN 
    categories c ON p.category_id = c.category_id;

//

DELIMITER ;
