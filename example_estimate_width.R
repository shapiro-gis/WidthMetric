###----------------------------------------------------------------------------------
### Title - Example Run to Estimate Width
### Purpose - Example based on the provided sample data to generate a width raster
### Created On - 2025-09-05
### Last Edited On - 
### Created by - Ben Robb
###----------------------------------------------------------------------------------
### Required Packages
require(dplyr)
require(sf)
require(nngeo)

### The width function
source("~/GitHub/WidthMetric/calculate_width_function.R")

#### Directories
print(paste("Starting Processing @", Sys.time()))


### Directories w/ area of interst and house features
the_dir = 'Sample_Data'

### Where to write out
writeDir = paste0('Raster_Dir')
if(!(dir.exists(writeDir))){
  dir.create(writeDir)
}

### area of interest
the_files = list.files(the_dir, full.names = TRUE)
aoi = st_read(the_files[grepl("StudyExtent", the_files)]) 
aoi = st_zm(aoi)

### Gis features to calulate width between, in this case buildings
features = st_read(the_files[grepl("Buildings", the_files)])
features = st_make_valid(features)

### Run the function
print(paste("Begin processing @ ", Sys.time()))
width_fun(aoi = aoi, features = features,
          max_dist = 10000, 
          theres = 30, 
          writeDir = writeDir, 
          n_apples = 1, 
          out_name = 'Width_Raster')
print(paste("Done processing @", Sys.time()))
