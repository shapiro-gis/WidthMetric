# Minimum Width Calculation 
This repository provides the tools to calculate the minimum width between two GIS features. This tool was initially developed to estimate the width between buildings to help inform the configuration of housing development that inhibits wildlife movement. Here, we define width as the shortest distance between any two features (in this case, bulidings). Existing GIS tools such as nearest distance and density can estimate proximty and abundance of development, but not necessarily the configuration. Nonetheless, disturbances on wildlife can be mitigated by considering their configuration. This project estimates width as a metric of configuration that can be used to help reduce habitat loss caused by housing development. The below R script was used for the associated paper available at [DOI HERE] and are designed to streamline the process of calculating critical widths in a study area. 

## Sample Data

This repository includes a *Sample Data* folder containing example datasets for testing and demonstrating the scripts. These datasets can be used to run the below width function and validate the output without needing additional data sources. The sample data helps in understanding the workflow and expected results for the minimum width calculation between features.

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
