%%% FILENAME: mimo_transmit.m
function tx_signal = mimo_transmit(bits_list, M_k_indices, P_k_list, symbolsPerBlock, mod_orders, bits_per_symbol_map)
Nt = length(M_k_indices);
tx_signal = zeros(Nt, symbolsPerBlock);
for k = 1:Nt
    mod_idx = M_k_indices(k); M = mod_orders(mod_idx);
    bits_per_sym = bits_per_symbol_map(mod_idx);
    power_stream = P_k_list(k); tx_bits_stream = bits_list{k};
    if M > 0 && bits_per_sym > 0 && ~isempty(tx_bits_stream)
        txBits_matrix = reshape(tx_bits_stream, bits_per_sym, symbolsPerBlock);
        txSymbIndices_binary = bi2de(txBits_matrix.', 'left-msb');
        if M > 2
            gray_map = graycode_gen(bits_per_sym);
            txSymbIndices_mapped = gray_map(txSymbIndices_binary + 1);
        else
            txSymbIndices_mapped = txSymbIndices_binary;
        end
        sym_norm = zeros(symbolsPerBlock, 1);
        switch M
            case 2; sym_norm = pskmod(txSymbIndices_mapped, M);
            case 4; sym_norm = pskmod(txSymbIndices_mapped, M, pi/4, 'InputType', 'integer');
            case 16; sym_norm = qammod(txSymbIndices_mapped, M, 'UnitAveragePower', true, 'InputType', 'integer');
            case 64; sym_norm = qammod(txSymbIndices_mapped, M, 'UnitAveragePower', true, 'InputType', 'integer');
        end
        tx_signal(k, :) = sym_norm.' * sqrt(power_stream);
    else
        tx_signal(k, :) = zeros(1, symbolsPerBlock);
    end
end
end