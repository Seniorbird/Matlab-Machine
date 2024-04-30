%%  ��ջ�������
warning off             % �رձ�����Ϣ
close all               % �رտ�����ͼ��
clear                   % ��ձ���
clc                     % ���������

%%  ���·��
addpath('LSSVM_Toolbox\')

%%  ��������
res = xlsread('���ݼ�.xlsx');

%%  ����ѵ�����Ͳ��Լ�
temp = randperm(357);

P_train = res(temp(1: 240), 1: 12)';
T_train = res(temp(1: 240), 13)';
M = size(P_train, 2);

P_test = res(temp(241: end), 1: 12)';
T_test = res(temp(241: end), 13)';
N = size(P_test, 2);

%%  ���ݹ�һ��
[p_train, ps_input] = mapminmax(P_train, 0, 1);
p_test = mapminmax('apply', P_test, ps_input );
t_train = T_train;
t_test  = T_test ;

%%  ת������Ӧģ��
p_train = p_train'; p_test = p_test';
t_train = t_train'; t_test = t_test';

%%  ��������
gam  = 10;                    % �˺�������
sig2 = 1.5;                   % �ͷ�����
type = 'c';                   % ģ������ ����
codefct = 'code_OneVsOne';    % һ��һ���루�Ƽ���
%          code_OneVsAll      % һ�Զ����
kernel_type = 'RBF_kernel';   % RBF �˺���  
%              poly_kernel    % ����ʽ�˺��� 
%              MLP_kernel     % ����֪���˺���
%              lin_kernel     % ���Ժ˺���

%%  ����
[t_train, codebook, old_codebook] = code(t_train, codefct);

%%  ����ģ��
model = initlssvm(p_train, t_train, type, gam, sig2, kernel_type, codefct); 

%%  ѵ��ģ��
model = trainlssvm(model);

%%  ����ģ��
t_sim1 = simlssvm(model, p_train);
t_sim2 = simlssvm(model, p_test ); 

%%  ����
T_sim1 = code(t_sim1, old_codebook, [], codebook);
T_sim2 = code(t_sim2, old_codebook, [], codebook);

%%  ��������
[T_train, index_1] = sort(T_train);
[T_test , index_2] = sort(T_test );

T_sim1 = T_sim1(index_1);
T_sim2 = T_sim2(index_2);

%%  ��������
error1 = sum((T_sim1' == T_train)) / M * 100 ;
error2 = sum((T_sim2' == T_test )) / N * 100 ;

%%  ��ͼ
figure
plot(1: M, T_train, 'r-*', 1: M, T_sim1, 'b-o', 'LineWidth', 1)
legend('��ʵֵ', 'Ԥ��ֵ')
xlabel('Ԥ������')
ylabel('Ԥ����')
string = {'ѵ����Ԥ�����Ա�'; ['׼ȷ��=' num2str(error1) '%']};
title(string)
grid

figure
plot(1: N, T_test, 'r-*', 1: N, T_sim2, 'b-o', 'LineWidth', 1)
legend('��ʵֵ', 'Ԥ��ֵ')
xlabel('Ԥ������')
ylabel('Ԥ����')
string = {'���Լ�Ԥ�����Ա�'; ['׼ȷ��=' num2str(error2) '%']};
title(string)
grid

%%  ��������
figure
cm = confusionchart(T_train, T_sim1);
cm.Title = 'Confusion Matrix for Train Data';
cm.ColumnSummary = 'column-normalized';
cm.RowSummary = 'row-normalized';
    
figure
cm = confusionchart(T_test, T_sim2);
cm.Title = 'Confusion Matrix for Test Data';
cm.ColumnSummary = 'column-normalized';
cm.RowSummary = 'row-normalized';