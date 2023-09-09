create database stores
GO
USE stores
GO
/* INTRODUCTION
- Mục tiêu của dự án:  Phân tích khách hàng và sản phẩm là phân tích dữ liệu từ cơ sở dữ liệu hồ sơ bán hàng dành cho ô tô mô hình quy mô và trích xuất thông tin để đưa ra quyết định.
- Một số câu hỏi dành cho dự án:
1. CHúng ta nên đặt mua nhiều hay ít sản phẩm nào?
2. Chúng ta nên điều chỉnh chiến lược tiếp thị và truyền thông như thế nào cho phù hợp với hành vi của khách hàng
3. CHúng ta có thể chi bao nhiêu tiền để có được khách hàng mới
- Dữ liệu gồm 8 bảng: 
+ Customers: dữ liệu khách hàng 
+ Employees: tất cả thông tin nhân viên
+ Offices: thông tin văn phòng bán hàng
+ Orders: Đơn đặt hàng của khách hàng
+ OrderDetails: Chi tiết thông tin bán hàng cho mỗi đơn hàng
+ Payments: Hồ sơ thanh toán của khách hàng
+ Products: Danh sách xe mô hình
+ ProductLines: Danh sách các dòng sản phẩm
*/


SELECT * FROM customers;--13 thuộc tính
SELECT * FROM employees; --8 thuộc tính
SELECT * FROM offices;--9 thuộc tính
SELECT * FROM orders; -- 7 thuộc tính
SELECT * FROM orderdetails; -- 5 thuộc tính
SELECT * FROM Payments; -- 4 thuộc tính
SELECT * FROM products; -- 9 thuộc tính
SELECT * FROM Productlines;--4 thuộc tính
----------------------------------------
/* CHI TIẾT CÁC BẢNG*/
SELECT 'Customers' AS Table_name, '13' AS Số_thuộc_tính, COUNT(*) AS Số_hàng FROM Customers
UNION ALL
SELECT 'Employees' AS Table_name,'8' as Số_thuộc_tính, COUNT(*) AS Số_hàng FROM employees
UNION ALL
SELECT 'Offices' AS Table_name, '9' AS Số_thuộc_tính, COUNT(*) AS Số_hàng FROM offices
UNION ALL
SELECT 'Order' AS Table_name, '7' AS Số_thuộc_tính, COUNT(*) AS Số_hàng FROM orders
UNION ALL
SELECT 'Orderdetails' AS Table_name, '5' AS Số_thuộc_tính, COUNT(*) AS Số_hàng FROM orderdetails
UNION ALL
SELECT 'Payments' AS Table_name, '4' AS Số_thuộc_tính, COUNT(*) AS Số_hàng FROM payments
UNION ALL
SELECT 'Products' AS Table_name, '9' AS Số_thuộc_tính, COUNT(*) AS Số_hàng FROM products
UNION ALL
SELECT 'Productline' AS Table_name, '4' AS Số_thuộc_tính, COUNT(*) AS Số_hàng FROM Productlines;

/*Câu hỏi 1: Chúng ta nên đặt hàng nhiều hay ít sản phẩm nào?*/
/* 
Để trả lời câu hỏi 1 chúng ta cần tính số lượng hàng tồn kho và hiệu suất sản phẩm 
Số lượng hàng tồn kho (low stock) = SUM(quantityOrdered)/quantityInStock
Hiệu suất sản phẩm (Product Performance) = SUM(quantityOrdered x priceEach) 
*/
--Tính hiệu suất sản phẩm:
   SELECT  TOP 10 productCode, 
		   SUM(quantityOrdered * priceEach) as product_performance
    FROM orderdetails
GROUP BY productCode
ORDER BY product_performance DESC;
---Tính tỷ số hàng tồn kho:
  SELECT TOP 10 od.productCode,
		  ROUND(SUM(quantityOrdered)/(SELECT quantityInStock
										FROM products AS p
									   WHERE p.productCode = od.ProductCode),2) AS low_stock
	FROM orderdetails AS od
GROUP BY od.productCode
ORDER BY low_stock;
---Tìm các sản phẩm ưu tiên nhập kho:
WITH 
	prfm AS (
	SELECT productCode,
		   sum(quantityOrdered) as sum_quan,
		   SUM(quantityOrdered * priceEach) as product_performance
	  FROM  orderdetails
  GROUP BY productCode 
	),
	lowstock AS (
	 SELECT  TOP 10 p.productcode,
		     p.productname,
		     p.productline,
			 sum(quantityOrdered) as sum_quan,
		     ROUND(SUM(quantityOrdered)/p.quantityInStock,2) as low_stock
	  FROM products AS p 
	  JOIN orderdetails AS od ON p.productcode = od.productcode
  GROUP BY p.productCode,p.productName,p.productLine, p.quantityInStock
  ORDER BY low_stock
  )
  SELECT pr.productCode,
	     ls.productname,
	     ls.productline,
	     pr.product_performance,
	     ls.low_stock,
	     ls.sum_quan
    FROM lowstock AS ls
    JOIN prfm AS pr ON pr.productCode = ls.productCode
ORDER BY pr.product_performance DESC;
--Câu hỏi 2: Chúng ta nên kết hợp chiến lược tiếp thị và truyền thông với hành vi của khách hàng như thế nào?
/* 
Để trả lời câu hỏi 2 chúng ta cần tính toán lợi nhuận cho mỗi khách hàng bằng công thức:
profit_per_cus = SUM(quantityOrdered * (priceEach - buyPrice))
*/
--  lợi nhuận cho mỗi khách hàng:
  SELECT TOP 10 customerNumber,
         SUM(quantityOrdered * (priceEach - buyPrice)) as profit_per_cus
    FROM products AS p 
    JOIN  orderdetails AS od ON p.productCode = od.productCode
    JOIN orders AS o ON o.orderNumber = od.orderNumber
GROUP BY customerNumber
ORDER BY profit_per_cus;
--- 5 khách hàng VIP (khách hàng mang lại lợi nhuận cao nhất):
WITH profit AS
(
  SELECT customerNumber,
         SUM(quantityOrdered * (priceEach - buyPrice)) as profit_per_cus
    FROM products AS p 
    JOIN  orderdetails AS od ON p.productCode = od.productCode
    JOIN orders AS o ON o.orderNumber = od.orderNumber
GROUP BY customerNumber
)
  SELECT TOP 5 c.contactFirstName,
	     c.contactLastName,
	     c.city,
	     c.country,
	     p.profit_per_cus
    FROM profit AS p
    JOIN customers AS c ON c.customerNumber = p.customerNumber
ORDER BY p.profit_per_cus DESC;

--- 5 khách hàng ít tương tác nhất (khách hàng mang lại lợi nhuận thấp nhất)
WITH profit AS
(
  SELECT customerNumber,
         SUM(quantityOrdered * (priceEach - buyPrice)) as profit_per_cus
    FROM products AS p 
    JOIN  orderdetails AS od ON p.productCode = od.productCode
    JOIN orders AS o ON o.orderNumber = od.orderNumber
GROUP BY customerNumber
)
  SELECT TOP 5 c.contactFirstName,
	     c.contactLastName,
	     c.city,
	     c.country,
	     p.profit_per_cus
    FROM profit AS p
    JOIN customers AS c ON c.customerNumber = p.customerNumber
ORDER BY p.profit_per_cus;

--Câu hỏi 3: Chúng ta có thể chi bao nhiêu để thu hút khách hàng mới?:

-- Tìm kiếm lượng khách hàng mới mỗi tháng:
select * from payments
WITH 
payment_with_year_month_table AS
(
SELECT *,
       CAST( SUBSTRING(CONVERT(varchar(15),paymentdate,112),1,4) AS INT)*100 + CAST(SUBSTRING(CONVERT(varchar(15),paymentdate,112),5,2) AS INT) as year_month
  FROM payments AS p
),
customers_by_month_table AS
(
  SELECT p1.year_month,
       COUNT(*) AS number_of_customers,
       SUM(p1.amount) AS total
    FROM payment_with_year_month_table p1
GROUP BY p1.year_month
),
new_customers_by_month_table AS 
(
  SELECT p1.year_month,
         COUNT(*) AS number_of_new_customers,
         SUM(p1.amount) AS new_customer_total,
        (SELECT number_of_customers 
           FROM customers_by_month_table AS c
          WHERE c.year_month = p1.year_month) AS number_of_customers,
        (SELECT total 
           FROM customers_by_month_table AS c
          WHERE c.year_month = p1.year_month) AS total
    FROM payment_with_year_month_table p1
   WHERE p1.customerNumber NOT IN (SELECT customerNumber
								     FROM	payment_with_year_month_table AS p2
								    WHERE p2.year_month < p1.year_month)
GROUP BY p1.year_month
)
SELECT year_month,
 ROUND(number_of_new_customers *100/number_of_customers,1) AS number_of_new_customers_props,
 ROUND(new_customer_total*100/total,1) AS new_customers_total_props
  FROM new_customers_by_month_table;

--- Tính Giá trị vòng đời khách hàng (LTV) bằng cách sử dụng lợi nhuận trung bình của mỗi khách hàng:
WITH profit AS
(
  SELECT customerNumber,
         SUM(quantityOrdered * (priceEach - buyPrice)) as profit_per_cus
    FROM products AS p 
    JOIN  orderdetails AS od ON p.productCode = od.productCode
    JOIN orders AS o ON o.orderNumber = od.orderNumber
GROUP BY customerNumber
)
SELECT ROUND(AVG(profit_per_cus),2) AS LTV
  FROM profit;

/* TỔNG KẾT:
CÂU HỎI 1: Chúng ta nên đặt hàng nhiều hay ít sản phẩm nào?
- Sau khi phân tích kết quả truy vấn đưa ra 10 sản phẩm có lượng hàng tồn kho thấp và hiệu suất sản phẩm cao, nhận thấy trong 10 sản phẩm trên thì có 6 sản phẩm thuộc dòng sản phẩm ‘Classic Cars’. Những sản phẩm này được bán thường xuyên với hiệu suất sản phẩm cao. Vì vậy, chúng ta nên bổ sung chúng lại chúng thường xuyên.
CÂU HỎI 2:Chúng ta nên kết hợp chiến lược tiếp thị và truyền thông với hành vi của khách hàng như thế nào?
- Từ kết quả truy vấn trên, chúng ta có thể xác định được các khách hàng VIP và khách hàng có ít tương tác nhất. Từ đó, chúng ta nên có những phần thưởng, dịch vụ ưu tiên dành cho những khách hàng trung thành để giữ chân họ. Ngoài ra, đối với những khách hàng ít tương tác với cửa hàng, chúng ta cần tiến hành khảo sát phản hồi của họ để hiểu rõ hơn về sở thích của họ. Bên cạnh đó, chúng ta cũng cần tạo ra những chiến dịch giảm giá, ưu đãi để tăng doanh số bán hàng.
CÂU HỎI 3:Chúng ta có thể chi bao nhiêu để thu hút khách hàng mới?
- Có thể thấy giá trị vòng đời khách hàng tại cửa hàng là 39,040 USD. Điều này có nghĩa là với mỗi khách hàng mới, cửa hàng sẽ kiếm được lợi nhuận là 39,040 USD. Từ thông tin này chúng ta có thể dự đoán số tiền mà cửa hàng có thể chi trả cho việc thu hút khách hàng mới, đồng thời duy trì hoặc tăng mức lợi nhuận của mình. 