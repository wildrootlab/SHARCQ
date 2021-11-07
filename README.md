# SHARCQ

This code is a modified development from https://github.com/cortex-lab/allenCCF allenCCF tools for working with the Allen Inst Mouse Brain CCF data, specifically the 10µm voxel 2017 version. 


## Requirements
- MATLAB (recommended at least R2020 version)
- MATLAB Image Processing Toolbox
- This repository (add all folders and subfolders to your MATLAB path)
- Histological images of mouse brain sections
- Cell Count (ROI pixel coordinate) files
- The npy-matlab repository (https://github.com/kwikteam/npy-matlab) (add 'npy-matlab-master' to 'Code' folder)
- The Allen Mouse Brain Atlas volume and annotations(http://data.cortexlab.net/allenCCF/) (download all 4 files from this link and add to 'Atlas'->'Allen' folder)

*See the Wiki for detailed instructions about these requirements

## Slice Histology Alignment, Registration, and Cell Quantification

SHARCQ is a MATLAB user interface developed from SHARP-Track (cortex lab) to explore the Allen Mouse Brain Atlas, register asymmetric slice images to the atlas using manual input, and analyze region-of-interest (ROI) data by registering locations of fluorescently labeled cells to standardized regions of the Atlas. A matlab GUI app is provided for ease of use while navigating the program. This program removes the focus from probe tracking inherent to SHARP-Track and incorporates the functionality of registering individual cell locations to the atlas. 

This development is a product from the Root Lab at the University of Colorado at Boulder. It was inspired by the utility of SHARP-Track in working with mouse brain atlases, and extended to encompass a larger goal of post-imaging analysis in 'connectome' research identifying circuits within the brain through registering input and output cell locations through atlas registration. 

*See this repository's wiki for a complete description of functionality and instructions.

This program contains the tools for analyzing sections and their cell counts with Franklin-Paxinos brain region labels as an option instead of Allen CCF. This uses data from Chon et al. Enhanced and unified anatomical labeling for a common mouse brain atlas (2020).

## Slice Histology Alignment, Registration, and Probe-Track Analysis
See this bioRxiv paper (https://www.biorxiv.org/content/early/2018/10/19/447995) for a greater understanding of the functionality of SHARP-Track, which SHARCQ and its GUI was developed from. SHARCQ provides an intuitive GUI for using many of SHARP-Track's functions to interact with the Allen Mouse Brain Atlas, and retains using a point and click method of common landmarks to register asymmetric or warped brain sections - and now their fluorescently labeled cell locations - to the atlas.

## Source
© 2015 Allen Institute for Brain Science. Allen Mouse Brain Atlas (2015) with region annotations (2017).
Available from: http://download.alleninstitute.org/informatics-archive/current-release/mouse_ccf/annotation/

See Allen Mouse Common Coordinate Framework Technical White Paper for details
http://help.brain-map.org/download/attachments/8323525/Mouse_Common_Coordinate_Framework.pdf?version=3&modificationDate=1508178848279&api=v2
