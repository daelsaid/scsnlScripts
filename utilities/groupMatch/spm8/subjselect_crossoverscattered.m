function xoverKids  = subjselect_crossoverscattered(parents,options,GenomeLength,FitnessFcn,unused,thisPopulation)

nKids = length(parents)/2;

xoverKids = zeros(nKids,GenomeLength);

index = 1;

for i=1:nKids
    r1 = parents(index);
    index = index + 1;
    r2 = parents(index);
    index = index + 1;

    while 1
        for j = 1:GenomeLength
            if(rand > 0.5)
                xoverKids(i,j) = thisPopulation(r1,j);
            else
                xoverKids(i,j) = thisPopulation(r2,j);       
            end
        end
        
        if size(xoverKids(i,:))==size(unique(xoverKids(i,:)))
            break
        end
    end
end
