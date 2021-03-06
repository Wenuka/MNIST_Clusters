classdef Network_new < handle
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (GetAccess = private)
        
        weightFile;
        
        t = 0.001;
        a = 15.0;
        b = [0.01, 0.01, 0.025];
        %b = [0.0, 0.0, 0.0];
        
    end
    
    properties (SetAccess = public)
        
        layerStruct;
        numLayers; 
        totalRounds;
        ffcheck;
        ltcheck;
        fbcheck;
        
        feedforwardConnections;
        lateralConnections;
        feedbackConnections;
        
    end
    
    properties
        
        
    end
    
    methods (Access = private)
        
        function createFeedforward(obj)
            
            if exist(obj.weightFile, 'file') == 2
                load(obj.weightFile, 'feedforwardConnections');
                obj.feedforwardConnections = feedforwardConnections;
            else
                
                obj.feedforwardConnections = cell([1, obj.numLayers - 1]);
                
                for i = 1 : obj.numLayers - 1
                    
                    %obj.feedforwardConnections{i} = rand(layerStruct(i + 1),layerStruct(i));
                    %obj.feedforwardConnections{i} = normr(binornd(1, 0.2, obj.layerStruct(i + 1), obj.layerStruct(i)));
                    obj.feedforwardConnections{i} = binornd(1, 0.2, obj.layerStruct(i + 1), obj.layerStruct(i));
                    
                end
                
            end
            
            obj.ffcheck = zeros(1, obj.numLayers - 1);
            
        end
        
        
        function createFeedback(obj,r,temp)
            
            this_a = obj.a;
            temp(temp < 0) = 0;
            temp = temp - 0.005;
            
            
            obj.feedforwardConnections{r} = this_a * temp + obj.feedforwardConnections{r};
            
        end
        
        function STDP_update_feedforward(obj, layers)
            weights = obj.feedforwardConnections;
            this_t = obj.t;
            this_check = obj.ffcheck;
            
            parfor r = 1 : obj.numLayers - 1
                
                mean_A = mean(layers{r}');
                mean_B = mean(layers{r+1}');
                
                [m,n] = size(layers{r});
               
                [e,l] = size((mean_A')*(mean_B));
                total_product = zeros(l,e);
                
                for k = 1 : n
                    
                        
                    total_temp  = layers{r+1}(:,k) * (layers{r}(:,k))'*0.099999;
                    
                    total_product = total_product + total_temp;
                    
                end
                
%                 disp(total_product);

                total_product = total_product./n;
                 
%                 temp = total_product - 0.95188*((mean_A')*(mean_B))';
temp = total_product - 0.5*((mean_A')*(mean_B))';
%                 if r==3
%                 disp(temp);
%                 end

%                 weights{r} = weights{r} + temp*0.551;
weights{r} = weights{r} + temp*0.6;

                %                 obj.createFeedback(r,temp);
                
                if any(temp < 0)
                    this_check(r) = this_check(r) + 1;
                end
            end
            obj.feedforwardConnections = weights;
            obj.ffcheck = this_check;
           
        end
        
        function saveWeights(obj)
            
            feedforwardConnections = obj.feedforwardConnections;
            %              lateralConnections = obj.lateralConnections;
            %             save(obj.weightFile, 'feedforwardConnections', 'lateralConnections');
            save(obj.weightFile, 'feedforwardConnections');
            
        end
        
    end
    
    methods
        
        function obj = Network_new(layerStruct)
            
            obj.layerStruct = layerStruct;
            [~, obj.numLayers] = size(layerStruct);
            obj.totalRounds = 0;
            
            fileName = sprintf('%d_', layerStruct);
            fileName = strcat(fileName(1 : end - 1), '.mat');
            obj.weightFile = fullfile(fileparts(which(mfilename)), '..\WeightDatabase\Temp', fileName);
            
            obj.createFeedforward();
            %              obj.createLateral();
            
            obj.saveWeights();
            
        end
        
        function layers = getOutput(obj, input)
            [m,n]=size(input);
          
            layers = cell([1, obj.numLayers]);
            layers{1} = normc(input);

%             layers{1} = input/norm(input,1.0);
            
%             layers_batch = zeros(1000, n);
            for k = 1 : obj.numLayers - 1
               
                if k == 1
                    layers_batch = obj.feedforwardConnections{k}* (layers{1});
                    
                else
                    layers_batch = obj.feedforwardConnections{k}* (layers_batch);
                    
                end
                
                layers{k + 1} = layers_batch;
                 layers{k + 1} = normc(layers{k + 1});
%                 layers{k + 1} = layers{k + 1}/norm(layers{k + 1},1.0);
            end
            
        end
        
        function STDP_update(obj, layers)
            
            obj.totalRounds = obj.totalRounds + 1;
            obj.STDP_update_feedforward(layers);
            %          obj.STDP_update_lateral(layers);
            
        end
        
    end
    
end

