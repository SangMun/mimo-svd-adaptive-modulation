%%% FILENAME: generate_mimo_channel.m
function H = generate_mimo_channel(Nr, Nt)
% Nr x Nt MIMO 채널 행렬 생성 (Spatially Independent Rayleigh)
% 각 요소는 평균 전력 1을 갖는 복소 가우시안 분포를 따름
H = (randn(Nr, Nt) + 1j*randn(Nr, Nt)) / sqrt(2);
end
