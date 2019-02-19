function population = subjselect_gacreate(numSelectedSubjects,FitnessFcn,...
    options,numSubjects)

for i = 1:options.PopulationSize
    allSubjectsUnique = 0;
    while ~allSubjectsUnique
        subjects = floor(rand(numSelectedSubjects,1)*numSubjects)+1;
        if size(subjects) == size(unique(subjects))
            allSubjectsUnique = 1;
        end
    end
    population(i,:) = subjects;
end
