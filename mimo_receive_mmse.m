%%% FILENAME: mimo_receive_mmse.m
function [sym_est_norm_list, G_matrix] = mimo_receive_mmse(rx_signal, H, N0)
% MIMO MMSE 수신기: 등화 수행 + 등화 이득 행렬 반환

[~, Nt] = size(H);

% MMSE 등화기 계산 (Es=1 기준)
% W = (H'H + N0*I)^-1 * H'
W_mmse = (H' * H + N0 * eye(Nt)) \ H'; % Nt x Nr

% 등화 수행 (W * y) -> 추정된 심볼
sym_est_norm = W_mmse * rx_signal; % (Nt x Nsym)

% 등화 이득 행렬 계산 G = WH (스케일링 보상용)
G_matrix = W_mmse * H; % (Nt x Nt)

% 출력 형식 맞추기
sym_est_norm_list = sym_est_norm;

end