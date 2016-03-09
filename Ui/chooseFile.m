function [ dirName, fileName ] = chooseFile(hObject,eventdata,textField)
  [fileName, dirName] = uigetfile();
  if fileName
    fullPath = [dirName fileName];
    set(textField, 'String', fullPath);
  end
end

