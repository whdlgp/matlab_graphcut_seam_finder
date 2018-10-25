function n = normL2(A, B)
    tmp = double(A) - double(B);
    tmp = tmp.^2;
    n = sum(tmp);
end