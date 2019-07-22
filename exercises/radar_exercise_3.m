%% Doppler Velocity Calculation
c = 3*10^8;  % speed of light
frequency = 77e9;  % Radar nominal frequency in Hz
fd = [3, -4.5, 11, -3] * 1e3;  % Doppler frequency shifts in Hz

% Calculate the wavelength
lambda = c / frequency;

% Calculate the velocity of the targets: fd = 2*vr/lambda
calculated_velocity = fd .* lambda ./ 2;

% Display the calculated velocity
disp(calculated_velocity);