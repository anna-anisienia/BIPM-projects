DROP TABLE IF EXISTS public.fact_purchase_order_item ;
DROP TABLE IF EXISTS public.dim_purchase_order ;
DROP TABLE IF EXISTS public.dim_time ;
DROP TABLE IF EXISTS public.dim_material ;


CREATE  TABLE IF NOT EXISTS dim_purchase_order (
  purchase_order_tk BIGINT PRIMARY KEY ,
  version INT NULL DEFAULT NULL ,
  date_from TIMESTAMP NULL DEFAULT NULL ,
  date_to TIMESTAMP NULL DEFAULT NULL ,
  purchase_order_id BIGINT NULL DEFAULT NULL ,
  state VARCHAR(100) NULL DEFAULT NULL ,
  supplier_name VARCHAR(255) NULL DEFAULT NULL ,
  supplier_category VARCHAR(100) NULL DEFAULT null, 
  supplier_country VARCHAR(255) NULL DEFAULT null,
  employee_name VARCHAR(255) NULL DEFAULT null);

CREATE INDEX idx_dim_purchase_order_tk ON dim_purchase_order (purchase_order_tk);   

CREATE TABLE IF NOT EXISTS dim_time (
  time_tk BIGINT PRIMARY KEY,
  calendarDate DATE NULL DEFAULT NULL ,
  yearID INT NULL DEFAULT NULL ,
  quarterID INT NULL DEFAULT NULL ,
  monthID INT NULL DEFAULT NULL ,
  dayID INT NULL DEFAULT null);
  
CREATE  INDEX idx_dim_time_tk ON dim_time (time_tk); 

CREATE TABLE IF NOT EXISTS dim_material (
  material_tk SERIAL PRIMARY KEY ,
  version INT NULL DEFAULT NULL ,
  date_from TIMESTAMP NULL DEFAULT NULL ,
  date_to TIMESTAMP NULL DEFAULT NULL ,
  material_id BIGINT NULL DEFAULT NULL ,
  material_name VARCHAR(255) NULL DEFAULT NULL ,
  material_type VARCHAR(100) NULL DEFAULT null);
  
  CREATE  INDEX idx_dim_material_lookup ON dim_material (material_id);
  
  CREATE  TABLE IF NOT EXISTS fact_purchase_order_item (
  time_tk BIGINT NULL DEFAULT NULL REFERENCES dim_time (time_tk),
  purchase_order_item_id BIGINT NULL ,
  material_tk BIGINT NULL REFERENCES dim_material (material_tk),
  purchase_order_tk BIGINT NULL REFERENCES dim_purchase_order (purchase_order_tk),
  unit_price DOUBLE PRECISION NULL DEFAULT NULL ,
  quantity INT NULL DEFAULT NULL ,
  total_cost DOUBLE PRECISION NULL DEFAULT NULL ,
  CONSTRAINT fact_purchase_order_item_pkey PRIMARY KEY (time_tk, purchase_order_item_id, material_tk, purchase_order_tk) );
  
CREATE  INDEX idx_purchase_order_tk ON fact_purchase_order_item (purchase_order_tk); 
CREATE  INDEX idx_material_tk ON fact_purchase_order_item (material_tk); 
CREATE  INDEX idx_time_tk ON fact_purchase_order_item (time_tk); 

