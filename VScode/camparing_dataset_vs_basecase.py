import os
import numpy as np
import tensorflow as tf
import matplotlib.pyplot as plt
from scipy.interpolate import interp1d

def load_data(directory, desired_end_time, desired_time_steps):
    inputs = []
    outputs_efield_freq = []  # For the efield_vs_freq model
    outputs_efield_time = []  # For the efield_vs_time model
    outputs_efield_time_unfiltered = []  # For debugging
    time_intervals = []  # For debugging
    outputs_impedance_freq = []  # For the impedance_vs_freq model
    # Define common time points for all samples in efield_vs_time
    common_time_points = np.linspace(0, desired_end_time, desired_time_steps)
    
    # List all model directories
    model_dirs = [d for d in os.listdir(directory) if os.path.isdir(os.path.join(directory, d))]

    # Now, let's read the frequencies just once:
    sample_file_path = os.path.join(directory, model_dirs[0], f'efield_vs_freq{"".join(filter(str.isdigit, model_dirs[0]))}.txt')
    with open(sample_file_path, 'r') as file:
        freq = [float(line.split()[0]) for line in file.readlines()[2:1003]]  # Read frequencies

    for model_dir in model_dirs:
        model_path = os.path.join(directory, model_dir)
        # Extract the model number from the directory name
        model_number = ''.join(filter(str.isdigit, model_dir))
        
        # Load input data
        input_file_path = os.path.join(model_path, f'geometric_input{model_number}.txt')
        with open(input_file_path, 'r') as file:
            input_data = [float(line.strip()) for line in file.readlines()]
            inputs.append(input_data)
        
        # Define the output filenames with model_number
        output_filenames = {
            'efield_vs_freq': f'efield_vs_freq{model_number}.txt',
            'efield_vs_time': f'efield_vs_time{model_number}.txt',
            'impedance_vs_freq': f'impedance_vs_freq{model_number}.txt',
        }
        
        # Load output data
        for key, filename in output_filenames.items():
            file_path = os.path.join(model_path, filename)
            with open(file_path, 'r') as file:
                if key == 'efield_vs_freq':
                    data = [float(line.split()[1]) for line in file.readlines()[2:1003]]  # Skip first two lines
                    outputs_efield_freq.append(data)
                elif key == 'efield_vs_time':
                    lines = file.readlines()[2:250]  # Adjusted to read the file lines just once
                    time_interval = [float(line.split()[0]) for line in lines]
                    data = [float(line.split()[1]) for line in lines]
                    # Interpolate
                    interpolator = interp1d(time_interval, data, kind='linear', fill_value='extrapolate')
                    interpolated_data = interpolator(common_time_points)
                    outputs_efield_time.append(interpolated_data)
                elif key == 'impedance_vs_freq':
                    data = [float(line.split()[1]) for line in file.readlines()[102:1003]]  # Skip first two lines
                    outputs_impedance_freq.append(data)

    return np.array(inputs), np.array(outputs_efield_freq), np.array(outputs_efield_time), np.array(outputs_impedance_freq), np.array(freq)

def load_base_case_data(efield_time_path, efield_freq_path, desired_end_time, desired_time_steps):
    # For the efield_vs_time data
    with open(efield_time_path, 'r') as file:
        lines = file.readlines()[3:251]  # Assuming the format is similar
        time_interval = [float(line.split()[0]) for line in lines]
        efield_time_data = [float(line.split()[1]) for line in lines]
        
    # Interpolate the efield_vs_time data
    common_time_points = np.linspace(0, desired_end_time, desired_time_steps)
    interpolator = interp1d(time_interval, efield_time_data, kind='linear', fill_value='extrapolate')
    interpolated_efield_time_data = interpolator(common_time_points)
    
    # For the efield_vs_freq data
    with open(efield_freq_path, 'r') as file:
        freq_and_efield_freq_data = [line.split() for line in file.readlines()[3:1004]]
        efield_freq_data = [float(line[1]) for line in freq_and_efield_freq_data]
    
    return interpolated_efield_time_data, efield_freq_data

directory = r'C:\Users\addkbr\Desktop\Bicone_Studies\500Mgz_bicone_random_lens_sims'
efield_time_path = r'C:\Users\addkbr\Desktop\Bicone_Studies\500Mhz_bicone_base_cases\500Mhz_bicone_no_collar_base_case\efield_vs_time_base_case.txt'
efield_freq_path = r'C:\Users\addkbr\Desktop\Bicone_Studies\500Mhz_bicone_base_cases\500Mhz_bicone_no_collar_base_case\efield_vs_freq_base_case.txt'
desired_end_time = 12
desired_time_steps = 300
inputs, outputs_efield_freq, outputs_efield_time, outputs_impedance_freq, frequencies  = load_data(directory, desired_end_time, desired_time_steps)

# Task A: Find the sample with the largest peak-to-peak value in outputs_efield_time
peak_to_peak_values_with_indices = []

for index, sample in enumerate(outputs_efield_time):
    max_value = np.max(sample)
    min_value = np.min(sample)
    peak_to_peak_value = max_value + abs(min_value)
    peak_to_peak_values_with_indices.append((peak_to_peak_value, index))

# Sort by the peak-to-peak value, then get the last item (largest)
largest_peak_to_peak, sample_index_a = max(peak_to_peak_values_with_indices, key=lambda x: x[0])
print(f'Largest peak-to-peak value in the data set: {round(largest_peak_to_peak)} V/m, Sample Index: {sample_index_a}')

# Task B: Find the largest value at the frequency closest to 5 for all samples in outputs_efield_freq, along with the sample index

# Find the index of the frequency closest to 5
target_frequency = 5  # Assuming the frequency units are such that this makes sense (e.g., GHz)
closest_frequency_index = np.abs(np.array(frequencies) - target_frequency).argmin()

max_values_at_closest_frequency_with_indices = []

for index, sample in enumerate(outputs_efield_freq):
    value_at_closest_frequency = sample[closest_frequency_index]
    max_values_at_closest_frequency_with_indices.append((value_at_closest_frequency, index))

# Sort by the value at the closest frequency, then get the last item (largest)
largest_value_at_closest_frequency, sample_index_b = max(max_values_at_closest_frequency_with_indices, key=lambda x: x[0])
print(f'Largest value at 5 GHz: {round(largest_value_at_closest_frequency)} Db(V/m), Sample Index: {sample_index_b}')

# Load base case data
interpolated_efield_time_data, efield_freq_data = load_base_case_data(efield_time_path, efield_freq_path, desired_end_time, desired_time_steps)

# Calculate max peak-to-peak value for the efield_vs_time data
max_value_time = np.max(interpolated_efield_time_data)
min_value_time = np.min(interpolated_efield_time_data)
peak_to_peak_value_base_case = max_value_time + abs(min_value_time)

print(f'Base Case - Largest peak-to-peak value: {round(peak_to_peak_value_base_case)} V/m')

# Find the index of the frequency closest to 5 GHz for the efield_vs_freq data
target_frequency = 5
closest_frequency_index = np.abs(np.array(frequencies) - target_frequency).argmin()
max_value_at_5ghz_base_case = efield_freq_data[closest_frequency_index]

print(f'Base Case - spectral content 5 GHz: {round(max_value_at_5ghz_base_case)} Db(V/m)')

# Plotting E-field vs Time for base case and sample_index_a
plt.figure(figsize=(12, 6))

# Plot for base case
common_time_points = np.linspace(0, desired_end_time, desired_time_steps)  # Ensure this is defined
plt.plot(common_time_points, interpolated_efield_time_data, label='Base Case', linestyle='-', marker='')

# Plot for sample_index_a
plt.plot(common_time_points, outputs_efield_time[sample_index_a], label=f'Sample Index {sample_index_a}', linestyle='--', marker='')

plt.title('E-field vs Time')
plt.xlabel('Time (ns)')
plt.ylabel('E-field (V/m)')
plt.legend()
plt.grid(True)
plt.show()

# Plotting E-field vs Frequency for base case and sample_index_b
plt.figure(figsize=(12, 6))

# Assuming frequencies are defined from the load_data or similar
plt.plot(frequencies, efield_freq_data, label='Base Case', linestyle='-', marker='')

# Plot for sample_index_b
plt.plot(frequencies, outputs_efield_freq[sample_index_b], label=f'Sample Index {sample_index_b}', linestyle='--', marker='')

plt.title('E-field vs Frequency')
plt.xlabel('Frequency (GHz)')
plt.ylabel('E-field (Db(V/m))')
plt.legend()
plt.grid(True)
plt.show()
