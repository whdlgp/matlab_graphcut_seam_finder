clear;
clc;

%determin weight type
% 1 : weight with RGB pixel
% 2 : weight with RGB pixel, use gradiant method
weight_type = 1;

%weight bias for preventing zero weight
add_weight_bias = 1;

%original images and mask
% RGB
im1 = imread('im1.jpg');
im2 = imread('im2.jpg');

%im1 = imresize(im1,[100 100]);
%im2 = imresize(im2,[100 100]);

[height, width, channel] = size(im1);

vertice_size = height * width; % number of vertice without souce and sink

%number of vertex pair(number of edge)
%X axis edge, Y axis edge, source/sink edge
number_of_pair = (((width - 1) * height) + (width * (height - 1))) + (2 * height);
s = zeros(1,number_of_pair); % image graph's edge and source, sink edge
t = zeros(1,number_of_pair); % image graph's edge and source, sink edge
weight = zeros(1,number_of_pair); % image graph's edge and source, sink edge

index = 1;

% progress bar
pb = waitbar(0,'Please wait...');

% 1 : weight with RGB pixel
if weight_type==1
    % draw graph with image pixels
    for vertex = 1:vertice_size
        waitbar(vertex/vertice_size,pb,'Creating graph, weight type 1');

        x = mod(vertex-1, width) + 1;
        y = fix((vertex-1) / width) + 1;
        % X axis weight
        if mod(vertex, width) ~= 0 % Except right-side vertex
            s(index) = vertex;
            t(index) = vertex+1;
            weight(index) = (normL2(im1(y,x,:), im2(y,x,:)) ...
                            + normL2(im1(y,x+1,:), im2(y,x+1,:)));
            index = index+1;
        end

        % Y axis weight
        if vertex <= width * (height - 1) % Except bottom-side vertex
            s(index) = vertex;
            t(index) = vertex+width;
            weight(index) = (normL2(im1(y,x,:), im2(y,x,:)) ...
                            + normL2(im1(y+1,x,:), im2(y+1,x,:)));
            index = index+1;
        end
    end
end

% 2 : weight with RGB pixel, use gradiant method
if weight_type==2
    %sobel filtered images
    sobel_x = [-1 0 1;-2 0 2;-1 0 1];
    sobel_y = [-1 -2 -1;0 0 0;1 2 1];

    im1_dx_3ch = imfilter(im1, sobel_x);
    im1_dy_3ch = imfilter(im1, sobel_y);
    im2_dx_3ch = imfilter(im2, sobel_x);
    im2_dy_3ch = imfilter(im2, sobel_y);

    im1_dx_1ch = zeros(height, width);
    im1_dy_1ch = zeros(height, width);
    im2_dx_1ch = zeros(height, width);
    im2_dy_1ch = zeros(height, width);

    for x = 1:width
        for y = 1:height
            im1_dx_1ch(y,x) = normL2(im1_dx_3ch(y,x,:));
            im1_dy_1ch(y,x) = normL2(im1_dy_3ch(y,x,:));
            im2_dx_1ch(y,x) = normL2(im2_dx_3ch(y,x,:));
            im2_dy_1ch(y,x) = normL2(im2_dy_3ch(y,x,:));
        end
    end

    % draw graph with image pixels
    for vertex = 1:vertice_size
        waitbar(vertex/vertice_size,pb,'Creating graph, weight type 2');

        x = mod(vertex-1, width) + 1;
        y = fix((vertex-1) / width) + 1;
        % X axis weight
        if mod(vertex, width) ~= 0 % Except right-side vertex
            grad = im1_dx_1ch(y,x) + im1_dx_1ch(y,x+1) + im2_dx_1ch(y,x) + im2_dx_1ch(y,x+1);
            s(index) = vertex;
            t(index) = vertex+1;
            weight(index) = (normL2(im1(y,x,:), im2(y,x,:)) ...
                            + normL2(im1(y,x+1,:), im2(y,x+1,:)))/(grad+1);
            index = index+1;
        end

        % Y axis weight
        if vertex <= width * (height - 1) % Except bottom-side vertex
            grad = im1_dy_1ch(y,x) + im1_dy_1ch(y+1,x) + im2_dy_1ch(y,x) + im2_dy_1ch(y+1,x);
            s(index) = vertex;
            t(index) = vertex+width;
            weight(index) = (normL2(im1(y,x,:), im2(y,x,:)) ...
                            + normL2(im1(y+1,x,:), im2(y+1,x,:)))/(grad+1);
            index = index+1;
        end
    end
end

close(pb)

% Last 2 vertex is source and sink
% Add source
for i = 1:height
    s(index) = vertice_size + 1;
    t(index) = 1 + (i - 1) * width;
    weight(index) = Inf;
    index = index+1;
end

% Add sink
for i = 1:height
    s(index) = i*width;
    t(index) = vertice_size + 2;
    weight(index) = Inf;
    index = index+1;
end

% Add weight bias to prevent zero weight value
weight = weight + add_weight_bias;

% Do maxflow/mincut
seam_graph = graph(s, t, weight);
[mf, gf, cs, ct] = maxflow(seam_graph, vertice_size + 1, vertice_size + 2);

% draw new seam mask

% seam mask from source
cs_x = mod(cs-1, width) + 1;
cs_y = fix((cs-1) / width) + 1;

seam_mask = zeros(height, width);
for i = 1:length(cs)
    seam_mask(cs_y(i),cs_x(i)) = 1;
end

% merge!
result = im2;
for x = 1:width
    for y = 1:height
        if seam_mask(y, x) ~= 0
            result(y, x, 1) = im1(y, x, 1);
            result(y, x, 2) = im1(y, x, 2);
            result(y, x, 3) = im1(y, x, 3);
        end
    end
end

% seam point draw
seam_draw = result;
for x = 1:width-1
    for y = 1:height
        if seam_mask(y, x) ~= seam_mask(y, x+1)
            seam_draw(y, x, 1) = 255;
            seam_draw(y, x, 2) = 0;
            seam_draw(y, x, 3) = 0;
        end
    end
end

figure(1);
imshow(im1);
figure(2);
imshow(im2);
figure(3);
imshow(seam_mask);
figure(4);
imshow(result);
figure(5);
imshow(seam_draw);

imwrite(seam_mask, 'seam_mask.jpg');
imwrite(result, 'result.jpg');
imwrite(seam_draw, 'seam_draw.jpg');
