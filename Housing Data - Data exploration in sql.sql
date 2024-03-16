-- Fort this project I will be looking at a housing data for a city in USA. The dataset contains more than 55K rows and 20 cloumns. 
-- Since I am using a mac system, I am unable to use SSMS so I will be using bigQuery for my sql queries. 

# I will be starting by standardizing the date format. 

SELECT SaleDate, PARSE_DATE('%b %d, %Y', SaleDate) AS SaleDate
FROM spry-bus-413817.HousingDataExploration.HousingData

UPDATE spry-bus-413817.HousingDataExploration.HousingData
SET SaleDate = FORMAT_DATE('%Y-%m-%d', PARSE_DATE('%b %d, %Y', SaleDate))
WHERE true


# The data we have has around 35 instances where the property address is NULL which is practically not possible. So let's populate the this field properly. 

SELECT PropertyAddress
FROM spry-bus-413817.HousingDataExploration.HousingData
WHERE PropertyAddress is null

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.PropertyAddress) AS PropertyAddressFixed
FROM spry-bus-413817.HousingDataExploration.HousingData a
JOIN spry-bus-413817.HousingDataExploration.HousingData b
ON a.ParcelID = b.ParcelID
AND a.UniqueID_ <> b.UniqueID_
WHERE a.PropertyAddress is NULL

-- The update statement in SQL or MySQL is pretty straight forward but there are a few complications in bigquery, and this is the update statement I have come up with in order to update the null values that we obtained from the above select query.
UPDATE spry-bus-413817.HousingDataExploration.HousingData
SET PropertyAddress = temp_table.PropertyAddressFixed
FROM (
  SELECT *,
    ROW_NUMBER() OVER (PARTITION BY Parcelid1 ORDER BY Parcelid1) AS row_num
  FROM spry-bus-413817.HousingDataExploration.tempTable
) temp_table
WHERE HousingData.ParcelID = temp_table.Parcelid1
AND HousingData.PropertyAddress IS NULL
AND temp_table.row_num = 1

-- In order to make the update statement work I have to make a tempTable to hold the data and then use that temp table to update the values. I did it that way becuase I could not figure out a way to use join in the update statement. 
/* CREATE TABLE spry-bus-413817.HousingDataExploration.tempTable(
  Parcelid1 string,
  PropertyAddress1 string,
  Parcelid2 string,
  PropertyAddress2 string,
  PropertyAddressFixed string
)

INSERT INTO `HousingDataExploration.tempTable`(
  Parcelid1,
  PropertyAddress1,
  Parcelid2,
  PropertyAddress2,
  PropertyAddressFixed
)
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, IFNULL(a.PropertyAddress, b.         PropertyAddress) AS PropertyAddressFixed
  FROM spry-bus-413817.HousingDataExploration.HousingData a
  JOIN spry-bus-413817.HousingDataExploration.HousingData b
  ON a.ParcelID = b.ParcelID
  AND a.UniqueID_ <> b.UniqueID_
  WHERE a.PropertyAddress is NULL */


# Next I will be breaking out the Address column into individual columns (Address, City, State). 

SELECT
SUBSTR(PropertyAddress, 1, STRPOS(PropertyAddress, ',') - 1) AS Address1,
SUBSTR(PropertyAddress, STRPOS(PropertyAddress, ',') + 1) AS Address2
FROM spry-bus-413817.HousingDataExploration.HousingData

ALTER TABLE spry-bus-413817.HousingDataExploration.HousingData
Add column PropertySplitAddress String

Update spry-bus-413817.HousingDataExploration.HousingData
SET PropertySplitAddress = SUBSTR(PropertyAddress, 1, STRPOS(PropertyAddress, ',') - 1)
WHERE true

ALTER TABLE spry-bus-413817.HousingDataExploration.HousingData
Add column PropertySplitCity String

Update spry-bus-413817.HousingDataExploration.HousingData
SET PropertySplitCity = SUBSTR(PropertyAddress, STRPOS(PropertyAddress, ',') + 1)
WHERE true

SELECT 
  SPLIT(OwnerAddress, ',')[SAFE_OFFSET(0)] AS Address,
  SPLIT(OwnerAddress, ',')[SAFE_OFFSET(1)] AS City,
  SPLIT(OwnerAddress, ',')[SAFE_OFFSET(2)] AS State
FROM spry-bus-413817.HousingDataExploration.HousingData

ALTER TABLE spry-bus-413817.HousingDataExploration.HousingData
Add Column OwnerSplitAddress string

Update spry-bus-413817.HousingDataExploration.HousingData
SET OwnerSplitAddress = SPLIT(OwnerAddress, ',')[SAFE_OFFSET(0)]
WHERE true

ALTER TABLE spry-bus-413817.HousingDataExploration.HousingData
Add Column OwnerSplitCity string

Update spry-bus-413817.HousingDataExploration.HousingData
SET OwnerSplitCity = SPLIT(OwnerAddress, ',')[SAFE_OFFSET(1)]
WHERE true

ALTER TABLE spry-bus-413817.HousingDataExploration.HousingData
Add Column OwnerSplitState string

Update spry-bus-413817.HousingDataExploration.HousingData
SET OwnerSplitState = SPLIT(OwnerAddress, ',')[SAFE_OFFSET(2)]
WHERE true


# Next, in our data the column 'SoldAsVacant' has boolean values true and false. We will be converting this to yes and no respectively.

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From spry-bus-413817.HousingDataExploration.HousingData
Group by SoldAsVacant
order by 2

Select SoldAsVacant
, CASE 
     WHEN SoldAsVacant THEN 'Yes'
	   ELSE 'No'
	   END
From spry-bus-413817.HousingDataExploration.HousingData

ALTER TABLE spry-bus-413817.HousingDataExploration.HousingData
ALTER COLUMN SoldAsVacant STRING

CREATE TABLE spry-bus-413817.HousingDataExploration.NewHousingData AS
SELECT *,
CASE WHEN SoldAsVacant THEN 'Yes' ELSE 'No' END AS SoldAsVacantString
FROM spry-bus-413817.HousingDataExploration.HousingData

DROP TABLE spry-bus-413817.HousingDataExploration.HousingData

ALTER TABLE spry-bus-413817.HousingDataExploration.NewHousingData RENAME TO HousingData


# Now we will remove the duplicate values from our data. 

DELETE FROM spry-bus-413817.HousingDataExploration.HousingData
WHERE UniqueID_ IN (
  SELECT UniqueID_
  FROM (
    SELECT UniqueID_,
           ROW_NUMBER() OVER (PARTITION BY ParcelID, 
                                          PropertyAddress, 
                                          SaleDate, 
                                          SalePrice,
                                          LegalReference
                                 ORDER BY UniqueID_) AS row_num
    FROM spry-bus-413817.HousingDataExploration.HousingData
  )
  WHERE row_num > 1
)


# At last, I will remove all the unused columns from the database. 

Select TaxDistrict
From spry-bus-413817.HousingDataExploration.HousingData


ALTER TABLE spry-bus-413817.HousingDataExploration.HousingData
DROP COLUMN OwnerAddress

ALTER TABLE spry-bus-413817.HousingDataExploration.HousingData
DROP COLUMN TaxDistrict

ALTER TABLE spry-bus-413817.HousingDataExploration.HousingData
DROP COLUMN PropertyAddress

ALTER TABLE spry-bus-413817.HousingDataExploration.HousingData
DROP COLUMN SoldAsVacant

ALTER TABLE spry-bus-413817.HousingDataExploration.HousingData
RENAME COLUMN SoldAsVacantString TO SoldAsVacant

--select * from spry-bus-413817.HousingDataExploration.HousingData

-- Some queries in the above script may seem overly complicated or different from Mysql or PostgreSQL. It is just because of the fact that Iam using bigquery to make these project scripts as I don't have acces to SSMS. 



