function errorRate = subjselect_gafit(subjectIndices,...
    data, var_names, var_type, var_mean, var_std, var_priority)


var_n = length(var_names);

errorRate = 0;
for ithvar = 1:var_n
    if(strcmpi(var_names{ithvar},'pid') == 1)
            PIDRepeated = 0;
            if(length(subjectIndices) ~= length(unique(data(subjectIndices,ithvar)))) PIDRepeated = 1; end
            errorRate = errorRate + 10000*PIDRepeated;
            continue
	end

	if(var_type(ithvar) == 1)
        if(var_mean(ithvar) ~= 0)
    		errorRate = errorRate + (abs(mean(data(subjectIndices,ithvar)) - var_mean(ithvar)))*var_priority(ithvar) + (abs(std(data(subjectIndices,ithvar)) - var_std(ithvar)));		
        end
	end

	if(var_type(ithvar) == 2)
        var_discrete_1 = length(find(data(subjectIndices,ithvar) == 1));
        var_discrete_0 = length(find(data(subjectIndices,ithvar) == 0));
		var_discrete_ratio = var_discrete_1/var_discrete_0;
		errorRate = errorRate + (abs(var_discrete_ratio - var_mean(ithvar)))*var_priority(ithvar); 		
	end
end

% meanNPAge = 9.87;
% meanFSIQ = 113.16;
% 
% 
% stdNPAge = 1.62;
% stdFSIQ = 17.33;
% 
% 
% PIDRepeated = 0;
% numMales = length(find(data(subjectIndices,2)) == 1);
% if(length(subjectIndices) ~= length(unique(data(subjectIndices,1)))) PIDRepeated = 1; end
%     
% %errorRate = abs(mean(data(subjectIndices,3)) - meanNPAge) + abs(numMales - 21)*5 + 10000*PIDRepeated + abs(std(data(subjectIndices,3)) - stdNPAge)/2;
% 
% 
% errorRate = ((abs(mean(data(subjectIndices,3)) - meanNPAge) + ...
%               abs(mean(data(subjectIndices,4)) - meanFSIQ)))*1 + ... 
%             abs(numMales - 21)*5 + ...
%             10000*PIDRepeated + ...
%             ((abs(std(data(subjectIndices,3)) - stdNPAge) + ...
%               abs(std(data(subjectIndices,4)) - stdFSIQ)))/2;
% 
% % errorRate = ((abs(mean(data(subjectIndices,3)) - mean(data(subjectIndices,4))) + ...
% %               abs(mean(data(subjectIndices,4)) - meanANSAge) + ...
% %               abs(mean(data(subjectIndices,5)) - meanVIQ) + ...
% %               abs(mean(data(subjectIndices,6)) - meanPIQ) + ...
% %               abs(mean(data(subjectIndices,7)) - meanFSIQ)))*1 + ... 
% %             abs(numMales - 21)*5 + ...
% %             10000*PIDRepeated + ...
% %             ((abs(std(data(subjectIndices,4)) - stdANSAge) + ...
% %               abs(std(data(subjectIndices,5)) - stdVIQ) + ...
% %               abs(std(data(subjectIndices,6)) - stdPIQ) + ...
% %               abs(std(data(subjectIndices,7)) - stdFSIQ)))/2;
