-- Standardizing date format
-- Note: important to keep raw data
Alter Table NashvilleHousing
Alter Column SaleDate Date


-- Populate Property Address data by filling in NULLs
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
From NashvilleHousing as a
Join NashvilleHousing as b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From NashvilleHousing as a
Join NashvilleHousing as b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


-- Splitting Property Address into individual columns (Address and City)
Select
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1,LEN(PropertyAddress))
From NashvilleHousing


Alter Table NashvilleHousing
Add PropertyAddressSplit nvarchar(255),
    PropertyCity nvarchar(255);

UPDATE NashvilleHousing
SET PropertyAddressSplit = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1),
    PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+1,LEN(PropertyAddress))


-- Splitting Owner Address into Address, City, and State (alternative method)
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
,PARSENAME(REPLACE(OwnerAddress, ',','.'),2)
,PARSENAME(REPLACE(OwnerAddress, ',','.'),1)
From NashvilleHousing


Alter Table NashvilleHousing
Add OwnerAddressSplit nvarchar(255),
    OwnerCity nvarchar(255),
	OwnerState nvarchar(255);

UPDATE NashvilleHousing
SET OwnerAddressSplit = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',','.'),2),
	OwnerState = PARSENAME(REPLACE(OwnerAddress, ',','.'),1);


-- Changing Y and N to Yes and No in "SoldAsVacant" column
Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From NashvilleHousing
Group by SoldAsVacant
Order by 2

Update NashvilleHousing
Set SoldAsVacant = CASE When SoldAsVacant = 'Y' Then 'Yes'
       When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant
	   End
From NashvilleHousing


-- Removing duplicates
WITH RowNumCTE AS(
Select*, 
  ROW_NUMBER() OVER (
  Partition by ParcelID,
               PropertyAddress,
			   SaleDate,
			   SalePrice,
			   LegalReference
			   ORDER By UniqueID
			   ) as row_num
 From NashvilleHousing
 )
DELETE
From RowNumCTE
Where row_num >1


-- Deleting extra columns
Alter Table NashvilleHousing
Drop Column PropertyAddress, OwnerAddress

