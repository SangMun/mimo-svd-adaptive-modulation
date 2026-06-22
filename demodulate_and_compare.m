%%% FILENAME: demodulate_and_compare.m
function [num_errors, num_bits, throughput_bits] = demodulate_and_compare(sym_est_norm_list, tx_bits_list, M_k_indices, mod_orders, bits_per_symbol_map, G_matrix)
% MMSE 수신기 출력 심볼 복조 (Gray 역매핑 포함), 송신 비트와 비교

Nstreams = length(M_k_indices);
rx_bits_list = cell(1, Nstreams); 
num_errors = 0;
num_bits = 0; 

scaling_factors = diag(G_matrix); 

for k = 1:Nstreams 
    mod_idx = M_k_indices(k);
    M = mod_orders(mod_idx);
    bits_per_sym = bits_per_symbol_map(mod_idx);
    
    if M > 0 && bits_per_sym > 0 
        symbolsPerBlock = size(sym_est_norm_list, 2);
        received_symbols_unscaled = sym_est_norm_list(k, :).'; 
        
        % --- MMSE 스케일링 보상 ---
        scale_factor_k = scaling_factors(k);
        if abs(scale_factor_k) < 1e-9 
            scaled_received_symbols = received_symbols_unscaled * NaN; 
            warning('Demodulate: Scaling factor for stream %d is near zero (%.2e). Setting symbols to NaN.', k, scale_factor_k);
        else
            scaled_received_symbols = received_symbols_unscaled / scale_factor_k;
        end
        
        % 복조 (심볼 -> 정수 인덱스) - 이 인덱스는 Gray 코드 기준 위치일 수 있음
        idx_demod_gray = zeros(symbolsPerBlock, 1); % 초기화
        try
            switch M
                case 2; idx_demod_gray = pskdemod(scaled_received_symbols, M); 
                case 4; idx_demod_gray = pskdemod(scaled_received_symbols, M, pi/4, 'OutputType', 'integer'); 
                case 16; idx_demod_gray = qamdemod(scaled_received_symbols, M, 'UnitAveragePower', true, 'OutputType', 'integer'); 
                case 64; idx_demod_gray = qamdemod(scaled_received_symbols, M, 'UnitAveragePower', true, 'OutputType', 'integer'); 
            end
        catch ME
             warning('Demodulation error for stream %d (M=%d): %s. Setting index to 0.', k, M, ME.message);
             % 복조 오류 시 0번 인덱스로 처리 (또는 NaN 처리 후 아래에서 de2bi 방지)
        end
        
        % 복조된 인덱스가 유효 범위 내에 있도록 처리 
        idx_demod_gray(isnan(idx_demod_gray)) = 0; % NaN 값 처리
        idx_demod_gray(idx_demod_gray >= M) = M-1; 
        idx_demod_gray(idx_demod_gray < 0) = 0;
        
        % --- Gray 코드 역매핑 (M > 2 인 경우) ---
        if M > 2
            try % graycode_gen 함수 및 정렬 필요
                gray_map = graycode_gen(bits_per_sym); % Gray 코드 순서 생성
                % 역매핑 테이블 생성: gray_map 값을 정렬하여 원래 이진 인덱스 순서 찾기
                [~, demapping_indices] = sort(gray_map); 
                demapping_indices = demapping_indices - 1; % 0-based index로 변환
                
                % 복조된 Gray 인덱스를 원래 이진 인덱스로 변환
                idx_binary = demapping_indices(idx_demod_gray + 1); % MATLAB 1-based 인덱싱
            catch ME
                 warning('Gray code demapping failed for M=%d: %s. Using demodulated index directly.', M, ME.message);
                 idx_binary = idx_demod_gray; % 오류 시 역매핑 없이 진행
            end
        else % BPSK (M=2)
            idx_binary = idx_demod_gray;
        end

        % 정수 인덱스 -> 비트 변환
        if M > 0 
            rxBits_matrix = de2bi(idx_binary, bits_per_sym, 'left-msb'); % Nsym x k
            % 비트 순서 조정 및 벡터화 (Tx와 일치)
            rx_bits_stream = reshape(rxBits_matrix.', [], 1); % (Nsym*k) x 1
        else
            rx_bits_stream = [];
        end
        rx_bits_list{k} = rx_bits_stream;
        
        % 에러 계산
        tx_bits_stream = tx_bits_list{k};
        if ~isempty(tx_bits_stream) 
             if length(rx_bits_stream) == length(tx_bits_stream)
                num_errors = num_errors + sum(tx_bits_stream ~= rx_bits_stream);
                num_bits = num_bits + length(tx_bits_stream);
             else
                warning('Demodulate: Bit length mismatch for stream %d! Tx:%d, Rx:%d. Treating all Tx bits as errors.', k, length(tx_bits_stream), length(rx_bits_stream));
                if ~isempty(tx_bits_stream)
                    num_bits = num_bits + length(tx_bits_stream); 
                    num_errors = num_errors + length(tx_bits_stream); 
                end
             end
        elseif ~isempty(rx_bits_stream)
             warning('Demodulate: Received bits found for non-transmitted stream %d!', k);
        end
    else
         rx_bits_list{k} = []; 
         if ~isempty(tx_bits_list{k})
             warning('Demodulate: Transmitted bits found for M=0/k=0 stream %d!', k);
         end
    end
end 

throughput_bits = num_bits - num_errors; 

end

% --- Helper: graycode_gen (별도 파일 또는 여기에 포함) ---
function gray_code = graycode_gen(k)
    if k == 0, gray_code = 0; return; end
    if k == 1, gray_code = [0; 1]; return; end
    prev_gray = graycode_gen(k-1);
    reflected_gray = flipud(prev_gray);
    gray_code = [prev_gray; reflected_gray + 2^(k-1)];
end