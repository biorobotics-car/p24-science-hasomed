
# P24Science - Matlab/Simulink Interface 

This project includes a set of MATLAB functions and a Simulink model developed by the **BioRobotics Group** at the **Center for Automation and Robotics (CAR - CSIC)**. It serves as the **final stage** in a real-time stimulation framework, responsible for sending commands to an electrical stimulation device (P24Science, Hasomed) through a serial connection.

> ⚠️ **Note**: This module does not include the stimulation decision logic. You must implement and connect that part yourself (e.g., based on other sensors or EMG devices). That would make the "Stimulation Current" vector (or any other parameter) change in real-time.

---

## 🔧 Setup Instructions

Before using the model:

### 1. Install Psychtoolbox

Required for serial communication in MATLAB.

- Use MATLAB Add-On Explorer:  
  `MathWorks > MATLAB Add-Ons > Toolboxes > Psychtoolbox-3`

- Or download it directly from:  
  [https://psychtoolbox.org/download](https://psychtoolbox.org/download)

### 2. Run the Setup Script

Psychtoolbox functions may require MATLAB paths to be correctly ordered. If you encounter path-related errors, run:

```matlab
SetupPsychtoolbox
```

### 3. Set the Serial Port

Make sure to update the COM port to match your device. To identify the correct COM port, open Device Manager and look under the "Ports (COM & LPT)" section. The device should appear as "USB Serial Port (COMx)". In `P24Science.m`, modify:

```matlab
comPortRehaStim = 'COM4';  % Change this to your device's COM port
```

---

## Simulink Integration

The Simulink model uses a **MATLAB S-Function** called `P24Science`.  
It receives stimulation parameters and sends them to the stimulator in real time.  
You must connect your own stimulation decision logic upstream.

### Inputs (to `P24Science` block):

| Port | Description                | Type    |
|------|----------------------------|---------|
| 1    | Channel activation vector  | Vector  |
| 2    | Frequency (Hz)             | Vector  |
| 3    | Duration (μs)              | Vector  |
| 4    | Current (mA)               | Vector  |

### Output:

| Port | Description                              |
|------|------------------------------------------|
| 1    | Last byte of transmitted stimulation message (for debugging/logging) |

---

## Key Functions

### `P24Science.m`

Custom MATLAB S-Function with three main phases:

- **Start**: Initializes the serial port and sets up communication.
- **Outputs**: Builds and sends a stimulation frame based on inputs.
- **Terminate**: (Currently unused, but reserved for cleanup logic.)

### `encodermid_multichannel.m`

Encodes stimulation parameters into a byte stream that conforms to the stimulator's custom protocol.

Features:
- Channel bitmask encoding
- Frequency, duration, and current encoding
- Frame headers and protocol bytes
- Special byte-stuffing (e.g., avoids `F0`, `0F`, `81`)
- Automatic checksum insertion

### `checksumdef.m`

Generates a CRC-16-CCITT checksum required by the stimulator.  
The checksum ensures data integrity.

---

## 📌 Notes

- Define the following **global variables** in the MATLAB workspace before running the model:

- `N_MUSCLES`: Number of stimulation channels (muscles). (Can be calculated as the length of a given vector generated at your previous function to decide how and when to stimulate).


---


## Troubleshooting

- **Serial port busy**: Make sure no other program is using the COM port.
- **MATLAB error about missing functions**: Re-run `SetupPsychtoolbox`.
- **No stimulation happens**: Double-check your channel vector and parameter values.

---

## 🧑‍🔬 Authors

**BioRobotics Group**  
Center for Automation and Robotics (CAR)  
CSIC - Spanish National Research Council
Tania Olmo Fajardo, PhD Student. (tania.olmo@cajal.csic.es)
Miguel Díaz Benito, internship student.

---

## 📄 License

This code is for academic and research use.  
Please cite the original authors when publishing work based on this project.
