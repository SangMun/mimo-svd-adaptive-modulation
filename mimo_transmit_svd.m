%%% FILENAME: mimo_transmit_svd.m
function tx_signal_precoded = mimo_transmit_svd(bits_list, M_k_indices, P_k_list, symbolsPerBlock, mod_orders, bits_per_symbol_map, V)
% SVD 프리코딩을 적용하는 MIMO 송신기
tx_signal_no_precoding = mimo_transmit(bits_list, M_k_indices, P_k_list, symbolsPerBlock, mod_orders, bits_per_symbol_map);
tx_signal_precoded = V * tx_signal_no_precoding;
end