import numpy as np
import tensorflow as tf
from deap import base, creator, tools, algorithms
import random
import matplotlib.pyplot as plt

# Load trained model
model_efield_freq = tf.keras.models.load_model('model_efield_freq_model_deep_l1_reg_elu.h5')

# Define and register functions in DEAP
creator.create("FitnessMax", base.Fitness, weights=(1.0,))  # Maximizing objective
creator.create("Individual", np.ndarray, fitness=creator.FitnessMax)

toolbox = base.Toolbox()
# toolbox.register("mate", tools.cxOnePoint)
# toolbox.register("mate", tools.cxTwoPoint)
toolbox.register("mate", tools.cxUniform, indpb=0.5)
toolbox.register("select", tools.selTournament, tournsize=3)

# Fitness function
def fitness_function_efield_freq(inputs, target_freq_index=57):  # index at 500 MHz
    predictions = model_efield_freq.predict(inputs, verbose=0)  # Set verbose to 0 to suppress the progress bar
    max_values_at_target_freq = predictions[:, target_freq_index].max()
    return (max_values_at_target_freq,)

def init_individual(ind_size, selected_value):
    return [selected_value if random.random() > 0.20 else 0 for _ in range(ind_size)]

def evaluate(individual):
    individual_array = np.array(individual).reshape(1, -1)
    fitness = fitness_function_efield_freq(individual_array)[0]
    return (fitness,)

toolbox.register("evaluate", evaluate)

def run_ga_for_float(float_value, n_gen=300, pop_size=100, ind_size=1890):
    # Adjusted mutation function to enforce specific values
    def custom_mutate(individual, indpb):
        for i in range(len(individual)):
            if random.random() < indpb:
                individual[i] = 0 if individual[i] == float_value else float_value
        return (individual,)

    toolbox.register("individual", tools.initIterate, creator.Individual, lambda: init_individual(ind_size, float_value))
    toolbox.register("population", tools.initRepeat, list, toolbox.individual)
    toolbox.register("mutate", custom_mutate, indpb=0.3) # tried with .05, .1, .2,

    population = toolbox.population(n=pop_size)
    stats = tools.Statistics(lambda ind: ind.fitness.values)
    stats.register("avg", np.mean)
    stats.register("std", np.std)
    stats.register("min", np.min)
    stats.register("max", np.max)

    logbook = tools.Logbook()
    logbook.header = ["gen", "evals"] + stats.fields

    for gen in range(n_gen):
        offspring = algorithms.varAnd(population, toolbox, cxpb=0.6, mutpb=0.2)
        fits = map(toolbox.evaluate, offspring)
        for fit, ind in zip(fits, offspring):
            ind.fitness.values = fit
        population[:] = toolbox.select(offspring, len(population))
        
        record = stats.compile(population)
        logbook.record(gen=gen, evals=len(offspring), **record)

        # Print the completion percentage
        print(f"Generation {gen+1}/{n_gen} ({(gen+1)/n_gen*100:.2f}%) completed")

    best_individual = tools.selBest(population, 1)[0]
    return best_individual, best_individual.fitness.values, logbook

# # Evaluate for each float from 1.7 to 4.3
# results = {}
# for float_value in np.arange(1.7, 4.4, 0.1):
#     best_individual, best_fitness, _ = run_ga_for_float(float_value)
#     results[float_value] = best_fitness[0]
#     with open(f"best_individual_{float_value:.1f}.txt", "w") as file:
#         for value in best_individual:
#             file.write(f"{value:.1f}\n")

# Evaluate only for float 2.2
float_value = 2.2
results = {}
best_individual, best_fitness, logbook = run_ga_for_float(float_value)
results[float_value] = best_fitness[0]
with open(f"best_individual_{float_value:.1f}.txt", "w") as file:
    for value in best_individual:
        file.write(f"{value:.1f}\n")

# Identify the best overall performer
best_float = max(results, key=results.get)
best_overall_fitness = results[best_float]
print(f"The best overall performer is at float {best_float:.1f} with a fitness score of {best_overall_fitness}.")

# Extracting data from logbook
generations = [log['gen'] for log in logbook]
max_fitness = [log['max'] for log in logbook]
avg_fitness = [log['avg'] for log in logbook]
min_fitness = [log['min'] for log in logbook]

# Plotting
plt.figure(figsize=(10, 5))
plt.plot(generations, max_fitness, label='Max Fitness')
plt.plot(generations, avg_fitness, label='Average Fitness')
plt.plot(generations, min_fitness, label='Min Fitness')
plt.xlabel('Generation')
plt.ylabel('Fitness')
plt.title('GA Performance Over Generations')
plt.legend()
plt.show()