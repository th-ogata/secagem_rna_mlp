clearvars; clc; 

%% PARA RODAR O PROGRAMA É NECESSÁRIO OS ARQUIVOS: Dados.xlsx e scriptRNA_regressao
%  NA MESMA PASTA
%
% Informar se terá etapa de simulação e se tem dados experimentais de saída
% para a etapa de simulação


simula = 'sim'; %'sim' ou 'nao'
saidasimul = 'nao'; % 'sim' ou 'nao'


%% NÃO ALTERAR ESTA SEÇÃO
%  Leitura dos dados que estão na planilha Dados.xlsx

ent_rede = xlsread('Dados.xlsx','ent_rede');                          
ent_rede = ent_rede';

sai_rede = xlsread('Dados.xlsx','sai_rede');                          
sai_rede = sai_rede';

if simula == 'sim'
    ent_simula = xlsread('Dados.xlsx','ent_simula');                          
    ent_simula = ent_simula';
    
    if saidasimul == 'sim'
        sai_simula = xlsread('Dados.xlsx','sai_simula');                          
        sai_simula = sai_simula';
    end
end 

%% COMANDO QUE GERA A RNA e CONFIGURAÇÕES DO TREINAMENTO


net = newff(ent_rede,sai_rede,5,{'tansig' 'purelin'},'trainlm');
%net = newff(ent_rede,sai_rede,5,{'tansig' 'tansig'},'trainlm');

net.trainParam.epochs =10000;          %Número máximo de iterações
net.trainParam.max_fail = 1000;         %máximo de checagem na validação, critério de parada 
net.trainParam.goal = 1e-6;         %erro máximo tolerado, critério de parada
net.divideParam.trainRatio = 0.70;
net.divideParam.valRatio   = 0.15;
net.divideParam.testRatio  = 0.15;

% COMANDO: net = newff(entrada,saída,[neur.1ª.camadaoculta neur.2ª.camada.oculta neur.3ª.camada.oculta],
%{'f.ativ.1ª.camada.oculta' 'f.ativ.2ª.camada.oculta' 'f.ativ.nª.camada.oculta' 'f.ativ.camada.saida'},
%'algorit.otimização')

%net é o nome do modelo

%Ex.: RNA com 1 camada oculta contento 5 neurônios, sendo tansig na camada
%oculta e linear na de saída. algoritmo levemberg-marquardt: 
%net = newff(ent_rede,sai_rede,[5],{'tansig' 'purelin'},'trainlm')

%Ex.: RNA com 3 camada ocultas contento 5, 10 e 5 neurônios, sendo tansig
%nas camadas ocultas e linear na de saída. algoritmo levemberg-marquardt com regularização bayesiana: 
%net = newff(ent_rede,sai_rede,[5 10 5],{'tansig' 'tansig' 'tansig' 'purelin'},'trainbr')

%%
% NÃO ALTERAR MAIS NADA A PARTIR DAQUI!!! 

% Treinamento da rede

[net,tr] = train(net, ent_rede, sai_rede);

% Construção de Gráficos
%Não alterar.

figure(1)
plotperform(tr)

treino_exp_ent=ent_rede(:,tr.trainInd);
valid_exp_ent=ent_rede(:,tr.valInd);
teste_exp_ent=ent_rede(:,tr.testInd);

treino_exp_sai=sai_rede(:,tr.trainInd);
valid_exp_sai=sai_rede(:,tr.valInd);
teste_exp_sai=sai_rede(:,tr.testInd);

%Resultados treinamento
treino_RNA = sim(net,treino_exp_ent);
treino_FOBJ = mse(treino_exp_sai-treino_RNA);
for i=1:size(sai_rede,1);
    e=abs(treino_RNA(i,:) - treino_exp_sai(i,:));
    e=e./treino_exp_sai(i,:);
    treino_ERRO(i)=100*sum(e)/size(tr.trainInd,2);
    cor = corrcoef(treino_RNA(i,:),treino_exp_sai(i,:));
    treino_CORR(i) = cor(1,2);
end


figure(2)
[m1,b1,r1] = postreg(treino_RNA,treino_exp_sai);
title('REGRESSÃO - TREINAMENTO')
xlabel('EXPERIMENTAL') % VALORES x-axis 
ylabel('RNA') % VALORES y-axis

%Resultados validação
valid_RNA = sim(net,valid_exp_ent);
valid_FOBJ = mse(valid_exp_sai-valid_RNA);
for i=1:size(sai_rede,1);
    e=abs(valid_RNA(i,:) - valid_exp_sai(i,:));
    e=e./valid_exp_sai(i,:);
    valid_ERRO(i)=100*sum(e)/size(tr.valInd,2);
    cor = corrcoef(valid_RNA(i,:),valid_exp_sai(i,:));
    valid_CORR(i) = cor(1,2);
end

figure(3)
[m1,b1,r1] = postreg(valid_RNA,valid_exp_sai);
title('REGRESSÃO - VALIDAÇÃO')
xlabel('EXPERIMENTAL') % VALORES x-axis 
ylabel('RNA') % VALORES y-axis

%Dados teste
teste_RNA = sim(net,teste_exp_ent);
teste_FOBJ = mse(teste_exp_sai-teste_RNA);

for i=1:size(sai_rede,1);
    e=abs(teste_RNA(i,:) - teste_exp_sai(i,:));
    e=e./teste_exp_sai(i,:);
    teste_ERRO(i)=100*sum(e)/size(tr.testInd,2);
    cor = corrcoef(teste_RNA(i,:),teste_exp_sai(i,:));
    teste_CORR(i) = cor(1,2);
end

figure(4)
[m1,b1,r1] = postreg(teste_RNA,teste_exp_sai);
title('REGRESSÃO - TESTE')
xlabel('EXPERIMENTAL') % VALORES x-axis 
ylabel('RNA') % VALORES y-axis

% SIMULAÇÃO

if simula == 'sim'
    sai_simula_RNA = sim(net,ent_simula);
    
    if saidasimul == 'sim'
        for i=1:size(sai_rede,1);
          e=abs(sai_simula_RNA(i,:) - sai_simula(i,:));
          e=e./sai_simula(i,:);
          simula_ERRO(i)=100*sum(e)/size(sai_simula,2);
          cor = corrcoef(sai_simula_RNA(i,:),sai_simula(i,:));
          simula_CORR(i) = cor(1,2);
        end   
        
    figure(5)
    [m2,b2,r2] = postreg(sai_simula_RNA,sai_simula);
    title('REGRESSÃO SIMULAÇÃO')
    xlabel('EXPERIMENTAL') % VALORES x-axis 
    ylabel('RNA') % VALORES y-axis

    end
end



% Pesos e bias das camadas escondidas e camada de saída

pesoscam1 = net.IW;                 % display dos pesos layer 1
pesosdemaiscam = net.LW;            % display dos pesos demais camadas (incluindo de saída)
bias = net.b;                       % display os bias de todas as camadas

pesos{1,1}=pesoscam1{1,1};

for i=2:size(pesosdemaiscam,1)
    pesos{i,1}=pesosdemaiscam{i,i-1};
end
    
    
sai_simula_RNA = sai_simula_RNA';
teste_exp_ent = teste_exp_ent';
teste_exp_sai = teste_exp_sai';
treino_exp_ent = treino_exp_ent';
treino_exp_sai = treino_exp_sai';
valid_exp_ent = valid_exp_ent';
valid_exp_sai = valid_exp_sai';
teste_RNA = teste_RNA';
treino_RNA = treino_RNA';
valid_RNA = valid_RNA';


clearvars -except net ent_rede sai_rede ent_simula sai_simula bias pesos teste_CORR teste_ERRO teste_FOBJ teste_RNA teste_exp_ent...
    teste_exp_sai tr treino_CORR treino_ERRO treino_FOBJ treino_RNA treino_exp_ent treino_exp_sai ...
    valid_CORR valid_ERRO valid_FOBJ valid_RNA valid_exp_ent valid_exp_sai simula_CORR simula_ERRO sai_simula_RNA

'FIM. Salvar o workspace antes de treinar outra estrutura'
