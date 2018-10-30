function n = normL2(varargin)
    if nargin==2
    A=varargin{1};
    B=varargin{2};
    tmp = double(A) - double(B);
    tmp = tmp.^2;
    n = sum(tmp);
    end
    
    if nargin==1
    A=varargin{1};
    tmp = double(A).^2;
    n = sum(tmp);
    end
end