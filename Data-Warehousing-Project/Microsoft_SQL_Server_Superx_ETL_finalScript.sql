--SELECT * FROM purchase_order_items;
--SELECT * FROM purchase_orders;
--SELECT * FROM employees;
--SELECT * FROM suppliers;
--SELECT * FROM materials;
/* data imported into SQL SERVER*/
USE DataMart_NewSuperX;
GO

-- Dim Time
CREATE TABLE DimTime (
time_id int NOT NULL CONSTRAINT [pkDimTime] PRIMARY KEY,
calendarDate Date NOT NULL,
dayID int NOT NULL,
month nvarchar(50) NOT NULL,
quarterID int NOT NULL,
yearID int NOT NULL,
yearmonth nvarchar(7) NOT NULL,
yearQuarterID nvarchar(7) NOT NULL,
effective_date Date NOT NULL,
current_flag bit NOT NULL
);
go

-- Dim Material
CREATE TABLE DimMaterial (
material_id int NOT NULL CONSTRAINT [pkDimMaterial] PRIMARY KEY,
name nvarchar(50) NOT NULL,
type nvarchar(50) NOT NULL,
effective_date Date NOT NULL,
current_flag bit NOT NULL
);
go

-- Dim Purchase Order
CREATE TABLE DimPurchaseOrder (
purchase_order_id int NOT NULL CONSTRAINT [pkDimPurchaseOrder] PRIMARY KEY,
state nvarchar(50) NOT NULL,
supplier_name nvarchar(50) NOT NULL,
supplier_category nvarchar(50) NOT NULL,
supplier_country nvarchar(50) NOT NULL,
employee_name nvarchar(50) NOT NULL,
effective_date Date NOT NULL,
current_flag bit NOT NULL
);
go

-- Fact table Purchase Order Items
CREATE TABLE FactPurchaseOrderItems (
	purchase_order_item_id int NOT NULL, --PK
	time_id int, -- PK, FK1
	material_id int, -- PK, FK2
	purchase_order_id int, -- PK, FK3
	quantity int,
	price_in_euro money,
	total_po_item_costs_euro money
	CONSTRAINT [pkFactPurchaseOrderItems] PRIMARY KEY (purchase_order_item_id, time_id, material_id, purchase_order_id)
);
go

-- FK constraints
ALTER TABLE dbo.FactPurchaseOrderItems 
ADD CONSTRAINT fkFactToDimTime FOREIGN KEY (time_id) REFERENCES dbo.DimTime (time_id);
go

ALTER TABLE dbo.FactPurchaseOrderItems 
ADD CONSTRAINT fkFactToDimMaterial FOREIGN KEY (material_id) REFERENCES dbo.DimMaterial (material_id);
go

ALTER TABLE dbo.FactPurchaseOrderItems 
ADD CONSTRAINT fkFactToDimPurchaseOrder FOREIGN KEY (purchase_order_id) REFERENCES dbo.DimPurchaseOrder (purchase_order_id);
go

-- INSERT DATA
INSERT INTO [DataMart_NewSuperX].[dbo].[DimTime]
SELECT distinct [time_id] = concat(YEAR(timestamp), MONTH(timestamp), DAY(timestamp)),
 [calendarDate] = cast(timestamp as date),
 [dayID] = DAY(timestamp), 
 [month] = DATENAME(month,timestamp),
[quarterID] = DATEPART(quarter, timestamp),
[yearID] = YEAR(timestamp),
[yearmonth] = concat(YEAR(timestamp),'-', MONTH(timestamp)),
[yearQuarterID] = concat(YEAR(timestamp),'-', DATEPART(quarter, timestamp)),
[effective_date] = cast(timestamp as date),
[current_flag] = 1
from NewSuperX.dbo.purchase_order_items;
go

INSERT INTO [DataMart_NewSuperX].[dbo].[DimMaterial]
SELECT DISTINCT material_id, name, type,
[effective_date] = cast(NewSuperX.dbo.materials.timestamp as date),
[current_flag] = 1
  FROM NewSuperX.dbo.purchase_order_items
  join NewSuperX.dbo.materials ON purchase_order_items.material_id = materials.id;
go

INSERT INTO [DataMart_NewSuperX].[dbo].[DimPurchaseOrder]
SELECT DISTINCT purchase_order_id, [state] = purchase_orders.state,
[supplier_name] = suppliers.name, 
[supplier_category] = CASE WHEN category='smal' THEN 'small' ELSE category END, 
[supplier_country] = CASE WHEN right(address, CHARINDEX(' ', REVERSE(address))-1)='U.S.A.' THEN 'USA'
WHEN right(address, CHARINDEX(' ', REVERSE(address))-1)='Deutschland' THEN 'Germany'
WHEN right(address, CHARINDEX(' ', REVERSE(address))-1)='Kingdom' THEN 'United Kingdom'
ELSE right(address, CHARINDEX(' ', REVERSE(address))-1) END,
[employee_name] = concat(employees.firstname, ' ', employees.lastname),
[effective_date] = cast(NewSuperX.dbo.purchase_orders.timestamp as date),
[current_flag] = 1
  FROM NewSuperX.dbo.purchase_order_items
  join NewSuperX.dbo.purchase_orders ON purchase_order_items.purchase_order_id = purchase_orders.id
  join NewSuperX.dbo.employees ON purchase_orders.employee_id = employees.id
  join NewSuperX.dbo.suppliers ON purchase_orders.supplier_id = suppliers.id;
go

CREATE OR ALTER VIEW cleaned_po_items
as with notnullcurrencies (purchase_order_id, nncurrency)
   as (SELECT distinct purchase_order_id, currency as nncurrency from NewSuperX.dbo.purchase_order_items where currency is not null)
   SELECT [purchase_order_item_id] = id,
  [time_id] = concat(YEAR(timestamp), MONTH(timestamp), DAY(timestamp)),
  material_id, [purchase_order_id] = purchase_order_items.purchase_order_id, quantity, 
   case when purchase_order_items.currency is null then nncurrency else purchase_order_items.currency end as currency
     FROM NewSuperX.dbo.purchase_order_items
	 join notnullcurrencies on notnullcurrencies.purchase_order_id = purchase_order_items.purchase_order_id;
go

INSERT INTO [DataMart_NewSuperX].[dbo].[FactPurchaseOrderItems]
SELECT c.purchase_order_item_id, c.time_id, c.material_id, c.purchase_order_id, c.quantity, 
[price_in_euro] =
  CASE WHEN c.currency='CAD' THEN price*0.64
  WHEN c.currency='USD' THEN price*0.81
  WHEN c.currency='PLN' THEN price*0.24  
  WHEN c.currency='GBP' THEN price*1.12 
  ELSE price END, 
  [total_po_item_costs_euro] = c.quantity*CASE WHEN c.currency='CAD' THEN price*0.64
  WHEN c.currency='USD' THEN price*0.81
  WHEN c.currency='PLN' THEN price*0.24  
  WHEN c.currency='GBP' THEN price*1.12 
  ELSE price END
FROM cleaned_po_items c
join [NewSuperX].[dbo].[purchase_order_items] on purchase_order_items.id = c.purchase_order_item_id;
