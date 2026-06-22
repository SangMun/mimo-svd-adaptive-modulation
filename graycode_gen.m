%%% FILENAME: graycode_gen.m
function gray_code = graycode_gen(k)
% k 비트 Gray 코드를 십진수 값으로 생성하는 함수
    if k == 0
        gray_code = 0;
        return;
    end
    if k == 1
        gray_code = [0; 1];
    else
        prev_gray = graycode_gen(k-1);
        reflected_gray = flipud(prev_gray); % 이전 코드 순서를 뒤집음
        % 뒤집은 코드에 2^(k-1)을 더하여 상위 비트가 1인 부분 생성
        gray_code = [prev_gray; reflected_gray + 2^(k-1)];
    end
end