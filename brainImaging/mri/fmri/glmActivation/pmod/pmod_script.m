% This script is an example pmod.m script that specifies how to add parametric modulators to add to a task
% _________________________________________________________________________
% 2019 Stanford Cognitive and Systems Neuroscience Laboratory
%
% $Id:  $ 03-18-19 Carlo de los Angeles

% -------------------------------------------------------------------------

function [sess_name names onsets durations pmod rest_exists ] = pmod_script(sess_name,names,onsets,durations,rest_exists)

%names{1} = 'rest';
%names{2} = 'visual stimulus';
%onsets{1} = [0 12 38 49 55];
%onsets{2} = [9 18 25 34 42];
%durations{1} = [0 0 0 0 0]; (or you can have just a single 0)
%durations{2} = [0 0 0 0 0];

pmod={};


%Let's say you want a linear (first order) parametric effect on the first
%condition

pmod{1}.name{1}  = 'visstim-param';
pmod{1}.param{1} = [1 1 2 3 5];  %(this must be the same length as #onsets in
%that condition)
pmod{1}.poly{1}  = 1; % (i.e., first order).

%If you wanted a parametric modulator on the second condition you include
%the second one as follows
pmod{2}.name{2}  = 'another-modulator';
pmod{2}.param{2} = [48 52 8 -43 -55];
pmod{2}.poly{2}  = 1;

end

%%% example for this script taken from https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=spm;d2ec8a0d.0711