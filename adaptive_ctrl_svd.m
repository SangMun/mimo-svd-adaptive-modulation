%%% FILENAME: adaptive_ctrl_svd.m
function [M_k_indices, P_k_list, k_bits_per_sym, U, S, V] = adaptive_ctrl_svd(H, N0, adaptParams)
% SVD 기반 적응형 제어기
[~, Nt] = size(H);
Nstreams = Nt;

% 1. SVD를 통한 채널 분리
[U, S, V] = svd(H);
lambda_k = diag(S).^2; % 채널의 Power Gain (특이값의 제곱)

% 2. 워터푸어링 적용
channel_quality_for_wp = lambda_k / N0;
P_k_list = water_pouring_on_sinr(channel_quality_for_wp, adaptParams.P_total);

% 3. 적응형 변조 선택
M_k_indices = zeros(1, Nstreams);
k_bits_per_sym = zeros(1, Nstreams);
snr_thresholds_linear = 10.^(adaptParams.sinr_thresholds_db / 10);

for k = 1:Nstreams
    if P_k_list(k) > 1e-9
        effective_snr = lambda_k(k) * P_k_list(k) / N0;
        valid_mod_idx = find(effective_snr >= snr_thresholds_linear, 1, 'last');
        if ~isempty(valid_mod_idx)
            M_k_indices(k) = valid_mod_idx;
            k_bits_per_sym(k) = adaptParams.bits_per_symbol_map(valid_mod_idx);
        else
            M_k_indices(k) = 1; k_bits_per_sym(k) = 0;
        end
    else
        M_k_indices(k) = 1; k_bits_per_sym(k) = 0;
    end
end
end