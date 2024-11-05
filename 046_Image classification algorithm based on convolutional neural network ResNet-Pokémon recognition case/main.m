warning off             % �رձ�����Ϣ
close all               % �رտ�����ͼ��
clear                   % ��ձ���
clc                     % ���������

%%  ��������
imds = imageDatastore('images', ...       % ��ȡ�ļ�������
        'IncludeSubfolders', true, ...    % �Ƿ�������ļ��� 
        'LabelSource', 'foldernames');    % �����ļ�������Ϊ��ǩ
    
%%  ��������
[imdTrain, imdTest] = splitEachLabel(imds, 0.8, 'randomized');

%%  ��ȡ�����Ŀ
numClasses = numel(categories(imdTrain.Labels));

%%  ����Ԥѵ������
net = resnet18;
analyzeNetwork(net)
img_size = net.Layers(1).InputSize(1: 2);

%% ��ȡ����Ĳ㲢�޸�����ȫ���Ӳ�ͷ����
lgraph = layerGraph(net);

% ����ԭʼ��ȫ���Ӳ�ͷ����
fcLayer = fullyConnectedLayer(numClasses, 'Name', 'new_fc');
classificationLayer = classificationLayer('Name', 'new_classoutput');

% �滻ԭ����ȫ���Ӳ�ͷ����
lgraph = replaceLayer(lgraph, 'fc1000', fcLayer);
lgraph = replaceLayer(lgraph, 'ClassificationLayer_predictions', classificationLayer);

%%  ������ǿ
pixelRange = [-10, 10];
imageAugmenter = imageDataAugmenter( ...
    'RandRotation'    , pixelRange,  ...    % ��ת�Ƕȷ�Χ
    'RandXReflection' , true,        ...    % ���·�����������
    'RandXTranslation', pixelRange,  ...    % ˮƽƽ�Ʒ�Χ
    'RandYTranslation', pixelRange);        % ��ֱƽ�Ʒ�Χ

Train = augmentedImageDatastore(img_size, imdTrain, 'DataAugmentation', imageAugmenter, ...
    'ColorPreprocessing', 'gray2rgb');
Test  = augmentedImageDatastore(img_size, imdTest , 'ColorPreprocessing', 'gray2rgb');

%%  ��������
options = trainingOptions('adam', ...      % Adam �ݶ��½��㷨
    'MiniBatchSize', 64, ...               % ����С, ÿ��ѵ����������
    'MaxEpochs', 30, ...                   % ���ѵ������
    'InitialLearnRate', 1e-3, ...          % ��ʼѧϰ��Ϊ
    'LearnRateSchedule', 'piecewise', ...  % ѧϰ���½�
    'LearnRateDropFactor', 0.1, ...        % ѧϰ���½�����
    'LearnRateDropPeriod', 20, ...         % ÿ����20��ѵ��, ѧϰ�� = ѧϰ�� * �½�����
    'Shuffle', 'every-epoch', ...          % ÿ��ѵ���������ݼ�
    'ValidationData', Test, ...            % ��֤���ݼ�
    'ValidationFrequency', 20, ...         % ÿ20����һ����֤
    'Plots', 'training-progress',...       % ������ʧ����
    'Verbose', false);                     % �ر���������ʾ

%%  ģ��ѵ��
net = trainNetwork(Train, lgraph, options);

%%  �������
T_sim1 = classify(net, Train);
T_sim2 = classify(net, Test );

%%  �������
T_train = imdTrain.Labels;
T_test  = imdTest.Labels ;

%%  ��������
accuracy1 = mean(T_sim1 == T_train) * 100;
accuracy2 = mean(T_sim2 == T_test ) * 100;

%%  ��ʾ׼ȷ��
disp(['ѵ����׼ȷ�ʣ�', num2str(accuracy1), '%'] )
disp(['���Լ�׼ȷ�ʣ�', num2str(accuracy2), '%'] )

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

%%  ��������
save net.mat net