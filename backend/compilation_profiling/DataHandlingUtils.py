import json



# Function to recursively extract filenames and compilation times
def extract_files_and_times(node, files, times):
    if 'name' in node and 'data' in node:

        # Extract the filename by splitting the name string
        name_parts = node['name'].split()
        if len(name_parts) != 2:
            raise RuntimeError("The script was thought to operate with a specific structure in the json file. The assumption was - the 'name' voice contains the actual name of the file and the compilation time.")

        # Identify compilation units and extract name and time.
        if name_parts[0].strip("'").endswith('.cpp.o') or name_parts[0].strip("'").endswith('.c.o'):
            if not "test" in name_parts[0]:

                filename = name_parts[0].strip("'").strip(".o")
                time = node['data'].get('$area', 0)                     # legacy: _convert_time_to_seconds(name_parts[1])
                time = round(time, 1)

                files.append(filename)
                times.append(time)

    # Recursively process children
    if 'children' in node:
        for child in node['children']:
            extract_files_and_times(child, files, times)

# Sorts times in ascending order, and the files based on the times.
def sort_based_on_time(times, files):
    # Sort based on time
    combined = list(zip(files, times)) # Combine files and times into a list of tuples
    sorted_combined = sorted(combined, key=lambda x: x[1]) # Sort the combined list based on times (ascending order)
    files_sorted, times_sorted = zip(*sorted_combined) # Unzip the sorted list back into separate files and times arrays

    # Convert tuples back to lists (if needed)
    files_sorted = list(files_sorted)
    times_sorted = list(times_sorted)

    return times_sorted, files_sorted

# TODO:
# def extract_modules_and_times(node, modules, times)

if __name__=="__main__":
    raise RuntimeError("This module is not intended to be run directly. Please run 'profile_compilation.py' instead.")

















# Legacy code

def _convert_time_to_seconds(time_str):
    if 'm' in time_str:
        # Split the string into minutes and seconds
        minutes_part, seconds_part = time_str.split('m')
        seconds = seconds_part.rstrip('s')  # Remove the 's' from the seconds part

        # Convert minutes and seconds to floats
        minutes = float(minutes_part)
        seconds = float(seconds)

        # Calculate total time in seconds
        total_seconds = minutes * 60 + seconds
    else:
        # Handle case where only seconds are present
        seconds = time_str.rstrip('s')
        total_seconds = float(seconds)

    return total_seconds
