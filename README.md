# Minimum Width Calculation 
This repository provides tools to calculate the minimum width between buildings and roads, focusing on understanding and minimizing wildlife disturbance. Most traditional GIS algorithms compute the nearest distance to features, often neglecting the width between them. To achieve a more comprehensive view, this project calculates widths to help guide minimum disturbance levels necessary for wildlife use. These python scripts complement the paper available at [DOI HERE] and are designed to streamline the process of calculating critical widths in a study area. 

## Sample Data

This repository includes a *Sample_Data* folder containing example datasets for testing and demonstrating the scripts. These datasets can be used to run the below width function and validate the output without needing additional data sources. The sample data helps in understanding the workflow and expected results for the minimum width calculation between features.

## Scripts
1. **Width Function**<br />
   
Source the R script *calculate_width_function.R* for the width function. The output of this function will be a spatial raster, see below for details.<br />

2. **Estimate Width From Sample Data**<br />

The R script *example_estimate_width.R* includes the steps to use the associated Sample_Data with the width function to generate a spatial raster where each cell is the narrowest width between any two buildings.<br />

## Details on Estimating Width
The *calculate_width_function.R* script performs the following steps:
1. Crop features within the given area of interest: In this case, the features of interest are building polygons.
2. Create Intersects Matrix: For every feature, identify every other feature within a threshold distance (in this case, 10 km) of one another. This intersection matrix will be used to estimate the distance between each feature
3. Draw Lines: For every feature, draw the nearest line to every other feature within a threshold distance (10 km). Include the length of each line as well. 
4. Convert to Raster: rasterize the area of interest where the value of each cell is the shortest (non-zero) length of each line. The shortest non-zero line at a given location is the width between buildings. 
5. Return Raster: Output raster will be written out to the provided write directory.

### Parameters Needed for the Width Function
The output of the *CreateWidths* script is a data frame that includes:
- Area of Interest: Should be a polygon
- Features: the GIS features between which to estimate width
- Maximum Distance: beyond this threshold, do not estimate width between two features
- The desired resolution of the output raster (in m2)
- The folder where the raster should be written out to
- The number of cores to use, if running in parallel
