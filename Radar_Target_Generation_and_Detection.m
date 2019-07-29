%% Radar Target Generation and Detection
% Udacity Sensor Fusion, Project 4
% Dylan Walker Brown

clear; close all; clc;

%% Physical constants

% Let speed of light = 3e8
c = 3e8;

%% Radar specifications 

% Frequency of operation = 77 GHz
fc = 77e9;  % Carrier frequency, Hz

% Max range = 200 m
maxRange = 200;

% Range resolution = 1 m
rangeResolution = 1;

% Max velocity = 100 m/s
maxVelocity = 100;

% In general, for an FMCW radar system, the sweep time should be at least
% five to six times the round trip time.
rttScale = 5.5;

%% User defined range and velocity of simulated target

R = 110;  % Initial position
v = -20;  % Initial velocity, remains contant

%% FMCW waveform generation

% Design the FMCW waveform by giving the specs of each of its parameters:
% calculate the chirp's bandwidth (B), time (Tchirp), and slope (slope).
B = c / (2 * rangeResolution);
Tchirp = rttScale * (2 * maxRange / c);  % scale factor on round-trip time 
slope =  B / Tchirp;
                                                          
% The number of chirps in one sequence. It's ideal to have 2^value for ease
% of running FFT for Doppler estimation. 
Nd = 128;  % # of doppler cells OR # of sent periods % number of chirps

% The number of samples on each chirp. 
Nr = 1024;  % for length of time OR # of range cells

% Timestamp for running the displacement scenario for every sample.
t = linspace(0, Nd * Tchirp, Nr * Nd); % total time for samples
L = Nr * Nd;

% Creating vectors for Tx, Rx, and Mix based on the total samples input.
Tx = zeros(1, length(t));  % transmitted signal
Rx = zeros(1, length(t));  % received signal
Mix = zeros(1, length(t));  % beat signal

% Similar vectors for range_covered and time delay.
r_t = zeros(1, length(t));
td = zeros(1, length(t));

%% Signal generation and moving target simulation

% For each time stamp update the range of the target for constant velocity. 
for i = 1:length(t)

    % Time delay for round trip on this iteration, given constant velocity.
    tau = (R + t(i) * v) / c;  % seconds
    
    % For each sample we need update the transmitted and received signal. 
    Tx(i) = cos(2 * pi * (fc * t(i) + slope * t(i)^2 / 2));
    Rx(i) = cos(2 * pi * (fc * (t(i) - tau) + slope * (t(i) - tau)^2 / 2));
    
    % Now by mixing the transmit and receive, generate the beat signal by
    % element-wise matrix multiplication of the tx/rx signals.
    Mix(i) = Tx(i) * Rx(i);
end

%% Range measurement

% Reshape the vector into a Nr x Nd array. Nr and Nd here would also define
% the size of range and Doppler FFT respectively.
beat = reshape(Mix, [Nr, Nd]);

% Run FFT on the beat signal along range bins dimension (Nr) and normalize.
signal_fft = fft(beat) / Nr;

% Take the absolute value of FFT output
abs_fft = abs(signal_fft);

% Output of FFT is a double sided signal, but we are interested in only one
% side of the spectrum. Hence we throw out half of the samples.
one_side_fft = abs_fft(1 : Nr / 2);

% Plotting the range using the output of first FFT
figure('Name', 'Range from first FFT');
f = Nr / length(one_side_fft) * (0 : (Nr / 2 - 1));
plot(f, one_side_fft);
axis([0 200 0 0.5]);

%% Range Doppler response

% The 2D FFT implementation is already provided here. This will run a 2DFFT
% on the mixed signal (beat signal) output and generate a range doppler
% map. You will implement CFAR on the generated RDM.

% Range Doppler Map Generation

% The output of the 2D FFT is an image that has reponse in the range and
% doppler FFT bins. So, it is important to convert the axis from bin sizes
% to range and doppler based on their Mix values.

Mix = reshape(Mix, [Nr Nd]);

% 2D FFT using the FFT size for both dimensions.
sig_fft2 = fft2(Mix, Nr, Nd);

% Taking just one side of signal from Range dimension.
sig_fft2 = sig_fft2(1 : Nr/2, 1 : Nd);
sig_fft2 = fftshift(sig_fft2);
RDM = abs(sig_fft2);
RDM = 10 * log10(RDM);

% Use the surf function to plot the output of 2D FFT as a 3D surface.
doppler_axis = linspace(-100, 100, Nd);
range_axis = linspace(-200, 200, Nr/2) * (Nr/2 / 400);
figure('Name', '2D FFT range Doppler response');
surf(doppler_axis, range_axis, RDM);

%% CFAR implementation

% Slide window through the complete range Doppler map

% Select the number of training cells in both the dimensions.
Tr = 12;  % Training (range dimension)
Td = 3;  % Training cells (doppler dimension)

% Select the number of guard cells in both dimensions around the Cell Under 
% Test (CUT) for accurate estimation.
Gr = 4;  % Guard cells (range dimension)
Gd = 1;  % Guard cells (doppler dimension)

% Offset the threshold by SNR value in dB
offset = 15;

% Calculate the total number of training and guard cells
N_guard = (2 * Gr + 1) * (2 * Gd + 1) - 1;  % Remove CUT
N_training = (2 * Tr + 2 * Gr + 1) * (2 * Td + 2 * Gd + 1) - (N_guard + 1);

% Create a vector to store noise_level for each iteration on training cells
% noise_level = zeros(1,1);

% Design a loop such that it slides the CUT across range doppler map by
% giving margins at the edges for training and guard cells. For every
% iteration sum the signal level within all the training cells. To sum
% convert the value from logarithmic to linear using the db2pow function.
% Average the summed values for all of the training cells used. After
% averaging convert it back to logarithimic using pow2db. Further, add the
% offset to it to determine the threshold. Next, compare the signal under
% CUT with this threshold. If the CUT level > threshold assign it a value
% of 1, else equate it to 0.

CFAR = zeros(size(RDM));

% Use RDM[x,y] from the output of 2D FFT above for implementing CFAR
for range_index = Tr + Gr + 1 : Nr/2 - Tr - Gr
    for doppler_index = Td + Gd + 1 : Nd - Td - Gd
        % Slice the entire window
        training = RDM(range_index - Tr - Gr : range_index + Tr + Gr, ...
                       doppler_index - Td - Gd : doppler_index + Td + Gd);
        % Set all non-training cells to zero
        training(range_index - Gr : range_index + Gr, ...
                 doppler_index - Gd : doppler_index + Gd) = 0;
        % Convert decibel measurements to power
        training = db2pow(training);
        % Calculate the training mean
        training = sum(training) / N_training;
        % Revert average power to decibels
        training = pow2db(training);
        % Use the offset to determine the SNR threshold
        threshold = training + offset;
        % Apply the threshold to the CUT
        if RDM(range_index, doppler_index) > threshold
            CFAR(range_index, doppler_index) = 1;
        end
    end
end

% The process above will generate a thresholded block, which is smaller 
% than the Range Doppler Map as the CUT cannot be located at the edges of
% the matrix. Hence, a few cells will not be thresholded. To keep the map
% size the same, set those values to 0.

% Display the CFAR output using the surf function as we did for RDM above.
figure('Name', '2D CFAR applied to range doppler map (RDM)');
surf(doppler_axis, range_axis, CFAR);
colorbar;
