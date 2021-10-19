#!/bin/bash
# Copyright (C) 2015 BaseCare Inc. All Rights Reserved

#MAJOR_BLOCK
VERSION="1.0"


# ===================================================
# Plugin initialization
# ===================================================

# Make sure it is empty
if [ -f ${TSP_FILEPATH_PLUGIN_DIR} ]; then
    run "rm -rf ${TSP_FILEPATH_PLUGIN_DIR}";
fi

PLUGIN_OUT_BAM_DIR="${ANALYSIS_DIR}/basecaller_results";
PLUGIN_OUT_MAP_BAM_DIR=${ANALYSIS_DIR};
PLUGIN_OUT_RESULTS_DIR=${RESULTS_DIR};

Aneuploid="${DIRNAME}/parallel_computation_noninvasion.pl"
Mapping="${DIRNAME}/MAPPING"

perl ${Aneuploid} ${PLUGIN_OUT_BAM_DIR} ${PLUGIN_OUT_MAP_BAM_DIR} ${PLUGIN_OUT_RESULTS_DIR} ${Mapping}

ZIP_DIR="${PLUGIN_OUT_RESULTS_DIR}/ZIP"
mkdir -p ${ZIP_DIR}

Zip="${Mapping}/zip.pl"
perl ${Zip} ${ANALYSIS_DIR} ${PLUGIN_OUT_RESULTS_DIR} ${Mapping}

