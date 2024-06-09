%%  ��ջ�������
warning off             % �رձ�����Ϣ
close all               % �رտ�����ͼ��
clear                   % ��ձ���
clc                     % ���������

%%  �������ݣ�ʱ�����еĵ������ݣ�
result = xlsread('���ݼ�.xlsx');

%%  ���ݷ���
num_samples = length(result);   % �������� 
kim =  24;                      % ��ʱ������kim����ʷ������Ϊ�Ա�����
zim =   1;                      % Ԥ��δ���������ݣ���zim��ʱ������Ԥ�⣩
ST  = 100;                      % �ݹ�Ԥ��δ����������

%%  �������ݼ�
for i = 1: num_samples - kim - zim + 1
    res(i, :) = [reshape(result(i: i + kim - 1), 1, kim), result(i + kim + zim - 1)];
end

%%  ����ѵ�����Ͳ��Լ�
temp = 1: 1: 576;

P_train = res(temp(1: 400), 1: 24)';
T_train = res(temp(1: 400), 25)';
M = size(P_train, 2);

P_test = res(temp(401: end), 1: 24)';
T_test = res(temp(401: end), 25)';
N = size(P_test, 2);

%%  ���ݹ�һ��
[P_train, ps_input] = mapminmax(P_train, 0, 1);
P_test = mapminmax('apply', P_test, ps_input);

[t_train, ps_output] = mapminmax(T_train, 0, 1);
t_test = mapminmax('apply', T_test, ps_output);

%%  ����ƽ��
%   ������ƽ�̳�1ά����ֻ��һ�ִ���ʽ
%   Ҳ����ƽ�̳�2ά���ݣ��Լ�3ά���ݣ���Ҫ�޸Ķ�Ӧģ�ͽṹ
%   ����Ӧ��ʼ�պ���������ݽṹ����һ��
P_train =  double(reshape(P_train, 24, 1, 1, M));
P_test  =  double(reshape(P_test , 24, 1, 1, N));

t_train = t_train';
t_test  = t_test' ;

%%  ���ݸ�ʽת��
for i = 1 : M
    p_train{i, 1} = P_train(:, :, 1, i);
end

for i = 1 : N
    p_test{i, 1}  = P_test( :, :, 1, i);
end

%%  ����ģ��
layers = [
    sequenceInputLayer(24)              % ���������
    
    lstmLayer(10, 'OutputMode', 'last') % LSTM��
    reluLayer                           % Relu�����
    
    fullyConnectedLayer(1)              % ȫ���Ӳ�
    regressionLayer];                   % �ع��
 
%%  ��������
options = trainingOptions('adam', ...       % Adam �ݶ��½��㷨
    'MaxEpochs', 1000, ...                  % ���ѵ������
    'InitialLearnRate', 2e-3, ...           % ��ʼѧϰ��
    'LearnRateSchedule', 'piecewise', ...   % ѧϰ���½�
    'LearnRateDropFactor', 0.1, ...         % ѧϰ���½�����
    'LearnRateDropPeriod', 800, ...         % ����800��ѵ���� ѧϰ��Ϊ 0.002 * 0.1
    'Shuffle', 'every-epoch', ...           % ÿ��ѵ���������ݼ�
    'Plots', 'training-progress', ...       % ��������
    'Verbose', false);

%%  ѵ��ģ��
net = trainNetwork(p_train, t_train, layers, options);

%%  ����Ԥ��
t_sim1 = predict(net, p_train);
t_sim2 = predict(net, p_test );

%%  ���ݷ���һ��
T_sim1 = mapminmax('reverse', t_sim1, ps_output);
T_sim2 = mapminmax('reverse', t_sim2, ps_output);

%%  ���������
error1 = sqrt(sum((T_sim1' - T_train).^2) ./ M);
error2 = sqrt(sum((T_sim2' - T_test ).^2) ./ N);

%%  �鿴����ṹ
analyzeNetwork(net)

%%  ��ͼ
figure
plot(1: M, T_train, 'r-', 1: M, T_sim1, 'b-', 'LineWidth', 1)
legend('��ʵֵ', 'Ԥ��ֵ')
xlabel('Ԥ������')
ylabel('Ԥ����')
string = {'ѵ����Ԥ�����Ա�'; ['RMSE=' num2str(error1)]};
title(string)
xlim([1, M])
grid

figure
plot(1: N, T_test, 'r-', 1: N, T_sim2, 'b-', 'LineWidth', 1)
legend('��ʵֵ', 'Ԥ��ֵ')
xlabel('Ԥ������')
ylabel('Ԥ����')
string = {'���Լ�Ԥ�����Ա�'; ['RMSE=' num2str(error2)]};
title(string)
xlim([1, N])
grid

%%  ���ָ�����
%  R2
R1 = 1 - norm(T_train - T_sim1')^2 / norm(T_train - mean(T_train))^2;
R2 = 1 - norm(T_test  - T_sim2')^2 / norm(T_test  - mean(T_test ))^2;

disp(['ѵ�������ݵ�R2Ϊ��', num2str(R1)])
disp(['���Լ����ݵ�R2Ϊ��', num2str(R2)])

%  MAE
mae1 = sum(abs(T_sim1' - T_train)) ./ M ;
mae2 = sum(abs(T_sim2' - T_test )) ./ N ;

disp(['ѵ�������ݵ�MAEΪ��', num2str(mae1)])
disp(['���Լ����ݵ�MAEΪ��', num2str(mae2)])

%  MBE
mbe1 = sum(T_sim1' - T_train) ./ M ;
mbe2 = sum(T_sim2' - T_test ) ./ N ;

disp(['ѵ�������ݵ�MBEΪ��', num2str(mbe1)])
disp(['���Լ����ݵ�MBEΪ��', num2str(mbe2)])

%%  ����ݹ�Ԥ��δ������
save_new_pred = zeros(1, ST);

% ��ȡ��ǰ��������
new_data = t_test(end - kim + 1: end)';

for i = 1: ST

    New_Data = double(reshape(new_data, 24, 1, 1, 1));
    
    % ���ݸ�ʽת��
    conv_data{1, 1} = New_Data(:, :, 1, 1);

    % Ԥ�����������
    new_pre = predict(net, conv_data);

    % ������������
    new_data(1: end - 1) = new_data(2: end);
    new_data(end) = new_pre;

    % ����Ԥ����
    save_new_pred(i) = new_pre;
end

%%  ���ݷ���һ��
T_sim3 = mapminmax('reverse', save_new_pred, ps_output);

%%  ����Ԥ����
figure
plot(1: length(result), result, 'b-', 'LineWidth', 1)
hold on
plot(length(result): length(result) + ST, [result(end), T_sim3], 'r-', 'LineWidth', 1)
legend('��ʵֵ', 'δ��ֵ')
xlabel('Ԥ������')
ylabel('Ԥ����')
string = {'δ��ֵԤ��'};
title(string)
xlim([1, length(result) + ST])
grid