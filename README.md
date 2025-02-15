# **Novel Dielectric Lens Optimization**

### **Project Overview**
This repository contains research and code for designing and optimizing dielectric lenses for a high-power microwave (HPM) biconical antenna operating at 500 MHz. The approach integrates **neural networks** and **genetic algorithms** to automate the lens creation process and reduce reliance on time-intensive electromagnetic simulations.

### **Repository Contents**
1. **MATLAB Folder**  
   - Scripts for random lens generation, geometry mapping, and boundary heuristics.

2. **VSCode Folder**  
   - Python scripts for training neural network models and running the genetic algorithm (GA).

3. **Summary Report on Dielectric Lens Optimization.pdf**  
   - Comprehensive research report documenting objectives, methodologies, findings, and future directions.

4. **500Mhz_bicone_no_collar.cst**  
   - CST Studio Suite model for the biconical antenna used in lens simulations.

5. **Lens Generation Demonstration.mp4**  
   - A short video showcasing the automated process of generating random dielectric lens geometries.

### **Usage Instructions**
1. **Lens Generation and Setup (MATLAB)**  
   - Generate lens geometries with MATLAB scripts.  
   - Export geometry data as text or node arrays.

2. **Neural Network and GA (VSCode)**  
   - Train neural networks to serve as surrogate models.  
   - Employ the genetic algorithm to optimize lens designs based on model predictions.

3. **Validation with CST**  
   - Use the **500Mhz_bicone_no_collar.cst** model to run final electromagnetic simulations on promising lens candidates for confirmation.

### **Key Features**
- **Automated Geometry Generation:**  
  Quickly create thousands of lens geometries with user-defined boundaries and resolution.
- **Machine Learning Integration:**  
  Accelerate design space exploration through neural network surrogates that approximate EM simulation results.
- **Evolutionary Optimization:**  
  Leverage genetic algorithms to evolve lens configurations that maximize electric field intensity near 500 MHz.

### **Contributions**
Researchers and developers are encouraged to enhance or adapt the code for related tasks, such as lens design for different frequencies or advanced ML optimization techniques. Please open an issue or submit a pull request for collaboration.

### **License**
This repository is released for research and academic purposes.

---
