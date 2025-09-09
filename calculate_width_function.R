###......................................................................................
### Function Title: Width Function
### Purpose: This function estimates the narrowest width between any two features
#### The output of this function is a raster that estimates width, which is effectively
### the shortest distance that connects any two features
### Below is the workflow of the function -
### 1. Crop features w/n the given area of interest, 
### Then, create an intersects matrix to identify every feature A w/n max distance
### 2. Set up parallel based on the intersects matrix (list of lists)
### By breaking apart the intersects matrix, run through every feature
### To get every other feature w/n the max distance (10 km in this case)
### While in parallel, draw the closest line for feature A - all other features w/n max distance, 
### this is the lapply loop w/n the foreach loop
##  B. Still in parallel, draw the length of every line. This length is the width
### C. Rasterize, based on the minimum value of the length of each line. 
### Because the terra package doesn't play great w/ parallel, need to wrap the raster
### 3. Parallel returns a list of "wrapped" rasters, 
## Unwrap, stack, then calculate the minimum non NA value

### Parameters Needed:
### Area of Interest - Polygon for the area over which to estimate width
### Features - the GIS features between which to estimate width
### Max_dist - the maximum relevant distance, any features farther apart than this distance will not estimate width
### So, this value will be the maximum possible value in the raster
### WriteDir: file directory where to write out the raster
### n_apples: the number of cores to use for parallel
### out_name: the file name (note raster is written out as  geotiff by default)
### 
### Requirements Not Checked For/What Could Break: 
### Taking the centroid does simplify things. This could be a problem if people apply on big features
### Maybe we could include a warning?
### For reasons I don't understand, the resulting raster isn't EXACTLY the resolution. Argh.
### Date Created: 2025-06-02
### Last Updated: 2025-06-18, no longer between centroids the polygons themselves
# Also updated on 6-18 to return non-0 numbers (before rounding), these are lines that intersect the same building
### Author: Ben Robb
###......................................................................................
### Okay, the actual function
width_fun = function(
                     aoi = aoi, # Area of interest, as polygon
                     features = features, # Features to estimate width between
                     max_dist = 10000, # Maximum relevant distance to estimate width
                     theres = 30,  # Raster resolution
                     writeDir = tempDir, # Directory to write out 
                     n_apples = 1,# How many cores if running in parallel.n_apples = 1 means not in parallel, >1 will be parallel
                     out_name = 'Width_Cody'){
  ## Load packages
  require(sf)
  require(dplyr)
  require(nngeo)
  require(terra)
  require(foreach)
  require(doParallel)
  
  ### 0. Quick Checks
  # Packages
  if(all(c("sf", "dplyr", "terra", "nngeo", "lwgeom") %in% installed.packages()[,1])==FALSE)
    stop("Sorry, you will need to install the following packages: sf, dplyr, nngeo, and/or terra")
  
  if(st_crs(aoi) != st_crs(features))
    stop("Sorry, make sure the grid of lines and the GIS features are in the same projection")
  
  
  ### Directory
  if(!(dir.exists(writeDir)))
    stop("The directory provided does not exist")
  
  
  # Everything needs to be an sf object
  if(!(inherits(aoi, 'sf')))
    stop("Please double check to make sure the aoi is an sf object")
  
  if(!(inherits(features, 'sf')))
    stop("Please double check to measure sure the features are sf objects")
  
  
  # Convenient Subset Function
  '%!in%' = function(a,b){!(a %in% b)}
  
  ### 1. Crop to the area of interest
  features = st_intersection(features,  aoi)
  
  ### Note previously was estimating width by the centroids prior to 2025-06-18
  ### But now just estimating width by the polygons themselves
  # feature_pts = features %>% 
    # st_centroid()
  feature_pts = st_geometry(features)
  
  ### Buffer the centroids by the maximum distance, this will be used
  ### In an intersects matrix to speed up the processing, with the intersects
  ### Matrix we can reduce for each feature A every other feature w/n the maximum distance
  feature_buff = st_buffer(feature_pts, max_dist) 
  
  # Intersects matrix to identify each feature A w/n  max distance
  inter_mat = st_intersects(feature_pts, feature_buff, sparse = TRUE)
  
  ### 2. Set up Parallel
  # How many to break apart into?
  bin_over = 1:length(inter_mat)
  divide_by = 500 #* Magic number here to decide how many features to process at a time
  bin_over = ceiling((1:length(inter_mat))/divide_by)
  
  # Break apart the intersects matrix into a list of lists
  # This will make it easier to process in parallel
  list_of_lists = list()
  for(j in 1:length(unique(bin_over))){
    sub_rows = which(bin_over == j)
    list_of_lists[[j]] = inter_mat[sub_rows]
  }
  
  ### Prep for parallel
  doParallel::registerDoParallel(cores = n_apples)
  a = Sys.time()
  print(paste("Begin Parallel @", a))
  rast_list = foreach(j = unique(bin_over),
                       .packages = c("sf", "nngeo", "lwgeom", "terra")) %dopar% {
                         
                         # Subset the intsersets matrix
                         inter_mat_sub = list_of_lists[[j]]
                         
                         # Get the index of the larger features
                         index_x = (j - 1)*divide_by
                         
                         # Now, from that subset, run the below lapply
                         the_lines = lapply(1:length(inter_mat_sub), function(x){

                           # Subset
                           inter_matsub2 = inter_mat_sub[[x]]
                           inter_matsub_others = inter_matsub2[which(inter_matsub2 %!in% x)]

                           # Get the points
                           pt = feature_pts[x + index_x]
                           others = feature_pts[inter_matsub_others]

                           # Draw nearest lines
                           the_lines = suppressMessages(st_connect(pt, others, k = length(others), progress = FALSE))
                           return(the_lines)

                         }) # End lapply
                         
                         # Still in parallel! Merge together the lines, as sfc
                         the_lines = do.call(c, the_lines) # Note that the result here is *huge*
                         st_crs(the_lines) = st_crs(feature_pts)

                         # B. Get the length of every line
                         the_lines = st_as_sf(the_lines)
                         the_lines$dist = as.numeric(st_length(the_lines)) 
                         
                         #* Added on 2025-06-19, anything w/ a distance of 0 is wrong be/ only intersects itself
                         the_lines = the_lines[which(the_lines$dist > 0), ]
                         
                         the_lines$dist = round(the_lines$dist, digits = 2)
                         
                         #  # C. Rasterize
                         the_rast = rast(ext(st_buffer(aoi, 1)),
                                         resolution = theres,
                                         crs = crs(aoi))

                         # Spat vect
                         the_lines = as(the_lines,"SpatVector")

                         the_rast = terra::rasterize(the_lines,
                                                     the_rast,
                                                     field = 'dist',
                                          fun = min)
                         # Pack it
                         the_rast = terra::wrap(the_rast)
                         # Return
                         return(the_rast)

                       } 
  b = Sys.time()
  print(paste(round(difftime(b,a), digits = 2),
              units(difftime(b,a)),
              'to run in parallel')) 
  stopImplicitCluster()
  
  ### 3. Stack together every raster into 1 layer, take the minimum across every layer
  ### Run a basic for loop to unwrap everything
  rast_stack = list()
  for(k in 1:length(rast_list)){
    rast_stack[[k]] = terra::unwrap(rast_list[[k]])
  }
  ### Stack it
  rast_stack = rast(rast_stack)
  the_rast = min(rast_stack, na.rm = TRUE)

  # Write out the raster
  writeRaster(the_rast, paste0(writeDir, '/',out_name,"_", Sys.Date(), '.tif'))
  gc()
  print(paste("Done processing @", Sys.time()))
}

