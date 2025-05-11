import csv
from openpyxl import Workbook
from openpyxl.utils import get_column_letter
import matplotlib.pyplot as plt


def create_csv(times_sorted, files_sorted, outFilename = "compilation_profiling_report.csv"):
    with open(outFilename, mode='w', newline='') as file:

        # Slower compiletimes at top!
        times_sorted.reverse()
        files_sorted.reverse()

        writer = csv.writer(file)
        writer.writerow(['Times (s)', 'Source file'])
        writer.writerows(zip(times_sorted, files_sorted))
        print(f"CSV file saved as {outFilename}")


def create_excel(times_sorted, files_sorted, outFilename = "compilation_profiling_report.xlsx"):
    # Create a new workbook and select the active worksheet
    wb = Workbook()
    ws = wb.active

    ws.append(['Times (s)', 'Source file'])

    # Slower compiletimes at top!
    times_sorted.reverse()
    files_sorted.reverse()

    # Write data rows
    for time, file in zip(times_sorted, files_sorted):
        ws.append([time, file])

    # Adjust column widths
    # Set width for the "Times" column (column A)
    ws.column_dimensions['A'].width = 15

    # Set width for the "Files" column (column B)
    max_file_length = max(len(file) for file in files_sorted)
    padding = 2
    ws.column_dimensions['B'].width = max_file_length + padding

    wb.save(outFilename)
    print(f"Excel file saved as {outFilename}")


# TODO: work on this
def create_plot(times, files):
    # Create a bar plot
    plt.figure(figsize=(20, 3))  # width:20, height:3

    plt.barh(files, times, color='skyblue')  # Horizontal bars
    plt.ylabel('Files')
    plt.xlabel('Compilation Time (seconds)')
    plt.yticks(fontsize=8)  # Adjust y-axis label font size

    n = 6 # how many to skip
    plt.xticks(range(0, len(times), n), [times[i] for i in range(0, len(files), n)],  fontsize=8)
    plt.tick_params(axis='y', which='both', pad=50)


    # Increase spacing between y-axis labels
    plt.subplots_adjust(left=0.2)  # Increase left margin to make room for labels

    # adjust spacing and margins
    """
    plt.gca().margins(x=0)
    plt.gcf().canvas.draw()
    tl = plt.gca().get_xticklabels()
    maxsize = max([t.get_window_extent().width for t in tl])
    m = 0.2 # inch margin
    s = maxsize / plt.gcf().dpi * num_files + 2 * m
    margin = m / plt.gcf().get_size_inches()[0]
    plt.gcf().subplots_adjust(left=margin, right=1. - margin)
    plt.gcf().set_size_inches(s, plt.gcf().get_size_inches()[1])
    """

    plt.subplots_adjust(left=0.2, bottom=0.1, top=0.95)

    #plt.savefig(__file__+".png")
    #plt.show()


if __name__=="__main__":
    raise RuntimeError("This module is not intended to be run directly. Please run 'profile_compilation.py' instead.")
