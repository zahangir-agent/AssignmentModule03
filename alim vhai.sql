 select 
 ITEM_PREFIX,Item_IS,Item_Group,Item_Type,Item_Category,
 inventory_Item_id,Item_Description,UOM,Openingqty,purchaseqty,purchaseValue,CONSUMPTION,Loan_toSupplier,CLOSINGSTOCK,Grnqty from(
 select
 vv.ITEM_PREFIX,vv.Item_IS,vv.Item_Group,vv.Item_Type,vv.Item_Category,inventory_Item_id,Item_Description,UOM,
Openingqty,purchaseqty,purchaseValue,CONSUMPTION,Loan_toSupplier,CLOSINGSTOCK,Openingqty+purchaseqty+CONSUMPTION+CLOSINGSTOCK qty,vv.Grnqty from(
 select
  (select description from xxpwc.pwc_flex_values_v where flex_value_set_name =  'XXSG_INV_ITEM_PREFIX' and flex_value=item.segment1 ) "ITEM_PREFIX",
(select D.Description from fnd_flex_values_tl D,fnd_flex_values M,mtl_categories_b catseg
where  M.FLEX_VALUE_ID=D.FLEX_VALUE_ID and FLEX_VALUE_SET_ID=1018219 and M.Flex_value=catseg.segment1 and catseg.Category_ID=(select Category_id from MTL_ITEM_CATEGORIES where inventory_item_id=ITEM.inventory_item_id and organization_ID=117 and Category_set_id=1)) Item_IS ,
(select D.Description from fnd_flex_values_tl D,fnd_flex_values M,mtl_categories_b catseg
where  M.FLEX_VALUE_ID=D.FLEX_VALUE_ID and FLEX_VALUE_SET_ID=1018220 and M.Flex_value=catseg.segment2 and catseg.Category_ID=(select Category_id from MTL_ITEM_CATEGORIES where inventory_item_id=ITEM.inventory_item_id and organization_ID=117 and Category_set_id=1)) Item_Group ,
(select D.Description from fnd_flex_values_tl D,fnd_flex_values M,mtl_categories_b catseg
where  M.FLEX_VALUE_ID=D.FLEX_VALUE_ID and FLEX_VALUE_SET_ID=1018221 and M.Flex_value=catseg.segment3 and M.PARENT_FLEX_VALUE_LOW=catseg.segment2 and catseg.Category_ID=(select Category_id from MTL_ITEM_CATEGORIES where inventory_item_id=ITEM.inventory_item_id and organization_ID=117 and Category_set_id=1))Item_Type ,
(select D.Description from fnd_flex_values_tl D,fnd_flex_values M,mtl_categories_b catseg
where  M.FLEX_VALUE_ID=D.FLEX_VALUE_ID and FLEX_VALUE_SET_ID=1018222 and M.Flex_value=catseg.segment4 and catseg.Category_ID=(select Category_id from MTL_ITEM_CATEGORIES where inventory_item_id=ITEM.inventory_item_id and organization_ID=117 and Category_set_id=1))Item_Category,
  item.inventory_Item_id, 
 (select description from APPS.MTL_SYSTEM_ITEMS MAT where MAT.Organization_id=117 and MAT.inventory_item_id=item.inventory_Item_id)Item_Description,
  (select PRIMARY_UNIT_OF_MEASURE from APPS.MTL_SYSTEM_ITEMS MAT where MAT.Organization_id=117 and MAT.inventory_item_id=item.inventory_Item_id)UOM,
 nvl((select sum(M.PRIMARY_QUANTITY) 
 from mtl_material_transactions M
 where  
  M.TRANSACTION_DATE<'01-JAN-2022'
 and m.inventory_Item_id=item.inventory_Item_id
 group by M.inventory_Item_id),0)Openingqty,
 NVL((select sum(((POL.Quantity*NVL((select Con.CONVERSION_RATE from MTL_UOM_CONVERSIONS Con where con.UNIT_OF_MEASURE=POL.Unit_meas_lookup_code),1))/NVL((select Con.CONVERSION_RATE from MTL_UOM_CONVERSIONS Con where con.UNIT_OF_MEASURE=item.PRIMARY_UNIT_OF_MEASURE and Con.inventory_item_id=Item.inventory_item_id),(select Con.CONVERSION_RATE from MTL_UOM_CONVERSIONS Con where con.UNIT_OF_MEASURE=item.PRIMARY_UNIT_OF_MEASURE and Con.inventory_item_id=0))))
    from PO_HEADERS_ALL PLL,PO_Lines_all pol
        where  PLL.PO_header_id=PoL.PO_header_id
 and Pol.CANCEL_FLAG='N'
 and pol.Item_ID=item.INVENTORY_ITEM_ID
 AND TO_DATE(PLL.APPROVED_DATE,'DD-MON-YY') BETWEEN '01-JAN-2022' AND '31-DEC-2022'  
 and PLL.AUTHORIZATION_STATUS='APPROVED'
 group by pol.Item_id),0)purchaseqty,
 NVL((select sum(POL.Quantity*UNIT_PRICE*nvl(PLL.RATE,1))
    from PO_HEADERS_ALL PLL,PO_Lines_all pol
         where  PLL.PO_header_id=PoL.PO_header_id
 and Pol.CANCEL_FLAG='N'
 and pol.Item_ID=item.INVENTORY_ITEM_ID
 AND TO_DATE(PLL.APPROVED_DATE,'DD-MON-YY') BETWEEN '01-JAN-2022' AND '31-DEC-2022'  
 and PLL.AUTHORIZATION_STATUS='APPROVED'
 group by pol.Item_id),0)purchaseValue,
  nvl((select sum(PRIMARY_QUANTITY) from   mtl_material_transactions MT where  MT.transaction_type_id=31 
 and MT.transaction_source_id in(select MGD.DISPOSITION_ID from MTL_GENERIC_DISPOSITIONS MGD where  MGD.DESCRIPTION='Issuance to Production')
 and MT.Inventory_item_id=item.inventory_item_id
 AND TO_DATE(MT.TRANSACTION_DATE,'DD-MON-YY') BETWEEN '01-JAN-2022' AND '31-DEC-2022'  
 group by MT.Inventory_item_id),0)consumption,
   nvl((select sum(PRIMARY_QUANTITY) from   mtl_material_transactions MT where  MT.transaction_type_id=31 
 and MT.transaction_source_id in(select MGD.DISPOSITION_ID from MTL_GENERIC_DISPOSITIONS MGD where  MGD.DESCRIPTION='Return / Loan to Supplier')
 and MT.Inventory_item_id=item.inventory_item_id
 and MT.PRIMARY_QUANTITY<0
 AND TO_DATE(MT.TRANSACTION_DATE,'DD-MON-YY') BETWEEN '01-JAN-2022' AND '31-DEC-2022'  
 group by MT.Inventory_item_id),0)Loan_toSupplier,
 NVL((select sum(M.PRIMARY_QUANTITY) 
 from mtl_material_transactions M
 where  
  M.TRANSACTION_DATE<='31-DEC-2022'
 and m.inventory_Item_id=item.inventory_Item_id
  group by M.inventory_Item_id),0)ClosingStock,
NVL((select sum(PRIMARY_QUANTITY) from rcv_transactions RCV,PO_lines_ALL PLL 
where
 PLL.PO_line_id=rcv.PO_line_id
 and RCV.TRANSACTION_TYPE='DELIVER'
 and PLL.Item_ID=Item.Inventory_item_id
 and PLL.CANCEL_FLAG='N'
 AND TO_DATE(RCV.TRANSACTION_DATE,'DD-MON-YY') BETWEEN '01-JAN-2022' AND '31-DEC-2022'
 group by Item.Inventory_item_id),0)-
 NVL((select sum(PRIMARY_QUANTITY) from rcv_transactions RCV,PO_lines_ALL PLL 
where
 PLL.PO_line_id=rcv.PO_line_id
 and RCV.TRANSACTION_TYPE='RETURN TO RECEIVING'
 and PLL.Item_ID=Item.Inventory_item_id
 and PLL.CANCEL_FLAG='N'
 AND TO_DATE(RCV.TRANSACTION_DATE,'DD-MON-YY') BETWEEN '01-JAN-2022' AND '31-DEC-2022'
 group by Item.Inventory_item_id),0)grnqty
  from APPS.MTL_SYSTEM_ITEMS Item where Item.ORGANIZATION_ID=117
  and item.inventory_item_id in(select  INVENTORY_ITEM_ID from mtl_item_categories where ORGANIZATION_ID=117 and CATEGORY_ID in(select CATEGORY_ID from MTL_CATEGORIES where SEGMENT1='15001'))
   ) vv
   )www
   where qty>0
   
   
   
   
   
   
   ----------------
   
   
    PO_lines_all POL,rcv_transactions rcv where POL.PO_line_id=rcv.PO_line_id and rcv.Transaction_id=MT.rcv_transaction_id and rcv.TRANSACTION_TYPE='DELIVER')Con_Rate,
 NVL((select Con.CONVERSION_RATE from MTL_UOM_CONVERSIONS Con where con.UOM_CODE=MT.TRANSACTION_UOM and Con.inventory_item_id>0),(select Con.CONVERSION_RATE from MTL_UOM_CONVERSIONS Con where con.UOM_CODE=MT.TRANSACTION_UOM and Con.inventory_item_id=0)) Convert_uom,
 
 ------------------------------
 
 select
ROW_NUMBER() OVER(ORDER BY TRANSACTION_DATE ) SL,
TRAN_DATE,
   USER_ID    NAME    ,
   GRN_CREATIONBY,
TRANSACTION_ID,
 OPERATING_UNIT_ID,
    OPERATING_UNIT    ,
--DDRESS,
ORGANIZATION_ID,
 INVORGNAME,
  SUBINVENTORY_CODE,
  SUBINVENTORY,
 --   LOCATOR_ID,
  DESCRIPTION,
   PHYSICAL_LOCATION,
       SUPPLIER,
        PO_NUMBER,
        Lagecy_Po_number,
        PO_created_by,
        Po_Created_date,
        PO_Approved_By,
        Po_Approval_date,
 PoLineID,    
    MASTER_TRACKING_NO,
    RETAILER,
    STYLE_NUMBER,
    SEASON    ,
    TRANSACTION_TYPE_ID,
   TRANSACTION_TYPE_NAME,
   TRANSACTION_SOURCE_ID,
 INVENTORY_ITEM_ID,
    ITEM_PREFIX,
    ITEM_DESCRIPTION,   
 --   SHIPMENT_NUMBER,
     POQTY,PO_Uom,
    Unit_price,
    PQ,Convert_uom,PQ/Convert_uom PO_QY_based_Tran_uom,
    POQTY*Unit_price POValue,Con_Rate,
    Unit_price/(Con_Rate/Convert_uom)ConvertUnitPrice,
    RECEIPT_NUMBER GRN_No,
    INVOICE_NUMBER,
    CHALLAN_NUMBER,
    INVOICE_QTY,
    RECEIVE_QUANTITY-NVL(RETURN_TO_VENDOR,0)RECEIVE_QUANTITY,
   -- ACCEPT_QUANTITY,
    TRANSACTION_QUANTITY-NVL(RETURN_TO_RECEIVING,0) GRNQTY,
    QtyBilled,
    RETURN_TO_VENDOR,
    RETURN_TO_RECEIVING,
    TRANSACTION_UOM,
    TRANSACTION_QUANTITY*(Unit_price/(Con_Rate/Convert_uom)) GV,
    (TRANSACTION_QUANTITY-NVL(RETURN_TO_RECEIVING,0))* (Unit_price/(Con_Rate/Convert_uom))GRNVALUE,
    Currency,
    Ap_InvoiceNo,Ap_Invoice_Date,
    rcv_transaction_id
    from
(
SELECT
 MT.TRANSACTION_DATE,
 TO_CHAR(MT.TRANSACTION_DATE,'DD-MON-YY') Tran_Date,
(SELECT USER_NAME FROM fnd_user WHERE USER_ID=MT.CREATED_BY ) USER_ID,
(SELECT fnd_user.User_name || ' - ' ||EMP.FIRST_NAME||' '||EMP.LAST_NAME FROM fnd_user,APPS.PER_PEOPLE_X EMP 
WHERE fnd_user.EMPLOYEE_ID=EMP.PERSON_ID AND fnd_user.USER_ID=MT.CREATED_BY)GRN_CREATIONBY,
(SELECT EMP.LAST_NAME FROM fnd_user,APPS.PER_PEOPLE_X EMP WHERE fnd_user.EMPLOYEE_ID=EMP.PERSON_ID AND fnd_user.USER_ID=MT.CREATED_BY) NAME,
 MT.TRANSACTION_ID,MT.rcv_transaction_id ,
 opunit.ORGANIZATION_ID Operating_Unit_id,
 opunit.Name Operating_Unit,
 --(select h1.address_line_1 || ',' ||  h1.address_line_2   from APPS.hr_locations h1,APPS.hr_organization_units HOU  where HOU.LOCATION_ID=h1.Location_id and hou.Organization_id=opunit.ORGANIZATION_ID) address,
 MT.ORGANIZATION_ID,UNIT.ORGANIZATION_NAME INVORGNAME,MT.SUBINVENTORY_CODE,SUBINV.DESCRIPTION SUBINVENTORY,
 MT.LOCATOR_ID,LOC.DESCRIPTION,
(select locvl.Description from xxpwc.pwc_flex_values_v locvl where flex_value_set_name = 'XXSG_INV_LOC_PHYSICAL_LOCATION' and locvl.FLEX_VALUE=LOC.SEGMENT7)physical_location, 
 (SELECT TRACKING_NO FROM XXSG.XXSG_BUYER_STY_SEASON_STNO RT WHERE RT.TRACKING_NO=LOC.SEGMENT5) MASTER_TRACKING_NO,
(SELECT RETAILER FROM XXSG.XXSG_BUYER_STY_SEASON_STNO RT WHERE RT.TRACKING_NO=LOC.SEGMENT5) RETAILER,
(SELECT STYLE_NUMBER FROM XXSG.XXSG_BUYER_STY_SEASON_STNO ST WHERE ST.TRACKING_NO=LOC.SEGMENT5) STYLE_NUMBER,
(SELECT SEASON_NAME FROM XXSG.XXSG_BUYER_STY_SEASON_STNO ST WHERE ST.TRACKING_NO=LOC.SEGMENT5) SEASON,
MT.TRANSACTION_TYPE_ID,TRANSACTION_TYPE_NAME,MT.TRANSACTION_SOURCE_ID,MT.INVENTORY_ITEM_ID,
( SELECT DESCRIPTION FROM xxpwc.pwc_flex_values_v where flex_value_set_name ='XXSG_INV_ITEM_PREFIX' AND flex_value=ITEM.SEGMENT1 ) ITEM_PREFIX,
ITEM.DESCRIPTION ITEM_DESCRIPTION,
MT.TRANSACTION_QUANTITY,
(select  sum(nvl(quantity,0)) quantity from rcv_transactions rv where rv.transaction_type='RETURN TO VENDOR' and rv.PARENT_TRANSACTION_ID=(select rcv.PARENT_TRANSACTION_ID from rcv_transactions rcv where  rcv.transaction_type='DELIVER' and rcv.transaction_id=MT.rcv_transaction_id)) RETURN_TO_VENDOR,
(select  sum(nvl(quantity,0)) quantity from rcv_transactions rv where rv.transaction_type='RETURN TO RECEIVING' and rv.PARENT_TRANSACTION_ID=(select rcv.transaction_id from rcv_transactions rcv where  rcv.transaction_type='DELIVER' and rcv.transaction_id=MT.rcv_transaction_id))RETURN_TO_RECEIVING,
/*(select NVL(PDL.QUANTITY_BILLED,'0') from rcv_transactions rcv ,PO_DISTRIBUTIONS_ALL PDL 
where rcv.po_distribution_id=PDL.po_distribution_id
and rcv.TRANSACTION_TYPE='DELIVER'
and rcv.transaction_id=MT.rcv_transaction_id) QtyBilled,*/
(select NVL(QUANTITY_BILLED,0) from rcv_transactions rv where rv.TRANSACTION_TYPE='RECEIVE' and rv.shipment_line_ID in (select rcv.shipment_line_ID from rcv_transactions rcv where  rcv.TRANSACTION_TYPE='DELIVER' and rcv.transaction_id=MT.rcv_transaction_id))QtyBilled,
(select NVL(PDL.QUANTITY_FUNDED,'0') from rcv_transactions rcv ,PO_DISTRIBUTIONS_ALL PDL 
where rcv.po_distribution_id=PDL.po_distribution_id
and rcv.TRANSACTION_TYPE='DELIVER'
and rcv.transaction_id=MT.rcv_transaction_id)Quantity_fund,
(select UNIT_OF_MEASURE from MTL_UNITS_OF_MEASURE where UOM_CODE=MT.TRANSACTION_UOM)TRANSACTION_UOM,
(select listagg(INVOICE_NUM, ',') within group (order by INVOICE_NUM) from rcv_transactions rv ,AP_INVOICE_LINES_ALL Apline,AP_invoices_all AP
where rv.TRANSACTION_TYPE='RECEIVE' 
and rv.TRANSACTION_ID=Apline.RCV_TRANSACTION_ID 
and AP.INVOICE_ID=Apline.INVOICE_ID
and Apline.CANCELLED_FLAG='N'
and QUANTITY_INVOICED>0
and rv.shipment_line_ID in (select distinct rcv.shipment_line_ID from rcv_transactions rcv where  rcv.TRANSACTION_TYPE='DELIVER' and rcv.transaction_id=MT.rcv_transaction_id)
group by rv.shipment_line_ID) Ap_InvoiceNo,
/*(select listagg(dd, ',') within group (order by dd)
from (select distinct TO_CHAR(AP.INVOICE_DATE,'DD-MON-YY')dd,rcv_transaction_id from ap_invoice_distributions_all Apall,ap_invoices_all AP where AP.INVOICE_ID=Apall.INVOICE_ID and Apall.rcv_transaction_id in(select distinct PARENT_TRANSACTION_ID from rcv_transactions 
where TRANSACTION_TYPE='ACCEPT' 
and TRANSACTION_ID in(select PARENT_TRANSACTION_ID from rcv_transactions RC where RC.TRANSACTION_ID=MT.rcv_transaction_id  and TRANSACTION_TYPE='DELIVER')))
group by rcv_transaction_id)*/
(select listagg(TO_CHAR(AP.INVOICE_DATE,'DD-MON-YY'), ',') within group (order by INVOICE_NUM) from rcv_transactions rv ,AP_INVOICE_LINES_ALL Apline,AP_invoices_all AP
where rv.TRANSACTION_TYPE='RECEIVE' 
and rv.TRANSACTION_ID=Apline.RCV_TRANSACTION_ID 
and Apline.CANCELLED_FLAG='N'
and QUANTITY_INVOICED>0
and AP.INVOICE_ID=Apline.INVOICE_ID
and rv.shipment_line_ID in (select distinct rcv.shipment_line_ID from rcv_transactions rcv where  rcv.TRANSACTION_TYPE='DELIVER' and rcv.transaction_id=MT.rcv_transaction_id)
group by rv.shipment_line_ID)Ap_Invoice_Date,
SHIPMENT_NUMBER,
(select rcvh.receipt_num from rcv_transactions rcv ,rcv_shipment_headers rcvh 
where rcv.shipment_header_id=rcvh.shipment_header_id
and rcv.TRANSACTION_TYPE='DELIVER'
and rcv.transaction_id=MT.rcv_transaction_id )receipt_number,
(select NVL(rcvh.ATTRIBUTE1,'-') from rcv_transactions rcv ,rcv_shipment_headers rcvh 
where rcv.shipment_header_id=rcvh.shipment_header_id
and rcv.TRANSACTION_TYPE='DELIVER'
and rcv.transaction_id=MT.rcv_transaction_id)Invoice_number,
(select NVL(rcvh.ATTRIBUTE2,'-') from rcv_transactions rcv ,rcv_shipment_headers rcvh 
where rcv.shipment_header_id=rcvh.shipment_header_id
and rcv.TRANSACTION_TYPE='DELIVER'
and rcv.transaction_id=MT.rcv_transaction_id)Challan_number,
(SELECT NVL(rcv_tran.ATTRIBUTE1,'0')
FROM rcv_transactions rcv_tran
where rcv_tran.transaction_id=MT.rcv_transaction_id
AND rcv_tran.TRANSACTION_TYPE='DELIVER')Invoice_qty,
(select quantity from rcv_transactions rv where rv.TRANSACTION_TYPE='RECEIVE' and rv.shipment_line_ID in (select rcv.shipment_line_ID from rcv_transactions rcv where  rcv.TRANSACTION_TYPE='DELIVER' and rcv.transaction_id=MT.rcv_transaction_id)) receive_quantity,
--(select sum(quantity) from rcv_transactions rv where rv.TRANSACTION_TYPE='ACCEPT'  and rv.shipment_line_ID in (select rcv.shipment_line_ID from rcv_transactions rcv where  rcv.TRANSACTION_TYPE='DELIVER' and rcv.transaction_id=MT.rcv_transaction_id))Accept_quantity,
--''Accept_quantity,
(select segment1 po_number from PO_HEADERS_ALL PLL,rcv_transactions rcv where PLL.PO_header_id=rcv.PO_header_id and rcv.Transaction_id=MT.rcv_transaction_id and rcv.TRANSACTION_TYPE='DELIVER') Po_number,
(select TO_CHAR(PLL.CREATION_DATE,'DD-MON-YY') from PO_HEADERS_ALL PLL,rcv_transactions rcv where PLL.PO_header_id=rcv.PO_header_id and rcv.Transaction_id=MT.rcv_transaction_id and rcv.TRANSACTION_TYPE='DELIVER') Po_Created_date,
(select TO_CHAR(PLL.APPROVED_DATE,'DD-MON-YY') from PO_HEADERS_ALL PLL,rcv_transactions rcv where PLL.PO_header_id=rcv.PO_header_id and rcv.Transaction_id=MT.rcv_transaction_id and rcv.TRANSACTION_TYPE='DELIVER') Po_Approval_date,
(SELECT fnd_user.User_name || ' - ' ||EMP.FIRST_NAME||' '||EMP.LAST_NAME FROM fnd_user,APPS.PER_PEOPLE_X EMP 
WHERE fnd_user.EMPLOYEE_ID=EMP.PERSON_ID AND fnd_user.USER_ID=(select PLL.CREATED_BY from PO_HEADERS_ALL PLL,rcv_transactions rcv where PLL.PO_header_id=rcv.PO_header_id and rcv.Transaction_id=MT.rcv_transaction_id and rcv.TRANSACTION_TYPE='DELIVER'))PO_created_by,
(SELECT E.EMPLOYEE_NUMBER||'-'||E.FIRST_NAME || ' ' || E.LAST_NAME FROM APPS.PER_PEOPLE_X E WHERE E.PERSON_ID=(select employee_ID from po.po_action_history 
where object_type_code='PO' and object_SUB_type_code='STANDARD'and Action_code='APPROVE' and object_ID=(select PLL.PO_HEADER_ID from PO_HEADERS_ALL PLL,rcv_transactions rcv where PLL.PO_header_id=rcv.PO_header_id and rcv.Transaction_id=MT.rcv_transaction_id and rcv.TRANSACTION_TYPE='DELIVER')
 and SEQUENCE_NUM= (select max(SEQUENCE_NUM) from po.po_action_history  where object_type_code='PO' and object_SUB_type_code='STANDARD'and Action_code='APPROVE'and object_ID=(select PLL.PO_HEADER_ID from PO_HEADERS_ALL PLL,rcv_transactions rcv where PLL.PO_header_id=rcv.PO_header_id and rcv.Transaction_id=MT.rcv_transaction_id and rcv.TRANSACTION_TYPE='DELIVER')))) PO_Approved_By,
(select PLL.ATTRIBUTE15 from PO_HEADERS_ALL PLL,rcv_transactions rcv where PLL.PO_header_id=rcv.PO_header_id and rcv.Transaction_id=MT.rcv_transaction_id and rcv.TRANSACTION_TYPE='DELIVER') Lagecy_Po_number,
(select po_line_id from rcv_transactions rcv where  rcv.Transaction_id=MT.rcv_transaction_id and rcv.TRANSACTION_TYPE='DELIVER')PoLineID,
(select PLL.Quantity from PO_lines_all PLL,rcv_transactions rcv where PLL.PO_line_id=rcv.PO_line_id and rcv.Transaction_id=MT.rcv_transaction_id and rcv.TRANSACTION_TYPE='DELIVER')POQTY,
(select PLL.UNIT_MEAS_LOOKUP_CODE from PO_lines_all PLL,rcv_transactions rcv where PLL.PO_line_id=rcv.PO_line_id and rcv.Transaction_id=MT.rcv_transaction_id and rcv.TRANSACTION_TYPE='DELIVER')PO_Uom,
(select Unit_price from PO_lines_all PLL,rcv_transactions rcv where PLL.PO_line_id=rcv.PO_line_id and rcv.Transaction_id=MT.rcv_transaction_id and rcv.TRANSACTION_TYPE='DELIVER') Unit_price,
 /*(select 
 ((POL.Quantity*NVL((select Con.CONVERSION_RATE from MTL_UOM_CONVERSIONS Con where con.UNIT_OF_MEASURE=POL.Unit_meas_lookup_code),1))
 /NVL((select Con.CONVERSION_RATE from MTL_UOM_CONVERSIONS Con where con.UOM_CODE=RCV.UOM_CODE and Con.inventory_item_id=POL.item_id),(select Con.CONVERSION_RATE from MTL_UOM_CONVERSIONS Con where con.UOM_CODE=RCV.UOM_CODE and Con.inventory_item_id=0)))
 from 
 PO_lines_all POL,rcv_transactions rcv where POL.PO_line_id=rcv.PO_line_id and rcv.Transaction_id=MT.rcv_transaction_id and rcv.TRANSACTION_TYPE='DELIVER')PO_qty_Basedon_grn_uom,*/
 (select 
 (POL.Quantity*NVL((select Con.CONVERSION_RATE from MTL_UOM_CONVERSIONS Con where con.UNIT_OF_MEASURE=POL.Unit_meas_lookup_code and Con.inventory_item_id=0),1))
 from 
 PO_lines_all POL,rcv_transactions rcv where POL.PO_line_id=rcv.PO_line_id and rcv.Transaction_id=MT.rcv_transaction_id and rcv.TRANSACTION_TYPE='DELIVER')PQ,
 (select 
 (NVL((select Con.CONVERSION_RATE from MTL_UOM_CONVERSIONS Con where con.UNIT_OF_MEASURE=POL.Unit_meas_lookup_code and Con.inventory_item_id=0),1))
 from 
 PO_lines_all POL,rcv_transactions rcv where POL.PO_line_id=rcv.PO_line_id and rcv.Transaction_id=MT.rcv_transaction_id and rcv.TRANSACTION_TYPE='DELIVER')Con_Rate,
 NVL((select Con.CONVERSION_RATE from MTL_UOM_CONVERSIONS Con where con.UOM_CODE=MT.TRANSACTION_UOM and Con.inventory_item_id>0),(select Con.CONVERSION_RATE from MTL_UOM_CONVERSIONS Con where con.UOM_CODE=MT.TRANSACTION_UOM and Con.inventory_item_id=0)) Convert_uom,
(select PLL.CURRENCY_CODE from PO_HEADERS_ALL PLL,rcv_transactions rcv where PLL.PO_header_id=rcv.PO_header_id and rcv.Transaction_id=MT.rcv_transaction_id and rcv.TRANSACTION_TYPE='DELIVER')Currency,
(select Vendor_name from ap_suppliers,rcv_transactions rcvsup where ap_suppliers.vendor_id=rcvsup.vendor_id and rcvsup.TRANSACTION_TYPE='DELIVER' and rcvsup.transaction_id=MT.rcv_transaction_id) Supplier
FROM  mtl_material_transactions MT,mtl_transaction_types TP,APPS.MTL_SYSTEM_ITEMS ITEM,MTL_ITEM_LOCATIONS Loc,apps.org_organization_definitions unit,apps.hr_operating_units opunit,MTL_SECONDARY_INVENTORIES SUBINV
where MT.TRANSACTION_TYPE_ID=TP.TRANSACTION_TYPE_ID
AND ITEM.INVENTORY_ITEM_ID=MT.INVENTORY_ITEM_ID
AND ITEM.ORGANIZATION_ID=MT.ORGANIZATION_ID
AND loc.ORGANIZATION_ID=MT.ORGANIZATION_ID
AND loc.INVENTORY_LOCATION_ID=MT.LOCATOR_ID
AND unit.ORGANIZATION_ID=MT.ORGANIZATION_ID
AND Unit.operating_unit=opunit.organization_id
AND MT.ORGANIZATION_ID=SUBINV.ORGANIZATION_ID
AND MT.SUBINVENTORY_CODE=SUBINV.SECONDARY_INVENTORY_NAME
AND MT.TRANSACTION_TYPE_ID=18
--and opunit.organization_id=98
AND (opunit.organization_id =:P_ORGANIZATION_ID OR :P_ORGANIZATION_ID IS Null)
and trunc(MT.TRANSACTION_DATE) between :P_GRN_Date_From and :P_GRN_Date_To
)
where TRANSACTION_QUANTITY-NVL(RETURN_TO_RECEIVING,0)>0
--and QtyBilled=0
AND (QtyBilled=:P_QtyBilled OR :P_QtyBilled IS Null)
--and Convert_uom>1
--and Po_UOM<>TRANSACTION_UOM
ORDER BY TRANSACTION_DATE
   
   
   
   
   
   
   
 