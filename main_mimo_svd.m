%%% FILENAME: main_mimo_comparison.m
clc; clear; close all;

% --- 시뮬레이션 파라미터 ---
simParams.EbN0_dB_vec = 0:5:30;
simParams.numBlocks = 5000;
simParams.symbolsPerBlock = 100;

% --- MIMO 파라미터 ---
mimoParams.Nt = 4;
mimoParams.Nr = 4;
mimoParams.Nstreams = mimoParams.Nt;

% --- 적응 변조 파라미터 ---
adaptParams.mod_orders = [0, 2, 4, 16, 64];
adaptParams.bits_per_symbol_map = [0, 1, 2, 4, 6];
adaptParams.sinr_thresholds_db = [-Inf, 0, 6, 12, 20];
adaptParams.P_total = mimoParams.Nt;
adaptParams.Es_per_stream_avg = adaptParams.P_total / mimoParams.Nstreams;
adaptParams.k_avg_approx = mean(adaptParams.bits_per_symbol_map(adaptParams.bits_per_symbol_map > 0));

% --- 고정 변조 파라미터 ---
fixedParams.mod_list = {'BPSK', 'QPSK', '16QAM', '64QAM'};
fixedParams.M_map = [2, 4, 16, 64];
fixedParams.k_map = [1, 2, 4, 6];

% --- 결과 저장 변수 ---
results.ber_fixed = zeros(length(fixedParams.mod_list), length(simParams.EbN0_dB_vec));
results.thr_fixed = zeros(length(fixedParams.mod_list), length(simParams.EbN0_dB_vec));
results.ber_adapt = zeros(1, length(simParams.EbN0_dB_vec));
results.thr_adapt = zeros(1, length(simParams.EbN0_dB_vec));

% --- 시뮬레이션 루프 (Eb/N0) ---
fprintf('4x4 MIMO 비교 시뮬레이션 시작 (SVD Adaptive vs Fixed MMSE)...\n');
startTime = tic;

for i_ebn0 = 1:length(simParams.EbN0_dB_vec)
    EbN0_dB = simParams.EbN0_dB_vec(i_ebn0);
    fprintf('  Eb/N0 = %d dB\n', EbN0_dB);
    loopStartTime = tic;

    % N0 계산
    EbN0_linear = 10^(EbN0_dB/10);
    N0 = adaptParams.Es_per_stream_avg / (adaptParams.k_avg_approx * EbN0_linear);
    noiseVar = N0 / 2;

    % --- 고정 변조 시뮬레이션 (MMSE 수신기 사용) ---
    for m = 1:length(fixedParams.mod_list)
        mod_idx_fixed = find(adaptParams.mod_orders == fixedParams.M_map(m));
        k_fixed = fixedParams.k_map(m);
        total_tx_bits_fixed = 0;
        total_rx_errors_fixed = 0;
        M_k_indices_fixed = repmat(mod_idx_fixed, 1, mimoParams.Nstreams);
        P_k_list_fixed = ones(1, mimoParams.Nstreams) * adaptParams.Es_per_stream_avg;
        k_bits_per_sym_fixed = repmat(k_fixed, 1, mimoParams.Nstreams);
        
        fprintf('    Fixed %s (MMSE)...\n', fixedParams.mod_list{m});
        for i_block = 1:simParams.numBlocks
            H = generate_mimo_channel(mimoParams.Nr, mimoParams.Nt);
            block_tx_bits_list = cell(1, mimoParams.Nstreams);
            for iStream = 1:mimoParams.Nstreams
                 num_bits_stream = k_bits_per_sym_fixed(iStream) * simParams.symbolsPerBlock;
                 block_tx_bits_list{iStream} = randi([0 1], num_bits_stream, 1);
            end
            
            tx_signal = mimo_transmit(block_tx_bits_list, M_k_indices_fixed, P_k_list_fixed, simParams.symbolsPerBlock, adaptParams.mod_orders, adaptParams.bits_per_symbol_map);
            noise = sqrt(noiseVar) * (randn(mimoParams.Nr, simParams.symbolsPerBlock) + 1j*randn(mimoParams.Nr, simParams.symbolsPerBlock));
            rx_signal = H * tx_signal + noise;
            
            % *** 여기가 수정된 부분입니다: mimo_receive_mmse를 호출합니다 ***
            [rx_sym_est, G_matrix_fixed] = mimo_receive_mmse(rx_signal, H, N0);
            
            [num_errors_iter, num_bits_iter, ~] = demodulate_and_compare(rx_sym_est, block_tx_bits_list, M_k_indices_fixed, adaptParams.mod_orders, adaptParams.bits_per_symbol_map, G_matrix_fixed);
            
            total_tx_bits_fixed = total_tx_bits_fixed + num_bits_iter;
            total_rx_errors_fixed = total_rx_errors_fixed + num_errors_iter;
        end
        if total_tx_bits_fixed > 0
            results.ber_fixed(m, i_ebn0) = total_rx_errors_fixed / total_tx_bits_fixed;
            results.thr_fixed(m, i_ebn0) = mimoParams.Nstreams * k_fixed * (1 - results.ber_fixed(m, i_ebn0));
        else
            results.ber_fixed(m, i_ebn0) = NaN; results.thr_fixed(m, i_ebn0) = 0;
        end
    end

    % --- 적응 변조 시뮬레이션 (SVD 기반) ---
    total_tx_bits_adapt = 0;
    total_rx_errors_adapt = 0;
    total_throughput_bits_adapt = 0;

    fprintf('    Adaptive (SVD)...\n');
    for i_block = 1:simParams.numBlocks
        H = generate_mimo_channel(mimoParams.Nr, mimoParams.Nt);
        [M_k_indices, P_k_list, k_bits_per_sym, U, S, V] = adaptive_ctrl_svd(H, N0, adaptParams);
        block_tx_bits_list = cell(1, mimoParams.Nstreams);
        if sum(k_bits_per_sym) == 0, continue; end
        for k = 1:mimoParams.Nstreams
            num_bits_stream = k_bits_per_sym(k) * simParams.symbolsPerBlock;
            if num_bits_stream > 0, block_tx_bits_list{k} = randi([0 1], num_bits_stream, 1);
            else, block_tx_bits_list{k} = []; end
        end
        tx_signal = mimo_transmit_svd(block_tx_bits_list, M_k_indices, P_k_list, simParams.symbolsPerBlock, adaptParams.mod_orders, adaptParams.bits_per_symbol_map, V);
        noise = sqrt(noiseVar) * (randn(mimoParams.Nr, simParams.symbolsPerBlock) + 1j*randn(mimoParams.Nr, simParams.symbolsPerBlock));
        rx_signal = H * tx_signal + noise;
        rx_sym_est = mimo_receive_svd(rx_signal, U);
        [num_errors_iter, num_bits_iter, throughput_bits_iter] = demodulate_and_compare(rx_sym_est, block_tx_bits_list, M_k_indices, adaptParams.mod_orders, adaptParams.bits_per_symbol_map, S);
        total_tx_bits_adapt = total_tx_bits_adapt + num_bits_iter;
        total_rx_errors_adapt = total_rx_errors_adapt + num_errors_iter;
        total_throughput_bits_adapt = total_throughput_bits_adapt + throughput_bits_iter;
    end

    if total_tx_bits_adapt > 0, results.ber_adapt(i_ebn0) = total_rx_errors_adapt / total_tx_bits_adapt;
    else, results.ber_adapt(i_ebn0) = NaN; end
    results.thr_adapt(i_ebn0) = total_throughput_bits_adapt / (simParams.numBlocks * simParams.symbolsPerBlock);
    
    loopEndTime = toc(loopStartTime);
    fprintf('    Eb/N0 = %d dB 완료 (소요 시간: %.2f 초)\n', EbN0_dB, loopEndTime);
end

totalTime = toc(startTime);
fprintf('시뮬레이션 완료. (총 소요 시간: %.2f 초)\n', totalTime);

% --- 결과 그래프 그리기 ---
figure(1); % BER
semilogy(simParams.EbN0_dB_vec, results.ber_fixed(1,:), '-bo', 'LineWidth', 1.5, 'MarkerFaceColor', 'b'); hold on;
semilogy(simParams.EbN0_dB_vec, results.ber_fixed(2,:), '-rs', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
semilogy(simParams.EbN0_dB_vec, results.ber_fixed(3,:), '-g^', 'LineWidth', 1.5, 'MarkerFaceColor', 'g');
semilogy(simParams.EbN0_dB_vec, results.ber_fixed(4,:), '-mx', 'LineWidth', 1.5);
semilogy(simParams.EbN0_dB_vec, results.ber_adapt, '-k*', 'LineWidth', 2, 'MarkerSize', 8);
hold off;
xlabel('Average Eb/N0 (approx. dB)'); ylabel('Average Bit Error Rate (BER)');
legend('BPSK (MMSE)', 'QPSK (MMSE)', '16QAM (MMSE)', '64QAM (MMSE)', 'SVD Adaptive', 'Location', 'southwest');
title('4x4 MIMO BER');
grid on; ylim([1e-6 1]);

figure(2); % Throughput
plot(simParams.EbN0_dB_vec, results.thr_fixed(1,:), '-bo', 'LineWidth', 1.5, 'MarkerFaceColor', 'b'); hold on;
plot(simParams.EbN0_dB_vec, results.thr_fixed(2,:), '-rs', 'LineWidth', 1.5, 'MarkerFaceColor', 'r');
plot(simParams.EbN0_dB_vec, results.thr_fixed(3,:), '-g^', 'LineWidth', 1.5, 'MarkerFaceColor', 'g');
plot(simParams.EbN0_dB_vec, results.thr_fixed(4,:), '-mx', 'LineWidth', 1.5);
plot(simParams.EbN0_dB_vec, results.thr_adapt, '-k*', 'LineWidth', 2, 'MarkerSize', 8);
hold off;
xlabel('Average Eb/N0 (approx. dB)'); ylabel('Throughput (bps/Hz)');
legend('BPSK (MMSE)', 'QPSK (MMSE)', '16QAM (MMSE)', '64QAM (MMSE)', 'SVD Adaptive', 'Location', 'northwest');
title('4x4 MIMO Throughput');
grid on;
ylim([0 mimoParams.Nstreams*max(adaptParams.bits_per_symbol_map)+1]);