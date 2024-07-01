%%  ��ջ�������
warning off             % �رձ�����Ϣ
close all               % �رտ�����ͼ��
clear                   % ��ձ���
clc                     % ���������

%%  ��ȡģ��
load model.mat
load ps_input.mat
load ps_output.mat

%%  ��������
res = xlsread('��ҪԤ�������.xlsx');

%%  ������Ŀ
M = size(res, 1);

%%  ���ݹ�һ��
p_test = mapminmax('apply', res', ps_input);

%%  ת������Ӧģ��
p_test = p_test';

%%  �������
t_sim3 = regRF_predict(p_test, model);

%%  ���ݷ���һ��
T_sim3 = mapminmax('reverse', t_sim3, ps_output);

%%  ������
xlswrite('Ԥ����.xlsx', T_sim3);
