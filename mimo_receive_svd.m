%%% FILENAME: mimo_receive_svd.m
function sym_est_norm = mimo_receive_svd(rx_signal, U)
% SVD 컴바이너를 이용한 MIMO 수신기
sym_est_norm = U' * rx_signal; % U'는 공액 전치
end