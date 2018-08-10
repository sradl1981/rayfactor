function stlWriter(fileName, stls)


stlWriterHeadEnd(fileName, true);

for iIt=1:size(stls,2)
  stl=stls{iIt};
  stlWritePlate(fileName, stl.origin, stl.span) ;
endfor

stlWriterHeadEnd(fileName, false);

endfunction
