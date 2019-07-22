%% Calculate the range of four targets with beat frequencies: [0 MHz, 1.1 MHz, 13 MHz, 24 MHz].

% Define our radar system requirements
d_resolution = 1;  % Required resolution in meters (m)
max_range = 300;  % Required max range in meters (m)

% Find the Bsweep of chirp for 1 m resolution
c = 3*10^8;  % Speed of light in meters per second (m/s)
Bsweep = c / (2 * d_resolution);

% Calculate the chirp time based on the Radar's Max Range
MAGIC_NUMBER = 5.5;
Ts = MAGIC_NUMBER * 2 * max_range / c; 

% Define the frequency shifts 
beat_frequencies = [0, 1.1, 13, 24] .* 1e6;
calculated_range = c * Ts * beat_frequencies / (2 * Bsweep);

% Display the calculated range
disp(calculated_range);