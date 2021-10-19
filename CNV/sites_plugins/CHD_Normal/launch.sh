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

ZIP_DIR="${PLUGIN_OUT_RESULTS_DIR}/ZIP"
mkdir -p ${ZIP_DIR}

perl ${Aneuploid} ${PLUGIN_OUT_BAM_DIR} ${PLUGIN_OUT_MAP_BAM_DIR} ${PLUGIN_OUT_RESULTS_DIR} ${DIRNAME}

Zip="${DIRNAME}/zip.pl"
perl ${Zip} ${ANALYSIS_DIR} ${PLUGIN_OUT_RESULTS_DIR} ${DIRNAME}

#commit 10c3f3a47e4bb850c91109f8b37f1259352a8b22
