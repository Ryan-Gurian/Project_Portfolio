/* DATA CLEANING PROJECT */
use PortfolioProject

select * from PortfolioProject.dbo.NashvilleHousing;



-- STANDARDIZE DATE FORMAT (replacing datetime column with date)
Alter table nashvillehousing
add SaleDateFormatted date;

update nashvillehousing
set saledateformatted = convert(date, saledate);

select saledateformatted from nashvillehousing; 



-- POPULATING THE DATA FOR "PROPERTY ADDRESS" (fill null addresses for duplicate parcelID's with the next address)
select a.parcelID, a.propertyaddress, b.parcelid, b.propertyaddress, ISNULL(a.propertyaddress, b.propertyaddress)
from nashvillehousing a
join nashvillehousing b
	on a.parcelID = b.parcelID
	and a.uniqueID != b.uniqueID
where a.propertyaddress is null

update a
set propertyaddress = ISNULL(a.propertyaddress, b.propertyaddress)
from nashvillehousing a
join nashvillehousing b
	on a.parcelID = b.parcelID
	and a.uniqueID != b.uniqueID
where a.propertyaddress is null



-- SEPARATING PROPERTY ADDRESS INTO INDIVIDUAL COLUMNS FOR ADDRESS & CITY
-- using substring() to split the column using , as the delimiter
select propertyaddress from nashvillehousing

alter table nashvillehousing
add property_split_address nvarchar(255);

alter table nashvillehousing
add property_split_city nvarchar(255);

update nashvillehousing
set property_split_address = substring(propertyaddress, 1, CHARindex(',', propertyaddress)-1);

update nashvillehousing
set property_split_city = substring(propertyaddress, CHARindex(',', propertyaddress)+1, len(propertyaddress));

select propertyaddress, property_split_address, property_split_city from nashvillehousing;



-- SEPARATING OWNER ADDRESS INTO INDIVIDUAL COLUMNS FOR ADDRESS / CITY / STATE
-- use parsename to separate with . as delimiter (but we need to replace , with .)
select owneraddress from nashvillehousing;

alter table nashvillehousing
add owner_split_address nvarchar(255);

alter table nashvillehousing
add owner_split_city nvarchar(255);

alter table nashvillehousing
add owner_split_state nvarchar(255);

update nashvillehousing
set owner_split_address = PARSEname(replace(owneraddress, ',', '.'), 3); 

update nashvillehousing
set owner_split_city = PARSEname(replace(owneraddress, ',', '.'), 2); 

update nashvillehousing
set owner_split_state = PARSEname(replace(owneraddress, ',', '.'), 1); 

select owneraddress, owner_split_address, owner_split_city, owner_split_state from nashvillehousing;



-- CHANGE "Y" & "N" in SOLD AS VACANT COLUMN TO "YES" & "NO"
update nashvillehousing
set SoldAsVacant = CASE WHEN soldasvacant = 'Y' THEN 'Yes'
	   WHEN soldasvacant = 'N' THEN 'No'
	   ELSE soldasvacant
	   END;

select distinct(soldasvacant)
, count(soldasvacant) as Yes_or_No_Count from nashvillehousing
group by soldasvacant;



-- REMOVE DUPLICATES (WE USE A CTE & PARTITION ON UNIQUE ROW CHARACTERISTICS)
-- use row_number() over(partition by) to identify a count of repeats (any row_num > 1 is a duplicate) 
-- need a CTE so we can use the where clause to single out rows with row_num > 1
WITH Row_Num_CTE AS (
select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
		         Propertyaddress,
				 SalePrice,
				 LegalReference
	ORDER BY UniqueID 
	) row_num
from nashvillehousing
)
DELETE FROM Row_Num_CTE
where row_num > 1;



-- DELETE EXTRA "UNCLEAN" COLUMNS & UPDATE ID INDEX TO MATCH ROW # (STARTS @ 0 WE WANT TO START @ 1)
ALTER TABLE nashvillehousing
drop column owneraddress, taxDistrict, propertyaddress, saledate;

update nashvillehousing
set uniqueID = uniqueID + 1;

select * from nashvillehousing
order by uniqueID; 