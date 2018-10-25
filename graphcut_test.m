clear;
clc;

%original images and mask
% RGB
im1 = imread('im1.jpg');
im2 = imread('im2.jpg');

[height, width, channel] = size(im1);
vertice_size = height * width; % number of vertice without souce and sink

%number of vertex pair(number of edge)
%X axis edge, Y axis edge, source/sink edge
number_of_pair = ((width - 1) * height) + (width * (height - 1)) + (2 * height);
s = zeros(1,number_of_pair); % image graph's edge and source, sink edge
t = zeros(1,number_of_pair); % image graph's edge and source, sink edge
weight = zeros(1,number_of_pair); % image graph's edge and source, sink edge

index = 1;

% draw graph with image pixels
for vertex = 1:vertice_size
    disp('vertice number :');
    disp(vertex);
    disp('percentage :');
    disp(100*(vertex/vertice_size));
    
    x = mod(vertex-1, width) + 1;
    y = fix((vertex-1) / width) + 1;
    % X axis weight
    if mod(vertex, width) ~= 0 % Except right-side vertex
        s(index) = vertex;
        t(index) = vertex+1;
        weight(index) = normL2(im1(y,x,:), im2(y,x,:)) ...
                        + normL2(im1(y,x+1,:), im2(y,x+1,:));
        index = index+1;
    end
    
    % Y axis weight
    if vertex <= width * (height - 1) % Except bottom-side vertex
        s(index) = vertex;
        t(index) = vertex+width;
        weight(index) = normL2(im1(y,x,:), im2(y,x,:)) ...
                        + normL2(im1(y+1,x,:), im2(y+1,x,:));
        index = index+1;
    end
end

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

seam_graph = graph(s, t, weight);
[mf, gf, cs, ct] = maxflow(seam_graph, vertice_size + 1, vertice_size + 2);

% draw new seam mask

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

%figure(4);
%plot(seam_graph, 'EdgeLabel', seam_graph.Edges.Weight);
