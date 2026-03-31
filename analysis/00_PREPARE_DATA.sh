#!/bin/bash
set -e

Rscript 10_create_network.R
Rscript 20_add_network_variables_largest_component.R
Rscript 21_add_network_variables_full_graph.R
