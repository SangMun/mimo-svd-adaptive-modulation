%%% FILENAME: water_pouring_on_sinr.m
function powerAlloc = water_pouring_on_sinr(sinr_lin_vector, totalPower)
    % 입력: sinr_lin_vector (추정된 각 스트림의 선형 SINR 벡터)
    %       totalPower (총 할당 전력)
    % 출력: powerAlloc (각 스트림에 할당된 전력 벡터, 1xN)

    channel_quality = sinr_lin_vector(:).'; % 행 벡터로 변환 및 복사
    channel_quality(channel_quality <= 1e-10) = 1e-10; % 0 또는 음수 방지
    inv_quality = 1 ./ channel_quality; % 품질이 나쁠수록 큰 값 (NoiseLevel 역할)

    N = length(sinr_lin_vector);
    lambda_low = 0;
    % lambda_high 초기값 설정 개선 (너무 크면 수렴 느릴 수 있음)
    lambda_high = max(inv_quality) + totalPower / N; 
    tolerance = 1e-7; % 수렴 정밀도
    maxIter = 1000; % 최대 반복 횟수
    iter = 0;

    % 이분 탐색 루프
    while (lambda_high - lambda_low) / max(lambda_high, tolerance) > tolerance && iter < maxIter
        lambda_mid = (lambda_low + lambda_high) / 2;
        % lambda_mid가 0 또는 음수가 되지 않도록 방지 (이론적으로 양수)
        if lambda_mid <= 0
             % lambda_low가 0에 매우 가까워진 경우 발생 가능
             lambda_mid = tolerance; % 매우 작은 양수값으로 설정
             % 또는 lambda_high 값에 따라 조정 필요할 수 있음
        end

        % 현재 lambda 값으로 전력 할당 계산: P_k = max(0, 1/lambda - 1/SINR_k)
        alloc = max(1/lambda_mid - inv_quality, 0);
        total_alloc = sum(alloc);

        % 이분 탐색 범위 업데이트
        if total_alloc > totalPower
            lambda_low = lambda_mid; % 더 높은 lambda 필요 (전력 줄여야 함)
        else
            lambda_high = lambda_mid; % 더 낮은 lambda 가능 (전력 늘릴 수 있음)
        end
        iter = iter + 1;
    end

    if iter == maxIter
        warning('water_pouring_on_sinr: 최대 반복 횟수(%d)에 도달했습니다. Lambda가 정확히 수렴하지 않았을 수 있습니다.', maxIter);
    end

    % 최종 워터 레벨 결정 (low와 high의 평균 또는 high 사용 등 가능)
    lambda_final = (lambda_low + lambda_high) / 2;
     if lambda_final <=0, lambda_final = tolerance; end

    % 최종 전력 할당
    powerAlloc = max(1/lambda_final - inv_quality, 0);

    % 정규화: 수치 오류로 총합이 약간 다를 수 있으므로, totalPower에 맞게 스케일 조정
    current_total_power = sum(powerAlloc);
    if current_total_power > 1e-9 % 0에 매우 가까운 경우 제외
        powerAlloc = powerAlloc * (totalPower / current_total_power);
    end
    % 할당되지 않은 빈(매우 작은 값 포함)에는 0 할당 보장
    powerAlloc(powerAlloc < 1e-9) = 0;
    powerAlloc = powerAlloc(:).'; % 최종적으로 행 벡터 확인
end