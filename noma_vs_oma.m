clc; clear; close all;

% Simulation parameters
numUsers = 2; % Number of users
numBits = 1e5; % Number of bits
SNR_dB = 0:2:20; % SNR range in dB
BER_NOMA = zeros(1, length(SNR_dB));
BER_OMA = zeros(1, length(SNR_dB));

% Power allocation for NOMA (higher power to weaker user)
alpha1 = 0.8; % Power for weaker user
alpha2 = 0.2; % Power for stronger user

% Generate random binary data
dataUser1 = randi([0 1], numBits, 1);
dataUser2 = randi([0 1], numBits, 1);

% QPSK Modulation
modData1 = pskmod(dataUser1, 4, pi/4);
modData2 = pskmod(dataUser2, 4, pi/4);

% NOMA Superposition Coding
superposedSignal = sqrt(alpha1) * modData1 + sqrt(alpha2) * modData2;

% Loop over different SNR values
for i = 1:length(SNR_dB)
    % Add Rayleigh fading
    h1 = (randn(numBits,1) + 1j*randn(numBits,1))/sqrt(2); % Channel for User 1
    h2 = (randn(numBits,1) + 1j*randn(numBits,1))/sqrt(2); % Channel for User 2
    
    % Add AWGN Noise
    noisePower = 10^(-SNR_dB(i)/10);
    noise = sqrt(noisePower/2) * (randn(numBits,1) + 1j*randn(numBits,1));
    
    % Received signals
    receivedUser1 = h1 .* superposedSignal + noise;
    receivedUser2 = h2 .* superposedSignal + noise;
    
    % Successive Interference Cancellation (SIC) at User 1
    estimatedUser2 = receivedUser1 / sqrt(alpha2); % Decode stronger user first
    decodedDataUser2 = pskdemod(estimatedUser2, 4, pi/4);
    
    % Subtract decoded signal from received signal
    decodedSignalUser1 = receivedUser1 - sqrt(alpha2) * pskmod(decodedDataUser2, 4, pi/4);
    decodedDataUser1 = pskdemod(decodedSignalUser1 / sqrt(alpha1), 4, pi/4);
    
    % OMA: Each user transmitted separately
    receivedOMA1 = h1 .* modData1 + noise;
    receivedOMA2 = h2 .* modData2 + noise;
    
    % OMA Demodulation
    decodedOMA1 = pskdemod(receivedOMA1, 4, pi/4);
    decodedOMA2 = pskdemod(receivedOMA2, 4, pi/4);
    
    % Compute BER
    BER_NOMA(i) = mean(decodedDataUser1 ~= dataUser1);
    BER_OMA(i) = mean(decodedOMA1 ~= dataUser1);
end

% Plot results
figure;
semilogy(SNR_dB, BER_NOMA, 'r-o', 'LineWidth', 2);
hold on;
semilogy(SNR_dB, BER_OMA, 'b-s', 'LineWidth', 2);
grid on;
xlabel('SNR (dB)');
ylabel('Bit Error Rate (BER)');
title('NOMA vs. OMA Performance');
legend('NOMA', 'OMA');
