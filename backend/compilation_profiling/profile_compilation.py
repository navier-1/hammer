#!/usr/bin/env python3
import sys

from ExportProfilationData import *
from DataHandlingUtils import *

# TODO:
# def extract_modules_and_times(node, modules, times)

# TODO:
# da togliere la conversione dei numeri, basta che accedo ad $area ed è già formattato

if __name__=="__main__":

    if len(sys.argv) != 2:
        raise RuntimeError("Usage: profile_compilation.py <JSON RAW DATABASE>")

    raw_data_file = sys.argv[1]

    f = open(raw_data_file, 'r')
    data = json.load(f)

    # Start recursive extraction from the root of the data
    files = []
    times = []
    extract_files_and_times(data, files, times)
    if len(files) != len(times):
        raise RuntimeError("Files and times arrays have different sizes; check the json file to see what was different.")

    num_files = len(files)

    times_sorted, files_sorted = sort_based_on_time(times, files)

    create_excel(times_sorted, files_sorted)
    exit(0)




