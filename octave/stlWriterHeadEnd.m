function stlWriterHeadEnd(fileName, init)

if(init)
  system(['rm ', fileName]);
  system(['echo "', 'solid ', fileName(1:end-4), '"'  ...
          ' >>  ', fileName])
else
  system(['echo "', 'endsolid ', fileName(1:end-4), '"'  ...
          ' >>  ', fileName])
endif

endfunction
