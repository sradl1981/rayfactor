function stlWritePlate(fileName, origin, span)

%Calculate normal vector from span (use zero-direction)
normalVec = 1*(span==0);
normNormalVec = norm(normalVec );
if(normNormalVec!=1)
  error('normal vector calculation failed, since length of normal vec is not UNITY!')
endif

%Determine the directions that have a non-zero span
walkDirection(1)=0;
walkDirection(2)=0;
if(span(1)>0)
  walkDirection(1)=1;
  walkVector(1,1:3) = [span(1) 0 0];
 elseif(span(2)>0)
  walkDirection(1)=2;
  walkVector(1,1:3) = [0 span(2) 0];
else
  error('both x and y span are zero. this is impossible!');
endif



if(span(2)>0)
  walkDirection(2)=2;
  walkVector(2,1:3) = [0 span(2) 0];
elseif(span(3)>0)
  walkDirection(2)=3;
  walkVector(2,1:3) = [0 0 span(3)];
else
  error('both x and y span are zero. this is impossible!');
endif

%disp('determined the following walk directions:')
%walkDirection
%disp('determined the following walk vectors:')
%walkVector

%-------------------------
%Triangle number 1

%Write the header
system(['echo ', '  facet normal ', ...
        num2str(normalVec(1)), ' ', ...
        num2str(normalVec(2)), ' ', ...
        num2str(normalVec(3)), ' ', ...
        ''  ...
        ' >>  ', fileName]);
        
system(['echo ', '    outer loop', ...
        ''  ...walkDirection(1)
        ' >>  ', fileName]);
        

point1=origin;
point2=origin+walkVector(1,:);
point3=origin+walkVector(1,:)+walkVector(2,:);
system(['echo ', '      vertex ', ...
        num2str(point1(1)), ' ', num2str(point1(2)), ' ', num2str(point1(3)), ...
        '',  ...
        ' >>  ', fileName]);
system(['echo ', '      vertex ', ...
        num2str(point2(1)), ' ', num2str(point2(2)), ' ', num2str(point2(3)), ...
        '',  ...
        ' >>  ', fileName]);
system(['echo ', '      vertex ', ...
        num2str(point3(1)), ' ', num2str(point3(2)), ' ', num2str(point3(3)), ...
        '',  ...
        ' >>  ', fileName]);
%write the closing section
system(['echo ', '    endloop', ...
        ''  ...
        ' >>  ', fileName]);
system(['echo ', '  endfacet', ...
        ''  ...
        ' >>  ', fileName]);
        
%-------------------------
%Triangle number 2

%Write the header
system(['echo ', '  facet normal ', ...
        num2str(normalVec(1)), ' ', ...
        num2str(normalVec(2)), ' ', ...
        num2str(normalVec(3)), ' ', ...
        ''  ...
        ' >>  ', fileName]);
        
system(['echo ', '    outer loop', ...
        ''  ...walkDirection(1)
        ' >>  ', fileName]);
        
point1=origin+walkVector(1,:)+walkVector(2,:);
point2=origin+walkVector(2,:);
point3=origin;

system(['echo ', '      vertex ', ...
        num2str(point1(1)), ' ', num2str(point1(2)), ' ', num2str(point1(3)), ...
        '',  ...
        ' >>  ', fileName]);
system(['echo ', '      vertex ', ...
        num2str(point2(1)), ' ', num2str(point2(2)), ' ', num2str(point2(3)), ...
        '',  ...
        ' >>  ', fileName]);
system(['echo ', '      vertex ', ...
        num2str(point3(1)), ' ', num2str(point3(2)), ' ', num2str(point3(3)), ...
        '',  ...
        ' >>  ', fileName]);
        
 %write the closing section
system(['echo ', '    endloop', ...
        ''  ...
        ' >>  ', fileName]);
system(['echo ', '  endfacet', ...
        ''  ...
        ' >>  ', fileName]);
        

endfunction
