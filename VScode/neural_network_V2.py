"""
Created on Sat Mar 30 03:22:54 2024

@author: addkbr
"""


import os
import numpy as np
import tensorflow as tf
import matplotlib.pyplot as plt
from scipy.interpolate import interp1d
import pandas as pd

def load_data(directory, desired_end_time, desired_time_steps, efield_freq_bias):
    inputs = []
    outputs_efield_freq = []
    outputs_efield_time = []
    common_time_points = np.linspace(0, desired_end_time, desired_time_steps)
    
    model_dirs = [d for d in os.listdir(directory) if os.path.isdir(os.path.join(directory, d))]
    sample_file_path = os.path.join(directory, model_dirs[0], f'efield_vs_freq{"".join(filter(str.isdigit, model_dirs[0]))}.txt')
    with open(sample_file_path, 'r') as file:
        freq = [float(line.split()[0]) for line in file.readlines()[2:1003]]

    for model_dir in model_dirs:
        model_path = os.path.join(directory, model_dir)
        model_number = ''.join(filter(str.isdigit, model_dir))
        
        input_file_path = os.path.join(model_path, f'geometric_input{model_number}.txt')
        with open(input_file_path, 'r') as file:
            input_data = [float(line.strip()) for line in file.readlines()]
            if len(input_data) < 1890:
                continue
            inputs.append(input_data)
        
        output_filenames = {
            'efield_vs_freq': f'efield_vs_freq{model_number}.txt',
            'efield_vs_time': f'efield_vs_time{model_number}.txt',
        }
        
        for key, filename in output_filenames.items():
            file_path = os.path.join(model_path, filename)
            with open(file_path, 'r') as file:
                if key == 'efield_vs_freq':
                    data = [efield_freq_bias * float(line.split()[1]) for line in file.readlines()[2:1003]]
                    outputs_efield_freq.append(data)
                elif key == 'efield_vs_time':
                    lines = file.readlines()[2:250]
                    time_interval = [float(line.split()[0]) for line in lines]
                    data = [float(line.split()[1]) for line in lines]
                    interpolator = interp1d(time_interval, data, kind='linear', fill_value='extrapolate')
                    interpolated_data = interpolator(common_time_points)
                    outputs_efield_time.append(interpolated_data)
                    
    return np.array(inputs), np.array(outputs_efield_freq), np.array(outputs_efield_time), np.array(freq)

def build_model(input_shape, output_shape, model_config):
    model = tf.keras.Sequential(name=model_config['name'])
    model.add(tf.keras.layers.InputLayer(input_shape=(input_shape,)))
    for layer_config in model_config['layers']:
        reg = tf.keras.regularizers.l1(float(layer_config.get('l1_reg', 0.0)))  # Convert l1_reg to float
        model.add(tf.keras.layers.Dense(layer_config['units'], activation=layer_config['activation'], kernel_regularizer=reg))
        if layer_config.get('batch_norm', False):
            model.add(tf.keras.layers.BatchNormalization())
        if 'dropout_rate' in layer_config:
            model.add(tf.keras.layers.Dropout(layer_config['dropout_rate']))
    model.add(tf.keras.layers.Dense(output_shape))
    
    optimizer_options = {'sgd': tf.keras.optimizers.SGD, 'adam': tf.keras.optimizers.Adam}
    optimizer = optimizer_options[model_config['optimizer']](**model_config.get('optimizer_config', {'learning_rate': 0.001}))
    
    model.compile(optimizer=optimizer, loss=model_config['loss'], metrics=['mae'])
    return model

def plot_model_history(model_name, history, key ):
    plt.figure(figsize=(10, 5))
    plt.plot(history.epoch, history.history['loss'], label=model_name.title() + ' Train', color='blue')
    plt.plot(history.epoch, history.history['val_'+'loss'], label=model_name.title() + ' Val', color='red')
    plt.title(f'Training and Validation {key}')
    plt.xlabel('Epochs')
    plt.ylabel(key)
    plt.legend()
    plt.show()

def validation_mse_500_mhz(model, inputs, true_outputs, sample_index=56):
    validation_inputs = inputs[int(0.8 * len(inputs)):]
    validation_outputs = true_outputs[int(0.8 * len(inputs)):]
    predictions = model.predict(validation_inputs)
    mse = tf.keras.losses.MeanSquaredError()
    mse_value = mse(validation_outputs[:, sample_index], predictions[:, sample_index]).numpy()
    true_mean = np.mean(validation_outputs[:, sample_index])
    percent_mse = (mse_value / true_mean**2) * 100
    return mse_value, percent_mse

def peak_to_peak_mse(model, inputs, true_outputs):
    validation_inputs = inputs[int(0.8 * len(inputs)):]
    validation_outputs = true_outputs[int(0.8 * len(inputs)):]
    predictions = model.predict(validation_inputs)
    
    # Calculating the difference between max and min peaks
    peak_to_peak_true = np.max(validation_outputs, axis=1) - np.min(validation_outputs, axis=1)
    peak_to_peak_pred = np.max(predictions, axis=1) - np.min(predictions, axis=1)
    
    mse = tf.keras.losses.MeanSquaredError()
    mse_value = mse(peak_to_peak_true, peak_to_peak_pred).numpy()
    true_mean = np.mean(peak_to_peak_true)
    percent_mse = (mse_value / true_mean**2) * 100 if true_mean != 0 else float('inf')  # Handle division by zero
    
    return mse_value, percent_mse

def plot_val_mae_comparisons_last_epoch(histories, model_names):
    plt.figure(figsize=(10, 5))
    for model_name, history in histories:
        last_epoch_val_mae = history.history['val_mae'][-1]
        plt.bar(model_name, last_epoch_val_mae, label=model_name)
    plt.title('Last Epoch Validation MAE Comparison')
    plt.xlabel('Model')
    plt.ylabel('Last Epoch Validation MAE (V/mHz * 10^4)')
    plt.xticks(rotation=45)
    plt.legend()
    plt.show()

def plot_sample_comparison(models, inputs, true_outputs, frequencies, time_points, sample_index):
    for i, model in enumerate(models):
        predictions = model.predict(np.expand_dims(inputs[sample_index], axis=0))[0]
        if i == 0:
            x_data = frequencies
            xlabel = 'Frequency (GHz)'
            plt.figure(figsize=(12, 6))
            plt.plot(x_data, true_outputs[i][sample_index], label='True Output', marker='o')
            plt.plot(x_data, predictions, label='Predicted Output', linestyle='--', marker='x')
            plt.title(f'{model.name} - True vs. Predicted FFT')
            plt.xlabel(xlabel)
            plt.ylabel('Efield (V/mHz * 10^4)')
            plt.legend()
            plt.show()
        if i == 1:
            x_data = time_points
            xlabel = 'Time (ns)'
            plt.figure(figsize=(12, 6))
            plt.plot(x_data, true_outputs[i][sample_index], label='True Output', marker='o')
            plt.plot(x_data, predictions, label='Predicted Output', linestyle='--', marker='x')
            plt.title(f'{model.name} - True vs. Predicted Efield Vs Time')
            plt.xlabel(xlabel)
            plt.ylabel('Efield (V/m)')
            plt.legend()
            plt.show()
        if i == 2:
            x_data = frequencies[100:]
            xlabel = 'Frequency'
        
       
directory = r'C:\Users\addkbr\Desktop\Bicone_Studies\500Mgz_bicone_random_lens_sims'
desired_end_time = 12
desired_time_steps = 300
efield_freq_bias = 10000
inputs, outputs_efield_freq, outputs_efield_time, frequencies = load_data(directory, desired_end_time, desired_time_steps, efield_freq_bias)

# Define models configurations
model_configs = [
    {
        'name': 'model_basic',
        'layers': [
            {'units': 4500, 'activation': 'relu'},
            {'units': 2250, 'activation': 'relu'},
        ],
        'optimizer': 'adam',
        'loss': 'mse'
    },
    {
        'name': 'model_deep_l1_reg_elu',
        'layers': [
            {'units': 3000, 'activation': 'elu', 'l1_reg': 0.01},
            {'units': 1500, 'activation': 'elu', 'l1_reg': 0.01},
            {'units': 750, 'activation': 'elu', 'l1_reg': 0.01},
        ],
        'optimizer': 'adam',
        'loss': 'mse'
    },
    {
        'name': 'model_wide',
        'layers': [
            {'units': 6000, 'activation': 'relu'},
            {'units': 3000, 'activation': 'relu'},
        ],
        'optimizer': 'adam',
        'loss': 'mse'
    },
    {
        'name': 'model_elu_activation',
        'layers': [
            {'units': 4500, 'activation': 'elu'},
            {'units': 2250, 'activation': 'elu'},
        ],
        'optimizer': 'adam',
        'loss': 'mse'
    },
    {
        'name': 'model_sgd_optimizer',
        'layers': [
            {'units': 4500, 'activation': 'relu'},
            {'units': 2250, 'activation': 'relu'},
        ],
        'optimizer': 'sgd',
        'optimizer_config': {'learning_rate': 0.01},
        'loss': 'mse'
    },
    {
        'name': 'model_batchnorm',
        'layers': [
            {'units': 4500, 'activation': 'relu', 'batch_norm': True},
            {'units': 2250, 'activation': 'relu', 'batch_norm': True},
        ],
        'optimizer': 'adam',
        'loss': 'mse'
    },
    {
        'name': 'model_l1_regularization',
        'layers': [
            {'units': 4500, 'activation': 'relu', 'l1_reg': 0.01},
            {'units': 2250, 'activation': 'relu', 'l1_reg': 0.01},
        ],
        'optimizer': 'adam',
        'loss': 'mse'
    }
]



# Initialize lists to store models and histories for different outputs
models_efield_freq, histories_efield_freq = [], []
models_efield_time, histories_efield_time = [], []

# Define the time points for the efield_vs_time plot
time_points = np.linspace(0, desired_end_time, desired_time_steps)

# Select a random sample index from the data
sample_index = np.random.randint(low=0, high=inputs.shape[0])

# Train models
for config in model_configs:
    model_freq = build_model(1890, 1001, config)
    history_freq = model_freq.fit(inputs, outputs_efield_freq, epochs=10, validation_split=0.2)
    models_efield_freq.append(model_freq)
    histories_efield_freq.append(history_freq)
    
    model_time = build_model(1890, 300, config)
    history_time = model_time.fit(inputs, outputs_efield_time, epochs=10, validation_split=0.2)
    models_efield_time.append(model_time)
    histories_efield_time.append(history_time)

    plot_model_history(model_freq.name, history_freq, 'MAE (V/mHz * 10^4)')
    plot_model_history(model_time.name, history_time, 'MAE (V/m)')
    # Call the plotting function with all models and their respective outputs
    plot_sample_comparison(
        [model_freq, model_time],
        inputs,
        [outputs_efield_freq, outputs_efield_time],
        frequencies,
        time_points,
        sample_index
        )

# Metrics tables initialization
metrics_table_freq = pd.DataFrame(columns=['Model Name', 'Val MAE Last Epoch', 'MSE @ 500 MHz', '% MSE @ 500 MHz'])
metrics_table_time = pd.DataFrame(columns=['Model Name', 'Val MAE Last Epoch', 'P2P MSE', '% P2P MSE'])

rows_freq = []
rows_time = []

for model_freq, history_freq, model_time, history_time in zip(models_efield_freq, histories_efield_freq, models_efield_time, histories_efield_time):
    last_val_mae_freq = history_freq.history['val_mae'][-1]
    mse_500_mhz, percent_mse_500_mhz = validation_mse_500_mhz(model_freq, inputs, outputs_efield_freq)
    rows_freq.append({
        'Model Name': model_freq.name,
        'Val MAE Last Epoch': last_val_mae_freq,
        'MSE @ 500 MHz': mse_500_mhz,
        '% MSE @ 500 MHz': percent_mse_500_mhz
    })

    last_val_mae_time = history_time.history['val_mae'][-1]
    peak_to_peak, percent_mse_peak_to_peak = peak_to_peak_mse(model_time, inputs, outputs_efield_time)
    rows_time.append({
        'Model Name': model_time.name,
        'Val MAE Last Epoch': last_val_mae_time,
        'P2P MSE': peak_to_peak,
        '% P2P MSE': percent_mse_peak_to_peak
    })


metrics_table_freq = pd.DataFrame(rows_freq)
metrics_table_time = pd.DataFrame(rows_time)

print("Frequency Metrics Table (V/mHz * 10^4):")
print(metrics_table_freq)
print("\nTime Metrics Table (V/m):")
print(metrics_table_time)

# Correctly prepare data for the plotting function
model_names_efield_freq = [config['name'] for config in model_configs]
model_history_pairs_freq = [(name, history) for name, history in zip(model_names_efield_freq, histories_efield_freq)]

# Call the function with the correct data
plot_val_mae_comparisons_last_epoch(model_history_pairs_freq, model_names_efield_freq)


# Directory to save models
save_directory = r'C:\Users\addkbr\Desktop\Bicone_Studies\VScode'

# Save all models for efield_freq
for model, config in zip(models_efield_freq, model_configs):
    model_filename = os.path.join(save_directory, f'model_efield_freq_2089_{config["name"]}.h5')
    model.save(model_filename)
    print(f'Saved {model_filename}')

# Save all models for efield_time
for model, config in zip(models_efield_time, model_configs):
    model_filename = os.path.join(save_directory, f'model_efield_time_2089_{config["name"]}.h5')
    model.save(model_filename)
    print(f'Saved {model_filename}')