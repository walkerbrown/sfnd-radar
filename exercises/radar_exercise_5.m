%% 2D Fast Fourier Transform (2D FFT)

% % See the doucmentation here: https://www.mathworks.com/help/matlab/ref/fft2.html
% signal  = reshape(signal, [M, N]);  % M samples and N size per sample
% signal_fft = fft2(signal, M, N);  % Take the 2D Fourier transform
% 
% % Shift zero-frequency terms to the center of the array
% signal_fft = fftshift(signal_fft);
% 
% % Convert complex values to magnitudes
% signal_fft = abs(signal_fft);
% 
% % Plot the output as a heatmap image
% imagesc(signal_fft);

%% Exercise on 2D FFT

% 2-D Transform
% The 2-D Fourier transform is useful for processing 2-D signals and other 2-D data such as images.
% Create and plot 2-D data with repeated blocks.

P = peaks(20);
X = repmat(P,[5 10]);
imagesc(X)

% Compute the 2-D Fourier transform of the data.
[M, N] = size(X);
signal_fft = fft2(X, M, N);

% Shift the zero-frequency component to the center of the output and get
% magnitudes from complex values.
signal_fft = fftshift(signal_fft);
signal_fft = abs(signal_fft);

% Plot the resulting 100-by-200 matrix, which is the same size as X.
imagesc(signal_fft)
