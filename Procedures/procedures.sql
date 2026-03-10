-- ========================================================================
-- PROCEDURES
-- ========================================================================

-- ------------------------------------------------------------------------
-- Stored Procedure: sp_GetMonthlySalesReport
-- Returns monthly sales metrics, top products, and category breakdown.
-- ------------------------------------------------------------------------
CREATE OR ALTER PROCEDURE sp_GetMonthlySalesReport
    @Year INT,
    @Month INT
AS
BEGIN
    SET NOCOUNT ON;

    WITH monthly_orders AS (
        SELECT
            o.order_id,
            oi.product_id,
            oi.price,
            oi.freight_value,
            (oi.price + ISNULL(oi.freight_value, 0)) AS total_item_value
        FROM orders_clean o
        JOIN order_items_clean oi ON o.order_id = oi.order_id
        WHERE YEAR(o.order_purchase_timestamp) = @Year
          AND MONTH(o.order_purchase_timestamp) = @Month
          AND o.order_status = 'delivered'
    )
    -- Overall metrics
    SELECT
        @Year AS ReportYear,
        @Month AS ReportMonth,
        COUNT(DISTINCT order_id) AS TotalOrders,
        SUM(total_item_value) AS TotalRevenue,
        AVG(total_item_value) AS AvgOrderValue
    FROM monthly_orders;

    -- Top 10 products
    SELECT TOP 10
        p.product_id,
        p.product_category_name,
        COUNT(*) AS QuantitySold,
        SUM(mo.total_item_value) AS Revenue
    FROM monthly_orders mo
    JOIN products_clean p ON mo.product_id = p.product_id
    GROUP BY p.product_id, p.product_category_name
    ORDER BY Revenue DESC;

    -- Revenue by product category
    SELECT
        p.product_category_name,
        COUNT(*) AS QuantitySold,
        SUM(mo.total_item_value) AS Revenue
    FROM monthly_orders mo
    JOIN products_clean p ON mo.product_id = p.product_id
    GROUP BY p.product_category_name
    ORDER BY Revenue DESC;
END;
GO
