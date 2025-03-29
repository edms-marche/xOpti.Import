-- ----------------------------------------------------------
-- MDB Tools - A library for reading MS Access database files
-- Copyright (C) 2000-2011 Brian Bruns and others.
-- Files in libmdb are licensed under LGPL and the utilities under
-- the GPL, see COPYING.LIB and COPYING files respectively.
-- Check out http://mdbtools.sourceforge.net
-- ----------------------------------------------------------

SET client_encoding = 'UTF-8';

CREATE TABLE IF NOT EXISTS "add"
 (
	"addcode"			VARCHAR (2) NOT NULL, 
	"adddescription"			VARCHAR (40)
);

-- CREATE INDEXES ...
ALTER TABLE "add" ADD CONSTRAINT "add_pkey" PRIMARY KEY ("addcode");
CREATE INDEX "add_adddescriptio_idx" ON "add" ("adddescription");

CREATE TABLE IF NOT EXISTS "barcodepool"
 (
	"id"			SERIAL, 
	"txnumber"			VARCHAR (10) NOT NULL, 
	"dateofentry"			TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	"sku"			VARCHAR (13) NOT NULL, 
	"qty"			INTEGER NOT NULL
);
COMMENT ON COLUMN "barcodepool"."qty" IS 'Default to 1 for CrystalReports';

-- CREATE INDEXES ...
CREATE INDEX "barcodepool_id_idx" ON "barcodepool" ("id");
ALTER TABLE "barcodepool" ADD CONSTRAINT "barcodepool_pkey" PRIMARY KEY ("id");
CREATE INDEX "barcodepool_txnumber_idx" ON "barcodepool" ("txnumber");

CREATE TABLE IF NOT EXISTS "branch"
 (
	"branchcode"			VARCHAR (3) NOT NULL, 
	"branchname"			VARCHAR (40) NOT NULL, 
	"contactperson"			VARCHAR (40), 
	"jobtitle"			VARCHAR (30), 
	"address1"			VARCHAR (40), 
	"address2"			VARCHAR (40), 
	"city"			VARCHAR (20), 
	"province"			VARCHAR (20), 
	"postalcode"			VARCHAR (8), 
	"country"			VARCHAR (20), 
	"phone"			VARCHAR (13), 
	"fax"			VARCHAR (13), 
	"summaryflag"			BOOLEAN NOT NULL
);

-- CREATE INDEXES ...
ALTER TABLE "branch" ADD CONSTRAINT "branch_pkey" PRIMARY KEY ("branchcode");
CREATE INDEX "branch_postalcode_idx" ON "branch" ("postalcode");

CREATE TABLE IF NOT EXISTS "branchinventory"
 (
	"branchcode"			VARCHAR (4) NOT NULL, 
	"sku"			VARCHAR (13) NOT NULL, 
	"qtyonhand"			INTEGER
);

-- CREATE INDEXES ...
CREATE INDEX "branchinventory_branchcode_idx" ON "branchinventory" ("branchcode");
ALTER TABLE "branchinventory" ADD CONSTRAINT "branchinventory_pkey" PRIMARY KEY ("branchcode", "sku");
CREATE INDEX "branchinventory_sku_idx" ON "branchinventory" ("sku");

CREATE TABLE IF NOT EXISTS "branchsummary"
 (
	"branchcode"			VARCHAR (3) NOT NULL, 
	"year"			INTEGER NOT NULL, 
	"month"			INTEGER NOT NULL, 
	"firstdateofmonth"			TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	"qtybf"			INTEGER, 
	"amtbf"			NUMERIC(15,2), 
	"qtycd"			INTEGER, 
	"amtcd"			NUMERIC(15,2), 
	"qtysold"			INTEGER, 
	"amtsold"			NUMERIC(15,2), 
	"amtcostofgoodssold"			NUMERIC(15,2), 
	"qtypurchased"			INTEGER, 
	"amtpurchased"			NUMERIC(15,2), 
	"qtyadjustincr"			INTEGER, 
	"amtadjustincr"			NUMERIC(15,2), 
	"qtyadjustdecr"			INTEGER, 
	"amtadjustdecr"			NUMERIC(15,2), 
	"qtyrejected"			INTEGER, 
	"amtrejected"			NUMERIC(15,2), 
	"qtyrestocked"			INTEGER, 
	"amtrestocked"			NUMERIC(15,2), 
	"qtytransferin"			INTEGER, 
	"amttransferin"			NUMERIC(15,2), 
	"qtytransferout"			INTEGER, 
	"amttransferout"			NUMERIC(15,2)
);
COMMENT ON COLUMN "branchsummary"."year" IS '0=CurrentYear,1=LastYear,2=2-yearAgo...';
COMMENT ON COLUMN "branchsummary"."month" IS '0=YTD,1=Jan,2=Feb...';

-- CREATE INDEXES ...
CREATE INDEX "branchsummary_branchcode_idx" ON "branchsummary" ("branchcode");
ALTER TABLE "branchsummary" ADD CONSTRAINT "branchsummary_pkey" PRIMARY KEY ("branchcode", "year", "month", "firstdateofmonth");
CREATE INDEX "branchsummary_firstdateofmonth_idx" ON "branchsummary" ("firstdateofmonth");
CREATE INDEX "branchsummary_month_idx" ON "branchsummary" ("month");
CREATE INDEX "branchsummary_year_idx" ON "branchsummary" ("year");

CREATE TABLE IF NOT EXISTS "brand"
 (
	"brandcode"			VARCHAR (4) NOT NULL, 
	"branddescription"			VARCHAR (40)
);

-- CREATE INDEXES ...
ALTER TABLE "brand" ADD CONSTRAINT "brand_pkey" PRIMARY KEY ("brandcode");
CREATE INDEX "brand_branddescription_idx" ON "brand" ("branddescription");

CREATE TABLE IF NOT EXISTS "category"
 (
	"departmentcode"			VARCHAR (2) NOT NULL, 
	"classcode"			VARCHAR (2) NOT NULL, 
	"categorycode"			VARCHAR (2) NOT NULL, 
	"categoryname"			VARCHAR (30), 
	"costingmethod"			VARCHAR (1) NOT NULL, 
	"inventorymethod"			VARCHAR (1) NOT NULL, 
	"taxmethod"			VARCHAR (1) NOT NULL, 
	"summaryflag"			BOOLEAN NOT NULL
);
COMMENT ON COLUMN "category"."classcode" IS 'Class:ClassCode';
COMMENT ON COLUMN "category"."costingmethod" IS '0=Average,1=FIFO,2=LIFO';
COMMENT ON COLUMN "category"."inventorymethod" IS '0=Perpetual,1=Periodic';
COMMENT ON COLUMN "category"."taxmethod" IS 'Null=NonTaxable,G=GSTOnly,P=PSTOnly,g=GSTIncluded,p=PSTonGST,B=Both';

-- CREATE INDEXES ...
CREATE INDEX "category_categorycode_idx" ON "category" ("categorycode");
CREATE INDEX "category_categoryname_idx" ON "category" ("categoryname");
CREATE INDEX "category_classcode_idx" ON "category" ("classcode");
CREATE INDEX "category_departmentcode_idx" ON "category" ("departmentcode");
ALTER TABLE "category" ADD CONSTRAINT "category_pkey" PRIMARY KEY ("departmentcode", "classcode", "categorycode");

CREATE TABLE IF NOT EXISTS "categorysummary"
 (
	"departmentcode"			VARCHAR (2) NOT NULL, 
	"classcode"			VARCHAR (2) NOT NULL, 
	"categorycode"			VARCHAR (2) NOT NULL, 
	"year"			INTEGER NOT NULL, 
	"month"			INTEGER NOT NULL, 
	"firstdateofmonth"			TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	"qtybf"			INTEGER, 
	"amtbf"			NUMERIC(15,2), 
	"qtycd"			INTEGER, 
	"amtcd"			NUMERIC(15,2), 
	"qtysold"			INTEGER, 
	"amtsold"			NUMERIC(15,2), 
	"amtcostofgoodssold"			NUMERIC(15,2), 
	"qtypurchased"			INTEGER, 
	"amtpurchased"			NUMERIC(15,2), 
	"qtyadjustedincr"			INTEGER, 
	"amtadjustedincr"			NUMERIC(15,2), 
	"qtyadjusteddecr"			INTEGER, 
	"amtadjusteddecr"			NUMERIC(15,2), 
	"qtyrejected"			INTEGER, 
	"amtrejected"			NUMERIC(15,2), 
	"qtyrestocked"			INTEGER, 
	"amtrestocked"			NUMERIC(15,2), 
	"qtytransferin"			INTEGER, 
	"amttransferin"			NUMERIC(15,2), 
	"qtytransferout"			INTEGER, 
	"amttransferout"			NUMERIC(15,2)
);
COMMENT ON COLUMN "categorysummary"."year" IS '0=CurrentYear,1=LastYear,2=2-yearAgo...';
COMMENT ON COLUMN "categorysummary"."month" IS '0=YTD,1=Jan,2=Feb...';

-- CREATE INDEXES ...
CREATE INDEX "categorysummary_categorycode_idx" ON "categorysummary" ("categorycode");
CREATE INDEX "categorysummary_classcode_idx" ON "categorysummary" ("classcode");
CREATE INDEX "categorysummary_departmentcode_idx" ON "categorysummary" ("departmentcode");
CREATE INDEX "categorysummary_firstdateofmonth_idx" ON "categorysummary" ("firstdateofmonth");
CREATE INDEX "categorysummary_month_idx" ON "categorysummary" ("month");
ALTER TABLE "categorysummary" ADD CONSTRAINT "categorysummary_pkey" PRIMARY KEY ("departmentcode", "classcode", "categorycode", "year", "month", "firstdateofmonth");
CREATE INDEX "categorysummary_year_idx" ON "categorysummary" ("year");

CREATE TABLE IF NOT EXISTS "city"
 (
	"code"			SERIAL, 
	"cityphonecode"			VARCHAR (4), 
	"cityname"			VARCHAR (26) NOT NULL, 
	"provincecode"			VARCHAR (2) NOT NULL, 
	"countrycode"			VARCHAR (3) NOT NULL
);

-- CREATE INDEXES ...
CREATE INDEX "city_cityphonecode_idx" ON "city" ();
CREATE INDEX "city_code_idx" ON "city" ();
ALTER TABLE "city" ADD CONSTRAINT "city_pkey" PRIMARY KEY ();

CREATE TABLE IF NOT EXISTS "class"
 (
	"department"			VARCHAR (2) NOT NULL, 
	"classcode"			VARCHAR (2) NOT NULL, 
	"classname"			VARCHAR (30), 
	"summaryflag"			BOOLEAN NOT NULL
);
COMMENT ON COLUMN "class"."department" IS 'Department:DepartmentCode';

-- CREATE INDEXES ...
CREATE INDEX "class_classcode_idx" ON "class" ("classcode");
CREATE INDEX "class_classname_idx" ON "class" ("classname");
CREATE INDEX "class_department_idx" ON "class" ("department");
ALTER TABLE "class" ADD CONSTRAINT "class_pkey" PRIMARY KEY ("department", "classcode");

CREATE TABLE IF NOT EXISTS "classsummary"
 (
	"departmentcode"			VARCHAR (2) NOT NULL, 
	"classcode"			VARCHAR (2) NOT NULL, 
	"year"			INTEGER NOT NULL, 
	"month"			INTEGER NOT NULL, 
	"firstdateofmonth"			TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	"qtybf"			INTEGER, 
	"amtbf"			NUMERIC(15,2), 
	"qtycd"			INTEGER, 
	"amtcd"			NUMERIC(15,2), 
	"qtysold"			INTEGER, 
	"amtsold"			NUMERIC(15,2), 
	"amtcostofgoodssold"			NUMERIC(15,2), 
	"qtypurchased"			INTEGER, 
	"amtpurchased"			NUMERIC(15,2), 
	"qtyadjustedincr"			INTEGER, 
	"amtadjustedincr"			NUMERIC(15,2), 
	"qtyadjusteddecr"			INTEGER, 
	"amtadjusteddecr"			NUMERIC(15,2), 
	"qtyrejected"			INTEGER, 
	"amtrejected"			NUMERIC(15,2), 
	"qtyrestocked"			INTEGER, 
	"amtrestocked"			NUMERIC(15,2), 
	"qtytransferin"			INTEGER, 
	"amttransferin"			NUMERIC(15,2), 
	"qtytransferout"			INTEGER, 
	"amttransferout"			NUMERIC(15,2)
);
COMMENT ON COLUMN "classsummary"."year" IS '0=CurrentYear,1=LastYear,2=2-yearAgo...';

-- CREATE INDEXES ...
CREATE INDEX "classsummary_classcode_idx" ON "classsummary" ("classcode");
CREATE INDEX "classsummary_firstdateofmonth_idx" ON "classsummary" ("firstdateofmonth");
CREATE INDEX "classsummary_month_idx" ON "classsummary" ("month");
ALTER TABLE "classsummary" ADD CONSTRAINT "classsummary_pkey" PRIMARY KEY ("departmentcode", "classcode", "year", "month", "firstdateofmonth");
CREATE INDEX "classsummary_year_idx" ON "classsummary" ("year");

CREATE TABLE IF NOT EXISTS "costingmethod"
 (
	"costingcode"			VARCHAR (1) NOT NULL, 
	"costingname"			VARCHAR (10) NOT NULL
);
COMMENT ON COLUMN "costingmethod"."costingcode" IS '0=Average,1=FIFO,2=LIFO';

-- CREATE INDEXES ...
ALTER TABLE "costingmethod" ADD CONSTRAINT "costingmethod_pkey" PRIMARY KEY ("costingcode");
CREATE UNIQUE INDEX "costingmethod_costingname_idx" ON "costingmethod" ("costingname");

CREATE TABLE IF NOT EXISTS "country"
 (
	"countryname"			VARCHAR (26) NOT NULL, 
	"countrycode"			VARCHAR (3) NOT NULL, 
	"countryphonecode"			VARCHAR (4)
);
COMMENT ON COLUMN "country"."countrycode" IS 'Equal to Telex Code';
COMMENT ON COLUMN "country"."countryphonecode" IS 'International Country Phone Code';

-- CREATE INDEXES ...
CREATE INDEX "country_countryname_idx" ON "country" ();
CREATE INDEX "country_countryphonecode_idx" ON "country" ();
ALTER TABLE "country" ADD CONSTRAINT "country_pkey" PRIMARY KEY ();

CREATE TABLE IF NOT EXISTS "customeraccounts"
 (
	"customerid"			INTEGER NOT NULL, 
	"jointdate"			TIMESTAMP WITHOUT TIME ZONE, 
	"ttlamtpurchased"			NUMERIC(15,2), 
	"ttlamtrefund"			NUMERIC(15,2), 
	"ttlamtmrkdwnapplied"			NUMERIC(15,2), 
	"ttlamtcpnused"			NUMERIC(15,2), 
	"ytdamtpurchased"			NUMERIC(15,2), 
	"ytdamtrefund"			NUMERIC(15,2), 
	"ytdamtmrkdwnapplied"			NUMERIC(15,2), 
	"ytdamtcpnused"			NUMERIC(15,2), 
	"lastpurchasedate"			TIMESTAMP WITHOUT TIME ZONE
);

-- CREATE INDEXES ...
CREATE INDEX "customeraccounts_custjoindate_idx" ON "customeraccounts" ("customerid", "jointdate");
CREATE INDEX "customeraccounts_custlastpurchasedate_idx" ON "customeraccounts" ("customerid", "lastpurchasedate");
ALTER TABLE "customeraccounts" ADD CONSTRAINT "customeraccounts_pkey" PRIMARY KEY ("customerid");
CREATE INDEX "customeraccounts_jointdate_idx" ON "customeraccounts" ("jointdate");
CREATE INDEX "customeraccounts_lastpurchasedate_idx" ON "customeraccounts" ("lastpurchasedate");

CREATE TABLE IF NOT EXISTS "customermedical"
 (
	"customerid"			INTEGER, 
	"insmaturitydate"			TIMESTAMP WITHOUT TIME ZONE, 
	"carecardno"			VARCHAR (10), 
	"carecardvalidperiod"			VARCHAR (4), 
	"carecardtype"			VARCHAR (4), 
	"prescriptionlensflag"			BOOLEAN NOT NULL, 
	"prescriptioncontactflag"			BOOLEAN NOT NULL
);
COMMENT ON COLUMN "customermedical"."carecardvalidperiod" IS '##/##';

-- CREATE INDEXES ...
CREATE INDEX "customermedical_custcarecard_idx" ON "customermedical" ("customerid", "carecardno");
CREATE INDEX "customermedical_custinsdate_idx" ON "customermedical" ("customerid", "insmaturitydate");
ALTER TABLE "customermedical" ADD CONSTRAINT "customermedical_pkey" PRIMARY KEY ("customerid");

CREATE TABLE IF NOT EXISTS "customerpreslens"
 (
	"customerid"			INTEGER NOT NULL, 
	"issuedon"			TIMESTAMP WITHOUT TIME ZONE, 
	"issuedbydr"			INTEGER, 
	"rightsphere"			REAL, 
	"rightcylinder"			REAL, 
	"rightaxis"			INTEGER, 
	"rightpddist"			REAL, 
	"rightpdnear"			REAL, 
	"rightprism"			REAL, 
	"rightadd"			REAL, 
	"rightpupil"			REAL, 
	"leftsphere"			REAL, 
	"leftcylinder"			REAL, 
	"leftaxis"			INTEGER, 
	"leftpddist"			REAL, 
	"leftpdnear"			REAL, 
	"leftprism"			REAL, 
	"leftadd"			REAL, 
	"leftpupil"			REAL
);
COMMENT ON COLUMN "customerpreslens"."issuedbydr" IS 'Doctor ID';
COMMENT ON COLUMN "customerpreslens"."rightsphere" IS '-12.50 ~ 12.50, step 0.25';
COMMENT ON COLUMN "customerpreslens"."rightcylinder" IS '-4 ~ 0, step 0.25';
COMMENT ON COLUMN "customerpreslens"."rightaxis" IS '0 ~ 180, step 1';
COMMENT ON COLUMN "customerpreslens"."rightpddist" IS '99.99';
COMMENT ON COLUMN "customerpreslens"."rightpdnear" IS '99.99';
COMMENT ON COLUMN "customerpreslens"."rightprism" IS '0.5 ~ 10, step 0.1';
COMMENT ON COLUMN "customerpreslens"."rightadd" IS '9999.99';
COMMENT ON COLUMN "customerpreslens"."rightpupil" IS '99.99';

-- CREATE INDEXES ...
ALTER TABLE "customerpreslens" ADD CONSTRAINT "customerpreslens_pkey" PRIMARY KEY ("customerid");

CREATE TABLE IF NOT EXISTS "department"
 (
	"departmentcode"			VARCHAR (2) NOT NULL, 
	"departmentname"			VARCHAR (30), 
	"summaryflag"			BOOLEAN NOT NULL
);

-- CREATE INDEXES ...
CREATE INDEX "department_departmentname_idx" ON "department" ("departmentname");
ALTER TABLE "department" ADD CONSTRAINT "department_pkey" PRIMARY KEY ("departmentcode");

CREATE TABLE IF NOT EXISTS "deptsummary"
 (
	"departmentcode"			VARCHAR (2) NOT NULL, 
	"year"			INTEGER NOT NULL, 
	"month"			INTEGER NOT NULL, 
	"firstdateofmonth"			TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	"qtybf"			INTEGER, 
	"amtbf"			NUMERIC(15,2), 
	"qtycd"			INTEGER, 
	"amtcd"			NUMERIC(15,2), 
	"qtysold"			INTEGER, 
	"amtsold"			NUMERIC(15,2), 
	"amtcostofgoodssold"			NUMERIC(15,2), 
	"qtypurchased"			INTEGER, 
	"amtpurchased"			NUMERIC(15,2), 
	"qtyadjustedincr"			INTEGER, 
	"amtadjustedincr"			NUMERIC(15,2), 
	"qtyadjusteddecr"			INTEGER, 
	"amtadjusteddecr"			NUMERIC(15,2), 
	"qtyrejected"			INTEGER, 
	"amtrejected"			NUMERIC(15,2), 
	"qtyrestocked"			INTEGER, 
	"amtrestocked"			NUMERIC(15,2), 
	"qtytransferin"			INTEGER, 
	"amttransferin"			NUMERIC(15,2), 
	"qtytransferout"			INTEGER, 
	"amttransferout"			NUMERIC(15,2)
);
COMMENT ON COLUMN "deptsummary"."year" IS '0=CurrentYear,1=LastYear,2=2-yearAgo...';
COMMENT ON COLUMN "deptsummary"."month" IS '0=YTD,1=Jan,2=Feb...';

-- CREATE INDEXES ...
CREATE INDEX "deptsummary_departmentcode_idx" ON "deptsummary" ("departmentcode");
ALTER TABLE "deptsummary" ADD CONSTRAINT "deptsummary_pkey" PRIMARY KEY ("departmentcode", "year", "month", "firstdateofmonth");
CREATE INDEX "deptsummary_firstdateofmonth_idx" ON "deptsummary" ("firstdateofmonth");
CREATE INDEX "deptsummary_month_idx" ON "deptsummary" ("month");
CREATE INDEX "deptsummary_year_idx" ON "deptsummary" ("year");

CREATE TABLE IF NOT EXISTS "doctor"
 (
	"id"			SERIAL, 
	"doctorname"			VARCHAR (40), 
	"address"			VARCHAR (128), 
	"city"			INTEGER, 
	"province"			VARCHAR (2), 
	"country"			VARCHAR (3), 
	"phone"			VARCHAR (10), 
	"postalcode"			VARCHAR (7), 
	"fax"			VARCHAR (10), 
	"emergency"			VARCHAR (15)
);

-- CREATE INDEXES ...
CREATE INDEX "doctor_doctorname_idx" ON "doctor" ("doctorname");
CREATE INDEX "doctor_id_idx" ON "doctor" ("id");
CREATE INDEX "doctor_postalcode_idx" ON "doctor" ("postalcode");
ALTER TABLE "doctor" ADD CONSTRAINT "doctor_pkey" PRIMARY KEY ("id");

CREATE TABLE IF NOT EXISTS "footer"
 (
	"footercode"			VARCHAR (2) NOT NULL, 
	"footerdescription"			VARCHAR (56), 
	"footernote"			TEXT
);

-- CREATE INDEXES ...
ALTER TABLE "footer" ADD CONSTRAINT "footer_pkey" PRIMARY KEY ("footercode");

CREATE TABLE IF NOT EXISTS "hardening"
 (
	"id"			SERIAL, 
	"name"			VARCHAR (30) NOT NULL
);

-- CREATE INDEXES ...
CREATE INDEX "hardening_id_idx" ON "hardening" ("id");
ALTER TABLE "hardening" ADD CONSTRAINT "hardening_pkey" PRIMARY KEY ("id");

CREATE TABLE IF NOT EXISTS "inventory"
 (
	"departmentcode"			VARCHAR (2) NOT NULL, 
	"classcode"			VARCHAR (2) NOT NULL, 
	"categorycode"			VARCHAR (2) NOT NULL, 
	"suppliercode"			VARCHAR (4) NOT NULL, 
	"brandcode"			VARCHAR (4) NOT NULL, 
	"model"			VARCHAR (30), 
	"color"			VARCHAR (8), 
	"size"			VARCHAR (6), 
	"bridge"			INTEGER, 
	"temple"			INTEGER, 
	"addcode"			VARCHAR (2), 
	"materialcode"			VARCHAR (2), 
	"sphere"			REAL, 
	"cylinder"			REAL, 
	"axis"			INTEGER, 
	"basecurve"			REAL, 
	"diameter"			REAL, 
	"sku"			VARCHAR (13) NOT NULL, 
	"name"			VARCHAR (40), 
	"description"			TEXT, 
	"remarks"			TEXT, 
	"abcgrading"			VARCHAR (1), 
	"inventorytype"			VARCHAR (1), 
	"inventorystatus"			VARCHAR (1), 
	"kitsetflag"			BOOLEAN NOT NULL, 
	"averagecost"			NUMERIC(15,2), 
	"reorderlevel"			INTEGER, 
	"reorderqty"			INTEGER, 
	"qtytotalonhand"			INTEGER, 
	"qtysaleorder"			INTEGER, 
	"qtypurchaseorder"			INTEGER, 
	"qtyholded"			INTEGER, 
	"qtyintransit"			INTEGER, 
	"datelastissued"			TIMESTAMP WITHOUT TIME ZONE, 
	"datelastreceived"			TIMESTAMP WITHOUT TIME ZONE, 
	"retailpriceflag"			BOOLEAN NOT NULL, 
	"wholesalepriceflag"			BOOLEAN NOT NULL, 
	"inventorylotflag"			BOOLEAN NOT NULL
);
COMMENT ON COLUMN "inventory"."addcode" IS 'No use';
COMMENT ON COLUMN "inventory"."axis" IS 'No use';
COMMENT ON COLUMN "inventory"."name" IS 'No use';
COMMENT ON COLUMN "inventory"."description" IS 'No use';
COMMENT ON COLUMN "inventory"."inventorytype" IS '0=standard; 1=consigment item; 2=reserved; 3=Gift Item; 4=Reserved; 5=Rental Item; 6=Service Item; 7=Serial Item';
COMMENT ON COLUMN "inventory"."inventorystatus" IS '0=null; 1=Frozen Item; 2=Fashion Item; 3=Staple Item';

-- CREATE INDEXES ...
CREATE INDEX "inventory_addcode_idx" ON "inventory" ("addcode");
CREATE INDEX "inventory_basecurve_idx" ON "inventory" ("basecurve");
CREATE INDEX "inventory_brandcode_idx" ON "inventory" ("brandcode");
CREATE INDEX "inventory_color_idx" ON "inventory" ("color");
CREATE INDEX "inventory_cylinder_idx" ON "inventory" ("cylinder");
CREATE INDEX "inventory_deptclasscat_idx" ON "inventory" ("departmentcode", "classcode", "categorycode");
CREATE INDEX "inventory_diameter_idx" ON "inventory" ("diameter");
CREATE INDEX "inventory_materialcode_idx" ON "inventory" ("materialcode");
CREATE INDEX "inventory_model_idx" ON "inventory" ("model");
CREATE INDEX "inventory_size_idx" ON "inventory" ("size");
ALTER TABLE "inventory" ADD CONSTRAINT "inventory_pkey" PRIMARY KEY ("sku");
CREATE INDEX "inventory_sphere_idx" ON "inventory" ("sphere");
CREATE INDEX "inventory_suppliercode_idx" ON "inventory" ("suppliercode");

CREATE TABLE IF NOT EXISTS "invtlotrecord"
 (
	"sku"			VARCHAR (13) NOT NULL, 
	"lotno"			VARCHAR (10), 
	"datereceived"			TIMESTAMP WITHOUT TIME ZONE, 
	"suppliercode"			VARCHAR (4) NOT NULL, 
	"qtypurchased"			INTEGER, 
	"qtyused"			INTEGER, 
	"qtyonhand"			INTEGER, 
	"unitamountpurchased"			NUMERIC(15,2), 
	"totalamountpurchased"			NUMERIC(15,2)
);

-- CREATE INDEXES ...
CREATE INDEX "invtlotrecord_datereceived_idx" ON "invtlotrecord" ("datereceived");
CREATE INDEX "invtlotrecord_lotno_idx" ON "invtlotrecord" ("lotno");
CREATE INDEX "invtlotrecord_sku_idx" ON "invtlotrecord" ("sku");
ALTER TABLE "invtlotrecord" ADD CONSTRAINT "invtlotrecord_pkey" PRIMARY KEY ("sku", "lotno");
CREATE INDEX "invtlotrecord_suppliercode_idx" ON "invtlotrecord" ("suppliercode");
CREATE INDEX "invtlotrecord_supplierdatelotno_idx" ON "invtlotrecord" ("suppliercode", "datereceived", "lotno");

CREATE TABLE IF NOT EXISTS "invtmethod"
 (
	"invtmethodcode"			VARCHAR (1) NOT NULL, 
	"invtmethodname"			VARCHAR (15) NOT NULL
);
COMMENT ON COLUMN "invtmethod"."invtmethodcode" IS '0=Perpetual,1=Periodic';

-- CREATE INDEXES ...
ALTER TABLE "invtmethod" ADD CONSTRAINT "invtmethod_pkey" PRIMARY KEY ("invtmethodcode");
CREATE UNIQUE INDEX "invtmethod_invtmethodname_idx" ON "invtmethod" ("invtmethodname");

CREATE TABLE IF NOT EXISTS "invtstheader"
 (
	"id"			SERIAL, 
	"name"			VARCHAR (30) NOT NULL, 
	"dateofcreation"			TIMESTAMP WITHOUT TIME ZONE, 
	"dateofupdate"			TIMESTAMP WITHOUT TIME ZONE, 
	"dateofpurge"			TIMESTAMP WITHOUT TIME ZONE, 
	"status"			SMALLINT
);
COMMENT ON COLUMN "invtstheader"."name" IS 'Description of each batch';
COMMENT ON COLUMN "invtstheader"."status" IS '0=Normal,1=Booked,2=Input,3=Printed,4=Updated,5=Deleted';

-- CREATE INDEXES ...
CREATE INDEX "invtstheader_id_idx" ON "invtstheader" ("id");
CREATE UNIQUE INDEX "invtstheader_name_idx" ON "invtstheader" ("name");
ALTER TABLE "invtstheader" ADD CONSTRAINT "invtstheader_pkey" PRIMARY KEY ("id");

CREATE TABLE IF NOT EXISTS "invtstimport"
 (
	"headerid"			INTEGER, 
	"sku"			VARCHAR (13) NOT NULL, 
	"qty"			INTEGER, 
	"status"			INTEGER
);
COMMENT ON COLUMN "invtstimport"."status" IS '0 = Good; 1= No Such SKU; 2 = Worksheet Not Include Such SKU';

-- CREATE INDEXES ...
CREATE INDEX "invtstimport_headerid_idx" ON "invtstimport" ("headerid");
ALTER TABLE "invtstimport" ADD CONSTRAINT "invtstimport_pkey" PRIMARY KEY ("headerid", "sku");
CREATE INDEX "invtstimport_sku_idx" ON "invtstimport" ("sku");
CREATE INDEX "invtstimport_status_idx" ON "invtstimport" ("status");

CREATE TABLE IF NOT EXISTS "invtststatus"
 (
	"code"			SMALLINT NOT NULL, 
	"name"			VARCHAR (10) NOT NULL
);

-- CREATE INDEXES ...
CREATE UNIQUE INDEX "invtststatus_code_idx" ON "invtststatus" ("code");
ALTER TABLE "invtststatus" ADD CONSTRAINT "invtststatus_pkey" PRIMARY KEY ("code");

CREATE TABLE IF NOT EXISTS "invtsummary"
 (
	"sku"			VARCHAR (13) NOT NULL, 
	"year"			INTEGER NOT NULL, 
	"month"			INTEGER NOT NULL, 
	"firstdateofmonth"			TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	"qtybf"			INTEGER, 
	"amtbf"			NUMERIC(15,2), 
	"qtycd"			INTEGER, 
	"amtcd"			NUMERIC(15,2), 
	"qtysold"			INTEGER, 
	"amtsold"			NUMERIC(15,2), 
	"amtcostofgoodssold"			NUMERIC(15,2), 
	"qtypurchased"			INTEGER, 
	"amtpurchased"			NUMERIC(15,2), 
	"qtyadjincr"			INTEGER, 
	"amtadjincr"			NUMERIC(15,2), 
	"qtyadjdecr"			INTEGER, 
	"amtadjdecr"			NUMERIC(15,2), 
	"qtyrejected"			INTEGER, 
	"amtrejected"			NUMERIC(15,2), 
	"qtyrestocked"			INTEGER, 
	"amtrestocked"			NUMERIC(15,2), 
	"qtytransferin"			INTEGER, 
	"amttransferin"			NUMERIC(15,2), 
	"qtytransferout"			INTEGER, 
	"amttransferout"			NUMERIC(15,2)
);
COMMENT ON COLUMN "invtsummary"."year" IS '0=current year; 1=last year; 2=2 year ago....';
COMMENT ON COLUMN "invtsummary"."month" IS '1=Jan; 2=Feb; 3=Mar.....';

-- CREATE INDEXES ...
CREATE INDEX "invtsummary_firstdateofmonth_idx" ON "invtsummary" ("firstdateofmonth");
CREATE INDEX "invtsummary_month_idx" ON "invtsummary" ("month");
CREATE INDEX "invtsummary_sku_idx" ON "invtsummary" ("sku");
ALTER TABLE "invtsummary" ADD CONSTRAINT "invtsummary_pkey" PRIMARY KEY ("sku", "year", "month", "firstdateofmonth");
CREATE INDEX "invtsummary_year_idx" ON "invtsummary" ("year");

CREATE TABLE IF NOT EXISTS "jobstatus"
 (
	"code"			VARCHAR (1) NOT NULL, 
	"name"			VARCHAR (20) NOT NULL
);

-- CREATE INDEXES ...
CREATE UNIQUE INDEX "jobstatus_code_idx" ON "jobstatus" ("code");
ALTER TABLE "jobstatus" ADD CONSTRAINT "jobstatus_pkey" PRIMARY KEY ("code");

CREATE TABLE IF NOT EXISTS "jobtitle"
 (
	"jobtitlecode"			VARCHAR (4) NOT NULL, 
	"jobtitle"			VARCHAR (30) NOT NULL
);

-- CREATE INDEXES ...
CREATE UNIQUE INDEX "jobtitle_jobtitle_idx" ON "jobtitle" ("jobtitle");
ALTER TABLE "jobtitle" ADD CONSTRAINT "jobtitle_pkey" PRIMARY KEY ("jobtitlecode");

CREATE TABLE IF NOT EXISTS "maritalstatus"
 (
	"code"			VARCHAR (1) NOT NULL, 
	"maritalstatus"			VARCHAR (15) NOT NULL
);

-- CREATE INDEXES ...
CREATE UNIQUE INDEX "maritalstatus_code_idx" ON "maritalstatus" ("code");
ALTER TABLE "maritalstatus" ADD CONSTRAINT "maritalstatus_pkey" PRIMARY KEY ("code");

CREATE TABLE IF NOT EXISTS "material"
 (
	"materialcode"			VARCHAR (2) NOT NULL, 
	"materialdescription"			VARCHAR (40)
);

-- CREATE INDEXES ...
ALTER TABLE "material" ADD CONSTRAINT "material_pkey" PRIMARY KEY ("materialcode");
CREATE INDEX "material_materialdescription_idx" ON "material" ("materialdescription");

CREATE TABLE IF NOT EXISTS "paymentmethods"
 (
	"paymentcode"			VARCHAR (1) NOT NULL, 
	"paymentnameshort"			VARCHAR (3) NOT NULL, 
	"paymentnamelong"			VARCHAR (20) NOT NULL, 
	"exchangerate"			DOUBLE PRECISION NOT NULL, 
	"reviseddate"			TIMESTAMP WITHOUT TIME ZONE, 
	"todayamtopening"			NUMERIC(15,2), 
	"todayamtclosing"			NUMERIC(15,2), 
	"todayamtsold"			NUMERIC(15,2), 
	"todaynumberofsold"			INTEGER, 
	"todayamtrefund"			NUMERIC(15,2), 
	"todaynumberofrefund"			INTEGER, 
	"todayamtchanged"			NUMERIC(15,2), 
	"todaynumberofchange"			INTEGER, 
	"todayamtpaidout"			NUMERIC(15,2), 
	"todaynumberofpaidout"			INTEGER, 
	"todayamtbankin"			NUMERIC(15,2), 
	"todaynumberofbankin"			INTEGER, 
	"alertlevel"			NUMERIC(15,2)
);

-- CREATE INDEXES ...
ALTER TABLE "paymentmethods" ADD CONSTRAINT "paymentmethods_pkey" PRIMARY KEY ("paymentcode");
CREATE UNIQUE INDEX "paymentmethods_paymentname_idx" ON "paymentmethods" ("paymentnamelong");
CREATE UNIQUE INDEX "paymentmethods_paymentnameshort_idx" ON "paymentmethods" ("paymentnameshort");

CREATE TABLE IF NOT EXISTS "paymentsummary"
 (
	"paymentcode"			VARCHAR (1) NOT NULL, 
	"date"			TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	"exchangerate"			INTEGER NOT NULL, 
	"amtopening"			NUMERIC(15,2), 
	"amtclosing"			NUMERIC(15,2), 
	"amtsold"			NUMERIC(15,2), 
	"numberofsold"			INTEGER, 
	"amtrefund"			NUMERIC(15,2), 
	"numberofrefund"			INTEGER, 
	"amtchanged"			NUMERIC(15,2), 
	"numberofchange"			INTEGER, 
	"amtpaidout"			NUMERIC(15,2), 
	"numberofpaidout"			INTEGER, 
	"amtbankin"			NUMERIC(15,2), 
	"numberofbankin"			INTEGER
);

-- CREATE INDEXES ...
CREATE INDEX "paymentsummary_date_idx" ON "paymentsummary" ("date");
CREATE INDEX "paymentsummary_numberofbankin_idx" ON "paymentsummary" ("numberofbankin");
CREATE INDEX "paymentsummary_numberofchange_idx" ON "paymentsummary" ("numberofchange");
CREATE INDEX "paymentsummary_numberofpaidout_idx" ON "paymentsummary" ("numberofpaidout");
CREATE INDEX "paymentsummary_numberofrefund_idx" ON "paymentsummary" ("numberofrefund");
CREATE INDEX "paymentsummary_numberofsold_idx" ON "paymentsummary" ("numberofsold");
CREATE INDEX "paymentsummary_paymentcode_idx" ON "paymentsummary" ("paymentcode");
ALTER TABLE "paymentsummary" ADD CONSTRAINT "paymentsummary_pkey" PRIMARY KEY ("paymentcode", "date");

CREATE TABLE IF NOT EXISTS "payper"
 (
	"code"			VARCHAR (1) NOT NULL, 
	"name"			VARCHAR (10) NOT NULL
);
COMMENT ON COLUMN "payper"."code" IS '0=Year,1=Month,2=Week,3=BiWeek';

-- CREATE INDEXES ...
CREATE UNIQUE INDEX "payper_code_idx" ON "payper" ("code");
ALTER TABLE "payper" ADD CONSTRAINT "payper_pkey" PRIMARY KEY ("code");

CREATE TABLE IF NOT EXISTS "payperiod"
 (
	"code"			VARCHAR (1) NOT NULL, 
	"name"			VARCHAR (10) NOT NULL
);
COMMENT ON COLUMN "payperiod"."code" IS '0=Week,1=BiWeek,2=Month,3=HalfMonth';

-- CREATE INDEXES ...
CREATE UNIQUE INDEX "payperiod_code_idx" ON "payperiod" ("code");
ALTER TABLE "payperiod" ADD CONSTRAINT "payperiod_pkey" PRIMARY KEY ("code");

CREATE TABLE IF NOT EXISTS "preference"
 (
	"serial number"			VARCHAR (10) NOT NULL, 
	"numberofuser"			INTEGER NOT NULL, 
	"paltform"			VARCHAR (20) NOT NULL, 
	"productname"			VARCHAR (128) NOT NULL, 
	"dateofinstallation"			TIMESTAMP WITHOUT TIME ZONE, 
	"username"			VARCHAR (40) NOT NULL, 
	"useraddress"			VARCHAR (128), 
	"usercity"			INTEGER, 
	"userprovince"			VARCHAR (2), 
	"userpostalcode"			VARCHAR (8), 
	"usercountry"			VARCHAR (20), 
	"userphone"			VARCHAR (15), 
	"userfax"			VARCHAR (15), 
	"usercontactperson"			VARCHAR (30), 
	"ownername"			VARCHAR (40) NOT NULL, 
	"owneraddress"			VARCHAR (128), 
	"ownercity"			INTEGER, 
	"ownerprovince"			VARCHAR (2), 
	"ownerpostalcode"			VARCHAR (8), 
	"ownercountry"			VARCHAR (20), 
	"ownerphone"			VARCHAR (15), 
	"ownerfax"			VARCHAR (15), 
	"ownercontactperson"			VARCHAR (30), 
	"branchnumber"			VARCHAR (4) NOT NULL, 
	"countrycode"			VARCHAR (2), 
	"pstnumber"			VARCHAR (10) NOT NULL, 
	"gstnumber"			VARCHAR (10) NOT NULL, 
	"taxarate"			REAL, 
	"taxbrate"			REAL, 
	"fiscalperiod"			TIMESTAMP WITHOUT TIME ZONE, 
	"currentmonth"			TIMESTAMP WITHOUT TIME ZONE, 
	"nextinvtcontrolnumber"			INTEGER NOT NULL, 
	"nextinvtsku"			INTEGER NOT NULL, 
	"nextinvoicenumber"			INTEGER NOT NULL, 
	"nextsalesordernumber"			INTEGER NOT NULL
);
COMMENT ON COLUMN "preference"."countrycode" IS 'Used in BarCodes';
COMMENT ON COLUMN "preference"."taxarate" IS 'PST rate (%)';
COMMENT ON COLUMN "preference"."taxbrate" IS 'GST rate (%)';
COMMENT ON COLUMN "preference"."fiscalperiod" IS 'First date of the fiscal period';
COMMENT ON COLUMN "preference"."currentmonth" IS 'First date of the working month';

-- CREATE INDEXES ...
CREATE INDEX "preference_countrycode_idx" ON "preference" ("countrycode");
CREATE INDEX "preference_numberofuser_idx" ON "preference" ("numberofuser");
CREATE INDEX "preference_ownerpostalcode_idx" ON "preference" ("ownerpostalcode");
ALTER TABLE "preference" ADD CONSTRAINT "preference_pkey" PRIMARY KEY ("serial number");
CREATE INDEX "preference_userpostalcode_idx" ON "preference" ("userpostalcode");

CREATE TABLE IF NOT EXISTS "preftxnumber"
 (
	"txprefix"			VARCHAR (2) NOT NULL, 
	"txnextnumber"			INTEGER NOT NULL, 
	"value"			VARCHAR (3), 
	"description"			VARCHAR (30) NOT NULL, 
	"remarks"			VARCHAR (30)
);

-- CREATE INDEXES ...
ALTER TABLE "preftxnumber" ADD CONSTRAINT "preftxnumber_pkey" PRIMARY KEY ("txprefix");
CREATE UNIQUE INDEX "preftxnumber_txprefix_idx" ON "preftxnumber" ("txprefix");

CREATE TABLE IF NOT EXISTS "province"
 (
	"provincename"			VARCHAR (26) NOT NULL, 
	"provincecode"			VARCHAR (2) NOT NULL
);

-- CREATE INDEXES ...
ALTER TABLE "province" ADD CONSTRAINT "province_pkey" PRIMARY KEY ("provincecode");
CREATE INDEX "province_provincecode_idx" ON "province" ("provincecode");

CREATE TABLE IF NOT EXISTS "paste errors"
 (
	"field0"			TEXT
);

-- CREATE INDEXES ...

CREATE TABLE IF NOT EXISTS "rebuildcost"
 (
	"sku"			VARCHAR (13) NOT NULL, 
	"averagecost"			NUMERIC(15,2), 
	"lsp"			NUMERIC(15,2)
);

-- CREATE INDEXES ...
ALTER TABLE "rebuildcost" ADD CONSTRAINT "rebuildcost_pkey" PRIMARY KEY ("sku");

CREATE TABLE IF NOT EXISTS "remarks"
 (
	"remarkscode"			VARCHAR (2) NOT NULL, 
	"remarksdescription"			VARCHAR (56), 
	"remarksnote"			TEXT
);

-- CREATE INDEXES ...
ALTER TABLE "remarks" ADD CONSTRAINT "remarks_pkey" PRIMARY KEY ("remarkscode");

CREATE TABLE IF NOT EXISTS "retailprice"
 (
	"sku"			VARCHAR (13) NOT NULL, 
	"leastsellingprice"			NUMERIC(15,2), 
	"retailprice"			NUMERIC(15,2), 
	"retailmarkdownamt"			NUMERIC(15,2), 
	"retailmarkdownpct"			REAL
);

-- CREATE INDEXES ...
ALTER TABLE "retailprice" ADD CONSTRAINT "retailprice_pkey" PRIMARY KEY ("sku");

CREATE TABLE IF NOT EXISTS "salesorderstatus"
 (
	"code"			VARCHAR (1) NOT NULL, 
	"name"			VARCHAR (20) NOT NULL
);
COMMENT ON COLUMN "salesorderstatus"."code" IS ' 0=Draft,1=Confirmed,2=Cancelled,3=Invoiced';

-- CREATE INDEXES ...
CREATE UNIQUE INDEX "salesorderstatus_code_idx" ON "salesorderstatus" ("code");
ALTER TABLE "salesorderstatus" ADD CONSTRAINT "salesorderstatus_pkey" PRIMARY KEY ("code");

CREATE TABLE IF NOT EXISTS "salutation"
 (
	"salutation"			VARCHAR (6) NOT NULL
);

-- CREATE INDEXES ...
ALTER TABLE "salutation" ADD CONSTRAINT "salutation_pkey" PRIMARY KEY ("salutation");
CREATE UNIQUE INDEX "salutation_salutation_idx" ON "salutation" ("salutation");

CREATE TABLE IF NOT EXISTS "security"
 (
	"level"			INTEGER NOT NULL, 
	"point_of_sale"			BOOLEAN NOT NULL, 
	"inventory_control"			BOOLEAN NOT NULL, 
	"olap"			BOOLEAN NOT NULL, 
	"information_centre"			BOOLEAN NOT NULL, 
	"coding"			BOOLEAN NOT NULL, 
	"report_centre"			BOOLEAN NOT NULL, 
	"preference"			BOOLEAN NOT NULL, 
	"cost"			BOOLEAN NOT NULL
);
COMMENT ON COLUMN "security"."level" IS 'Simple =  0~9 ; Advance = 00~99';

-- CREATE INDEXES ...
ALTER TABLE "security" ADD CONSTRAINT "security_pkey" PRIMARY KEY ("level");

CREATE TABLE IF NOT EXISTS "staff"
 (
	"staffcode"			VARCHAR (4) NOT NULL, 
	"stafffirstname"			VARCHAR (20), 
	"stafflastname"			VARCHAR (20), 
	"stafffullname"			VARCHAR (40), 
	"staffinitial"			VARCHAR (2), 
	"jobtitle"			VARCHAR (4), 
	"jobstatus"			VARCHAR (1), 
	"jobnature"			VARCHAR (1), 
	"securitylevel"			INTEGER NOT NULL, 
	"password"			VARCHAR (10), 
	"datehired"			TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	"dateleaved"			TIMESTAMP WITHOUT TIME ZONE, 
	"sin"			VARCHAR (9) NOT NULL, 
	"birthday"			TIMESTAMP WITHOUT TIME ZONE, 
	"sex"			VARCHAR (1), 
	"maritalstatus"			VARCHAR (1), 
	"homeaddress"			VARCHAR (128), 
	"homecity"			INTEGER, 
	"homeprovince"			VARCHAR (2), 
	"homecountry"			VARCHAR (3), 
	"homepostalcode"			VARCHAR (8), 
	"homephone"			VARCHAR (10), 
	"homefax"			VARCHAR (10), 
	"salarybasic"			NUMERIC(15,2), 
	"salaryper"			VARCHAR (1), 
	"salarypayperiod"			VARCHAR (1), 
	"bankaccount"			VARCHAR (15), 
	"commissionrate"			INTEGER, 
	"commissionbonus"			INTEGER, 
	"commissiongeneral"			INTEGER
);
COMMENT ON COLUMN "staff"."jobnature" IS '0=FullTime,1=PartTime,2=PermanentPartTime,3=ContractedStaff,4=SeasonalHelper';
COMMENT ON COLUMN "staff"."sex" IS 'Male or Female';
COMMENT ON COLUMN "staff"."maritalstatus" IS 'Single,Married,Widowed,Divorced,Separated';
COMMENT ON COLUMN "staff"."salaryper" IS '0=Year,1=Month,2=Week,3=BiWeek';
COMMENT ON COLUMN "staff"."salarypayperiod" IS '0=Week,1=BiWeek,2=Month,3=HalfMonth';

-- CREATE INDEXES ...
CREATE INDEX "staff_homepostalcode_idx" ON "staff" ("homepostalcode");
ALTER TABLE "staff" ADD CONSTRAINT "staff_pkey" PRIMARY KEY ("staffcode");
CREATE INDEX "staff_stafffirstname_idx" ON "staff" ("stafffirstname");
CREATE INDEX "staff_stafffullname_idx" ON "staff" ("stafffullname");
CREATE INDEX "staff_stafflastname_idx" ON "staff" ("stafflastname");

CREATE TABLE IF NOT EXISTS "staffhistory"
 (
	"staffcode"			VARCHAR (4) NOT NULL, 
	"date"			TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	"reason"			VARCHAR (20), 
	"remarks"			TEXT NOT NULL
);

-- CREATE INDEXES ...
CREATE INDEX "staffhistory_date_idx" ON "staffhistory" ("date");
CREATE INDEX "staffhistory_staffcode_idx" ON "staffhistory" ("staffcode");
ALTER TABLE "staffhistory" ADD CONSTRAINT "staffhistory_pkey" PRIMARY KEY ("staffcode", "date");

CREATE TABLE IF NOT EXISTS "supplier"
 (
	"suppliercode"			VARCHAR (4) NOT NULL, 
	"suppliername"			VARCHAR (50), 
	"address"			VARCHAR (128), 
	"city"			INTEGER, 
	"province"			VARCHAR (2), 
	"postcode"			VARCHAR (8), 
	"country"			VARCHAR (3), 
	"phonegenvoice"			VARCHAR (12), 
	"phonegenfax"			VARCHAR (12), 
	"phoneacdeptext"			VARCHAR (12), 
	"phoneacdeptfax"			VARCHAR (12), 
	"phonesaleext"			VARCHAR (12), 
	"phonesalefax"			VARCHAR (12), 
	"phoneserviceext"			VARCHAR (12), 
	"phoneservicefax"			VARCHAR (12), 
	"accountno"			VARCHAR (8), 
	"datestarted"			TIMESTAMP WITHOUT TIME ZONE, 
	"creditlimit"			NUMERIC(15,2), 
	"paymentterms"			VARCHAR (10), 
	"contactperson"			VARCHAR (40), 
	"contactpersonflag"			VARCHAR (1), 
	"summaryflag"			VARCHAR (1), 
	"branchflag"			VARCHAR (1), 
	"remarks"			TEXT, 
	"gstnumber"			VARCHAR (10), 
	"pstnumber"			VARCHAR (10), 
	"tollfreephone1"			VARCHAR (24), 
	"tollfreephone2"			VARCHAR (24), 
	"tollfreefax1"			VARCHAR (24), 
	"tollfreefax2"			VARCHAR (24)
);

-- CREATE INDEXES ...
CREATE INDEX "supplier_supaccountno_idx" ON "supplier" ("accountno");
ALTER TABLE "supplier" ADD CONSTRAINT "supplier_pkey" PRIMARY KEY ("suppliercode");
CREATE INDEX "supplier_suppliername_idx" ON "supplier" ("suppliername");
CREATE INDEX "supplier_suppostcode_idx" ON "supplier" ("postcode");

CREATE TABLE IF NOT EXISTS "suppliercontactperson"
 (
	"supcode"			VARCHAR (4) NOT NULL, 
	"firstname"			VARCHAR (20), 
	"initial"			VARCHAR (2), 
	"lastname"			VARCHAR (20), 
	"fullname"			VARCHAR (40), 
	"salutation"			VARCHAR (4), 
	"jobtitle"			VARCHAR (30), 
	"phonegeneralvoice"			VARCHAR (15), 
	"phonegeneralfax"			VARCHAR (15), 
	"phonehome"			VARCHAR (12), 
	"phonemobile"			VARCHAR (12), 
	"phonepager"			VARCHAR (12), 
	"phonework"			VARCHAR (16)
);

-- CREATE INDEXES ...
CREATE INDEX "suppliercontactperson_firstname_idx" ON "suppliercontactperson" ("firstname");
CREATE INDEX "suppliercontactperson_full name_idx" ON "suppliercontactperson" ("fullname");
CREATE INDEX "suppliercontactperson_initial_idx" ON "suppliercontactperson" ("initial");
CREATE INDEX "suppliercontactperson_jobtitle_idx" ON "suppliercontactperson" ("jobtitle");
CREATE INDEX "suppliercontactperson_lastname_idx" ON "suppliercontactperson" ("lastname");
CREATE INDEX "suppliercontactperson_phonegeneralfax_idx" ON "suppliercontactperson" ("phonegeneralfax");
CREATE INDEX "suppliercontactperson_phonegeneralvoice_idx" ON "suppliercontactperson" ("phonegeneralvoice");
CREATE INDEX "suppliercontactperson_phonehome_idx" ON "suppliercontactperson" ("phonehome");
CREATE INDEX "suppliercontactperson_phonemobile_idx" ON "suppliercontactperson" ("phonemobile");
CREATE INDEX "suppliercontactperson_supcode_idx" ON "suppliercontactperson" ("supcode");
ALTER TABLE "suppliercontactperson" ADD CONSTRAINT "suppliercontactperson_pkey" PRIMARY KEY ("supcode", "firstname", "initial", "lastname");

CREATE TABLE IF NOT EXISTS "taxmethod"
 (
	"taxcode"			VARCHAR (1) NOT NULL, 
	"taxname"			VARCHAR (20) NOT NULL
);
COMMENT ON COLUMN "taxmethod"."taxcode" IS '0=Non-Taxable,G=GST only,P=PST only,g=GST included,p=PST on GST, B=Both GST & PST';

-- CREATE INDEXES ...
CREATE INDEX "taxmethod_taxcode_idx" ON "taxmethod" ("taxcode");

CREATE TABLE IF NOT EXISTS "txdetails"
 (
	"controlnumber"			VARCHAR (10) NOT NULL, 
	"txtype"			VARCHAR (2) NOT NULL, 
	"txnumber"			VARCHAR (10) NOT NULL, 
	"dateofentry"			TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	"rowno"			REAL NOT NULL, 
	"sku"			VARCHAR (13) NOT NULL, 
	"remarks"			TEXT, 
	"prescriptionlensflag"			BOOLEAN NOT NULL, 
	"prescriptioncontactflag"			BOOLEAN NOT NULL, 
	"qty"			INTEGER, 
	"unitamount"			NUMERIC(15,2), 
	"unitcost"			NUMERIC(15,2), 
	"unitlsp"			NUMERIC(15,2), 
	"markdownpercent"			REAL, 
	"markdownamount"			NUMERIC(15,2), 
	"amount"			NUMERIC(15,2), 
	"taxcode"			VARCHAR (1)
);
COMMENT ON COLUMN "txdetails"."txtype" IS 'Refer to TxPrefix for description';
COMMENT ON COLUMN "txdetails"."txnumber" IS 'TxPrefix + TxRunningNumber';
COMMENT ON COLUMN "txdetails"."taxcode" IS 'Refer to TaxMethod for description';

-- CREATE INDEXES ...
CREATE INDEX "txdetails_controlnumber_idx" ON "txdetails" ("controlnumber");
CREATE INDEX "txdetails_dateofentry_idx" ON "txdetails" ("dateofentry");
CREATE INDEX "txdetails_rowno_idx" ON "txdetails" ("rowno");
CREATE INDEX "txdetails_sku_idx" ON "txdetails" ("sku");
CREATE INDEX "txdetails_taxcode_idx" ON "txdetails" ("taxcode");
CREATE INDEX "txdetails_txnumber_idx" ON "txdetails" ("txnumber");
CREATE INDEX "txdetails_txtype_idx" ON "txdetails" ("txtype");
ALTER TABLE "txdetails" ADD CONSTRAINT "txdetails_pkey" PRIMARY KEY ("txtype", "txnumber", "dateofentry", "rowno");

CREATE TABLE IF NOT EXISTS "txheader"
 (
	"controlnumber"			VARCHAR (10) NOT NULL, 
	"txtype"			VARCHAR (2) NOT NULL, 
	"txnumber"			VARCHAR (10) NOT NULL, 
	"dateofentry"			TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	"dateofcreation"			TIMESTAMP WITHOUT TIME ZONE, 
	"refnumber"			VARCHAR (10), 
	"trackingnumber"			VARCHAR (10), 
	"customerid"			INTEGER, 
	"suppliercode"			VARCHAR (4), 
	"seconddate"			TIMESTAMP WITHOUT TIME ZONE, 
	"particulars"			TEXT, 
	"totalcost"			NUMERIC(15,2), 
	"totalsale"			NUMERIC(15,2), 
	"taxa"			NUMERIC(15,2), 
	"taxb"			NUMERIC(15,2), 
	"taxc"			NUMERIC(15,2), 
	"othercharges"			NUMERIC(15,2), 
	"grosssale"			NUMERIC(15,2), 
	"salesdiscount"			NUMERIC(15,2), 
	"totalamount"			NUMERIC(15,2), 
	"totalqty"			INTEGER, 
	"previouspaid"			NUMERIC(15,2), 
	"thispaid"			NUMERIC(15,2), 
	"change"			NUMERIC(15,2), 
	"printcounter"			INTEGER, 
	"paymentlink"			SMALLINT, 
	"salespersonlink"			SMALLINT, 
	"status"			VARCHAR (1)
);
COMMENT ON COLUMN "txheader"."txtype" IS 'Refer to TxPrefix for description';
COMMENT ON COLUMN "txheader"."txnumber" IS 'TxPrefix + TxRunningNumber';
COMMENT ON COLUMN "txheader"."seconddate" IS 'In Sales Order=Estimated Delivery date';
COMMENT ON COLUMN "txheader"."totalcost" IS 'Total Amount Cost-of-Good Sold';
COMMENT ON COLUMN "txheader"."totalsale" IS 'Total Amount Sold';
COMMENT ON COLUMN "txheader"."taxa" IS 'GST';
COMMENT ON COLUMN "txheader"."taxb" IS 'PST';
COMMENT ON COLUMN "txheader"."totalamount" IS 'GrossSale - SalesDiscount';
COMMENT ON COLUMN "txheader"."paymentlink" IS '0=Null, 1=Single, 2=Split (Two), 3=Split (Three)';
COMMENT ON COLUMN "txheader"."salespersonlink" IS '0=Null, 1=Single, 2=Two, 3=Three...';
COMMENT ON COLUMN "txheader"."status" IS 'For SalesOrder: 0=Draft,1=Confirmed,2=Cancelled,3=Invoiced; for Invoice:0=Normal,-1=Refunded;';

-- CREATE INDEXES ...
CREATE INDEX "txheader_controlno_idx" ON "txheader" ("controlnumber");
CREATE INDEX "txheader_customercode_idx" ON "txheader" ("customerid");
CREATE INDEX "txheader_dateofentry_idx" ON "txheader" ("dateofentry");
CREATE INDEX "txheader_previouspaid_idx" ON "txheader" ("previouspaid");
CREATE INDEX "txheader_referenceno_idx" ON "txheader" ("refnumber");
CREATE INDEX "txheader_status_idx" ON "txheader" ("status");
CREATE INDEX "txheader_suppliercode_idx" ON "txheader" ("suppliercode");
CREATE INDEX "txheader_thispaid_idx" ON "txheader" ("thispaid");
CREATE INDEX "txheader_trackingnumber_idx" ON "txheader" ("trackingnumber");
ALTER TABLE "txheader" ADD CONSTRAINT "txheader_pkey" PRIMARY KEY ("txnumber");
CREATE INDEX "txheader_txtype_idx" ON "txheader" ("txtype");

CREATE TABLE IF NOT EXISTS "txpayment"
 (
	"txnumber"			VARCHAR (10) NOT NULL, 
	"paymentlineno"			REAL NOT NULL, 
	"type"			VARCHAR (1) NOT NULL, 
	"cardnumber"			VARCHAR (30), 
	"authorizationcode"			VARCHAR (10), 
	"amounttender"			NUMERIC(15,2), 
	"exchangerate"			REAL, 
	"eqamount"			NUMERIC(15,2), 
	"totalthispay"			NUMERIC(15,2)
);

-- CREATE INDEXES ...
CREATE INDEX "txpayment_authorizationcode_idx" ON "txpayment" ("authorizationcode");
CREATE INDEX "txpayment_paymentseq#_idx" ON "txpayment" ("paymentlineno");
ALTER TABLE "txpayment" ADD CONSTRAINT "txpayment_pkey" PRIMARY KEY ("txnumber", "paymentlineno", "type");
CREATE INDEX "txpayment_txnumber_idx" ON "txpayment" ("txnumber");
CREATE INDEX "txpayment_type_idx" ON "txpayment" ("type");

CREATE TABLE IF NOT EXISTS "txsaleperson"
 (
	"txnumber"			VARCHAR (10) NOT NULL, 
	"salesrowno"			REAL NOT NULL, 
	"staffcode"			VARCHAR (4) NOT NULL
);

-- CREATE INDEXES ...
CREATE INDEX "txsaleperson_salesseq#_idx" ON "txsaleperson" ("salesrowno");
CREATE INDEX "txsaleperson_staffcode_idx" ON "txsaleperson" ("staffcode");
ALTER TABLE "txsaleperson" ADD CONSTRAINT "txsaleperson_pkey" PRIMARY KEY ("txnumber", "salesrowno", "staffcode");
CREATE INDEX "txsaleperson_txnumber_idx" ON "txsaleperson" ("txnumber");

CREATE TABLE IF NOT EXISTS "txsorderadd"
 (
	"txnumber"			VARCHAR (10) NOT NULL, 
	"linenumber"			REAL NOT NULL, 
	"supplier"			VARCHAR (30), 
	"brand"			VARCHAR (30), 
	"model"			VARCHAR (30)
);
COMMENT ON COLUMN "txsorderadd"."linenumber" IS 'From 1.1~1.6, 2.1~2.6, ... 6.1~6.6';
COMMENT ON COLUMN "txsorderadd"."supplier" IS 'Supplier Name';
COMMENT ON COLUMN "txsorderadd"."brand" IS 'Brand Name';
COMMENT ON COLUMN "txsorderadd"."model" IS 'Model Name';

-- CREATE INDEXES ...
CREATE INDEX "txsorderadd_linenumber_idx" ON "txsorderadd" ("linenumber");
ALTER TABLE "txsorderadd" ADD CONSTRAINT "txsorderadd_pkey" PRIMARY KEY ("txnumber", "linenumber");

CREATE TABLE IF NOT EXISTS "txsordercont"
 (
	"txnumber"			VARCHAR (10) NOT NULL, 
	"linenumber"			REAL NOT NULL, 
	"issuedon"			TIMESTAMP WITHOUT TIME ZONE, 
	"issuedby"			INTEGER, 
	"rightsphere"			REAL, 
	"rightcylinder"			REAL, 
	"rightaxis"			INTEGER, 
	"rightkreadingv"			REAL, 
	"rightkreadingh"			REAL, 
	"rightpalp"			REAL, 
	"rightcorn"			REAL, 
	"rightpupil"			REAL, 
	"leftsphere"			REAL, 
	"leftcylinder"			REAL, 
	"leftaxis"			INTEGER, 
	"leftkreadingv"			REAL, 
	"leftkreadingh"			REAL, 
	"leftpalp"			REAL, 
	"leftcorn"			REAL, 
	"leftpupil"			REAL, 
	"history"			VARCHAR (56), 
	"medical"			VARCHAR (56), 
	"allergy"			VARCHAR (56), 
	"reason"			VARCHAR (56), 
	"evaluation"			VARCHAR (56), 
	"test"			VARCHAR (56), 
	"specialinstruction"			VARCHAR (128)
);
COMMENT ON COLUMN "txsordercont"."linenumber" IS 'From 1.1~1.6, 2.1~2.6, ... 6.1~6.6';
COMMENT ON COLUMN "txsordercont"."issuedon" IS 'Prescription Issued on';
COMMENT ON COLUMN "txsordercont"."issuedby" IS 'Prescription Issued by Doctor ID';

-- CREATE INDEXES ...
CREATE INDEX "txsordercont_linenumber_idx" ON "txsordercont" ("linenumber");
ALTER TABLE "txsordercont" ADD CONSTRAINT "txsordercont_pkey" PRIMARY KEY ("txnumber", "linenumber");
CREATE INDEX "txsordercont_txnumber_idx" ON "txsordercont" ("txnumber");

CREATE TABLE IF NOT EXISTS "txsorderextra"
 (
	"txnumber"			VARCHAR (10) NOT NULL, 
	"redo"			BOOLEAN NOT NULL, 
	"warranty"			BOOLEAN NOT NULL, 
	"mail"			BOOLEAN NOT NULL, 
	"msd"			BOOLEAN NOT NULL, 
	"remarks"			INTEGER
);
COMMENT ON COLUMN "txsorderextra"."remarks" IS 'Select from Remarks Table, ID';

-- CREATE INDEXES ...
ALTER TABLE "txsorderextra" ADD CONSTRAINT "txsorderextra_pkey" PRIMARY KEY ("txnumber");
CREATE UNIQUE INDEX "txsorderextra_txnumber_idx" ON "txsorderextra" ("txnumber");

CREATE TABLE IF NOT EXISTS "txsorderframe"
 (
	"txnumber"			VARCHAR (10) NOT NULL, 
	"linenumber"			REAL NOT NULL, 
	"supply"			BOOLEAN NOT NULL, 
	"enclosed"			BOOLEAN NOT NULL, 
	"follow"			BOOLEAN NOT NULL, 
	"lenses"			BOOLEAN NOT NULL, 
	"mode"			VARCHAR (30), 
	"color"			VARCHAR (8), 
	"eyesize"			VARCHAR (6), 
	"bridge"			INTEGER, 
	"temple"			INTEGER, 
	"r1"			VARCHAR (10), 
	"r2"			VARCHAR (10), 
	"r3"			VARCHAR (10), 
	"a"			VARCHAR (10), 
	"b"			VARCHAR (10), 
	"specialinstruction"			VARCHAR (128)
);
COMMENT ON COLUMN "txsorderframe"."linenumber" IS 'From 1.1~1.6, 2.1~2.6, ... 6.1~6.6';

-- CREATE INDEXES ...
CREATE INDEX "txsorderframe_linenumber_idx" ON "txsorderframe" ("linenumber");
ALTER TABLE "txsorderframe" ADD CONSTRAINT "txsorderframe_pkey" PRIMARY KEY ("txnumber", "linenumber");

CREATE TABLE IF NOT EXISTS "utilchecklog"
 (
	"lognumber"			SERIAL, 
	"dateoflog"			TIMESTAMP WITHOUT TIME ZONE, 
	"parenttable"			VARCHAR (30), 
	"parentkey"			VARCHAR (30), 
	"remarks"			VARCHAR (50)
);

-- CREATE INDEXES ...
CREATE INDEX "utilchecklog_parentkey_idx" ON "utilchecklog" ("parentkey");
ALTER TABLE "utilchecklog" ADD CONSTRAINT "utilchecklog_pkey" PRIMARY KEY ("lognumber");

CREATE TABLE IF NOT EXISTS "wholesaleprice"
 (
	"sku"			VARCHAR (13) NOT NULL, 
	"suggestedretailprice"			NUMERIC(15,2), 
	"sellingpricegradea"			NUMERIC(15,2), 
	"sellingpricegradeb"			NUMERIC(15,2), 
	"sellingpricegradec"			NUMERIC(15,2)
);

-- CREATE INDEXES ...
ALTER TABLE "wholesaleprice" ADD CONSTRAINT "wholesaleprice_pkey" PRIMARY KEY ("sku");

CREATE TABLE IF NOT EXISTS "z_defaultclass"
 (
	"code"			VARCHAR (2) NOT NULL, 
	"name"			VARCHAR (20) NOT NULL
);

-- CREATE INDEXES ...
CREATE UNIQUE INDEX "z_defaultclass_code_idx" ON "z_defaultclass" ("code");
ALTER TABLE "z_defaultclass" ADD CONSTRAINT "z_defaultclass_pkey" PRIMARY KEY ("code");

CREATE TABLE IF NOT EXISTS "z_defaultremarks"
 (
	"id"			SERIAL, 
	"group"			SMALLINT NOT NULL, 
	"remarks"			VARCHAR (128)
);
COMMENT ON COLUMN "z_defaultremarks"."group" IS '0=PoS';

-- CREATE INDEXES ...
CREATE UNIQUE INDEX "z_defaultremarks_id_idx" ON "z_defaultremarks" ("id");
ALTER TABLE "z_defaultremarks" ADD CONSTRAINT "z_defaultremarks_pkey" PRIMARY KEY ("id");

CREATE TABLE IF NOT EXISTS "customer"
 (
	"id"			SERIAL, 
	"vipcode"			VARCHAR (16), 
	"firstname"			VARCHAR (20), 
	"initial"			VARCHAR (2), 
	"lastname"			VARCHAR (20), 
	"fullname"			VARCHAR (40), 
	"salutation"			VARCHAR (4), 
	"birthday"			TIMESTAMP WITHOUT TIME ZONE, 
	"homeaddress"			VARCHAR (128), 
	"homecity"			INTEGER, 
	"homeprovince"			VARCHAR (2), 
	"homepostalcode"			VARCHAR (8), 
	"homecountry"			VARCHAR (3), 
	"homephone"			VARCHAR (12), 
	"homefax"			VARCHAR (12), 
	"cellular"			VARCHAR (15), 
	"bizcompanyname"			VARCHAR (40), 
	"bizjobtitle"			VARCHAR (20), 
	"bizaddress"			VARCHAR (128), 
	"bizcity"			INTEGER, 
	"bizprovince"			VARCHAR (2), 
	"bizpostalcode"			VARCHAR (8), 
	"bizcountry"			VARCHAR (3), 
	"bizphone"			VARCHAR (12), 
	"bizfax"			VARCHAR (12), 
	"creditlimit"			NUMERIC(15,2), 
	"paymentterms"			VARCHAR (10), 
	"vipmarkdownpct"			REAL, 
	"summaryflag"			BOOLEAN NOT NULL, 
	"accountingflag"			BOOLEAN NOT NULL, 
	"remarks"			TEXT, 
	"email"			VARCHAR (128)
);

-- CREATE INDEXES ...
CREATE INDEX "customer_birthday_idx" ON "customer" ("birthday");
CREATE INDEX "customer_bizpostalcode_idx" ON "customer" ("bizpostalcode");
CREATE INDEX "customer_countrylastname_idx" ON "customer" ("homecountry", "lastname");
CREATE INDEX "customer_firstname_idx" ON "customer" ("firstname");
CREATE INDEX "customer_fullname_idx" ON "customer" ("fullname");
CREATE INDEX "customer_homecountry_idx" ON "customer" ("homecountry");
CREATE INDEX "customer_homephone_idx" ON "customer" ("homephone");
CREATE INDEX "customer_initial_idx" ON "customer" ("initial");
CREATE INDEX "customer_lastname_idx" ON "customer" ("lastname");
CREATE INDEX "customer_post_code_idx" ON "customer" ("homepostalcode");
ALTER TABLE "customer" ADD CONSTRAINT "customer_pkey" PRIMARY KEY ("id");
CREATE INDEX "customer_vipcode_idx" ON "customer" ("vipcode");

CREATE TABLE IF NOT EXISTS "customerprescontact"
 (
	"customerid"			INTEGER, 
	"issuedon"			TIMESTAMP WITHOUT TIME ZONE, 
	"issuedbydr"			INTEGER, 
	"rightsphere"			REAL, 
	"rightcylinder"			REAL, 
	"rightaxis"			INTEGER, 
	"rightkreadingv"			REAL, 
	"rightkreadingh"			REAL, 
	"rightpalp"			REAL, 
	"rightcorn"			REAL, 
	"rightpupil"			REAL, 
	"leftsphere"			REAL, 
	"leftcylinder"			REAL, 
	"leftaxis"			INTEGER, 
	"leftkreadingv"			REAL, 
	"leftkreadingh"			REAL, 
	"leftpalp"			REAL, 
	"leftcorn"			REAL, 
	"leftpupil"			REAL, 
	"history"			VARCHAR (56), 
	"medical"			VARCHAR (56), 
	"allergy"			VARCHAR (56), 
	"reason"			VARCHAR (56), 
	"evaluation"			VARCHAR (56), 
	"test"			VARCHAR (56)
);
COMMENT ON COLUMN "customerprescontact"."rightsphere" IS '-12.50 ~ 12.50, step 0.25';
COMMENT ON COLUMN "customerprescontact"."rightcylinder" IS '-4 ~ 0, step 0.25';
COMMENT ON COLUMN "customerprescontact"."rightaxis" IS '0 ~ 180, step 1';
COMMENT ON COLUMN "customerprescontact"."rightkreadingv" IS '99.99';
COMMENT ON COLUMN "customerprescontact"."rightkreadingh" IS '99.99';
COMMENT ON COLUMN "customerprescontact"."rightpalp" IS '99.99';
COMMENT ON COLUMN "customerprescontact"."rightcorn" IS '99.99';
COMMENT ON COLUMN "customerprescontact"."rightpupil" IS '99.99';

-- CREATE INDEXES ...
ALTER TABLE "customerprescontact" ADD CONSTRAINT "customerprescontact_pkey" PRIMARY KEY ("customerid");

CREATE TABLE IF NOT EXISTS "invtstdetails"
 (
	"id"			SERIAL, 
	"headerid"			INTEGER NOT NULL, 
	"sku"			VARCHAR (13) NOT NULL, 
	"computerqty"			REAL, 
	"physicalqty"			REAL, 
	"diffqty"			REAL, 
	"averagecost"			NUMERIC(15,2)
);

-- CREATE INDEXES ...
CREATE INDEX "invtstdetails_headerid_idx" ON "invtstdetails" ("headerid");
CREATE INDEX "invtstdetails_id_idx" ON "invtstdetails" ("id");
ALTER TABLE "invtstdetails" ADD CONSTRAINT "invtstdetails_pkey" PRIMARY KEY ("headerid", "sku");
CREATE INDEX "invtstdetails_sku_idx" ON "invtstdetails" ("sku");

CREATE TABLE IF NOT EXISTS "jobnature"
 (
	"code"			VARCHAR (1) NOT NULL, 
	"name"			VARCHAR (20) NOT NULL
);
COMMENT ON COLUMN "jobnature"."code" IS '0=FullTime,1=PartTime,2=PermanentPartTime,3=ContractedStaff,4=SeasonalHelper';

-- CREATE INDEXES ...
CREATE UNIQUE INDEX "jobnature_code_idx" ON "jobnature" ("code");
ALTER TABLE "jobnature" ADD CONSTRAINT "jobnature_pkey" PRIMARY KEY ("code");

CREATE TABLE IF NOT EXISTS "sex"
 (
	"code"			VARCHAR (1) NOT NULL, 
	"sex"			VARCHAR (10) NOT NULL
);
COMMENT ON COLUMN "sex"."code" IS 'F=Female,M=Male';

-- CREATE INDEXES ...
CREATE UNIQUE INDEX "sex_code_idx" ON "sex" ("code");
ALTER TABLE "sex" ADD CONSTRAINT "sex_pkey" PRIMARY KEY ("code");

CREATE TABLE IF NOT EXISTS "suppliersummary"
 (
	"suppliercode"			VARCHAR (4) NOT NULL, 
	"year"			INTEGER NOT NULL, 
	"month"			INTEGER NOT NULL, 
	"firstdateofmonth"			TIMESTAMP WITHOUT TIME ZONE NOT NULL, 
	"qtypurchased"			INTEGER, 
	"amtpurchased"			NUMERIC(15,2), 
	"qtyrejected"			INTEGER, 
	"amtrejected"			NUMERIC(15,2)
);
COMMENT ON COLUMN "suppliersummary"."year" IS '0=Current Year, 1=Last Year, 2=2-year ago....';
COMMENT ON COLUMN "suppliersummary"."month" IS '1=Jan, 2=Feb, 3=Mar....';

-- CREATE INDEXES ...
CREATE INDEX "suppliersummary_month_idx" ON "suppliersummary" ("month");
ALTER TABLE "suppliersummary" ADD CONSTRAINT "suppliersummary_pkey" PRIMARY KEY ("suppliercode", "year", "month", "firstdateofmonth");
CREATE INDEX "suppliersummary_suppliercode_idx" ON "suppliersummary" ("suppliercode");
CREATE INDEX "suppliersummary_year_idx" ON "suppliersummary" ("year");

CREATE TABLE IF NOT EXISTS "txsorderlens"
 (
	"txnumber"			VARCHAR (10) NOT NULL, 
	"linenumber"			REAL NOT NULL, 
	"issuedon"			TIMESTAMP WITHOUT TIME ZONE, 
	"issuedby"			INTEGER, 
	"rightsphere"			REAL, 
	"rightcylinder"			REAL, 
	"rightaxis"			INTEGER, 
	"rightpddist"			REAL, 
	"rightpdnear"			REAL, 
	"rightprism"			REAL, 
	"rightadd"			REAL, 
	"rightpupil"			REAL, 
	"rightstyle"			VARCHAR (30), 
	"rightseght"			REAL, 
	"rigthoc"			REAL, 
	"rigthbase"			REAL, 
	"rightvd"			REAL, 
	"leftsphere"			REAL, 
	"leftcylinder"			REAL, 
	"leftaxis"			INTEGER, 
	"leftpddist"			REAL, 
	"leftpdnear"			REAL, 
	"leftprism"			REAL, 
	"leftadd"			REAL, 
	"leftpupil"			REAL, 
	"leftstyle"			VARCHAR (30), 
	"leftseght"			REAL, 
	"leftoc"			REAL, 
	"leftbase"			REAL, 
	"leftvd"			REAL, 
	"type"			VARCHAR (30), 
	"hardening"			VARCHAR (30), 
	"material"			VARCHAR (2), 
	"coating"			VARCHAR (2), 
	"tint"			VARCHAR (30), 
	"others"			VARCHAR (30), 
	"hardcoat"			BOOLEAN NOT NULL, 
	"arcoat"			BOOLEAN NOT NULL, 
	"uv"			BOOLEAN NOT NULL
);
COMMENT ON COLUMN "txsorderlens"."linenumber" IS 'From 1.1~1.6, 2.1~2.6, ... 6.1~6.6';
COMMENT ON COLUMN "txsorderlens"."issuedon" IS 'Prescription Issued on';
COMMENT ON COLUMN "txsorderlens"."issuedby" IS 'Prescription Issued by Doctor ID';
COMMENT ON COLUMN "txsorderlens"."type" IS 'Select from Catgory Table, CategoryName';
COMMENT ON COLUMN "txsorderlens"."hardening" IS '?? Unknown';
COMMENT ON COLUMN "txsorderlens"."material" IS 'Select from Material Table, MaterialCode';
COMMENT ON COLUMN "txsorderlens"."coating" IS 'Select from Add Table, AddCode';

-- CREATE INDEXES ...
CREATE INDEX "txsorderlens_rowno_idx" ON "txsorderlens" ("linenumber");
ALTER TABLE "txsorderlens" ADD CONSTRAINT "txsorderlens_pkey" PRIMARY KEY ("txnumber", "linenumber");
CREATE INDEX "txsorderlens_txnumber_idx" ON "txsorderlens" ("txnumber");


-- CREATE Relationships ...
ALTER TABLE "Inventory" ADD CONSTRAINT "inventory_brandcode_fk" FOREIGN KEY ("brandcode") REFERENCES "Brand"("brandcode") DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "Inventory" ADD CONSTRAINT "inventory_departmentcode_fk" FOREIGN KEY ("departmentcode") REFERENCES "Category"("departmentcode") DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "Inventory" ADD CONSTRAINT "inventory_classcode_fk" FOREIGN KEY ("classcode") REFERENCES "Category"("classcode") DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "Inventory" ADD CONSTRAINT "inventory_categorycode_fk" FOREIGN KEY ("categorycode") REFERENCES "Category"("categorycode") DEFERRABLE INITIALLY IMMEDIATE;
-- Relationship from "Customer" ("homecity") to "City"("code") does not enforce integrity.
-- Relationship from "Customer" ("bizcity") to "City"("code") does not enforce integrity.
ALTER TABLE "Category" ADD CONSTRAINT "category_departmentcode_fk" FOREIGN KEY ("departmentcode") REFERENCES "Class"("department") DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "Category" ADD CONSTRAINT "category_classcode_fk" FOREIGN KEY ("classcode") REFERENCES "Class"("classcode") DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "City" ADD CONSTRAINT "city_countrycode_fk" FOREIGN KEY ("countrycode") REFERENCES "Country"("countrycode") DEFERRABLE INITIALLY IMMEDIATE;
-- Relationship from "City" ("countrycode") to "Country"("countrycode") does not enforce integrity.
-- Relationship from "Customer" ("id") to "CustomerAccounts"("customerid") does not enforce integrity.
-- Relationship from "Customer" ("id") to "CustomerMedical"("customerid") does not enforce integrity.
ALTER TABLE "Class" ADD CONSTRAINT "class_department_fk" FOREIGN KEY ("department") REFERENCES "Department"("departmentcode") DEFERRABLE INITIALLY IMMEDIATE;
-- Relationship from "InvtSTDetails" ("sku") to "Inventory"("sku") does not enforce integrity.
-- Relationship from "InvtSummary" ("sku") to "Inventory"("sku") does not enforce integrity.
-- Relationship from "TxDetails" ("sku") to "Inventory"("sku") does not enforce integrity.
ALTER TABLE "Inventory" ADD CONSTRAINT "inventory_materialcode_fk" FOREIGN KEY ("materialcode") REFERENCES "Material"("materialcode") DEFERRABLE INITIALLY IMMEDIATE;
ALTER TABLE "City" ADD CONSTRAINT "city_provincecode_fk" FOREIGN KEY ("provincecode") REFERENCES "Province"("provincecode") DEFERRABLE INITIALLY IMMEDIATE;
-- Relationship from "City" ("provincecode") to "Province"("provincecode") does not enforce integrity.
-- Relationship from "Inventory" ("sku") to "RetailPrice"("sku") does not enforce integrity.
-- Relationship from "City" ("code") to "Supplier"("city") does not enforce integrity.
ALTER TABLE "Inventory" ADD CONSTRAINT "inventory_suppliercode_fk" FOREIGN KEY ("suppliercode") REFERENCES "Supplier"("suppliercode") DEFERRABLE INITIALLY IMMEDIATE;
-- Relationship from "TxDetails" ("txnumber") to "TxHeader"("txnumber") does not enforce integrity.
-- Relationship from "CustomerMedical" ("customerid") to "CustomerPresContact"("customerid") does not enforce integrity.
-- Relationship from "CustomerMedical" ("customerid") to "CustomerPresLens"("customerid") does not enforce integrity.
