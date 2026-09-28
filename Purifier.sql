use ropurifier;
select * from RO;

CREATE TABLE ro (
    `Product No` INT PRIMARY KEY,
    `Product/Model Name` VARCHAR(150),
    `Manufacturer/Brand` VARCHAR(150),
    `RO Capacity (LPH)` VARCHAR(50),
    `Number of purification stages` VARCHAR(100),
    `RO Membrane specification` VARCHAR(255),
    `Pump specification` VARCHAR(255),
    `Storage capacity` VARCHAR(50),
    `Power consumption` VARCHAR(50),
    `Product price` INT,
    `Warranty` VARCHAR(100),
    `Main application/use case` VARCHAR(255),
    `Manufacturer/Supplier location` VARCHAR(150),
    `Source/Website URL` VARCHAR(255),
    `Seller` VARCHAR(50)
);

SELECT COUNT(*) AS total_products 
FROM ro; 
# to count the no of produsts based on RO capacity 
SELECT 
    `RO Capacity (LPH)` AS capacity_lph, 
    COUNT(*) AS product_count
FROM ro
WHERE `RO Capacity (LPH)` IS NOT NULL
GROUP BY `RO Capacity (LPH)`
ORDER BY product_count DESC;

SELECT COUNT(DISTINCT TRIM(`Manufacturer/Brand`)) AS total_brands
FROM ro;

# query to get the correration 
SELECT
    (
        SUM(cap * price) - SUM(cap) * SUM(price) / COUNT(*)
    )
    /
    SQRT(
        (SUM(cap * cap) - SUM(cap) * SUM(cap) / COUNT(*)) *
        (SUM(price * price) - SUM(price) * SUM(price) / COUNT(*))
    ) AS correlation
FROM (
    SELECT 
        CAST(`RO Capacity (LPH)` AS DECIMAL(5,1)) AS cap,
        `Product price` AS price
    FROM ro
    WHERE TRIM(`RO Capacity (LPH)`) NOT IN ('Not specified', '')
) AS cleaned;

# Average price by capacity range
SELECT
    CASE
        WHEN TRIM(`RO Capacity (LPH)`) = 'Not specified' 
             OR TRIM(`RO Capacity (LPH)`) = '' THEN 'Not specified'
        WHEN CAST(`RO Capacity (LPH)` AS DECIMAL(5,1)) <= 12 THEN 'Up to 12 LPH'
        WHEN CAST(`RO Capacity (LPH)` AS DECIMAL(5,1)) <= 15 THEN '13-15 LPH'
        WHEN CAST(`RO Capacity (LPH)` AS DECIMAL(5,1)) <= 20 THEN '16-20 LPH'
        WHEN CAST(`RO Capacity (LPH)` AS DECIMAL(5,1)) <= 25 THEN '21-25 LPH'
        ELSE 'Above 25 LPH'
    END AS capacity_bucket,
    COUNT(*) AS product_count,
    ROUND(AVG(`Product price`), 0) AS avg_price,
    MIN(`Product price`) AS min_price,
    MAX(`Product price`) AS max_price
FROM ro
GROUP BY capacity_bucket
ORDER BY 
    CASE capacity_bucket
        WHEN 'Up to 12 LPH' THEN 1
        WHEN '13-15 LPH' THEN 2
        WHEN '16-20 LPH' THEN 3
        WHEN '21-25 LPH' THEN 4
        WHEN 'Above 25 LPH' THEN 5
        WHEN 'Not specified' THEN 6
    END;
    
    #  manufacture comprision 
    SELECT
    `Manufacturer/Brand` AS brand,
    COUNT(*) AS product_count,
    ROUND(AVG(`Product price`), 0) AS avg_price,
    MIN(`Product price`) AS min_price,
    MAX(`Product price`) AS max_price,
    ROUND(AVG(
        CASE WHEN `RO Capacity (LPH)` REGEXP '^[0-9]+(\\.[0-9]+)?$' 
             THEN CAST(`RO Capacity (LPH)` AS DECIMAL(5,1)) 
        END
    ), 1) AS avg_capacity,
    ROUND(AVG(
        CASE WHEN `Number of purification stages` REGEXP '^[0-9]+$' 
             THEN CAST(`Number of purification stages` AS UNSIGNED) 
        END
    ), 1) AS avg_stages
FROM ro
GROUP BY `Manufacturer/Brand`
HAVING COUNT(*) >= 2   -- only brands with enough products to compare meaningfully
ORDER BY product_count DESC;

# market segmentation by price tier 
SELECT
    CASE
        WHEN `Product price` < 15000 THEN 'Budget'
        WHEN `Product price` <= 22000 THEN 'Mid-range'
        ELSE 'Premium'
    END AS price_tier,
    COUNT(*) AS product_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS percent
FROM ro
GROUP BY price_tier;

# top 5 "best value" products 
SELECT 
    product_name,
    brand,
    capacity_lph,
    price_inr,
    ROUND(capacity_lph * 1000.0 / price_inr, 3) AS lph_per_1000_inr
FROM (
    SELECT 
        `Product/Model Name` AS product_name,
        `Manufacturer/Brand` AS brand,
        CAST(`RO Capacity (LPH)` AS DECIMAL(5,1)) AS capacity_lph,
        `Product price` AS price_inr
    FROM ro
    WHERE `RO Capacity (LPH)` REGEXP '^[0-9]+(\\.[0-9]+)?$'
) AS cleaned
ORDER BY lph_per_1000_inr DESC
LIMIT 5;

# ranks within each brands 
SELECT * FROM (
    SELECT 
        `Product/Model Name` AS product_name,
        `Manufacturer/Brand` AS brand,
        `Product price` AS price_inr,
        RANK() OVER (PARTITION BY `Manufacturer/Brand` ORDER BY `Product price` DESC) AS price_rank_in_brand,
        COUNT(*) OVER (PARTITION BY `Manufacturer/Brand`) AS brand_product_count
    FROM ro
) t
WHERE brand_product_count >= 2
ORDER BY brand, price_rank_in_brand;

# mising values 

SELECT
    SUM(CASE WHEN TRIM(`RO Capacity (LPH)`) = 'Not specified' 
              OR TRIM(`RO Capacity (LPH)`) = '' 
              OR `RO Capacity (LPH)` IS NULL 
             THEN 1 ELSE 0 END) AS missing_capacity,
    SUM(CASE WHEN TRIM(`Power consumption`) = 'Not specified' 
              OR TRIM(`Power consumption`) = '' 
              OR `Power consumption` IS NULL 
             THEN 1 ELSE 0 END) AS missing_power,
    COUNT(*) AS total_products
FROM ro;

# Price spread 
SELECT 
    `Manufacturer/Brand` AS brand, 
    MAX(`Product price`) - MIN(`Product price`) AS price_spread
FROM ro
GROUP BY `Manufacturer/Brand`
HAVING COUNT(*) > 1
ORDER BY price_spread DESC; 
# products with low to high 5 products 
SELECT 
    `Product/Model Name` AS product_name,
    `Manufacturer/Brand` AS brand,
    `Product price` AS price_inr
FROM ro
ORDER BY `Product price` asc
LIMIT 5;