## Usage write_predict_config(outdir,model_dir,image_dir)
## 
## Writes out a <outdir>/predict.config file with the following text:
## [default]
## 
## trainedmodel=<model_dir>
## augimage=<image_dir>
##

function write_predict_config(outdir,model_dir, image_dir)
  predict_config = strcat(outdir,filesep(), 'predict.config');
  out = fopen(predict_config,"w");
  fprintf(out, "[default]\n\n");
  fprintf(out, "trainedmodeldir=%s\n",model_dir);
  fprintf(out, "augimagedir=%s\n",image_dir);
  fclose(out);
endfunction

%!error <undefined> write_predict_config();

# test with valid directory
%!test
%! test_fname = tempname();
%! create_dir(test_fname);
%! write_predict_config(test_fname,'yoyo','bye');
%! config_file = strcat(test_fname,filesep(),'predict.config');
%! assert(exists(config_file));
%! rmdir(test_fname,'s');